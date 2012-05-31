require('jDataView/src/jdataview')

# Module borrowed from Spine
class Module
  @include: (obj) ->
    throw('include(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @::[key] = value
    obj.included?.apply(@)
    this

  @extend: (obj) ->
    throw('extend(obj) requires obj') unless obj
    for key, value of obj when key not in moduleKeywords
      @[key] = value
    obj.extended?.apply(@)
    this


# Read a FITS header
class Header extends Module
  @keywordPattern = /([\w_]+)\s*=?\s*(.*)/
  @nonStringPattern = /([^\/]*)\s*\/*(.*)/
  @stringPattern = /'(.*)'\s*\/*(.*)/
  @principalMandatoryKeywords = ['BITPIX', 'NAXIS', 'END']
  @extensionKeywords = ['BITPIX', 'NAXIS', 'PCOUNT', 'GCOUNT']
  @arrayKeywordPattern = /^((?:NAXIS)|(?:PSCAL)|(?:PZERO)|(?:TBCOL)|(?:TSCAL)|(?:TZERO)|(?:ZNAXIS)|(?:ZTILE)|(?:CRPIX)|(?:CRVAL)|(?:CDELT)|(?:CROTA)|(?:PC)|(?:CD))(\d+)_*\d*/
  
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
    @cards[key] = if comment then [@cardIndex, value, comment] else [@cardIndex, value]
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

  @parseNonNegativeInt: (value) ->
    value = parseInt(value)
    throw "Value must be an integer" if isNaN(value)
    throw "Value #{value} must be non-negative" if value < 0
    return value
  
  @parsePositiveInt: (value) ->
    value = parseInt(value)
    throw "Value must be an integer" if isNaN(value)
    throw "Value must be positive" if value < 1
    return value

  @parseDate: (value) -> value = new Date(value)

  @parseLogical: (value) -> return if value is "T" then true else false

  @reservedKeywordFormat =
    SIMPLE: Header.parseLogical
    BITPIX: parseInt
    NAXIS: Header.parseNonNegativeInt
    PCOUNT: parseInt
    GCOUNT: parseInt
    DATE: Header.parseDate
    EXTEND: Header.parseLogical
    'DATE-OBS': Header.parseDate
    BSCALE: parseFloat
    BZERO: parseFloat
    DATAMAX: parseFloat
    DATAMIN: parseFloat
    EXTVER: parseInt
    EXTLEVEL: parseInt
    PSCAL: parseFloat
    PZERO: parseFloat
    TFIELDS: Header.parseNonNegativeInt
    TBCOL: Header.parsePositiveInt
    TSCAL: parseFloat
    TZERO: parseFloat
    THEAP: parseInt
    ZIMAGE: Header.parseLogical
    ZBITPIX: parseInt
    ZNAXIS: Header.parseNonNegativeInt
    ZTILE: Header.parsePositiveInt
    ZSIMPLE: Header.parseLogical
    ZEXTEND: Header.parseLogical
    ZPCOUNT: parseInt
    ZGCOUNT: parseInt
    WCSAXES: parseInt
    CRPIX: parseFloat
    CRVAL: parseFloat
    CDELT: parseFloat
    CROTA: parseFloat
    PC: parseFloat
    CD: parseFloat
  
  # Read a card from the header
  readCard: (line) ->
    match = line.match(Header.keywordPattern)
    [key, value] = match[1..]
    if value[0] is "'"
      match = value.match(Header.stringPattern)
    else
      match = value.match(Header.nonStringPattern)
    [value, comment] = match[1..]
    
    # Trim the value and comment
    value = value.trim()
    comment = comment.trim()
    
    # Check keyword again list of required and reserved keywords and apply formatting
    value = Header.reservedKeywordFormat[key](value) if Header.reservedKeywordFormat.hasOwnProperty(key)
    
    # Check for array keywords (e.g. NAXISn, PSCALn, PZEROn, etc)
    arrayKeywordMatch = key.match(Header.arrayKeywordPattern)
    if arrayKeywordMatch?
      keyMatch = arrayKeywordMatch[1]
      value = Header.reservedKeywordFormat[keyMatch](value)
    
    switch key
      when "COMMENT"
        @setComment(value)
      when "HISTORY"
        @setHistory(value)
      else
        @set(key, value, comment)

  verify: ->
    if @cards.hasOwnProperty("SIMPLE")
      type = "SIMPLE"
      @primary = true
      keywords = Header.principalMandatoryKeywords
    else
      type = "XTENSION"
      @extension = true
      @extensionType = @getValue("XTENSION")
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
        while axisIndex <= @getValue("NAXIS")
          naxisKeyword = keyword + axisIndex
          throw "Header does not contain the required keyword #{naxisKeyword}" unless @cards.hasOwnProperty(naxisKeyword)
          console.warn("#{naxisKeyword} is not in the correct order") unless @getIndex(naxisKeyword) is cardIndex
          cardIndex += 1
          axisIndex += 1

  # Verifies the header according to the primary header standards
  # @primaryRequiredKeywords = ["SIMPLE", "BITPIX", "NAXIS", "END"]
  @primaryRequiredKeywords = [
    {keyword: "SIMPLE", values: ["T", "F"], dataType: "boolean", position: 0},
    {keyword: "BITPIX", values: [8, 16, 32, 64, -32, -64], dataType: "integer", position: 1},
    {keyword: "NAXIS", dataType: "integer", position: 2},
    {keyword: "END"}
  ]
  @verifyPrimary: (header) ->
    for keyDef in Header.primaryRequiredKeywords
      keyword   = keyDef['keyword']
      values    = keyDef['values']
      dataType  = keyDef['dataType']
      position  = keyDef['position']

      throw "Keyword #{keyword} is required" unless header.contains(keyword)
      
      if values?
        throw "Inappropriate value for #{keyword}" unless header.getValue(keyword) in values
        

  hasDataUnit: ->
    return if @getValue("NAXIS") is 0 then false else true

  isPrimary: -> return @primary
  isExtension: -> return @extension

# Base class for FITS data units (e.g. Primary, BINTABLE, TABLE, IMAGE).  Derived classes must
# define @length describing the byte length of the data unit
class Data extends Module

  constructor: (view, header) ->
    @view   = view
    @begin  = @current = view.tell()

# Image represents a standard image stored in the data unit of a FITS file
class Image extends Data

  constructor: (view, header) ->
    super

    naxis   = header.getValue("NAXIS")
    bitpix  = header.getValue("BITPIX")
    @naxis = []
    @rowByteSize = header.getValue("NAXIS1") * Math.abs(bitpix) / 8
    @rowsRead = 0

    i = 1
    while i <= naxis
      @naxis.push header.getValue("NAXIS#{i}")
      i += 1

    @length   = @naxis.reduce( (a, b) -> a * b) * Math.abs(bitpix) / 8
    @data     = undefined
    
    # Define a function to read the image data
    switch bitpix
      when 8
        @arrayType  = Uint8Array
        @accessor   = =>
          return @view.getUint8()
      when 16
        @arrayType  = Int16Array
        @accessor   = =>
          return @view.getInt16()
      when 32
        @arrayType  = Int32Array
        @accessor   = =>
          return @view.getInt32()
      when 64
        @arrayType  = Int32Array
        @accessor   = =>
          console.warn "Something funky happens here when dealing with 64 bit integers.  Be wary!!!"
          highByte = Math.abs @view.getInt32()
          lowByte = Math.abs @view.getInt32()
          mod = highByte % 10
          factor = if mod then -1 else 1
          highByte -= mod
          value = factor * ((highByte << 32) | lowByte)
          return value
      when -32
        @arrayType  = Float32Array
        @accessor   = =>
          return @view.getFloat32()
      when -64
        @arrayType  = Float64Array
        @accessor   = =>
          return @view.getFloat64()
      else
        throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, 64, -32, -64]"

  # Initializes a 1D array for storing image pixels
  initArray: -> @data = new @arrayType(@naxis.reduce( (a, b) -> a * b))

  # The method initArray must be called before requesting any rows
  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    rowLength = @naxis[0]
    @view.seek(@current)
    for i in [0..rowLength - 1]
      @data[rowLength * @rowsRead + i] = @accessor()
    @rowsRead += 1
  
  getFrame: -> @getRow() for i in [0..@naxis[1] - 1]

