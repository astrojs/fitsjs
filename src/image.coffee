
# Image represents a standard image stored in the data unit of a FITS file
class Image extends DataUnit
  @include ImageUtils
  swapEndian:
    8: (value) -> return value
    16: (value) -> return (value << 8) | (value >> 8)
    32: (value) -> return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
  
  
  constructor: (header, view, offset) ->
    super
    
    naxis   = header.get("NAXIS")
    @bitpix = header.get("BITPIX")
    
    @naxis = []
    @naxis.push header.get("NAXIS#{i}") for i in [1..naxis]
    
    @width  = header.get("NAXIS1")
    @height = header.get("NAXIS2") or 1
    
    @bzero  = header.get("BZERO") or 0
    @bscale = header.get("BSCALE") or 1
    
    @bytes  = Math.abs(@bitpix) / 8
    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(@bitpix) / 8
    @frame  = 0    # Needed for data cubes
  
  getFrame: (@frame = @frame) ->
    # Reference the buffer
    buffer = @view.buffer
    
    # Get bytes representing this dataunit
    nPixels = i = @width * @height
    start = @offset + (@frame * nPixels * @bytes)
    
    chunk = buffer.slice(start, start + nPixels * @bytes)
    
    bitpix = Math.abs(@bitpix)
    if @bitpix > 0
      switch @bitpix
        when 8
          arr = new Uint8Array(chunk)
          arr = new Uint16Array(arr)
        when 16
          arr = new Uint16Array(chunk)
        when 32
          arr = new Int32Array(chunk)
      
      while nPixels--
        value = arr[nPixels]
        value = @swapEndian[bitpix](value)
        arr[nPixels] = @bzero + @bscale * value + 0.5
      
    else
      arr = new Uint32Array(chunk)
      
      while i--
        value = arr[i]
        arr[i] = @swapEndian[bitpix](value)
      
      # Initialize a Float32 array using the same buffer
      arr = new Float32Array(chunk)
      
      # Apply BZERO and BSCALE
      while nPixels--
        arr[nPixels] = @bzero + @bscale * arr[nPixels]
    
    @frame += 1 if @isDataCube()
    
    return arr
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image