require('jDataView/src/jdataview')

FITS        = @FITS or require('fits')
Tabular     = require('fits.tabular')
Decompress  = require('fits.decompress')

class FITS.CompImage extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  @extend Decompress
  
  @typeArray =
    B: Uint8Array
    I: Int16Array
    J: Int32Array
    1: Uint8Array
    2: Uint8Array
    4: Int16Array
    8: Int32Array
  
  constructor: (view, header) ->
    super
    
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @cols         = header["TFIELDS"]
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead     = 0
  
    @length   += header["PCOUNT"]
    @zcmptype = header["ZCMPTYPE"]
    @zbitpix  = header["ZBITPIX"]
    @znaxis   = header["ZNAXIS"]
    @zblank   = FITS.CompImage.setValue(header, "ZBLANK", undefined)
    
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
    
    @accessors = []
    for i in [1..@cols]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(FITS.CompImage.arrayDescriptorPattern)
      console.log match
      ttype = header["TTYPE#{i}"]
      
      if match?
        # Define an array accessor method
        if ttype.toUpperCase() is "COMPRESSED_DATA"
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
    data  = row[0]
    scale = row[1][0]
    zero  = row[2][0]
    
    pixels = new Float32Array(data.length)
    for i in [0..data.length - 1]
      pixels[i] = (data[i] * scale) + zero
    return pixels
  
  getFrame: ->
    @rowsRead = 0
    pixels = new Float32Array(@ztile[0] * @rows)
    
    loop
      @current = @begin + @rowsRead * @rowByteSize
      @view.seek(@current)
      row = []
      row.push @accessors[i]() for i in [0..@accessors.length-1]
      @rowsRead += 1
      data  = row[0]
      scale = row[1][0]
      zero  = row[2][0]
      for i in [0..data.length - 1]
        pixels[i + @rowsRead * @ztile[0]] = (data[i] * scale) + zero
      break if @rowsRead is @rows
    return pixels
      
  
  @subtractiveDither1: -> throw "Not yet implemented"
  @linearScaling: -> throw "Not yet implemented"

  

module?.exports = FITS.CompImage