
# Image represents a standard image stored in the data unit of a FITS file
class Image extends DataUnit
  @include ImageUtils
  
  
  constructor: (header, view, offset) ->
    super
    naxis   = header.get("NAXIS")
    bitpix  = header.get("BITPIX")
    
    @naxis = []
    @naxis.push header.get("NAXIS#{i}") for i in [1..naxis]
    
    @width  = header.get("NAXIS1")
    @height = header.get("NAXIS2") or 1
    
    @bzero  = header.get("BZERO") or 0
    @bscale = header.get("BSCALE") or 1
    
    @bytes = Math.abs(bitpix) / 8
    @rowByteSize = @width * @bytes
    @totalRowsRead = 0
    
    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(bitpix) / 8
    @data   = undefined
    @frame  = 0    # Needed for data cubes
    
    # Define the function that interprets the data
    switch bitpix
      when 8
        if @bscale % 1 is 0
          @arrayType  = Uint8Array
          @accessor   = => return @bzero + @bscale * @view.getUint8(@offset)
        else
          @arrayType  = Float32Array
          @accessor   = => return @bzero + @bscale * @view.getUint8(@offset)
      when 16
        if @bscale % 1 is 0
          @arrayType  = Int16Array
          @accessor   = => return @bzero + @bscale * @view.getInt16(@offset)
        else
          @arrayType  = Float32Array
          @accessor   = => return @bzero + @bscale * @view.getInt16(@offset)
      when 32
        if @bscale % 1 is 0
          @arrayType  = Int32Array
          @accessor   = => return @bzero + @bscale * @view.getUint32(@offset)
        else
          @arrayType  = Float32Array
          @accessor   = => return @bzero + @bscale * @view.getUint32(@offset)
      when -32
        @arrayType  = Float32Array
        @accessor   = => return @bzero + @bscale * @view.getFloat32(@offset)
      else
        throw "Invalid BITPIX"
  
  incrementOffset: => @offset += @bytes
  
  # Read a row of pixels from the array buffer.  The method initArray
  # must be called before requesting any rows.
  getRow: ->
    @offset = @begin + @totalRowsRead * @rowByteSize
    
    for i in [0..@width - 1]
      @data[@width * @rowsRead + i] = @accessor()
      @incrementOffset()
    
    @rowsRead += 1
    @totalRowsRead += 1
  
  # Read the entire frame of the image.  If the image is a data cube, it reads
  # a slice of the data.
  getFrame: (@frame = @frame) ->
    @initArray(@arrayType) unless @data?
    
    @totalRowsRead = @width * @frame
    @rowsRead = 0
    
    height = @height
    @getRow() while height--
    
    @frame += 1
    return @data

  # Moves the pointer that is used to read the array buffer to a specified frame.  For 2D images
  # this defaults to the first and only frame.  Indexing of the frame argument begins at 0.
  seek: (frame = 0) ->
    if @naxis.length is 2
      @totalRowsRead  = 0
      @frame          = 0
    else
      @totalRowsRead  = @height * frame
      @frame          = @height / @totalRowsRead - 1
  
  # Checks if the image is a data cube
  isDataCube: -> return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image