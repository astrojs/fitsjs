
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
    
    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(bitpix) / 8
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
  
  getFrame: (@frame = @frame) ->
    length = @width * @height
    
    # Initialize appropriate typed array
    arr = new @arrayType(length)
    
    # Update the offset
    @offset = @begin + @frame * arr.byteLength
    
    # Read each pixel from the buffer
    for index in [0..length - 1]
      arr[index] = @accessor()
      @offset += @bytes
    
    # Increment frame number when handling data cubes
    @frame += 1 if @isDataCube()
    
    return arr
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image