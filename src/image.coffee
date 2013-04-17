
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
  
  # Temporary method when FITS objects are initialized using a File instance.  This method must be called
  # by the developer before getFrame(Async), otherwise the Image instance will not have access to the representing
  # arraybuffer.
  start: (callback, context, args) ->
    unless @blob?
      context = if context? then context else @
      callback.apply(context, [args]) if callback?
      return
    
    # Initialize a reader for the blob
    reader = new FileReader()
    
    # Determine the number of chunkSize blobs
    i = 1
    nChunks = Math.floor(@blob.size / @chunkSize) - 1
    lastChunkSize = @blob.size - @chunkSize * nChunks
    buffer = []
    
    # Define the callback
    reader.onloadend = (e) =>
      console.log 'onloadend'
      
      # Whoa! What a hack!
      # @view = {}
      # @view.buffer = e.target.result
      buffer.push e.target.result
      console.log buffer
      
      while nChunks--
        begin = @chunkSize * i
        end = begin + @chunkSize
        console.log begin, end
        # reader.readAsArrayBuffer(@blob.slice(begin, end))
        i += 1
      
      # Execute callback
      context = if context? then context else @
      callback.apply(context, [args]) if callback?
    
    # Start by reading the first chunk
    console.log 0, @chunkSize
    chunk = @blob.slice(0, @chunkSize)
    reader.readAsArrayBuffer(chunk)
  
  # Shared method for Image class and also for Web Worker.  Cannot reference any instance variables
  _getFrame: (buffer, width, height, offset, frame, bytes, bitpix, bzero, bscale) ->
    
    # Get bytes representing this dataunit
    nPixels = i = width * height
    start = offset + (frame * nPixels * bytes)
    
    chunk = buffer.slice(start, start + nPixels * bytes)
    
    dataType = Math.abs(bitpix)
    if bitpix > 0
      switch bitpix
        when 8
          arr = new Uint8Array(chunk)
          arr = new Uint16Array(arr)
          swapEndian = (value) ->
            return value
        when 16
          arr = new Uint16Array(chunk)
          swapEndian = (value) ->
            return (value << 8) | (value >> 8)
        when 32
          arr = new Int32Array(chunk)
          swapEndian = (value) ->
            return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
            
      while nPixels--
        value = arr[nPixels]
        value = swapEndian(value)
        arr[nPixels] = bzero + bscale * value + 0.5
        
    else
      arr = new Uint32Array(chunk)
      
      swapEndian = (value) ->
        return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
        
      while i--
        value = arr[i]
        arr[i] = swapEndian(value)
        
      # Initialize a Float32 array using the same buffer
      arr = new Float32Array(chunk)
      
      # Apply BZERO and BSCALE
      while nPixels--
        arr[nPixels] = bzero + bscale * arr[nPixels]
        
    return arr
  
  getFrameAsync: (@frame = @frame, callback, opts = undefined) ->
    
    # Define the function to be executed on the worker thread
    onmessage = (e) ->
      # Cache variables
      data    = e.data
      buffer  = data.buffer
      width   = data.width
      height  = data.height
      offset  = data.offset
      frame   = data.frame
      bytes   = data.bytes
      bitpix  = data.bitpix
      bzero   = data.bzero
      bscale  = data.bscale
      url     = data.url
      
      importScripts(url)
      
      arr = _getFrame(buffer, width, height, offset, frame, bytes, bitpix, bzero, bscale)
      postMessage(arr)
    
    # Trick to format function for worker
    fn1 = onmessage.toString().replace('return postMessage(data);', 'postMessage(data);')
    fn1 = "onmessage = #{fn1}"
    
    # Functions passed to worker via url cannot be anonymous
    fn2 = @_getFrame.toString()
    fn2 = fn2.replace('function', 'function _getFrame')
    
    # Construct blob for an inline worker and getFrame function
    mime = "application/javascript"
    blobOnMessage = new Blob([fn1], {type: mime})
    blobGetFrame = new Blob([fn2], {type: mime})
    
    # Prefix for Safari
    URL = window.URL or window.webkitURL or window.MozURLProperty
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
    
    # Define object to be passed to worker
    msg = {}
    msg.buffer  = @view.buffer
    msg.width   = @width
    msg.height  = @height
    msg.offset  = @offset
    msg.frame   = @frame
    msg.bytes   = @bytes
    msg.bitpix  = @bitpix
    msg.bzero   = @bzero
    msg.bscale  = @bscale
    msg.url     = urlGetFrame
    
    # Pass object to worker
    worker.postMessage(msg)
  
  # Read single frame from image.  Frames are read sequentially unless nFrame is set.
  # For the case when the file is not yet in memory, a callback must be provided to
  # expose the resulting array.  This is another case where a synchronous and
  # asynchronous process are abstracted by a single function.
  getFrame: (nFrame, callback) ->
    
    @frame = nFrame or @frame
    frameInfo = @frameOffsets[@frame]
    
    # Check if bytes are in memory
    if frameInfo.buffer?
      arr = @_getFrame(frameInfo.buffer, @width, @height, @offset, @frame, @bytes, @bitpix, @bzero, @bscale)
      
      # Increment frame counter if handling data cube
      @frame += 1 if @isDataCube()
      callback.call(@, arr) if callback?
      return arr
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
        @getFrame(frame, callback)
        
      reader.readAsArrayBuffer(blobFrame)
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image 