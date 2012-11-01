HDU         = require('./fits.hdu')
Header      = require('./fits.header')
Image       = require('./fits.image')
CompImage   = require('./fits.compressedimage')
Table       = require('./fits.table')
BinaryTable = require('./fits.binarytable')


# File is the class that parses all the HDUs, initializes Header instances
# and appropriate Data instances.
class File
  @LINEWIDTH   = 80
  @BLOCKLENGTH = 2880
  
  @getType: (obj) -> return Object.prototype.toString.call(obj).slice(8, -1).toLowerCase()
  
  constructor: (buffer) ->
    name = File.getType(buffer)
    switch name
      when 'arraybuffer'
        @initFromBuffer(buffer)
      when 'object'
        @initFromObject(buffer)
      else
        throw 'fitsjs cannot initialize object'

  # ##Class Methods

  # Determine the number of characters following a header or data unit
  @excessBytes: (length) -> return (File.BLOCKLENGTH - (length % File.BLOCKLENGTH)) % File.BLOCKLENGTH

  @extendDataView: (view) ->
    
    # Add methods to native DataView object
    DataView::getString = (length) ->
      value = ''
      for i in [0..length - 1]
        c = @getUint8()
        value += String.fromCharCode(if c > 127 then 65533 else c)
      return value

    DataView::getChar = -> return @getString(1)
    
    view.offset = 0
    
    getInt8     = view.getInt8      # unsigned long byteOffset
    getUint8    = view.getUint8     # unsigned long byteOffset
    getInt16    = view.getInt16     # unsigned long byteOffset, optional boolean littleEndian
    getUint16   = view.getUint16    # unsigned long byteOffset, optional boolean littleEndian
    getInt32    = view.getInt32     # unsigned long byteOffset, optional boolean littleEndian
    getUint32   = view.getUint32    # unsigned long byteOffset, optional boolean littleEndian
    getFloat32  = view.getFloat32   # unsigned long byteOffset, optional boolean littleEndian
    getFloat64  = view.getFloat64   # unsigned long byteOffset, optional boolean littleEndian
    
    view.getInt8 = ->
      value = getInt8.apply(@, [@offset])
      @offset += 1
      return value
    
    view.getUint8 = ->
      value = getUint8.apply(@, [@offset])
      @offset += 1
      return value
      
    view.getInt16 = ->
      value = getInt16.apply(@, [@offset, false])
      @offset += 2
      return value
      
    view.getUint16 = ->
      value = getUint16.apply(@, [@offset, false])
      @offset += 2
      return value
      
    view.getInt32 = ->
      value = getInt32.apply(@, [@offset, false])
      @offset += 4
      return value
      
    view.getUint32 = ->
      value = getUint32.apply(@, [@offset, false])
      @offset += 4
      return value
      
    view.getFloat32 = ->
      value = getFloat32.apply(@, [@offset, false])
      @offset += 4
      return value
      
    view.getFloat64 = ->
      value = getFloat64.apply(@, [@offset, false])
      @offset += 8
      return value
    
    view.seek = (offset) -> @offset = offset
    view.tell = -> return @offset

  # ##Instance Methods
  
  # Initialize the object from an array buffer
  initFromBuffer: (buffer) ->
    @length     = buffer.byteLength
    @view       = new DataView buffer
    @hdus       = []
    @eof        = false

    File.extendDataView(@view)
    
    loop
      header  = @readHeader()
      data    = @readData(header)
      hdu = new HDU(header, data)
      @hdus.push hdu
      break if @eof
  
  # Initialize the object from a serialized instance
  initFromObject: (buffer) ->
    @length = buffer.length
    @view   = null
    @hdus   = buffer.hdus
    @eof    = true

  # Extracts a single header without interpreting each line (interpretation is slow for large headers)
  readHeader: ->
    whitespacePattern = /\s{80}/
    endPattern = /^END\s/
    
    # Store the current byte offset and mark when the header END has been reached
    beginOffset = @view.tell()
    done = false
    loop
      break if done
      
      # Grab a 2880 block
      block = @view.getString(File.BLOCKLENGTH)
      
      # Set a line counter
      i = 0
      loop
        # Search for the END keyword starting at the last line of the block
        start = File.BLOCKLENGTH - File.LINEWIDTH * (i + 1)
        end   = File.BLOCKLENGTH - File.LINEWIDTH * i
        line  = block.slice(start, end) # Is this expensive?
        
        # Search one line up if white space is matched
        match = line.match(whitespacePattern)
        if match
          i += 1
          continue
        
        # Otherwise attempt to match END
        match = line.match(endPattern)
        if match
          endOffset = @view.tell()
          @view.seek(beginOffset)
          
          # Grab the entire chunk representing the header
          # TODO: Another option would be to concatentate the header as we go.
          #       Not sure if this is memory efficient when dealing with ~10000
          #       line headers.
          block = @view.getString(endOffset - beginOffset)
          
          # TODO: Send to Header object for interpretion of mandatory and reserved keywords
          header = new Header()
          header.init(block)
          done = true
          @checkEOF()
          return header
        
        # Otherwise grab next block
        break

  # Read a data unit and initialize an appropriate instance depending
  # on the type of data unit (e.g. image, binary table, ascii table).
  # Note: Bytes are not interpreted by this function.  That is left 
  #       to the user to call when the data is needed.
  readData: (header) ->
    return unless header.hasDataUnit()
    
    if header.isPrimary()
      data = new Image(@view, header)
    else if header.isExtension()
      if header.extensionType is "BINTABLE"
        if header.contains("ZIMAGE")
          data = new CompImage(@view, header)
        else
          data = new BinaryTable(@view, header)
      else if header.extensionType is "TABLE"
        data = new Table(@view, header)
      else if header.extensionType is "IMAGE"
        data = new Image(@view, header)
      
    excess = File.excessBytes(data.length)
    
    # Forward to the next HDU
    @view.seek(@view.tell() + data.length + excess)
    @checkEOF()
    return data

  checkEOF: -> @eof = true if @view.offset >= @length

  # Count the number of HDUs
  count: -> return @hdus.length
  
  # ### API
  
  # Returns the first HDU containing a data unit.  An optional argument may be passed to retreive 
  # a specific HDU
  getHDU: (index = undefined) ->
    return @hdus[index] if index? and @hdus[index]?
    for hdu in @hdus
      return hdu if hdu.hasData()
  
  # Returns the header associated with the first HDU containing a data unit.  An optional argument
  # may be passed to point to a specific HDU.
  getHeader: (index = undefined) -> return @getHDU(index).header
  
  # Returns the data object associated with the first HDU containing a data unit.  This method does not read from the array buffer
  # An optional argument may be passed to point to a specific HDU.
  getDataUnit: (index = undefined) -> return @getHDU(index).data

  # Returns the data associated with the first HDU containing a data unit.  An optional argument
  # may be passed to point to a specific HDU.
  getData: (index = undefined) -> return @getHDU(index).data.getFrame()
  
module?.exports = File