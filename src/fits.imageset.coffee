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
      data = image.getHDU().data
      data.getFrame()
      extremes = data.getExtremes()
      minimums.push extremes[0]
      maximums.push extremes[1]
    
    @minimum = Math.min.apply Math, minimums
    @maximum = Math.max.apply Math, maximums
  
  addImage: (image) ->
    filter = image.getHDU().header["FILTER"] or @count
    @keys.push filter
    @images[filter] = image
    index = @count
    @.__defineGetter__(index, -> return @images[@keys[index]])
    @count += 1
  
  getWidth: ->
    key = @keys[0]
    return null unless @images[key]?
    return @images[key].getHDU().header["NAXIS1"]

  getHeight: ->
    key = @keys[0]
    return null unless @images[key]?
    return @images[key].getHDU().header["NAXIS2"]
  
  getCount: -> return @count
  
  getData: (filter) -> return @[filter].getHDU().data.data
  
  seek: (frame = 0) ->
    for key, image of @images
      image.getDataUnit.seek(frame)

module?.exports = ImageSet