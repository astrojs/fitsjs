require('jDataView/src/jdataview')
Header    = require('./fits.header')
Image     = require('./fits.image')
CompImage = require('./fits.compressedimage')

# Compute basic statistics for a image
class ImageStats

  constructor: (@image) ->
    [@minimum, @maximum] = @image.getExtremes()
    @pixels = @image.naxis.reduce((a, b) -> a * b)
    
    @mean       = undefined
    @std        = undefined
    @histogram  = undefined
    @bins       = undefined

  computeMean: ->
    return @mean if @mean?
    
    sum = 0
    sum += pixel for pixel in @image.data
    @mean = sum / @pixels

  computeSTD: ->
    return @std if @std?
    @computeMean() unless @mean?
    
    sum = 0
    for pixel in @image.data
      diff = pixel - @mean
      sum += (diff * diff)
    @std = Math.sqrt(sum / @pixels)

  computeHistogram: (@bins = 100) ->
    range       = @maximum - @minimum
    binSize     = range / @bins
    data        = @image.data
    
    if @pixels < 256
      arrayType = Uint8Array
    else if @pixels < 65535
      arrayType = Uint16Array
    else
      arrayType = Uint32Array
    
    @histogram = new arrayType(@bins + 1)
    for pixel in data
      index = Math.floor(((pixel - @minimum) / range) * @bins)
      @histogram[index] += 1
    return @histogram
    
module?.exports = ImageStats