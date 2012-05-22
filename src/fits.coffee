require('jDataView/src/jdataview')

class Fits
  @LINEWIDTH   = 80
  @BLOCKLENGTH = 2880

  constructor: (buffer) ->
    @view = new jDataView buffer, undefined, undefined, false
    @hdus = {}

  parseHeaders: ->
    linesRead = 0
    headerString = ""

    loop
      line = @view.getString(@LINEWIDTH)
      headerString += line
      linesRead += 1
      [key, value] = line.split("=")

      bitpix  = Fits.readCard(value, 'int') if key.match("BITPIX")
      columns = Fits.readCard(value, 'int') if key.match("NAXIS1")
      rows    = Fits.readCard(value, 'int') if key.match("NAXIS2")

      break if line[0..2] is "END"

    excess = Fits.excessChars(linesRead)
    @view.seek(@LINEWIDTH * linesRead + excess)

  @readCard: (str) ->
    card = {}

    line = line.split('=')
    key = line[0].trim()
    card['key']   = key
    card['data']  = {}
    if line[1]?
      value = line[1]
      value = value.split('/')
      card['data']['value']   = value[0].trim()
      card['data']['comment'] = value[1].trim() if value[1]?
    return card

  # @readCard: (str, format) ->
  #   value = str.split('/')[0].trim()
  #   switch format
  #     when 'int'
  #       return parseInt(value)
  #     when 'float'
  #       return parseFloat(value) 
  #     else 'string'
  #       return value

  @excessChars: (lines) -> return @BLOCKLENGTH - (lines * @LINEWIDTH) % @BLOCKLENGTH

module.exports = Fits