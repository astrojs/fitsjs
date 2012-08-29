
ImageUtils =
  
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

module?.exports = ImageUtils