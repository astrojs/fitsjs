# Container class for multiple FITS images
class ImageSet

  constructor: ->
    @images = {}
    @keys = []
    @minimum = undefined
    @maximum = undefined
    @count = 0
  
  getExtremes: ->
    minimums = []
    maximums = []
    for key, image of @images
      image.hdus[0].data.getFrameWebGL()
      extremes = image.hdus[0].data.getExtremes()
      minimums.push extremes[0]
      maximums.push extremes[1]
    
    @minimum = Math.min.apply Math, minimums
    @maximum = Math.max.apply Math, maximums
  
  addImage: (image) ->
    filter = image.hdus[0].header["FILTER"] || @count
    @keys.push filter
    @images[filter] = image
    index = @count
    @.__defineGetter__(index, -> return @images[@keys[index]])
    @count += 1
  
  getWidth: ->
    key = @keys[0]
    return null unless @images[key]?
    return @images[key].hdus[0].header["NAXIS1"]

  getHeight: ->
    key = @keys[0]
    return null unless @images[key]?
    return @images[key].hdus[0].header["NAXIS2"]
  
  getCount: -> return @count
  
  getData: (filter) -> return @[filter].hdus[0].data.data

module?.exports = ImageSet