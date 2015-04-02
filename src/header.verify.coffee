# This module is a collection of function for verifying reserved keywords of the FITS standard
# When new keywords and extensions are defined, this module may be extended.

HeaderVerify =
  
  verifyOrder: (keyword, order) ->
    console.warn("#{keyword} should appear at index #{@cardIndex} in the FITS header") unless order is @cardIndex

  verifyBetween: (keyword, value, lower, upper) ->
    throw "The #{keyword} value of #{value} is not between #{lower} and #{upper}" unless value >= lower and value <= upper

  verifyBoolean: (value) ->
    return if value is "T" then true else false

  VerifyFns:
    SIMPLE: (args...) ->
      value = arguments[0]
      @primary = true
      @verifyOrder("SIMPLE", 0)
      return @verifyBoolean(value)
      
    XTENSION: (args...) ->
      @extension = true
      @extensionType = arguments[0]
      @verifyOrder("XTENSION", 0)
      return @extensionType
      
    BITPIX: (args...) ->
      key = "BITPIX"
      value = parseInt(arguments[0])
      @verifyOrder(key, 1)
      throw "#{key} value #{value} is not permitted" unless value in [8, 16, 32, -32, -64]
      return value
      
    NAXIS: (args...) ->
      key = "NAXIS"
      value = parseInt(arguments[0])
      array = arguments[1]
      
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
      value = parseInt(arguments[0])
      order = 1 + 1 + 1 + @get("NAXIS")
      @verifyOrder(key, order)
      
      if @isExtension()
        if @extensionType in ["IMAGE", "TABLE"]
          required = 0
          throw "#{key} must be #{required} for the #{@extensionType} extensions" unless value is required
      
      return value
    
    GCOUNT: (args...) ->
      key = "GCOUNT"
      value = parseInt(arguments[0])
      order = 1 + 1 + 1 + @get("NAXIS") + 1
      @verifyOrder(key, order)
      
      if @isExtension()
        if @extensionType in ["IMAGE", "TABLE", "BINTABLE"]
          required = 1
          throw "#{key} must be #{required} for the #{@extensionType} extensions" unless value is required
      
      return value
    
    EXTEND: (args...) ->
      value = arguments[0]
      throw "EXTEND must only appear in the primary header" unless @isPrimary()
      return @verifyBoolean(value)
    
    BSCALE: (args...) ->
      return parseFloat(arguments[0])
    
    BZERO: (args...) ->
      return parseFloat(arguments[0])
      
    BLANK: (args...) ->
      value = arguments[0]
      console.warn "BLANK is not to be used for BITPIX = #{@get('BITPIX')}" unless @get("BITPIX") > 0
      return parseInt(value)
    
    DATAMIN: (args...) ->
      return parseFloat(arguments[0])
    
    DATAMAX: (args...) ->
      return parseFloat(arguments[0])
    
    EXTVER: (args...) ->
      return parseInt(arguments[0])
      
    EXTLEVEL: (args...) ->
      return parseInt(arguments[0])
    
    TFIELDS: (args...) ->
      value = parseInt(arguments[0])
      @verifyBetween("TFIELDS", value, 0, 999)
      return value
    
    TBCOL: (args...) ->
      value = arguments[0]
      index = arguments[2]
      @verifyBetween("TBCOL", index, 0, @get("TFIELDS"))
      return value
    
    ZIMAGE: (args...) ->
      return @verifyBoolean(arguments[0])
    
    ZCMPTYPE: (args...) ->
      value = arguments[0]
      throw "ZCMPTYPE value #{value} is not permitted" unless value in ['GZIP_1', 'RICE_1', 'PLIO_1', 'HCOMPRESS_1']
      throw "Compress type #{value} is not yet implement" unless value in ['RICE_1']
      return value
    
    ZBITPIX: (args...) ->
      value = parseInt(arguments[0])
      throw "ZBITPIX value #{value} is not permitted" unless value in [8, 16, 32, 64, -32, -64]
      return value
      
    ZNAXIS: (args...) ->
      value = parseInt(arguments[0])
      array = arguments[1]
      value = value
      
      @verifyBetween("ZNAXIS", value, 0, 999) unless array
      
      return value
    
    ZTILE: (args...) ->
      return parseInt(arguments[0])
    
    ZSIMPLE: (args...) ->
      return if arguments[0] is "T" then true else false
    
    ZPCOUNT: (args...) ->
      return parseInt(arguments[0])
    
    ZGCOUNT: (args...) ->
      return parseInt(arguments[0])
    
    ZDITHER0: (args...) ->
      return parseInt(arguments[0])


@astro.FITS.HeaderVerify = HeaderVerify