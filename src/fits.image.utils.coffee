
ImageUtils =
  
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


module?.exports = ImageUtils