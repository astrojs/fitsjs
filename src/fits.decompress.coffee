# # Decompress

# Module will contain various decompression algorithms used in compressing FITS images.  Currently only
# the Rice decompression algorithm is implemented.  The four adopted algorithms are:

# * Rice
# * Gzip
# * IRAF PLIO
# * H-Compress

FITS.Decompress =
  
  # ### rice
  # * array: Array of compressed bytes to be decompressed
  # * arrayLen: Length of array
  # * blocksize: Number of pixels encoded in a block
  # * bytepix: Number of 8-bit bytes of the original integer pixel
  # * pixels: Output array containing the decompressed values
  # * nx: Length of pixels
  rice: (array, arrayLen, blocksize, bytepix, pixels, nx) ->
    
    fsbits = 4
    fsmax = 14
    
    # fsbits = 3
    # fsmax = 6
    
    bbits = 1 << fsbits
    
    [fsbits, fsmax, lastpix] = @riceSetup[bytepix]()
    
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
    
    # Bit buffer
    b = array.shift()

    # Number of bits remaining in b
    nbits = 8
    
    i = 0
    while i < nx

      nbits -= fsbits
      while nbits < 0
        b = (b << 8) | (array.shift())
        nbits += 8
      fs = (b >> nbits) - 1
      b &= (1 << nbits) - 1
      imax = i + blocksize
      imax = nx if imax > nx

      if fs < 0
        while i < imax
          array[i] = lastpix
          i++
      else if fs is fsmax
        while i < imax
          k = bbits - nbits
          diff = b << k
          k -= 8
          while k >= 0
            b = array.shift()
            diff |= b << k
            k -= 8
          if nbits > 0
            b = array.shift()
            diff |= b >> (-k)
            b &= (1 << nbits) - 1
          else
            b = 0
          if (diff & 1) is 0
            diff = diff >> 1
          else
            diff = ~(diff >> 1)
          array[i] = diff + lastpix
          lastpix = array[i]
          i++
      else
        while i < imax
          while b is 0
            nbits += 8
            b = array.shift()
          nzero = nbits - nonzeroCount[b]
          nbits -= nzero + 1
          b ^= 1 << nbits
          nbits -= fs
          while nbits < 0
            b = (b << 8) | (array.shift())
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

    # # TODO: This should go elsewhere (inefficient!!!)
    # for i in [0..pixels.length-1]
    #   pixels[i] = pixels[i] + @bzero

    return pixels

  riceSetup:
    
    # Setting up for bytepix = 1
    1: ->
      fsbits = 3
      fsmax = 6
      lastpix = array.shift()
      
      return [fsbits, fsmax, lastpix]

    # Setting up for bytepix = 2
    2: ->
      fsbits = 4
      fsmax = 14
      
      # Decode in blocks of BLOCKSIZE pixels
      lastpix = 0
      bytevalue = array.shift()
      lastpix = lastpix | (bytevalue << 8)
      bytevalue = array.shift()
      lastpix = lastpix | bytevalue
      
      return [fsbits, fsmax, lastpix]
  
  gzip: (array, length) ->
    throw "Not yet implemented"
  
  plio: (array, length) ->
    throw "Not yet implemented"
  
  hcompress: (array, length) ->
    throw "Not yet implemented"

module?.exports = FITS.Decompress