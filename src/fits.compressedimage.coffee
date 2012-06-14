require('jDataView/src/jdataview')

FITS        = @FITS or require('fits')
Data        = require('fits.data')
Decompress  = require('fits.decompress')

class FITS.CompImage extends Data
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  @compressedImageKeywords = ["ZIMAGE", "ZCMPTYPE", "ZBITPIX", "ZNAXIS"]
  @extend Decompress
  
  @typeArray =
    B: Uint8Array
    I: Int16Array
    J: Int32Array
    1: Uint8Array
    2: Uint8Array
    4: Int16Array
    8: Int32Array

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
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead = 0
  
    @length += header["PCOUNT"]
    @zcmptype = header["ZCMPTYPE"]
    @zbitpix = header["ZBITPIX"]
    @znaxis = header["ZNAXIS"]
    
    @ztile = []
    for i in [1..@znaxis]
      ztile = if header.contains("ZTILE#{i}") then header["ZTILE#{i}"] else if i is 1 then header["ZNAXIS1"] else 1
      @ztile.push ztile
    
    @algorithmParameters = {}
    i = 1
    loop
      key = "ZNAME#{i}"
      break unless header.contains(key)
      value = "ZVAL#{i}"
      @algorithmParameters[header[key]] = header[value]
      i += 1
    
    # Set default values for the algorithm parameters
    @["setDefaultParameters_#{@zcmptype}"]()

    @zmaskcmp = FITS.CompImage.setValue(header, "ZMASKCMP", undefined)
    @zquantiz = FITS.CompImage.setValue(header, "ZQUANTIZ", "LINEAR_SCALING")
    
    @bzero  = FITS.CompImage.setValue(header, "BZERO", 0)
    @bscale = FITS.CompImage.setValue(header, "BSCALE", 1)
    
    # Select the column data types
    @fields = header["TFIELDS"]
    @accessors = []
    
    for i in [1..@fields]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(FITS.CompImage.arrayDescriptorPattern)
      ttype = header["TTYPE#{i}"]
      
      if match?
        # Define an array accessor method
        if ttype is "COMPRESSED_DATA"
          do =>
            dataType = match[1]
            accessor = =>
              # Length and offset are stored in the binary table as an array descriptor
              length  = @view.getInt32()
              offset  = @view.getInt32()
              @current = @view.tell()
              @view.seek(@begin + @tableLength + offset)
              data = new FITS.CompImage.typeArray[dataType](length)
              for i in [1..length]
                data[i-1] = FITS.CompImage.dataAccessors[dataType](@view)
              @view.seek(@current)
              
              # Call the decompression algorithm
              pixels = new FITS.CompImage.typeArray[@algorithmParameters["BYTEPIX"]](@ztile[0])
              FITS.CompImage.rice(data, length, @algorithmParameters["BLOCKSIZE"], @algorithmParameters["BYTEPIX"], pixels, @ztile[0])
              return pixels
            @accessors.push(accessor)
        else
          do =>
            dataType = match[1]
            accessor = =>
              # Length and offset are stored in the binary table as an array descriptor
              length  = @view.getInt32()
              offset  = @view.getInt32()
              @current = @view.tell()
              @view.seek(@begin + @tableLength + offset)
              data = []
              for i in [1..length]
                data.push FITS.CompImage.dataAccessors[dataType](@view)
              @view.seek(@current)
              return data
            @accessors.push(accessor)
      else
        match = value.match(FITS.CompImage.dataTypePattern)
        [r, dataType] = match[1..]
        r = if r then parseInt(r) else 0
        if r is 0
          do =>
            dataType = match[2]
            accessor = =>
              return FITS.CompImage.dataAccessors[dataType](@view)
            @accessors.push(accessor)
        else
          do =>
            dataType = match[2]
            accessor = =>
              data = []
              for i in [1..r]
                data.push FITS.CompImage.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)
  
  setDefaultParameters_RICE_1: ->
    @algorithmParameters["BLOCKSIZE"] = 32 unless @algorithmParameters.hasOwnProperty("BLOCKSIZE")
    @algorithmParameters["BYTEPIX"] = 4 unless @algorithmParameters.hasOwnProperty("BYTEPIX")

  @setValue: (header, key, defaultValue) -> return if header.contains(key) then header[key] else defaultValue
  
  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    row.push @accessors[i]() for i in [0..@accessors.length-1]
    @rowsRead += 1
    console.log row
  
  @subtractiveDither1: -> throw "Not yet implemented"
  @linearScaling: -> throw "Not yet implemented"

  

module?.exports = FITS.CompImage