
ImageUtils =
  
  # Compute the minimum and maximum pixels
  getExtent: (arr) ->
    
    # Set initial values for min and max
    index = arr.length
    while index--
      value = arr[index]
      continue if isNaN(value)
      
      min = max = value
      break
    
    if index is -1
      return [NaN, NaN]
    
    # Continue loop to find extent
    while index--
      value = arr[index]
      
      if isNaN(value)
        continue
      
      if value < min
        min = value
      
      if value > max
        max = value
      
    return [min, max]
  
  getPixel: (arr, x, y) ->
    return arr[y * @width + x]


@astro.FITS.ImageUtils = ImageUtils