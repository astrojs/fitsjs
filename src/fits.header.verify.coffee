
# This module is a collection of function for verifying reserved keywords of the FITS standard
# When new keywords and extensions are defined, this module may be extended.

VerifyCards =
  primary:    false
  extension:  false
  
  isPrimary: -> return @primary
  isExtension: -> return @extension

  verifyOrder: (keyword, order) ->
    console.warn("#{keyword} should appear at index #{order} in the FITS header") unless order is @cardIndex

  verifyBetween: (keyword, value, lower, upper) ->
    throw "The #{keyword} value of #{value} is not between #{lower} and #{upper}" unless value >= lower and value <= upper

  verifyInteger: (keyword, value) ->
    val = parseInt(value)
    throw "The #{keyword} value of #{value} is not an integer" unless val is value
    return val

  Functions:
    SIMPLE: (args...) ->
      value = arguments[0]
      @primary = true
      @verifyOrder("SIMPLE", 0)
      return if value is "T" then true else false
      
    XTENSION: (args...) ->
      value = arguments[0]
      @extension = true
      @extensionType = value
      @verifyOrder("XTENSION", 0)
      return value
      
    BITPIX: (args...) ->
      key = "BITPIX"
      value = @verifyInteger(key, arguments[0])
      @verifyOrder(key, 1)
      throw "#{key} value #{value} is not permitted" unless value in [8, 16, 32, 64, -32, -64]
      return parseInt(value)
      
    NAXIS: (args...) ->
      key = "NAXIS"
      value = arguments[0]
      array = arguments[1]
      value = @verifyInteger(key, value)
      
      unless array
        @verifyOrder(key, 2)
        @verifyBetween(key, value, 0, 999)
        if @isExtension()
          if @extensionType in ["TABLE", "BINTABLE"]
            required = 2
            throw "#{key} must be #{required} for TABLE and BINTABLE extensions" unless value is required
      
      return value
    
    PCOUNT: (args...) ->
      key = "PCOUNT"
      value = @verifyInteger(key, arguments[0])
      order = 1 + 1 + 1 + @["NAXIS"]
      @verifyOrder(key, order)
      
      if @isExtension()
        if @extensionType in ["IMAGE", "TABLE"]
          required = 0
          throw "#{key} must be #{required} for the #{@extensionType} extensions" unless value is required
      
      return value
    
    GCOUNT: (args...) ->
      key = "GCOUNT"
      value = @verifyInteger(key, arguments[0])
      order = 1 + 1 + 1 + @["NAXIS"] + 1
      @verifyOrder(key, order)
      
      if @isExtension()
        if @extensionType in ["IMAGE", "TABLE", "BINTABLE"]
          required = 1
          throw "#{key} must be #{required} for the #{@extensionType} extensions" unless value is required
      
      return value
    
    DATE: (args...) ->
      key = "DATE"
      value = new Date(value)
      return value
    
    EXTEND: (args...) ->
      key = "EXTEND"
      value = arguments[0]
      throw "#{key} must only appear in the primary header" unless @isPrimary()
      return if value is "T" then true else false
    
    BSCALE: (args...) ->
      return parseFloat(arguments[0])
    
    BZERO: (args...) ->
      return parseFloat(arguments[0])
      
    BLANK: (args...) ->
      key = "BLANK"
      value = arguments[0]
      throw "#{key} is not to be used for BITPIX = #{@['BITPIX']}" unless @["BIXPIX"] > 0
      return @verifyInteger(value)
    
    DATAMAX: (args...) ->
      return parseFloat(arguments[0])
    
    DATAMAX: (args...) ->
      return parseFloat(arguments[0])
    
    EXTVER: (args...) ->
      key "EXTVER"
      value = arguments[0]
      value = @verifyInteger(key, value)
      return value
      
    EXTLEVEL: (args...) ->
      key = "EXTLEVEL"
      value = arguments[0]
      value = @verifyInteger(key, value)
      return value
    
    TFIELDS: (args...) ->
      key = "TFIELDS"
      value = arguments[0]
      value = @verifyInteger(key, value)
      @verifyBetween(key, value, 0, 999)
      return value
    
    TBCOL: (args...) ->
      key = "TBCOL"
      value = arguments[0]
      index = arguments[2]
      @verifyBetween(key, index, 0, @["TFIELDS"])
    
    ZIMAGE: (args...) ->
      key = "ZIMAGE"
      value = arguments[0]
      return if value is "T" then true else false
    
    ZCMPTYPE: (args...) ->
      key = "ZCMPTYPE"
      value = arguments[0]
      throw "#{key} value #{value} is not permitted" unless value in ["GZIP_1", "RICE_1", "PLIO_1", "HCOMPRESS_1"]
      throw "Compress type #{value} is not yet implement" unless value in ["RICE_1"]
      return value
    
    ZBITPIX: (args...) ->
      key = "ZBITPIX"
      value = @verifyInteger(key, arguments[0])
      throw "#{key} value #{value} is not permitted" unless value in [8, 16, 32, 64, -32, -64]
      return parseInt(value)
      
    ZNAXIS: (args...) ->
      key = "ZNAXIS"
      value = arguments[0]
      array = arguments[1]
      value = @verifyInteger(key, value)
      
      @verifyBetween(key, value, 0, 999) unless array
      
      return value
    
    ZTILE: (args...) ->
      key = "ZTILE"
      value = @verifyInteger(key, arguments[0])
      return value
    
    ZSIMPLE: (args...) ->
      return if arguments[0] is "T" then true else false
    
    ZPCOUNT: (args...) ->
      key = "ZPCOUNT"
      value = arguments[0]
      return @verifyInteger(key, value)
    
    ZGCOUNT: (args...) ->
      key = "ZGCOUNT"
      value = arguments[0]
      return @verifyInteger(key, value)

module.exports = VerifyCards