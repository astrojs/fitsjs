
# Parses all header-dataunits, initializes Header instances
# and appropriate dataunit instances.
class File
  LINEWIDTH: 80
  BLOCKLENGTH: 2880
  
  # FITS file may be initialized using either (1) path to a remote
  # file (2) an array buffer or (3) a File object for loading local files
  constructor: (arg, callback, opts = undefined) ->
    @hdus = []
    @offset = 0
    
    if arg instanceof window.File
      @initializeFromFile(arg, callback, opts)
    else if typeof arg is 'string'
      @constructor.extendDataView(@view)
      
      # Get the file using XHR
      xhr = new XMLHttpRequest()
      xhr.open('GET', arg)
      xhr.responseType = 'arraybuffer'
      xhr.onload = =>
        @initializeFromBuffer(xhr.response, callback, opts)
      xhr.send()
    else
      @constructor.extendDataView(@view)
      @initializeFromBuffer(arg)
  
  initializeFromBuffer: (buffer, callback, opts) ->
    @length = buffer.byteLength
    @view   = new DataView buffer
    # Loop until the end of file
    loop
      header  = @readHeader()
      data    = @readData(header)
      hdu = new HDU(header, data)
      @hdus.push hdu
      break if @isEOF()
    
    context = if opts?.context? then opts.context else @
    callback.call(context, @, opts) if callback?
  
  initializeFromFile: (file, callback, opts) ->
    
    # Initialize a new FileReader
    reader = new FileReader()
    
    # Set variables needed for scope of onloadend
    blockCount = begin = end = offset = null
    
    # Running storage for header
    headerStorage = new Uint8Array()
    
    # Set reader handlers
    reader.onloadend = (e) =>
      
      # Read block as integers
      arr = new Uint8Array(e.target.result)
      
      # Temporary storage for header
      tmp = new Uint8Array(headerStorage)
      
      # Reallocate header storage
      headerStorage = new Uint8Array(end)
      
      # Copy contents from temporary storage
      headerStorage.set(tmp, 0)
      
      # Copy contents from current iteration
      headerStorage.set(arr, begin)
      
      # Check current array one row at a time
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
          for value in headerStorage
            s += String.fromCharCode(value)
          header = new Header(s)
          
          # Get data unit start and length
          start = end + offset
          length = header.getDataLength()
          
          # Create data unit instance
          blob = file.slice(start, start + length)
          if header.hasDataUnit()
            data = @createDataUnit(header, blob)
          
          # Store HDU on instance
          @hdus.push( new HDU(header, data) )
          
          # Update byte offset
          offset += end + length + @excessBytes(length)
          
          # Return if at the end of file
          if offset is file.size
            context = if opts?.context? then opts.context else @
            callback.call(context, @, opts) if callback?
            return
          
          # Reset variables for next header
          blockCount = 0
          begin = blockCount * @BLOCKLENGTH
          end = begin + @BLOCKLENGTH
          headerStorage = new Uint8Array()
          
          # Begin parsing for next header
          block = file.slice(begin + offset, end + offset)
          reader.readAsArrayBuffer(block)
          return
        
        # Read next block since END not found
        blockCount += 1
        begin = blockCount * @BLOCKLENGTH
        end = begin + @BLOCKLENGTH
        block = file.slice(begin + offset, end + offset)
        reader.readAsArrayBuffer(block)
        return
    
    # Set start and end byte locations
    offset = 0
    blockCount = 0
    begin = blockCount * @BLOCKLENGTH
    end = begin + @BLOCKLENGTH
    
    # Begin parsing for headers
    block = file.slice(begin + offset, end + offset)
    reader.readAsArrayBuffer(block)
  
  # ##Class Methods

  @extendDataView: (view) ->
    
    # Add methods to native DataView object
    DataView::getString = (offset, length) ->
      value = ''
      while length--
        c = @getUint8(offset)
        offset += 1
        value += String.fromCharCode(if c > 127 then 65533 else c)
      return value
    
    DataView::getChar = (offset) ->
      return @getString(offset, 1)
  
  # ##Instance Methods

  # Determine the number of characters following a header or data unit
  excessBytes: (length) ->
    return (@BLOCKLENGTH - (length % @BLOCKLENGTH)) % @BLOCKLENGTH

  # Extracts a single header without interpreting each line.
  # Interpretation is slow for large headers.
  readHeader: ->
    endPattern = /^END\s/
    
    # Store the current byte offset and mark when the END keyword is reached
    beginOffset = @offset
    loop
      # Grab a 2880 block
      block = @view.getString(@offset, @BLOCKLENGTH)
      @offset += @BLOCKLENGTH
      
      # Set a line counter
      i = 1
      loop
        # Search for the END keyword starting at the last line of the block
        begin = @BLOCKLENGTH - @LINEWIDTH * i
        end   = begin + @LINEWIDTH
        line  = block.slice(begin, end)
        
        # Search one line up if white space is matched
        match = /\s{80}/.test(line)
        if match
          i += 1
          continue
        
        # Otherwise attempt to match END
        match = /^END\s/.test(line)
        if match
          endOffset = @offset
          
          # Get entire block representing header
          block = @view.getString(beginOffset, endOffset - beginOffset)
          return new Header(block)
        
        break
  
  # Create the appropriate data unit based on info from header
  createDataUnit: (header, blob) ->
    type = header.getDataType()
    return new astro.FITS[type](header, blob)
  
  # Read a data unit and initialize an appropriate instance depending
  # on the type of data unit (e.g. image, binary table, ascii table).
  # Note: Bytes are not interpreted by this function.  That is left 
  #       to the user to call when the data is needed.
  readData: (header) ->
    return unless header.hasDataUnit()
    
    if header.isPrimary()
      DU = Image
    else if header.isExtension()
      if header.extensionType is "BINTABLE"
        if header.contains("ZIMAGE")
          DU = CompressedImage
        else
          DU = BinaryTable
      else if header.extensionType is "TABLE"
        DU = Table
      else if header.extensionType is "IMAGE"
        DU = Image
    data = new DU(header, @view, @offset)
    
    excess = @excessBytes(data.length)
    
    # Forward to the next HDU
    @offset += data.length + excess
    
    return data

  isEOF: ->
    return if @offset is @length then true else false
  
  # ### API
  
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

  # Returns the data associated with the first HDU containing a data unit.  An optional argument
  # may be passed to point to a specific HDU.
  getData: (index) -> return @getHDU(index).data.getFrame()


@astro.FITS.File = File