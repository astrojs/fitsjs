Module      = require('./fits.module')
VerifyCards = require('./fits.header.verify')

# Header parses and stores the FITS header.  Verification is done for reserved
# keywords (e.g. SIMPLE, BITPIX, etc).

# TODO: Storage of COMMENT and HISTORY fields needs improvement
class Header extends Module

  @keywordPattern   = /^([A-Z0-9_-]+)\s*=\s*(.*)/
  @nonStringPattern = /([^\/]*)\s*\/*(.*)/
  @stringPattern    = /'(.*)'\s*\/*(.*)/
  @arrayPattern     = /([A-Za-z]+)(\d+)/
  @include VerifyCards
  
  constructor: ->
    @primary    = false
    @extension  = false
    
    # Add verification methods to instance
    @verifyCard = {}
    @verifyCard[name] = @proxy(method) for name, method of @Functions
    
    # e.g. [index, value, comment]
    @cards      = {}
    @cardIndex  = 0
    
  # Get the index value and comment for a key
  get: (key) ->
    if @contains(key) then return @cards[key] else console.warn("Header does not contain the key #{key}")

  # Get the index for a specified key
  getIndex: (key) ->
    if @contains(key) then return @cards[key][0] else console.warn("Header does not contain the key #{key}")

  # Get the comment for a specified key
  getComment: (key) ->
    if @contains(key)
      if @cards[key][2]? then return @cards[key][2] else console.warn("#{key} does not contain a comment")
    else
      console.warn("Header does not contain the key #{key}")

  # Get comments stored with the COMMENT keyword
  getComments: ->
    if @contains('COMMENT') then return @cards['COMMENT'] else console.warn("Header does not contain any COMMENT fields")

  # Get history stored with the HISTORY keyword
  getHistory: ->
    if @contains('HISTORY') then return @cards['HISTORY'] else console.warn("Header does not contain any HISTORY fields")

  # Set a key with a passed value and optional comment
  set: (key, value, comment) ->
    @cards[key] = if comment then [@cardIndex, value, comment] else [@cardIndex, value]
    @cardIndex += 1

  # Set comment from the COMMENT keyword
  setComment: (comment) ->
    unless @contains("COMMENT")
      @cards["COMMENT"] = []
      @cardIndex += 1
    @cards["COMMENT"].push(comment)

  # Set history from the HISTORY keyword
  setHistory: (history) ->
    unless @contains("HISTORY")
      @cards["HISTORY"] = []
      @cardIndex += 1
    @cards["HISTORY"].push(history)

  # Checks if the header contains a specified keyword
  contains: (keyword) -> return @cards.hasOwnProperty(keyword)

  # Read a card from the header
  readCard: (line) ->
    match = line.match(Header.keywordPattern)
    return unless match?
    
    [key, value] = match[1..]
    if key in ["COMMENT", "HISTORY"]
      match[1] = value.trim()
    else if value[0] is "'"
      match = value.match(Header.stringPattern)
      match[1] = match[1].trim()
    else
      match = value.match(Header.nonStringPattern)
      match[1] = if match[1][0] in ["T", "F"] then match[1].trim() else parseFloat(match[1])
    match[2] = match[2].trim()
    [value, comment] = match[1..]
    
    # Verification
    keyToVerify = key
    [array, index] = [false, undefined]
    match = key.match(Header.arrayPattern)
    if match?
      keyToVerify = match[1]
      [array, index] = [true, match[2]]
    
    if @verifyCard.hasOwnProperty(keyToVerify)
      value = @verifyCard[keyToVerify](value, array, index)
  
    switch key
      when "COMMENT" then @setComment(value)
      when "HISTORY" then @setHistory(value)
      else
        @set(key, value, comment)
        @.__defineGetter__(key, -> return @cards[key][1])
  
  # Initialize a header, interpretting only mandatory and reserved keywords
  # HACK: For now interpretting only the first 600 lines ...
  init: (block) =>
    lineWidth = 80
    
    numLines = block.length / lineWidth
    maxNumLines = 600 # Arbitrary number
    numLines = if numLines < maxNumLines then numLines else maxNumLines
    
    for i in [0..numLines - 1]
      line = block.slice(i * lineWidth, (i + 1) * lineWidth)
      @readCard(line)
  
  # Tells if a data unit follows based on NAXIS
  hasDataUnit: -> return if @["NAXIS"] is 0 then false else true

  # Check type of header
  isPrimary: -> return @primary
  isExtension: -> return @extension

module?.exports = Header