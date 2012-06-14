require('jDataView/src/jdataview')

FITS        = @FITS or require('fits')
Data        = require('fits.data')
Decompress  = require('fits.decompress')

class FITS.BinTable extends Data
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  
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
    @compressedImage  = header.contains("ZIMAGE")
    @rowsRead = 0

    # Select the column data types
    @fields = header["TFIELDS"]
    @accessors = []

    for i in [1..@fields]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(FITS.BinTable.arrayDescriptorPattern)
      if match?
        do =>
          dataType = match[1]
          accessor = =>
            # TODO: Find out how to pass dataType
            length  = @view.getInt32()
            offset  = @view.getInt32()
            @current = @view.tell()
            # Troublesome
            # TODO: Find a way to preserve the dataType in this function for each column
            @view.seek(@begin + @tableLength + offset)
            data = []
            for i in [1..length]
              data.push FITS.BinTable.dataAccessors[dataType](@view)
            @view.seek(@current)
            return data
          @accessors.push(accessor)
      else
        match = value.match(FITS.BinTable.dataTypePattern)
        [r, dataType] = match[1..]
        r = if r then parseInt(r) else 0
        if r is 0
          do =>
            dataType = match[2]
            accessor = (dt) =>
              data = FITS.BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)
        else
          do =>
            dataType = match[2]
            accessor = =>
              data = []
              for i in [1..r]
                data.push FITS.BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)

  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    for i in [0..@accessors.length-1]
      data = @accessors[i]()
      row.push(data)
    @rowsRead += 1
    
    if @compressedImage
      # array, arrayLen, blocksize, bytepix, pixels, nx
      console.log @riceDecompressShort(data)
    return row
    
  riceDecompressShort: (arr) ->
    
    # TODO: Typed array should be set by BITPIX of the uncompressed data
    pixels = new Uint16Array(@nx)
    fsbits = 4
    fsmax = 14
    bbits = 1 << fsbits
    
    nonzeroCount = new Array(256)
    nzero = 8
    k = 128
    i = 255
    while i >= 0
      while i >= k
        nonzeroCount[i] = nzero
        i -= 1
      k = k / 2
      nzero -= 1
    # FIXME: Not sure why this element is incorrectly -1024
    nonzeroCount[0] = 0
    
    # NOTES:  nx      = ZTILE1
    #         nblock  = BLOCKSIZE
    
    # Decode in blocks of BLOCKSIZE pixels
    lastpix = 0
    bytevalue = arr.shift()
    lastpix = lastpix | (bytevalue << 8)
    bytevalue = arr.shift()
    lastpix = lastpix | bytevalue
    
    # Bit buffer
    b = arr.shift()
    
    # Number of bits remaining in b
    nbits = 8
    
    i = 0
    while i < @nx
      
      nbits -= fsbits
      while nbits < 0
        b = (b << 8) | (arr.shift())
        nbits += 8
      fs = (b >> nbits) - 1
      b &= (1 << nbits) - 1
      imax = i + @blocksize
      imax = @nx if imax > @nx
      
      if fs < 0
        while i < imax
          arr[i] = lastpix
          i++
      else if fs is fsmax
        while i < imax
          k = bbits - nbits
          diff = b << k
          k -= 8
          while k >= 0
            b = arr.shift()
            diff |= b << k
            k -= 8
          if nbits > 0
            b = arr.shift()
            diff |= b >> (-k)
            b &= (1 << nbits) - 1
          else
            b = 0
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          arr[i] = diff + lastpix
          lastpix = arr[i]
          i++
      else
        while i < imax
          while b is 0
            nbits += 8
            b = arr.shift()
          nzero = nbits - nonzeroCount[b]
          nbits -= nzero + 1
          b ^= 1 << nbits
          nbits -= fs
          while nbits < 0
            b = (b << 8) | (arr.shift())
            nbits += 8
          diff = (nzero << fs) | (b >> nbits)
          b &= (1 << nbits) - 1
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          pixels[i] = diff + lastpix
          lastpix = pixels[i]
          i++

    # TODO: This should go elsewhere
    for i in [0..pixels.length-1]
      pixels[i] = pixels[i] + @bzero
    return pixels

module?.exports = FITS.BinTable