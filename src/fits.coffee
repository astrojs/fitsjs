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

  constructor: (view, header) ->
    @view   = view
    @begin  = @current = view.tell()

class Image extends Data

    constructor: (view, header) ->
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
  @requiredKeywords = ["TFORM"]
  @optionalKeywords = ["TTYPE", "TUNIT", "TSCAL"]
  @dataTypePattern = /([0-9]*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\(([0-9]*)\)/

  @dataAccessors =
    L: (view) ->
      value = if view.getInt8() is 84 then true else false
      return value
    X: (view) ->
      throw "Data type not yet implemented"
    B: (view) ->
      return view.getUint8()
    I: (view) ->
      return view.getInt16()
    J: (view) ->
      return view.getInt32()
    K: (view) ->
      highByte = Math.abs view.getInt32()
      lowByte = Math.abs view.getInt32()
      mod = highByte % 10
      factor = if mod then -1 else 1
      highByte -= mod
      value = factor * ((highByte << 32) | lowByte)
      console.warn "Something funky happens here when dealing with 64 bit integers.  Be wary!!!"
      return value
    A: (view) ->
      return view.getChar()
    E: (view) ->
      return view.getFloat32()
    D: (view) ->
      return view.getFloat64()
    C: (view) ->
      return [view.getFloat32(), view.getFloat32()]
    M: (view) ->
      return [view.getFloat64(), view.getFloat64()]
      
  constructor: (view, header) ->
    super

    @rowByteSize  = parseInt(header.getValue("NAXIS1"))
    @rows         = parseInt(header.getValue("NAXIS2"))
    @length       = @tableLength = @rowByteSize * @rows
    @compressedImage  = header.contains("ZIMAGE")
    @length += parseInt(header.getValue("PCOUNT")) if @compressedImage
    @rowsRead = 0
    
    # Assuming the header has been verified
    # TODO: Verify the FITS Binary Table header in the Header class
    # Grab the column data types
    @fields = parseInt(header.getValue("TFIELDS"))
    @accessors = []

    for i in [1..@fields]
      keyword = "TFORM#{i}"
      value = header.getValue(keyword)
      match = value.match(BinTable.arrayDescriptorPattern)
      if match?
        do =>
          dataType = match[1]
          accessor = =>
            # TODO: Find out how to pass dataType
            length  = @view.getInt32()
            offset  = @view.getInt32()
            @current = @view.tell()
            # Troublesome
            # TODO: Find a way to preserve the dataType in this function for each column
            @view.seek(@begin + @tableLength + offset)
            data = []
            for i in [1..length]
              data.push BinTable.dataAccessors[dataType](@view)
            @view.seek(@current)
            return data
          @accessors.push(accessor)
      else
        match = value.match(BinTable.dataTypePattern)
        [r, dataType] = match[1..]
        r = if r then parseInt(r) else 0
        if r is 0
          do =>
            dataType = match[2]
            accessor = (dt) =>
              data = BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)
        else
          do =>
            dataType = match[2]
            accessor = =>
              data = []
              for i in [1..r]
                data.push BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)

  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    for i in [0..@accessors.length-1]
      data = @accessors[i]()
      row.push(data)
    @rowsRead += 1
    return row

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
      data = new Image(@view, header)
      excess = 0
    else
      data = new BinTable(@view, header)
      excess = File.excessChars(data.length)
      # if data.compressedImage
      #   excess = 0
      # else
      #   excess = File.excessChars(data.length)

    # Forward to the next HDU
    @view.seek(@view.tell() + data.length + excess)
    @checkEOF()
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