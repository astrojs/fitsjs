
class CompressedImage extends BinaryTable
  @include ImageUtils
  @extend Decompress
  
  
  # Predefined random number generator from http://arxiv.org/pdf/1201.1336v1.pdf
  # This is the same method used by fpack when dithering images during compression.
  @randomGenerator: ->
    a = 16807
    m = 2147483647
    seed = 1
    
    random = new Float32Array(10000)
    
    for i in [0..9999]
      temp = a * seed
      seed = temp - m * parseInt(temp / m)
      random[i] = seed / m
      
    return random
  
  # Store the random look up table on the class.
  @randomSequence = @randomGenerator()
  
  
  constructor: (header, view, offset) ->
    super
    
    # Get compression values
    @zcmptype = header.get("ZCMPTYPE")
    @zbitpix  = header.get("ZBITPIX")
    @znaxis   = header.get("ZNAXIS")
    @zblank   = header.get("ZBLANK")
    @blank    = header.get("BLANK")
    @zdither  = header.get('ZDITHER0') or 0
    
    @ztile = []
    for i in [1..@znaxis]
      ztile = if header.contains("ZTILE#{i}") then header.get("ZTILE#{i}") else if i is 1 then header.get("ZNAXIS1") else 1
      @ztile.push ztile
    
    @width  = header.get("ZNAXIS1")
    @height = header.get("ZNAXIS2") or 1
    
    # Storage for compression algorithm parameters
    @algorithmParameters = {}
    
    # Set default parameters
    if @zcmptype is 'RICE_1'
      @algorithmParameters["BLOCKSIZE"] = 32
      @algorithmParameters["BYTEPIX"] = 4
    
    # Get compression algorithm parameters (override defaults when keys present)
    i = 1
    loop
      key = "ZNAME#{i}"
      break unless header.contains(key)
      
      value = "ZVAL#{i}"
      @algorithmParameters[ header.get(key) ] = header.get(value)
      
      i += 1
    
    @zmaskcmp = header.get("ZMASKCMP")
    @zquantiz = header.get("ZQUANTIZ") or "LINEAR_SCALING"
    
    @bzero  = header.get("BZERO") or 0
    @bscale = header.get("BSCALE") or 1
    
    # Define the internal _getRow function
    hasBlanks = @zblank? or @blank? or @columns.indexOf("ZBLANK") > -1
    @_getRow = if hasBlanks then @_getRowHasBlanks else @_getRowNoBlanks
    
    @setAccessors(header)
    
  # TODO: Test this function.  Need example file with blanks.
  # TODO: Implement subtractive dithering
  _getRowHasBlanks: (arr) ->
    [data, blank, scale, zero] = @getTableRow()
    # Cache frequently accessed variables
    random = @constructor.randomSequence
    ditherOffset = @ditherOffset
    offset = @rowsRead * @width
    
    for value, index in data
      i = offset + index
      r = random[ditherOffset]
      arr[i] = if value is blank then NaN else (value - r + 0.5) * scale + zero
      ditherOffset = (ditherOffset + 1) % 10000
    @rowsRead += 1
    
  # _getRowNoBlanks: (arr) ->
  #   [data, blank, scale, zero] = @getTableRow()
  #   
  #   width = @width
  #   offset = @rowsRead * width
  #   randomSeq = @randomSeq
  #   zdither = @zdither
  #   
  #   for value, index in data
  #     i = offset + index
  #     
  #     # Get tile number (usually tiles are row-wise)
  #     # TODO: Optimize int casting
  #     # nTile = parseInt(index / width)
  #     # r = @getRandom(nTile)
  #     
  #     r = randomSeq[zdither]
  #     
  #     # Unquantize the pixel intensity
  #     arr[i] = (value - r + 0.5) * scale + zero
  #     zdither = (zdither + 1) % 10000
  #   
  #   @rowsRead += 1
  
  _getRowNoBlanks: (arr) ->
    [data, blank, scale, zero] = @getTableRow()
    
    # Set initial seeds using ZDITHER0
    seed0 = @rowsRead + @zdither - 1
    seed1 = (seed0 - 1) % 10000
    
    # Set initial index in random sequence
    rIndex = parseInt(@constructor.randomSequence[seed1] * 500)
    
    # Set offset based on number of tiles read
    offset = @rowsRead * @width
    
    for value, index in data
      i = offset + index
      
      # Set NaN values
      if value is -2147483647
        arr[i] = NaN
      # Set zero values
      else if value is -2147483646
        arr[i] = 0
      # Unquantize
      else
        if @rowsRead is 0
          console.log @constructor.randomSequence[rIndex]
        arr[i] = (value - @constructor.randomSequence[rIndex] + 0.5) * scale + zero
      
      # Update the random number
      rIndex += 1
      if rIndex is 10000
        seed1 = (seed1 + 1) % 10000
        rIndex = parseInt(@constructor.randomSequence[seed1] * 500)
    
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
  
  getRandom: (nTile) ->
    # Ensure nTile does not exceed length of random look up table
    nTile = nTile % 10000
    
    # Get random number from predefined sequence
    r = @constructor.randomSequence[nTile]
    
    # Compute offset using random
    offset = parseInt(500 * r)
    
    # Return random number based on tile number and offset
    return @constructor.randomSequence[offset]


@astro.FITS.CompressedImage = CompressedImage