class Table extends Data
  
  constructor: (view, header) ->
    super
    @length = header.getValue("NAXIS1") * header.getValue("NAXIS2")

class BinTable extends Data
  @requiredKeywords = ["TFORM"]
  @optionalKeywords = ["TTYPE", "TUNIT", "TSCAL"]
  @dataTypePattern = /([0-9]*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\(([0-9]*)\)/
  @compressedImageKeywords = ["ZIMAGE", "ZCMPTYPE", "ZBITPIX", "ZNAXIS"]

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

    @rowByteSize  = header.getValue("NAXIS1")
    @rows         = header.getValue("NAXIS2")
    @length       = @tableLength = @rowByteSize * @rows
    @compressedImage  = header.contains("ZIMAGE")
    @rowsRead = 0

    if @compressedImage
      @length += header.getValue("PCOUNT")
      @cmptype = header.getValue("ZCMPTYPE")
      @bitpix = header.getValue("ZBITPIX")
      @naxis = header.getValue("ZNAXIS")
      @nx = if header.contains("ZTILE1") then parseInt(header.getValue("ZTILE1")) else header.getValue("ZNAXIS1")
      @bzero = if header.contains("BZERO") then header.getValue("BZERO") else 0
      
      if @cmptype is "RICE_1"
        i = 1
        loop
          break unless header.contains("ZNAME#{i}")
          name = header.getValue("ZNAME#{i}")
          value = header.getValue("ZVAL#{i}")
          if name is "BLOCKSIZE"
            @blocksize = value
          else if name is "BYTEPIX"
            @bytepix = value
          i += 1
        
        # Set default values if not in header
        @blocksize = 32 unless @blocksize
        @bytepix = 4 unless @bytepix
        
      else
        throw "Compression algorithm not yet implemented."

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
    
    if @compressedImage
      console.log @riceDecompressShort(data)
    return row
    
  riceDecompressShort: (arr) ->
    
    # TODO: Typed array should be set by BITPIX of the uncompressed data
    pixels = new Uint16Array(@nx)
    fsbits = 4
    fsmax = 14
    bbits = 1 << fsbits
    
    nonzeroCount = new Array(256)
    nzero = 8
    k = 128
    i = 255
    while i >= 0
      while i >= k
        nonzeroCount[i] = nzero
        i -= 1
      k = k / 2
      nzero -= 1
    # FIXME: Not sure why this element is incorrectly -1024
    nonzeroCount[0] = 0
    
    # NOTES:  nx      = ZTILE1
    #         nblock  = BLOCKSIZE
    
    # Decode in blocks of BLOCKSIZE pixels
    lastpix = 0
    bytevalue = arr.shift()
    lastpix = lastpix | (bytevalue << 8)
    bytevalue = arr.shift()
    lastpix = lastpix | bytevalue
    
    # Bit buffer
    b = arr.shift()
    
    # Number of bits remaining in b
    nbits = 8
    
    i = 0
    while i < @nx
      
      nbits -= fsbits
      while nbits < 0
        b = (b << 8) | (arr.shift())
        nbits += 8
      fs = (b >> nbits) - 1
      b &= (1 << nbits) - 1
      imax = i + @blocksize
      imax = @nx if imax > @nx
      
      if fs < 0
        while i < imax
          arr[i] = lastpix
          i++
      else if fs is fsmax
        while i < imax
          k = bbits - nbits
          diff = b << k
          k -= 8
          while k >= 0
            b = arr.shift()
            diff |= b << k
            k -= 8
          if nbits > 0
            b = arr.shift()
            diff |= b >> (-k)
            b &= (1 << nbits) - 1
          else
            b = 0
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          arr[i] = diff + lastpix
          lastpix = arr[i]
          i++
      else
        while i < imax
          while b is 0
            nbits += 8
            b = arr.shift()
          nzero = nbits - nonzeroCount[b]
          nbits -= nzero + 1
          b ^= 1 << nbits
          nbits -= fs
          while nbits < 0
            b = (b << 8) | (arr.shift())
            nbits += 8
          diff = (nzero << fs) | (b >> nbits)
          b &= (1 << nbits) - 1
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          pixels[i] = diff + lastpix
          lastpix = pixels[i]
          i++

    # TODO: This should go elsewhere
    for i in [0..pixels.length-1]
      pixels[i] = pixels[i] + @bzero
    return pixels

  riceDecompressByte: (arr) ->
    pixels = new Uint8Array(@nx)
    fsbits = 3
    fsmax = 6
    bbits = 1 << fsbits

    nonzeroCount = new Array(256)
    nzero = 8
    k = 128
    i = 255
    while i >= 0
      while i >= k
        nonzeroCount[i] = nzero
        i -= 1
      k = k / 2
      nzero -= 1
    # FIXME: Not sure why this element is incorrectly -1024
    nonzeroCount[0] = 0

    # NOTES:  nx      = ZTILE1
    #         nblock  = BLOCKSIZE

    # Decode in blocks of BLOCKSIZE pixels
    lastpix = arr.shift()
    
    # Bit buffer
    b = arr.shift()

    # Number of bits remaining in b
    nbits = 8

    i = 0
    while i < @nx

      nbits -= fsbits
      while nbits < 0
        b = (b << 8) | (arr.shift())
        nbits += 8
      fs = (b >> nbits) - 1
      b &= (1 << nbits) - 1
      imax = i + @blocksize
      imax = @nx if imax > @nx

      if fs < 0
        while i < imax
          arr[i] = lastpix
          i++
      else if fs is fsmax
        while i < imax
          k = bbits - nbits
          diff = b << k
          k -= 8
          while k >= 0
            b = arr.shift()
            diff |= b << k
            k -= 8
          if nbits > 0
            b = arr.shift()
            diff |= b >> (-k)
            b &= (1 << nbits) - 1
          else
            b = 0
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          arr[i] = diff + lastpix
          lastpix = arr[i]
          i++
      else
        while i < imax
          while b is 0
            nbits += 8
            b = arr.shift()
          nzero = nbits - nonzeroCount[b]
          nbits -= nzero + 1
          b ^= 1 << nbits
          nbits -= fs
          while nbits < 0
            b = (b << 8) | (arr.shift())
            nbits += 8
          diff = (nzero << fs) | (b >> nbits)
          b &= (1 << nbits) - 1
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          pixels[i] = diff + lastpix
          lastpix = pixels[i]
          i++

    # TODO: This should go elsewhere
    for i in [0..pixels.length-1]
      pixels[i] = pixels[i] + @bzero
    return pixels


class HDU

  constructor: (header, data)->
    @header = header
    @data   = data

class File
  @LINEWIDTH   = 80
  @BLOCKLENGTH = 2880
  @BITPIX = [8, 16, 32, 64, -32, -64]

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
  @excessBytes: (length) -> return File.BLOCKLENGTH - (length) % File.BLOCKLENGTH

  # ##Instance Methods

  # Read a header unit
  readHeader: ->
    linesRead = 0
    header = new Header()
    loop
      line = @view.getString(File.LINEWIDTH)
      linesRead += 1
      header.readCard(line)
      break if line[0..3] is "END "
    
    # Check if header is primary
    # Header.verifyPrimary(header) if @hdus.length is 0
    header.verify()

    # Seek to the next relavant block in file
    excess = File.excessBytes(linesRead * File.LINEWIDTH)
    @view.seek(@view.tell() + excess)
    @checkEOF()

    return header

  # Read a data unit
  readData: (header) ->
    return unless header.hasDataUnit()
    if header.isPrimary()
      data = new Image(@view, header)
    else if header.isExtension()
      if header.extensionType is "BINTABLE"
        data = new BinTable(@view, header)
      else if header.extensionType is "TABLE"
        data = new Table(@view, header)
    excess = File.excessBytes(data.length)

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
FITS.Table      = Table
FITS.BinTable   = BinTable