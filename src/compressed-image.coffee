
class CompressedImage extends BinaryTable
  @include ImageUtils
  @extend Decompress
  
  
  constructor: (header, view, offset) ->
    super
    
    @counter = 0
    
    @length   += header.get("PCOUNT")
    @zcmptype = header.get("ZCMPTYPE")
    @zbitpix  = header.get("ZBITPIX")
    @znaxis   = header.get("ZNAXIS")
    @zblank   = @getValue(header, "ZBLANK", undefined)
    @blank    = @getValue(header, "BLANK", undefined)
    
    @ztile = []
    for i in [1..@znaxis]
      ztile = if header.contains("ZTILE#{i}") then header.get("ZTILE#{i}") else if i is 1 then header.get("ZNAXIS1") else 1
      @ztile.push ztile
    
    @width  = header.get("ZNAXIS1")
    @height = header.get("ZNAXIS2") or 1
    
    # Get algorithm specific parameters
    @params = {}
    i = 1
    loop
      key = "ZNAME#{i}"
      break unless header.contains(key)
      value = "ZVAL#{i}"
      @params[header.get(key)] = header.get(value)
      i += 1
    
    # Set default parameters unless already set
    @setRiceDefaults() if @zcmptype is 'RICE_1'
    
    @zmaskcmp = @getValue(header, "ZMASKCMP", undefined)
    @zquantiz = @getValue(header, "ZQUANTIZ", "LINEAR_SCALING")
    
    @bzero  = @getValue(header, "BZERO", 0)
    @bscale = @getValue(header, "BSCALE", 1)
    
    @setAccessors(header)
    @defGetRow()
    
  getValue: (header, key, defaultValue) ->
    return if header.contains(key) then header.get(key) else defaultValue
    
  setRiceDefaults: ->
    @params["BLOCKSIZE"] = 32 unless "BLOCKSIZE" of @params
    @params["BYTEPIX"] = 4 unless "BYTEPIX" of @params
    
  defGetRow: ->
    hasBlanks = @zblank? or @blank? or @columnNames.hasOwnProperty("ZBLANK")
    @getRow = if hasBlanks then @getRowHasBlanks else @getRowNoBlanks
    
  # TODO: Test this function.  Need example file with blanks.
  getRowHasBlanks: (arr) ->
    [data, blank, scale, zero] = @getTableRow()
    
    offset = @rowsRead * @width
    for value, index in data
      i = offset + index
      arr[i] = if value is blank then NaN else (zero + scale * value)
    @rowsRead += 1
    
  getRowNoBlanks: (arr) ->
    [data, blank, scale, zero] = @getTableRow()
    
    offset = @rowsRead * @width
    for value, index in data
      i = offset + index
      arr[i] = zero + scale * value
    @rowsRead += 1
    
  getTableRow: ->
    @offset = @begin + @rowsRead * @rowByteSize
    row = []
    for accessor in @accessors
      row.push accessor()
    
    data  = row[@columnNames["COMPRESSED_DATA"]] or row[@columnNames["UNCOMPRESSED_DATA"]] or row[@columnNames["GZIP_COMPRESSED_DATA"]]
    blank = row[@columnNames["ZBLANK"]] or @zblank
    scale = row[@columnNames["ZSCALE"]] or @bscale
    zero  = row[@columnNames["ZZERO"]] or @bzero
    
    return [data, blank, scale, zero]
    
  getFrame: ->
    arr = new Float32Array(@width * @height)
    
    @rowsRead = 0
    height = @height
    while height--
      @getRow(arr)
    
    return arr


@astro.FITS.CompressedImage = CompressedImage