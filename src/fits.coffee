require('jDataView/src/jdataview')

class Fits
  Fits.LINEWIDTH   = 80
  Fits.BLOCKLENGTH = 2880
  Fits.headerPattern = /([A-Z0-9]+)\s*=?\s*([^\/]+)\s*\/?\s*(.*)/
  Fits.BITPIX = [8, 16, 32, -32, -64]
  Fits.mandatoryKeywords = ['BITPIX', 'NAXIS', 'END']
  # Fits.mandatoryKeywords = ['SIMPLE', 'BITPIX', 'NAXIS', 'END']

  constructor: (buffer) ->
    @view       = new jDataView buffer, undefined, undefined, false
    @headers    = []
    @dataunits  = []

    @headerNext = true
    @parseHeader() while @headerNext

  # ##Class Methods

  # Read a card from the header
  @readCard: (row, header) ->
    match = row.match(Fits.headerPattern)
    [key, value, comment] = match[1..]
    header[key] = value.trim()

  # Determine the number of characters following a header or data unit
  @excessChars: (lines) ->
    return Fits.BLOCKLENGTH - (lines * Fits.LINEWIDTH) % Fits.BLOCKLENGTH

  # ##Instance Methods

  # Parse the header
  parseHeader: ->
    linesRead = 0
    header = {}
    loop
      line = @view.getString(Fits.LINEWIDTH)
      Fits.readCard(line, header)
      linesRead += 1
      break if line[0..2] is "END"
    @headers.push(header)

    # Check for mandatory keywords
    for keyword in Fits.mandatoryKeywords
      throw "FITS does not contain the required keyword #{keyword}" unless header.hasOwnProperty(keyword)

    naxis = parseInt(header["NAXIS"])
    bitpix = parseInt(header["BITPIX"])

    i = 1
    while i <= naxis
      throw "FITS does not contain the required keyword NAXIS#{i}" unless header.hasOwnProperty("NAXIS#{i}")
      i += 1

    # Determine if a header or data unit follows
    @headerNext = if naxis is 0 then true else false

    # Seek to the next relavant character in file
    excess = Fits.excessChars(linesRead)
    @view.seek(Fits.LINEWIDTH * linesRead + excess)

module.exports = Fits