# # Decompress

# Module will contain various decompression algorithms used in compressing FITS images.  Currently only
# the Rice decompression algorithm is implemented.  The four adopted algorithms are:

# * Rice
# * Gzip
# * IRAF PLIO
# * H-Compress

Decompress =
  
  RiceSetup:
    # Set up for bytepix = 1
    1: (array) ->
      pointer = 1
      fsbits = 3
      fsmax = 6
      
      lastpix = array[0]
      
      return [fsbits, fsmax, lastpix, pointer]
      
    # Set up for bytepix = 2
    2: (array) ->
      pointer = 2
      fsbits = 4
      fsmax = 14
      
      lastpix = 0
      bytevalue = array[0]
      lastpix = lastpix | (bytevalue << 8)
      bytevalue = array[1]
      lastpix = lastpix | bytevalue
      
      return [fsbits, fsmax, lastpix, pointer]
    
    # Set up for bytepix = 4
    4: (array) ->
      pointer = 4
      fsbits = 5
      fsmax = 25
      
      lastpix = 0
      bytevalue = array[0]
      lastpix = lastpix | (bytevalue << 24)
      bytevalue = array[1]
      lastpix = lastpix | (bytevalue << 16)
      bytevalue = array[2]
      lastpix = lastpix | (bytevalue << 8)
      bytevalue = array[3]
      lastpix = lastpix | bytevalue
      
      return [fsbits, fsmax, lastpix, pointer]
  
  # ### Rice
  # * array: Array of compressed bytes to be decompressed
  # * blocksize: Number of pixels encoded in a block
  # * bytepix: Number of 8-bit bytes of the original integer pixel
  # * pixels: Output array containing the decompressed values
  # * nx: Length of pixels (ztile1)
  Rice: (array, blocksize, bytepix, pixels, nx, setup) ->
    bbits = 1 << fsbits
    
    [fsbits, fsmax, lastpix, pointer] = setup[bytepix](array)
    
    nonzeroCount = new Uint8Array(256)
    nzero = 8
    [k, i] = [128, 255]
    while i >= 0
      while i >= k
        nonzeroCount[i] = nzero
        i -= 1
      k = k / 2
      nzero -= 1
    nonzeroCount[0] = 0
    
    # Bit buffer
    b = array[pointer++]
    
    # Number of bits remaining in b
    nbits = 8
    
    i = 0
    while i < nx
      nbits -= fsbits
      
      while nbits < 0
        b = (b << 8) | array[pointer++]
        nbits += 8
      
      fs = (b >> nbits) - 1
      b &= (1 << nbits) - 1
      
      imax = i + blocksize
      imax = nx if imax > nx
      
      if fs < 0
        while i < imax
          pixels[i] = lastpix
          i += 1
      else if fs is fsmax
        
        while i < imax
          k = bbits - nbits
          diff = b << k
          k -= 8
          while k >= 0
            b = array[pointer++]
            diff |= b << k
            k -= 8
          if nbits > 0
            b = array[pointer++]
            diff |= b >> (-k)
            b &= (1 << nbits) - 1
          else
            b = 0
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          pixels[i] = diff + lastpix
          lastpix = pixels[i]
          i++
      else
        
        while i < imax
          while b is 0
            nbits += 8
            b = array[pointer++]
          nzero = nbits - nonzeroCount[b]
          nbits -= nzero + 1
          b ^= 1 << nbits
          nbits -= fs
          while nbits < 0
            b = (b << 8) | (array[pointer++])
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

    return pixels


@astro.FITS.Decompress = Decompress