Tabular     = require('./fits.tabular')
Decompress  = require('./fits.decompress')

class CompImage extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  @extend Decompress
  
  @typedArray =
    B: Uint8Array
    I: Int16Array
    J: Int32Array
    E: Float32Array
    D: Float64Array
    1: Uint8Array
    2: Uint8Array
    4: Int16Array
    8: Int32Array
  
  constructor: (view, header) ->
    super
    
    @length   += header["PCOUNT"]
    @zcmptype = header["ZCMPTYPE"]
    @zbitpix  = header["ZBITPIX"]
    @znaxis   = header["ZNAXIS"]
    @zblank   = CompImage.setValue(header, "ZBLANK", undefined)
    @blank    = CompImage.setValue(header, "BLANK", undefined)
    
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
    
    @["setDefaultParameters_#{@zcmptype}"]()
    
    @zmaskcmp = CompImage.setValue(header, "ZMASKCMP", undefined)
    @zquantiz = CompImage.setValue(header, "ZQUANTIZ", "LINEAR_SCALING")
    
    @bzero  = CompImage.setValue(header, "BZERO", 0)
    @bscale = CompImage.setValue(header, "BSCALE", 1)
    
    @defineColumnAccessors header
    @defineGetRow()
    
  defineColumnAccessors: (header) ->
    @columnNames = {}
    for i in [1..@cols]
      value = header["TFORM#{i}"]
      match = value.match(CompImage.arrayDescriptorPattern)
      ttype = header["TTYPE#{i}"].toUpperCase()
      @columnNames[ttype] = i - 1
      accessor = null
      if match?
        # Define array accessor methods
        dataType = match[1]
        switch ttype
          when "COMPRESSED_DATA"
            do (dataType) =>
              accessor = =>
                data = @_accessor(dataType)
                return null unless data?

                pixels = new CompImage.typedArray[@algorithmParameters["BYTEPIX"]](@ztile[0])
                CompImage.Rice(data, length, @algorithmParameters["BLOCKSIZE"], @algorithmParameters["BYTEPIX"], pixels, @ztile[0])
                return pixels
          when "UNCOMPRESSED_DATA"
            do (dataType) => accessor = @_accessor(dataType)
          when "GZIP_COMPRESSED_DATA"
            # TODO: Decompress using Gzip
            do (dataType) => accessor = @_accessor(dataType)
          else
            # Might not need this as default.  TODO: Check how NULL_PIXEL_MASK is stored
            do (dataType) => accessor = @_accessor(dataType)
      else
        match = value.match(CompImage.dataTypePattern)
        [length, dataType] = match[1..]
        length = if length? then parseInt(length) else 0
        if length in [0, 1]
          do (dataType) =>
            accessor = => return CompImage.dataAccessors[dataType](@view)
        else
          do (length, dataType) =>
            accessor = =>
              data = new CompImage.typedArray[dataType](length)
              for i in [0..length - 1]
                data[i] = CompImage.dataAccessors[dataType](@view)
              return data
      @accessors.push(accessor)
  
  defineGetRow: ->
    hasBlanks = @zblank? or @blank? or @columnNames.hasOwnProperty("ZBLANK")
    @getRow = if hasBlanks then @getRowHasBlanks else @getRowNoBlanks
  
  setDefaultParameters_RICE_1: ->
    @algorithmParameters["BLOCKSIZE"] = 32 unless @algorithmParameters.hasOwnProperty("BLOCKSIZE")
    @algorithmParameters["BYTEPIX"] = 4 unless @algorithmParameters.hasOwnProperty("BYTEPIX")
  
  @setValue: (header, key, defaultValue) -> return if header.contains(key) then header[key] else defaultValue
  
  getFrame: ->
    @rowsRead = 0
    @data = new Float32Array(@ztile[0] * @rows)
    
    loop
      row = @getRow()
      for value, index in row
        location = @rowsRead * @ztile[0] + index
        @data[@rowsRead * @ztile[0] + index] = value
      break if @rowsRead is @rows
    return @data
      
  getRowHasBlanks: ->
    [data, blank, scale, zero] = @_getRow()
    
    pixels = new Float32Array(data.length)
    for value, index in data
      if value is blank
        pixels[index] = NaN
        continue
      pixels[index] = zero + (scale * value)
    return pixels
  
  getRowNoBlanks: ->
    [data, blank, scale, zero] = @_getRow()
    
    pixels = new Float32Array(data.length)
    for value, index in data
      pixels[index] = zero + scale * value
    return pixels

  _accessor: (dataType) ->
    [length, offset]  = [@view.getInt32(), @view.getInt32()]
    return null if length is 0
    
    data = new CompImage.typedArray[dataType](length)
    @current = @view.tell()
    @view.seek(@begin + @tableLength + offset)
    for i in [0..length - 1]
      data[i] = CompImage.dataAccessors[dataType](@view)
    @view.seek(@current)
    
    return data

  _getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    row.push accessor() for accessor in @accessors
    @rowsRead += 1
    
    data  = row[@columnNames["COMPRESSED_DATA"]] || row[@columnNames["UNCOMPRESSED_DATA"]] || row[@columnNames["GZIP_COMPRESSED_DATA"]]
    blank = row[@columnNames["ZBLANK"]] || @zblank
    scale = row[@columnNames["ZSCALE"]] || @bscale
    zero  = row[@columnNames["ZZERO"]] || @bzero
    return [data, blank, scale, zero]
  
  # Compute the minimum and maximum pixels
  getExtremes: ->
    return [@min, @max] if @min? and @max?

    for value, index in @data
      continue if isNaN(value)
      [min, max] = [value, value]
      break

    for i in [index..@data.length - 1]
      value = @data[i]
      continue if isNaN(value)
      min = value if value < min
      max = value if value > max

    [@min, @max] = [min, max]
    return [@min, @max]

  @subtractiveDither1: -> throw "Not yet implemented"
  @linearScaling: -> throw "Not yet implemented"

module?.exports = CompImage