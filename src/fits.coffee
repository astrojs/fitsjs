require('jDataView/src/jdataview')

class Fits
  Fits.LINEWIDTH   = 80
  Fits.BLOCKLENGTH = 2880
  Fits.headerPattern = /([A-Z0-9]+)\s*=?\s*([^\/]+)\s*\/?\s*(.*)/
  Fits.BITPIX = [8, 16, 32, -32, -64]
  Fits.mandatoryKeywords = ['BITPIX', 'NAXIS', 'END'] 
  Fits.requiredBinTableKeywords = ['XTENSION', 'BITPIX', 'NAXIS', 'NAXIS1', 'NAXIS2', 'PCOUNT', 'GCOUNT', 'TFIELDS', 'TFORM']

  constructor: (buffer) ->
    @length     = buffer.byteLength
    @view       = new jDataView buffer, undefined, undefined, false
    @headers    = []
    @dataunits  = []

    @headerNext = true
    @eof        = false

    @readHeader() while @headerNext
    @readData()

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

  # Read a header unit
  readHeader: ->
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

    @checkEOF()

  # Read a data unit
  readData: ->
    # Select the last read header
    header = @headers[@headers.length - 1]
    
    # Read for an extension
    extension = header["XTENSION"] if header.hasOwnProperty("XTENSION")
    
    @readBinTable(header) if extension is "'BINTABLE'"

    bitpix = parseInt(header["BITPIX"])
    switch bitpix
      when 8
        @view.getData = @view.getUint8
      when 16
        @view.getData = @view.getInt16
      when 32
        @view.getData = @view.getInt32
      when -32
        @view.getData = @view.getFloat32
      when -64
        @view.getData = @view.getFloat64
      else
        throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, -32, -64]"

    data = []

    # Determine how many points to read
    naxis = parseInt(header["NAXIS"])
    i = 1
    numberOfPixels = 1
    while i <= naxis
      numberOfPixels *= parseInt(header["NAXIS#{i}"])
      i += 1
    numberOfPixels

    # Read the data
    i = 0
    while numberOfPixels
      data.push(@view.getData())
      numberOfPixels -= 1

    @dataunits.push(data)
    @checkEOF()

  checkEOF: -> @eof = true if @view.tell() is @length

  readBinTable: (header) ->
    # Check for required keywords
    for keyword in Fits.requiredBinTableKeywords
      if keyword is "TFORM"
        tfields = parseInt(header["TFIELDS"])
        i = 1
        while i <= tfields
          throw "FITS binary table does not contain the required keyword TFORM#{i}" unless header.hasOwnProperty("TFORM#{i}")
          i += 1
      else
        throw "FITS binary table does not contain the required keyword #{keyword}" unless header.hasOwnProperty(keyword)


module.exports = Fits