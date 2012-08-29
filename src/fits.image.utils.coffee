
ImageUtils =
  
  # Initializes a 1D array for storing image pixels for a single frame
  initArray: (arrayType) -> @data = new arrayType(@width * @height)
  
  # Compute the minimum and maximum pixels
  getExtremes: ->
    return [@min, @max] if @min? and @max?
    
    index = @data.length
    while index--
      value = @data[index]
      continue if isNaN(value)
      
      [min, max] = [value, value]
      break
    
    while index--
      value = @data[index]
      continue if isNaN(value)
      min = value if value < min
      max = value if value > max
    
    [@min, @max] = [min, max]
    return [@min, @max]

  # Get the value of a pixel.
  # Note: Indexing of pixels starts at 0.
  getPixel: (x, y) ->
    return @data[y * @width + x]
    # byteSize = @rowByteSize / @width
    # @view.offset = @begin + (@frame - 1) * @height * @rowByteSize + y * @rowByteSize + x * byteSize
    # return @accessor()

module?.exports = ImageUtils