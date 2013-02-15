
# Image represents a standard image stored in the data unit of a FITS file
class Image extends DataUnit
  @include ImageUtils
  
  
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
  
  getFrameAsync: (@frame = @frame, callback) ->
    
    # Define the function to be executed on the worker thread
    onmessage = (e) ->
      # Cache variables
      data    = e.data
      bitpix  = data.bitpix
      width   = data.width
      height  = data.height
      bzero   = data.bzero
      bscale  = data.bscale
      chunk   = data.chunk
      
      # Set counters
      nPixels = i = width * height
      
      # Define swap endian functions (must be defined in worker since functions not passable to worker)
      switch Math.abs(bitpix)
        when 16
          swapEndian = (value) ->
            return (value << 8) | (value >> 8)
        when 32
          swapEndian = (value) ->
            return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
        else
          swapEndian = (value) -> return value
      
      # Determine appropriate typed array
      if bitpix > 0
        # Data type is integer
        switch bitpix
          when 8
            arr = new Uint8Array(chunk)
            arr = new Uint16Array(arr)
          when 16
            arr = new Uint16Array(chunk)
          when 32
            arr = new Int32Array(chunk)
        
        # Swap endian and apply BZERO and BSCALE
        while nPixels--
          value = arr[nPixels]
          value = swapEndian(value)
          arr[nPixels] = bzero + bscale * value + 0.5
      else
        # Data type is float
        arr = new Uint32Array(chunk)

        while i--
          value = arr[i]
          arr[i] = swapEndian(value)

        # Initialize a Float32 array using the same buffer
        arr = new Float32Array(chunk)

        # Apply BZERO and BSCALE
        while nPixels--
          arr[nPixels] = bzero + bscale * arr[nPixels]
      
      postMessage(arr)
    
    # Trick to format function for worker
    fn = onmessage.toString().split('').reverse().join('').replace(' nruter', '')
    fn = fn.split('').reverse().join('')
    fn = "onmessage = #{fn}"
    
    # Construct blob for an inline worker
    blob = new Blob([fn], {type: "application/javascript"})
    
    # Prefix for Safari
    URL = URL or webkitURL
    blobUrl = URL.createObjectURL(blob)
    
    # Initialize worker
    worker = new Worker(blobUrl)
    
    # Define function for when worker job is complete
    worker.onmessage = (e) ->
      arr = e.data
      
      # Execute callback
      callback.call(@, arr) if callback?
      
      # Clean up blob url
      URL.revokeObjectURL(blobUrl)
    
    # Get bytes representing this dataunit
    nPixels = @width * @height
    start   = @offset + (@frame * nPixels * @bytes)
    
    # Define object to be passed to worker
    data = {}
    data.bitpix = @bitpix
    data.width  = @width
    data.height = @height
    data.bzero  = @bzero
    data.bscale = @bscale
    data.chunk  = @view.buffer.slice(start, start + nPixels * @bytes)
    
    # Pass object to worker
    worker.postMessage(data)
  
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