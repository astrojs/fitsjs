
class CompressedImage extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  @include ImageUtils
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
  
  
  constructor: (header, view, offset) ->
    super
    
    @length   += header["PCOUNT"]
    @zcmptype = header["ZCMPTYPE"]
    @zbitpix  = header["ZBITPIX"]
    @znaxis   = header["ZNAXIS"]
    @zblank   = @constructor.setValue(header, "ZBLANK", undefined)
    @blank    = @constructor.setValue(header, "BLANK", undefined)
    
    @ztile = []
    for i in [1..@znaxis]
      ztile = if header.contains("ZTILE#{i}") then header["ZTILE#{i}"] else if i is 1 then header["ZNAXIS1"] else 1
      @ztile.push ztile
    
    @width  = header["ZNAXIS1"]
    @height = header["ZNAXIS2"] or 1
    
    # Grab any algorithm specific parameters from header
    @algorithmParameters = {}
    i = 1
    loop
      key = "ZNAME#{i}"
      break unless header.contains(key)
      value = "ZVAL#{i}"
      @algorithmParameters[header[key]] = header[value]
      i += 1
    
    # Set default parameters if not set in the header
    @setRiceDefaults() if @zcmptype is 'RICE_1'
    
    @zmaskcmp = @constructor.setValue(header, "ZMASKCMP", undefined)
    @zquantiz = @constructor.setValue(header, "ZQUANTIZ", "LINEAR_SCALING")
    
    @bzero  = @constructor.setValue(header, "BZERO", 0)
    @bscale = @constructor.setValue(header, "BSCALE", 1)
    
    @defineColumnAccessors header
    @defineGetRow()
    
  defineColumnAccessors: (header) ->
    @columnNames = {}
    for i in [1..@cols]
      value = header["TFORM#{i}"]
      match = value.match(@constructor.arrayDescriptorPattern)
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
                return new Float32Array(@ztile[0]) unless data?
                
                # TODO: Assuming Rice compression
                pixels = new @constructor.typedArray[@algorithmParameters["BYTEPIX"]](@ztile[0])
                @constructor.Rice(data, length, @algorithmParameters["BLOCKSIZE"], @algorithmParameters["BYTEPIX"], pixels, @ztile[0])
                return pixels
          when "UNCOMPRESSED_DATA"
            do (dataType) => accessor = @_accessor(dataType)
          # TODO: Decompress using Gzip
          when "GZIP_COMPRESSED_DATA"
            do (dataType) =>
              accessor = =>
                data = @_accessor(dataType)
                if data?
                  data = new Float32Array(@width)
                  data[index] = NaN for item, index in data
                  return data
                else
                  return null
          else
            # TODO: Check how NULL_PIXEL_MASK is stored. Might not need this as default.
            do (dataType) => accessor = @_accessor(dataType)
      else
        match = value.match(@constructor.dataTypePattern)
        [length, dataType] = match[1..]
        length = if length? then parseInt(length) else 0
        if length in [0, 1]
          do (dataType) =>
            accessor = => return @dataAccessors[dataType](@view, @offset)
        else
          do (length, dataType) =>
            accessor = =>
              data = new @constructor.typedArray[dataType](length)
              for i in [0..length - 1]
                [data[i], @offset] = @dataAccessors[dataType](@view, @offset)
              return data
      @accessors.push(accessor)

  defineGetRow: ->
    @totalRowsRead = 0
    
    hasBlanks = @zblank? or @blank? or @columnNames.hasOwnProperty("ZBLANK")
    @getRow = if hasBlanks then @getRowHasBlanks else @getRowNoBlanks
  
  setRiceDefaults: ->
    @algorithmParameters["BLOCKSIZE"] = 32 unless @algorithmParameters.hasOwnProperty("BLOCKSIZE")
    @algorithmParameters["BYTEPIX"] = 4 unless @algorithmParameters.hasOwnProperty("BYTEPIX")
  
  @setValue: (header, key, defaultValue) -> return if header.contains(key) then header[key] else defaultValue
  
  # TODO: Test this function.  Need example file with blanks.
  getRowHasBlanks: ->
    [data, blank, scale, zero] = @_getRow()
    
    for value, index in data
      location = @totalRowsRead * @width + index
      @data[location] = if value is blank then NaN else (zero + scale * value)
    
    @rowsRead += 1
    @totalRowsRead += 1
  
  getRowNoBlanks: ->
    [data, blank, scale, zero] = @_getRow()
    for value, index in data
      location = @totalRowsRead * @width + index
      @data[location] = zero + scale * value
    
    @rowsRead += 1
    @totalRowsRead += 1
  
  getFrame: ->
    @initArray(Float32Array) unless @data?
    
    @totalRowsRead = 0  # Here for future use for compressed data cubes (mind blown!)
    @rowsRead = 0
    height = @height
    while height--
      @getRow()
    
    return @data
  
  _accessor: (dataType) =>
    [length, offset]  = [@view.getInt32(@offset), @view.getInt32(@offset)]
    return null if length is 0
    
    data = new @constructor.typedArray[dataType](length)
    
    tempOffset = @offset
    @offset = @begin + @tableLength + offset
    for i in [0..length - 1]
      [data[i], @offset] = @dataAccessors[dataType](@view, @offset)
    @offset = tempOffset
    
    return data

  _getRow: ->
    @offset = @begin + @totalRowsRead * @rowByteSize
    row = []
    for accessor in @accessors
      row.push accessor()
    
    data  = row[@columnNames["COMPRESSED_DATA"]] or row[@columnNames["UNCOMPRESSED_DATA"]] or row[@columnNames["GZIP_COMPRESSED_DATA"]]
    blank = row[@columnNames["ZBLANK"]] or @zblank
    scale = row[@columnNames["ZSCALE"]] or @bscale
    zero  = row[@columnNames["ZZERO"]] or @bzero
    return [data, blank, scale, zero]

  @subtractiveDither1: -> throw "Not yet implemented"
  @linearScaling: -> throw "Not yet implemented"


@astro.FITS.CompressedImage = CompressedImage