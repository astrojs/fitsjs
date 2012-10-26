Data        = require('./fits.data')
ImageUtils  = require('./fits.image.utils')

# Image represents a standard image stored in the data unit of a FITS file
class Image extends Data
  @include ImageUtils
  
  constructor: (view, header) ->
    super
    naxis   = header["NAXIS"]
    bitpix  = header["BITPIX"]
    
    @naxis = []
    @naxis.push header["NAXIS#{i}"] for i in [1..naxis]
    
    @width  = header["NAXIS1"]
    @height = header["NAXIS2"] or 1
    
    @rowByteSize = @width * Math.abs(bitpix) / 8
    @totalRowsRead = 0
    
    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(bitpix) / 8
    @data   = undefined
    @frame  = 0    # Only relevant for data cubes
    
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

  # Read a row of pixels from the array buffer.  The method initArray
  # must be called before requesting any rows.
  getRow: ->
    @current = @begin + @totalRowsRead * @rowByteSize
    @view.seek(@current)
    
    for i in [0..@width - 1]
      @data[@width * @rowsRead + i] = @accessor()
    
    @rowsRead += 1
    @totalRowsRead += 1
  
  # Read the entire frame of the image.  If the image is a data cube, it reads
  # a slice of the data.
  getFrame: (@frame = @frame) ->
    @initArray(@arrayType) unless @data?
    
    @totalRowsRead = @width * @frame
    @rowsRead = 0
    
    height = @height
    while height--
      @getRow()
    
    @frame += 1
    return @data

  # getFrame: (@frame = @frame) =>
  #   length = @width * @height
  #   buffer = @view.buffer.slice(@begin, @begin + 2 * length)
  #   @data = new Uint16Array(buffer)
  #   for index in [0..length-1]
  #     value = @data[index]
  #     @data[index] = (((value & 0xFF) << 8) | ((value >> 8) & 0xFF))
  #     
  #   @frame += 1
  #   @rowsRead = @totalRowsRead = @frame * @width
  #   return @data

  # Moves the pointer that is used to read the array buffer to a specified frame.  For 2D images
  # this defaults to the first and only frame.  Indexing of the frame argument begins at 0.
  seek: (frame = 0) ->
    if @naxis.length is 2
      @totalRowsRead = 0
      @frame    = 0
    else
      @totalRowsRead = @height * frame
      @frame    = @height / @totalRowsRead - 1
  
  # Checks if the image is a data cube
  isDataCube: -> return if @naxis.length > 2 then true else false
    
module?.exports = Image