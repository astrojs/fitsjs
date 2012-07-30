# Header data unit to store a header and its associated data unit
class HDU

  constructor: (@header, @data) ->
  
  hasData: -> return if @data? then true else false
  
  # ### API
  
  # Returns the value from the header of the user specifed key
  getCard: (key) -> return @header[key]

module?.exports = HDU