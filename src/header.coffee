
# Parse and store a FITS header.  Verification is done for reserved
# keywords (e.g. SIMPLE, BITPIX, etc).
class Header extends Base
  @include HeaderVerify
  
  arrayPattern: /(\D+)(\d+)/
  
  # Headers can become extremely large (for instance after Drizzle). This parameters
  # limits the number of lines that are parsed.  Typically the important information
  # describing the structure of the associated data unit and astrometry are near the
  # top.
  maxLines: 600
  
  
  constructor: (block) ->
    @primary    = false
    @extension  = false
    
    # Add verification methods to instance
    @verifyCard = {}
    @verifyCard[name] = @proxy(method) for name, method of @VerifyFns
    
    # e.g. [index, value, comment]
    @cards = {}
    @cards["COMMENT"] = []
    @cards["HISTORY"] = []
    @cardIndex  = 0
    @block = block
    
    @readBlock(block)
    
  # Get the value for a key
  get: (key) ->
    if @contains(key) then return @cards[key].value else null
  
  # Set value to key with optional comment
  set: (key, value, comment) ->
    comment = comment or ''
    @cards[key] =
      index: @cardIndex
      value: value
      comment: comment
    @cardIndex += 1
  
  # Checks if the header contains a specified keyword
  contains: (key) -> @cards.hasOwnProperty(key)
  
  readLine: (l) ->
    
    # Check bytes 1 to 8 for key or whitespace
    key = l[0..7].trim()
    blank = key is ''
    return if blank
    
    # Get indicator and value
    indicator = l[8..9]
    value = l[10..]
    
    # Check the indicator
    unless indicator is "= "
      # Key will be either COMMENT, HISTORY or END
      # all else is outside the standard.
      if key in ['COMMENT', 'HISTORY']
        @cards[key].push(value.trim())
      return
    
    # Check the value
    [value, comment] = value.split(' /')
    value = value.trim()
    
    # Values can be a string pattern starting with single quote
    # a boolean pattern (T or F), or a numeric
    firstByte = value[0]
    if firstByte is "'"
      # String data type
      value = value.slice(1, -1).trim()
    else
      # Boolean or numeric
      unless value in ['T', 'F']
        value = parseFloat(value)
    
    value = @validate(key, value)
    
    @set(key, value, comment)
  
  validate: (key, value) ->
    index   = null
    baseKey = key
    isArray = @arrayPattern.test(key)
    
    if isArray
      match = @arrayPattern.exec(key)
      [baseKey, index] = match[1..]
    
    if baseKey of @verifyCard
      value = @verifyCard[baseKey](value, isArray, index)
    
    return value
  
  readBlock: (block) ->
    lineWidth = 80
    
    nLines = block.length / lineWidth
    nLines = if nLines < @maxLines then nLines else @maxLines
    
    for i in [0..nLines - 1]
      line = block.slice(i * lineWidth, (i + 1) * lineWidth)
      @readLine(line)
  
  # Tells if a data unit follows based on NAXIS
  hasDataUnit: ->
    return if @get("NAXIS") is 0 then false else true
  
  getDataLength: ->
    return 0 unless @hasDataUnit()

    naxis = []
    naxis.push @get("NAXIS#{i}") for i in [1..@get("NAXIS")]
    length = naxis.reduce( (a, b) -> a * b) * Math.abs(@get("BITPIX")) / 8
    length += @get("PCOUNT")

    return length
  
  # Determine the data unit type (e.g IMAGE, BINTABLE, TABLE, COMPRESSED)
  getDataType: ->
    switch @extensionType
      when 'BINTABLE'
        return 'CompressedImage' if @contains('ZIMAGE')
        return 'BinaryTable'
      when 'TABLE'
        return 'Table'
      else
        if @hasDataUnit()
          return 'Image'
        else null
  
  # Determine type of header
  isPrimary: -> return @primary
  isExtension: -> return @extension


@astro.FITS.Header = Header