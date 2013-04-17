
# Image represents a standard image stored in the data unit of a FITS file
class Image extends DataUnit
  @include ImageUtils
  
  # When reading from a File object, only needed portions of file are placed into memory.
  # When large heaps are required, they are requested in 16 MB increments.
  allocationSize: 16777216
  
  
  constructor: (header, data) ->
    super
    
    # Get parameters from header
    naxis   = header.get("NAXIS")
    @bitpix = header.get("BITPIX")
    
    @naxis = []
    @naxis.push header.get("NAXIS#{i}") for i in [1..naxis]
    
    @width  = header.get("NAXIS1")
    @height = header.get("NAXIS2") or 1
    @depth  = header.get("NAXIS3") or 1
    
    @bzero  = header.get("BZERO") or 0
    @bscale = header.get("BSCALE") or 1
    
    @bytes  = Math.abs(@bitpix) / 8
    @length = @naxis.reduce( (a, b) -> a * b) * Math.abs(@bitpix) / 8
    @frame  = 0    # Needed for data cubes
    
    # Create a look up table to store byte offsets for each frame
    # in the image.  This is mostly relevant to data cubes.  Each entry stores
    # the beginning offset of a frame.  A frame length parameter stores the byte
    # length of a single frame.
    @frameOffsets = []
    @frameLength = @bytes * @width * @height
    for i in [0..@depth - 1]
      begin = i * @frameLength
      frame = {begin: begin}
      if @buffer?
        frame.buffer = @buffer.slice(begin, begin + @frameLength)
      @frameOffsets.push frame
  
  # Shared method for Image class and also for Web Worker.  Cannot reference any instance variables
  # This is an internal function that converts bytes to pixel values.  There is no reference to instance
  # variables in this function because it is executed on a Web Worker, which always exists outside the
  # scope of this function (class).
  _getFrame: (buffer, bitpix, bzero, bscale) ->
    
    # Get the number of pixels represented in buffer
    bytes = Math.abs(bitpix) / 8
    nPixels = i = buffer.byteLength / bytes
    
    dataType = Math.abs(bitpix)
    if bitpix > 0
      switch bitpix
        when 8
          arr = new Uint8Array(buffer)
          arr = new Uint16Array(arr)
          swapEndian = (value) ->
            return value
        when 16
          arr = new Uint16Array(buffer)
          swapEndian = (value) ->
            return (value << 8) | (value >> 8)
        when 32
          arr = new Int32Array(buffer)
          swapEndian = (value) ->
            return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
            
      while nPixels--
        value = arr[nPixels]
        value = swapEndian(value)
        arr[nPixels] = bzero + bscale * value + 0.5
        
    else
      arr = new Uint32Array(buffer)
      
      swapEndian = (value) ->
        return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
        
      while i--
        value = arr[i]
        arr[i] = swapEndian(value)
        
      # Initialize a Float32 array using the same buffer
      arr = new Float32Array(buffer)
      
      # Apply BZERO and BSCALE
      while nPixels--
        arr[nPixels] = bzero + bscale * arr[nPixels]
        
    return arr
  
  getFrameAsync: (buffer, callback, opts) ->
    
    # Define function to be executed on the worker thread
    onmessage = (e) ->
      # Get variables sent from main thread
      data    = e.data
      buffer  = data.buffer
      bitpix  = data.bitpix
      bzero   = data.bzero
      bscale  = data.bscale
      url     = data.url
      
      # Import getFrame function
      importScripts(url)
      
      arr = _getFrame(buffer, bitpix, bzero, bscale)
      postMessage(arr)
    
    # Trick to format function for worker
    fn1 = onmessage.toString().replace('return postMessage(data);', 'postMessage(data);')
    fn1 = "onmessage = #{fn1}"
    
    # Functions passed to worker via url cannot be anonymous
    fn2 = @_getFrame.toString()
    fn2 = fn2.replace('function', 'function _getFrame')
    
    # Construct blob for an inline worker and _getFrame function
    mime = "application/javascript"
    blobOnMessage = new Blob([fn1], {type: mime})
    blobGetFrame = new Blob([fn2], {type: mime})
    
    # Get the native URL object
    URL = URL or webkitURL
    
    # Create URLs to onmessage and _getFrame scripts
    urlOnMessage = URL.createObjectURL(blobOnMessage)
    urlGetFrame = URL.createObjectURL(blobGetFrame)
    
    # Initialize worker
    worker = new Worker(urlOnMessage)
    
    # Define function for when worker job is complete
    worker.onmessage = (e) ->
      arr = e.data
      
      # Execute callback
      context = if opts?.context? then opts.context else @
      callback.call(context, arr, opts) if callback?
      
      # Clean up urls and worker
      URL.revokeObjectURL(urlOnMessage)
      URL.revokeObjectURL(urlGetFrame)
      worker.terminate()
    
    # Define object containing parameters to be passed to worker
    msg =
      buffer: buffer
      bitpix: @bitpix
      bzero: @bzero
      bscale: @bscale
      url: urlGetFrame
    worker.postMessage(msg)
  
  # Read single frame from image.  Frames are read sequentially unless nFrame is set.
  # A callback must be provided since there are 1 or more asynchronous processes happening
  # to convert bytes to flux. This is a case where a partially synchronous and
  # completely asynchronous process are abstracted by a single function.
  getFrame: (nFrame, callback, opts) ->
    
    @frame = nFrame or @frame
    frameInfo = @frameOffsets[@frame]
    buffer = frameInfo.buffer
    
    # Check if bytes are in memory
    if buffer?
      @getFrameAsync(buffer, callback, opts)
    else
      # Read frame bytes into memory since not yet copied.
      # TODO: For HUGE images each frame should be sliced into equal
      #       chunks rather than imposing so much memory to be allocated
      #       by one operation.
      
      # Slice blob for only current frame bytes
      begin = frameInfo.begin
      blobFrame = @blob.slice(begin, begin + @frameLength)
      
      # Create file reader and store frame number on object for later reference
      reader = new FileReader()
      reader.frame = @frame
      reader.onloadend = (e) =>
        
        frame = e.target.frame
        buffer = e.target.result
        
        # Store the buffer for later access
        @frameOffsets[frame].buffer = buffer
        
        # Call function again
        @getFrame(frame, callback, opts)
        
      reader.readAsArrayBuffer(blobFrame)
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image 