# Header data unit to store a header and its associated data unit
class HDU

  constructor: (@header, @data) ->
  
  hasData: ->
    return if @data? then true else false


@astro.FITS.HDU = HDU