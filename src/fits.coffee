require('jDataView/src/jdataview')

# Class for storing and validating FITS headers
class Header
  @keywordPattern = /([A-Z0-9]+)\s*=?\s*(.*)/
  @nonStringPattern = /([^\/]*)\s*\/*(.*)/
  @stringPattern = /'(.*)'\s*\/*(.*)/
  @principalMandatoryKeywords = ['BITPIX', 'NAXIS', 'END']
  @extensionKeywords = ['BITPIX', 'NAXIS', 'PCOUNT', 'GCOUNT']
  @compressedImageKeywords = ['ZIMAGE', 'ZCMPTYPE', 'ZBITPIX', 'ZNAXIS', 'ZNAXISn']
  @compressedImageKeywordsOptional =
    ['ZTILEn', 'ZNAMEn', 'ZVALn', 'ZMASKCMP', 'ZSIMPLE', 'ZTENSION', 'ZEXTEND', 'ZBLOCKED', 'ZPCOUNT', 'ZGCOUNT', 'ZHECKSUM', 'ZDATASUM', 'ZQUANTIZ']
  
  @arrayKeywords = ['BSCALE', 'BZERO', 'BUNIT', 'BLANK', 'CTYPEn', 'CRPIXn', 'CRVALn', 'CDELTn', 'CROTAn', 'DATAMAX', 'DATAMIN']
  @otherReservedKeywords = [
    'DATE', 'ORIGIN', 'BLOCKED',
    'DATE-OBS', 'TELESCOP', 'INSTRUME', 'OBSERVER', 'OBJECT', 'EQUINOX', 'EPOCH',
    'AUTHOR', 'REFERENC',
    'COMMENT', 'HISTORY',
    'EXTNAME', 'EXTVER', 'EXTLEVEL'
  ]

  constructor: ->
    # e.g. [index, value, comment]
    @cards      = {}
    @cardIndex  = 0
    @primary    = false
    @extension  = false

  # Get the index value and comment for a key
  get: (key) ->
    if @cards.hasOwnProperty(key) then return @cards[key] else console.warn("Header does not contain the key #{key}")

  # Get the index for a specified key
  getIndex: (key) ->
    if @cards.hasOwnProperty(key) then return @cards[key][0] else console.warn("Header does not contain the key #{key}")

  # Get the value for a specified key
  getValue: (key) ->
    if @cards.hasOwnProperty(key) then return @cards[key][1] else console.warn("Header does not contain the key #{key}")

  # Get the comment for a specified key
  getComment: (key) ->
    if @cards.hasOwnProperty(key)
      if @cards[key][2]?
        return @cards[key][2]
      else
        console.warn("#{key} does not contain a comment")
    else
      console.warn("Header does not contain the key #{key}")

  # Get comments stored with the COMMENT keyword
  getComments: ->
    if @cards.hasOwnProperty(key) then return @cards['COMMENT'] else console.warn("Header does not contain any COMMENT fields")

  # Get history stored with the HISTORY keyword
  getHistory: ->
    if @cards.hasOwnProperty(key) then return @cards['HISTORY'] else console.warn("Header does not contain any HISTORY fields")

  # Set a key with a passed value and optional comment
  set: (key, value, comment) ->
    if comment
      @cards[key] = [@cardIndex, value, comment]
    else
      @cards[key] = [@cardIndex, value]
    @cardIndex += 1

  # Set comment from the COMMENT keyword
  setComment: (comment) ->
    unless @cards.hasOwnProperty("COMMENT")
      @cards["COMMENT"] = []
      @cardIndex += 1
    @cards["COMMENT"].push(comment)

  # Set history from the HISTORY keyword
  setHistory: (history) ->
    unless @cards.hasOwnProperty("HISTORY")
      @cards["HISTORY"] = []
      @cardIndex += 1
    @cards["HISTORY"].push(history)

  # Checks if the header contains a specified keyword
  contains: (keyword) -> return @cards.hasOwnProperty(keyword)

  # Read a card from the header
  readCard: (line) ->
    match = line.match(Header.keywordPattern)
    [key, value] = match[1..]
    if value[0] is "'"
      match = value.match(Header.stringPattern)
    else
      match = value.match(Header.nonStringPattern)
    [value, comment] = match[1..]
    
    switch key
      when "COMMENT"
        @setComment(value.trim())
      when "HISTORY"
        @setHistory(value.trim())
      else
        @set(key, value.trim(), comment.trim())

  verify: ->
    if @cards.hasOwnProperty("SIMPLE")
      type = "SIMPLE"
      @primary = true
      keywords = Header.principalMandatoryKeywords
    else
      type = "XTENSION"
      @extension = true
      keywords = Header.extensionKeywords

    cardIndex = 0
    unless @getIndex(type) is cardIndex
      console.warn("#{type} should be the first keyword in the header")
      cardIndex -= 1
    cardIndex += 1

    for keyword in keywords
      throw "Header does not contain the required keyword #{keyword}" unless @cards.hasOwnProperty(keyword)
      if keyword is "END"
        console.warn("#{keyword} is not in the correct order") unless @getIndex(keyword) is @cardIndex - 1
      else
        console.warn("#{keyword} is not in the correct order") unless @getIndex(keyword) is cardIndex
      cardIndex += 1

      if keyword is "NAXIS"
        axisIndex = 1
        while axisIndex <= parseInt(@getValue("NAXIS"))
          naxisKeyword = keyword + axisIndex
          throw "Header does not contain the required keyword #{naxisKeyword}" unless @cards.hasOwnProperty(naxisKeyword)
          console.warn("#{naxisKeyword} is not in the correct order") unless @getIndex(naxisKeyword) is cardIndex
          cardIndex += 1
          axisIndex += 1

  hasDataUnit: ->
    return if parseInt(@getValue("NAXIS")) is 0 then false else true

  isPrimary: -> return @primary
  isExtension: -> return @extension

class Data

  constructor: (begin, header) ->
    @begin = begin

class Image extends Data

    constructor: (begin, header) ->
      super

      naxis   = parseInt(header.getValue("NAXIS"))
      bitpix  = parseInt(header.getValue("BITPIX"))

      i = 1
      numberOfPixels = 1
      while i <= naxis
        numberOfPixels *= parseInt(header.getValue("NAXIS#{i}"))
        i += 1
      @length = numberOfPixels * Math.abs(bitpix) / 8

      # Determine which function is used to read the image data
      # if bitpix < 0
      #   @accessor = "get" + "#{@bitpix}".replace("-", "Float")
      # else if bitpix > 8
      #   @accessor = "get" + "Int#{@bitpix}"
      # else
      #   @accessor = "get" + "Uint#{@bitpix}"

      switch bitpix
        when 8
          @accessor = 'getUint8'
        when 16
          @accessor = 'getInt16'
        when 32
          @accessor = 'getInt32'
        when -32
          @accessor = 'getFloat32'
        when -64
          @accessor = 'getFloat64'
        else
          throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, -32, -64]"

class BinTable extends Data
  
  constructor: (begin, header) ->
    super

    naxis1 = parseInt(header.getValue("NAXIS1"))
    naxis2 = parseInt(header.getValue("NAXIS2"))
    @length           = naxis1 * naxis2
    @compressedImage  = header.contains("ZIMAGE")

class HDU

  constructor: (header, data)->
    @header = header
    @data   = data

class File
  @LINEWIDTH   = 80
  @BLOCKLENGTH = 2880
  @BITPIX = [8, 16, 32, -32, -64]

  constructor: (buffer) ->
    @length     = buffer.byteLength
    @view       = new jDataView buffer, undefined, undefined, false
    @hdus       = []
    @eof        = false

    loop
      header = @readHeader()
      data = @readData(header)
      hdu = new HDU(header, data)
      @hdus.push(hdu)
      break if @eof

  # ##Class Methods

  # Determine the number of characters following a header or data unit
  @excessChars: (length) ->
    return File.BLOCKLENGTH - (length) % File.BLOCKLENGTH

  # ##Instance Methods

  # Read a header unit
  readHeader: ->
    linesRead = 0
    header = new Header()
    loop
      line = @view.getString(File.LINEWIDTH)
      linesRead += 1
      header.readCard(line)
      break if line[0..2] is "END"
    header.verify()

    # Seek to the next relavant character in file
    excess = File.excessChars(linesRead * File.LINEWIDTH)
    @view.seek(@view.tell() + excess)
    @checkEOF()

    return header

  # Read a data unit
  readData: (header) ->
    return unless header.hasDataUnit()
    if header.isPrimary()
      data = new Image(@view.tell(), header)
      excess = 0
    else
      data = new BinTable(@view.tell(), header)
      excess = File.excessChars(data.length)
      # if data.compressedImage
      #   excess = 0
      # else
      #   excess = File.excessChars(data.length)

    # Forward to the next HDU
    @view.seek(@view.tell() + data.length + excess)
    @checkEOF()
    console.log data, @length, @view.tell()
    return data

  checkEOF: -> @eof = true if @view.tell() is @length

FITS = @FITS    = {}
module?.exports = FITS

FITS.version    = '0.0.1'
FITS.File       = File
FITS.Header     = Header
FITS.Data       = Data
FITS.Image      = Image
FITS.BinTable   = BinTable