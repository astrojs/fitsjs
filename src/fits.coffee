

@astro = {} unless @astro?


class Base
  @include: (obj) ->
    for key, value of obj
      @::[key] = value
    this

  @extend: (obj) ->
    for key, value of obj
      @[key] = value
    this

  proxy: (func) ->
    => func.apply(this, arguments)
  
  invoke: (callback, opts, data) ->
    context = if opts?.context? then opts.context else @
    callback.call(context, data, opts) if callback?


class Parser extends Base
  LINEWIDTH: 80
  BLOCKLENGTH: 2880
  
  # Prefix function for Safari :(
  File.prototype.slice = File.prototype.slice or File.prototype.webkitSlice
  Blob.prototype.slice = Blob.prototype.slice or Blob.prototype.webkitSlice
  
  # FITS objects are constructed using either
  # 1) Path to a remote FITS file
  # 2) Native File object
  
  # First argument is either a path or File object
  # Second argument is a callback to execute after
  # initialization is complete
  # Third argument is a set of options that may be passed
  # to the callback.  If opts has the context key, the callback
  # is executed with respect to that context.
  constructor: (@arg, @callback, @opts) ->
    
    # Storage for header dataunits
    @hdus = []
    
    # Set initial state for parsing buffer
    # Blocks of 2880 will be read until an entire header is read.
    # The process will be repeated until all headers have been parsed from file.
    
    # Number of 2880 blocks read.  This is reset every time an entire header is extracted.
    @blockCount = 0
    
    # Byte offsets relative to the current header
    @begin = 0
    @end = @BLOCKLENGTH
    
    # Byte offset relative to the file
    @offset = 0
    
    # Initial storage for storing header while parsing.
    @headerStorage = new Uint8Array()
    
    # Check the input type for either
    # 1) Path to remote file
    # 2) Native File object
    if typeof(@arg) is 'string'
      
      # Define function at runtime for getting next block
      @readNextBlock = @_readBlockFromBuffer
      
      # Get the remote file as an arraybuffer
      xhr = new XMLHttpRequest()
      xhr.open('GET', @arg)
      xhr.responseType = 'arraybuffer'
      xhr.onload = =>
        
        # Error handling on the response status
        if xhr.status isnt 200
          
          # Execute callback returning a null object on failure
          @invoke(@callback, @opts)
          return
        
        # Get buffer from response
        @arg = xhr.response
        
        # Store the buffer byte length
        @length = @arg.byteLength
        
        # Begin reading buffer
        @readFromBuffer()
      
      # Send the request
      xhr.send()
      
    else
      # Store the file byte length
      @length = @arg.size
      
      # Define function at runtime for getting next block
      @readNextBlock = @_readBlockFromFile
      
      # Get the local file as an arraybuffer
      @readFromFile()
  
  # Interpret an array buffer that is already copied in memory.  Usually
  # used for remote files, though this can be used for local files if
  # the arraybuffer is already in memory.
  readFromBuffer: ->
    
    # Get first 2880 block
    block = @arg.slice(@begin + @offset, @end + @offset)
    
    # Begin parsing for headers
    @readBlock(block)
  
  # Read a file by copying only the headers into memory.  This is needed
  # to handle large files efficiently.
  readFromFile: ->
    
    # Initialize a new FileReader
    @reader = new FileReader()
    
    # Set reader handler
    @reader.onloadend = (e) =>
      @readBlock(e.target.result)
    
    # Get first 2880 block
    block = @arg.slice(@begin + @offset, @end + @offset)
    
    # Begin parsing for headers
    @reader.readAsArrayBuffer(block)
    
  # Read a 2880 size block. Function is responsible for storing block,
  # searching for END marker, initializing an HDU, and clearing storage.
  readBlock: (block) ->
    
    # Read block as integers
    arr = new Uint8Array(block)
    
    # Temporary storage for header
    tmp = new Uint8Array(@headerStorage)
    
    # Reallocate header storage
    @headerStorage = new Uint8Array(@end)
    
    # Copy contents from temporary storage
    @headerStorage.set(tmp, 0)
    
    # Copy contents from current iteration
    @headerStorage.set(arr, @begin)
    
    # Check current array one row at a time starting from
    # bottom of the block.
    rows = @BLOCKLENGTH / @LINEWIDTH
    while rows--
      
      # Get index of first element in row
      rowIndex = rows * @LINEWIDTH
      
      # Go to next row if whitespace found
      continue if arr[rowIndex] is 32
      
      # Check for END keyword with trailing space (69, 78, 68, 32)
      if arr[rowIndex] is 69 and
         arr[rowIndex + 1] is 78 and
         arr[rowIndex + 2] is 68 and
         arr[rowIndex + 3] is 32
        
        # Interpret as string
        s = ''
        for value in @headerStorage
          s += String.fromCharCode(value)
        header = new Header(s)
        
        # Get data unit start and length
        @start = @end + @offset
        dataLength = header.getDataLength()
        
        # Create data unit instance
        slice = @arg.slice(@start, @start + dataLength)
        if header.hasDataUnit()
          dataunit = @createDataUnit(header, slice)
        
        # Store HDU on instance
        @hdus.push( new HDU(header, dataunit) )
        
        # Update byte offset
        @offset += @end + dataLength + @excessBytes(dataLength)
        
        # Return if at the end of file
        if @offset is @length
          @headerStorage = null
          
          @invoke(@callback, @opts, @)
          return
        
        # Reset variables for next header
        @blockCount = 0
        @begin = @blockCount * @BLOCKLENGTH
        @end = @begin + @BLOCKLENGTH
        @headerStorage = new Uint8Array()
        
        # Get next block
        block = @arg.slice(@begin + @offset, @end + @offset)
        
        # Begin parsing for next header
        @readNextBlock(block)
        return
      
      break
    
    # Read next block since END not found
    @blockCount += 1
    @begin = @blockCount * @BLOCKLENGTH
    @end = @begin + @BLOCKLENGTH
    block = @arg.slice(@begin + @offset, @end + @offset)
    @readNextBlock(block)
    return
  
  # Use one of these depending on the initialization parameter (File or ArrayBuffer)
  _readBlockFromBuffer: (block) -> @readBlock(block)
  _readBlockFromFile: (block) -> @reader.readAsArrayBuffer(block)
  
  # Create the appropriate data unit based on info from header
  createDataUnit: (header, blob) ->
    type = header.getDataType()
    return new astro.FITS[type](header, blob)
  
  # Determine the number of characters following a header or data unit
  excessBytes: (length) ->
    return (@BLOCKLENGTH - (length % @BLOCKLENGTH)) % @BLOCKLENGTH
  
  # Check for the end of file
  isEOF: ->
    return if @offset is @length then true else false
  
  
class FITS extends Base
  
  constructor: (@arg, callback, opts) ->
    
    parser = new Parser(@arg, (fits) =>
      @hdus = parser.hdus
      @invoke(callback, opts, @)
    )
  
  # Public API
  
  # Returns the first HDU containing a data unit.  An optional argument may be passed to retreive 
  # a specific HDU
  getHDU: (index) ->
    return @hdus[index] if index? and @hdus[index]?
    for hdu in @hdus
      return hdu if hdu.hasData()

  # Returns the header associated with the first HDU containing a data unit.  An optional argument
  # may be passed to point to a specific HDU.
  getHeader: (index) -> return @getHDU(index).header

  # Returns the data object associated with the first HDU containing a data unit.  This method does not read from the array buffer
  # An optional argument may be passed to point to a specific HDU.
  getDataUnit: (index) -> return @getHDU(index).data


FITS.version = '0.6.5'
@astro.FITS = FITS
