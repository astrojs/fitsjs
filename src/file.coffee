
# Parses all header-dataunits, initializes Header instances
# and appropriate dataunit instances.
class File
  LINEWIDTH: 80
  BLOCKLENGTH: 2880
  
  constructor: (buffer) ->
    @offset = 0
    @length = buffer.byteLength
    @view   = new DataView buffer
    
    @hdus = []
    @eof  = false
    
    @constructor.extendDataView(@view)
    
    # Loop until the end of file
    loop
      header  = @readHeader()
      data    = @readData(header)
      hdu = new HDU(header, data)
      @hdus.push hdu
      break if @eof
  
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
  excessBytes: (length) =>
    return (@BLOCKLENGTH - (length % @BLOCKLENGTH)) % @BLOCKLENGTH

  # Extracts a single header without interpreting each line.
  # Interpretation is slow for large headers.
  readHeader: ->
    whitespacePattern = /\s{80}/
    endPattern = /^END\s/
    
    # Store the current byte offset and mark when the END keyword is reached
    beginOffset = @offset
    done = false
    loop
      break if done
      
      # Grab a 2880 block
      block = @view.getString(@offset, @BLOCKLENGTH)
      @offset += @BLOCKLENGTH
      
      # Set a line counter
      i = 0
      loop
        # Search for the END keyword starting at the last line of the block
        start = @BLOCKLENGTH - @LINEWIDTH * (i + 1)
        end   = @BLOCKLENGTH - @LINEWIDTH * i
        line  = block.slice(start, end) # Is this expensive?
        
        # Search one line up if white space is matched
        match = line.match(whitespacePattern)
        if match
          i += 1
          continue
        
        # Otherwise attempt to match END
        match = line.match(endPattern)
        if match
          endOffset = @offset
          
          # Get entire block representing header
          block = @view.getString(beginOffset, endOffset - beginOffset)
          header = new Header(block)
          done = true
          @checkEOF()
          return header
        
        # Otherwise get next block
        break

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
    @checkEOF()
    return data

  checkEOF: ->
    @eof = true if @offset >= @length
  
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


@astro.FITS.File = File