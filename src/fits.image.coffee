Data  = require('./fits.data')

# Image represents a standard image stored in the data unit of a FITS file
class Image extends Data

  constructor: (view, header) ->
    super

    naxis   = header["NAXIS"]
    bitpix  = header["BITPIX"]
    
    @naxis = []
    @naxis.push header["NAXIS#{i}"] for i in [1..naxis]
    @rowByteSize = header["NAXIS1"] * Math.abs(bitpix) / 8
    @rowsRead = 0
    @min = if header["DATAMIN"]? then header["DATAMIN"] else undefined
    @max = if header["DATAMAX"]? then header["DATAMAX"] else undefined

    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(bitpix) / 8
    @data   = undefined
    @frame  = -1    # Only relevant for data cubes
    
    # Define the function to interpret the image data
    switch bitpix
      when 8
        @arrayType  = Uint8Array
        @accessor   = => return @view.getUint8()
      when 16
        @arrayType  = Int16Array
        @accessor   = => return @view.getInt16()
      when 32
        @arrayType  = Int32Array
        @accessor   = => return @view.getInt32()
      when 64
        @arrayType  = Int32Array
        @accessor   = =>
          console.warn "Something funky happens here when dealing with 64 bit integers.  Be wary!!!"
          highByte  = Math.abs @view.getInt32()
          lowByte   = Math.abs @view.getInt32()
          mod       = highByte % 10
          factor    = if mod then -1 else 1
          highByte  -= mod
          value     = factor * ((highByte << 32) | lowByte)
          return value
      when -32
        @arrayType  = Float32Array
        @accessor   = => return @view.getFloat32()
      when -64
        @arrayType  = Float64Array
        @accessor   = => return @view.getFloat64()
      else
        throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, 64, -32, -64]"

  # Initializes a 1D array for storing image pixels
  initArray: -> @data = new @arrayType(@naxis.reduce( (a, b) -> a * b))

  # Read a row of pixels from the array buffer.  The method initArray
  # must be called before requesting any rows.
  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    rowLength = @naxis[0]
    @view.seek(@current)
    for i in [0..rowLength - 1]
      @data[rowLength * @rowsRead + i] = @accessor()
    @rowsRead += 1
  
  # Read the entire frame of the image.  If the image is a data cube, it reads
  # a slice of the data.  It's not required to call initArray prior, though there
  # is no harm in doing so.
  getFrame: ->
    @initArray() unless @data?
    @getRow() for i in [0..@naxis[1] - 1]
    @frame += 1
    return @data
  
  # Read the entire image and return the pixels in a typed array for WebGL.
  # A Float32Array is used for now because I have not been able to render other
  # typed arrays aside from Uint8.  This method will be deprecated when I figure
  # that out.
  getFrameWebGL: ->
    @data = new Float32Array(@naxis.reduce( (a, b) -> a * b))
    @rowsRead = 0
    rowLength = @naxis[0]
    
    for j in [0..@naxis[1] - 1]
      @current = @begin + @rowsRead * @rowByteSize
      @view.seek(@current)
      for i in [0..rowLength - 1]
        @data[rowLength * @rowsRead + i] = @accessor()
      @rowsRead += 1
      
    @frame += 1
    return @data
  
  # Compute the minimum and maximum pixels
  getExtremes: ->
    return [@min, @max] if @min? and @max?
    
    for value, index in @data
      continue if isNaN(value)
      [min, max] = [value, value]
      break
    
    for i in [index..@data.length - 1]
      value = @data[i]
      continue if isNaN(value)
      min = value if value < min
      max = value if value > max
    
    [@min, @max] = [min, max]
    return [@min, @max]
  
  # Get the value of a pixel.
  # Note: Indexing of pixels starts at 0.
  getPixel: (x, y) -> return @data[(@frame * @naxis[0] * @naxis[1]) + y * @naxis[0] + x]

  # Moves the pointer that is used to read the array buffer to a specified frame.  For 2D images
  # this defaults to the first and only frame.  Indexing of the frame argument begins at 0.
  seek: (frame = 0) ->
    if @naxis.length is 2
      @rowsRead = 0
      @frame    = -1
    else
      @rowsRead = @naxis[1] * (frame + 1)
      @frame    = @naxis[1] / @rowsRead - 1
  
  # Checks if the image is a data cube
  isDataCube: -> return if @naxis.length is 3 then true else false
    
module?.exports = Image