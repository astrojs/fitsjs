
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
    
    # Set number of buffers per frame
    @nBuffers = if @buffer? then 1 else 2
    
    for i in [0..@depth - 1]
      begin = i * @frameLength
      frame = {begin: begin}
      if @buffer?
        frame.buffers = [@buffer.slice(begin, begin + @frameLength)]
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
          tmp = new Uint8Array(buffer)
          tmp = new Uint16Array(tmp)
          swapEndian = (value) ->
            return value
        when 16
          tmp = new Int16Array(buffer)
          swapEndian = (value) ->
            return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF)
        when 32
          tmp = new Int32Array(buffer)
          swapEndian = (value) ->
            return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
      
      # Patch for data unit with BSCALE AND BZERO ...
      unless (parseInt(bzero) is bzero and parseInt(bscale) is bscale)
        arr = new Float32Array(tmp.length)
      else
        arr = tmp
      while nPixels--
        
        # Swap endian and recast into typed array (needed to properly handle any overflow)
        tmp[nPixels] = swapEndian( tmp[nPixels] )
        arr[nPixels] = bzero + bscale * tmp[nPixels]
      
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
  
  _getFrameAsync: (buffers, callback, opts) ->
    
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
    fn1 = onmessage.toString().replace('return postMessage', 'postMessage')
    fn1 = "onmessage = #{fn1}"
    
    # Functions passed to worker via url cannot be anonymous
    fn2 = @_getFrame.toString()
    fn2 = fn2.replace('function', 'function _getFrame')
    
    # Construct blob for an inline worker and _getFrame function
    mime = "application/javascript"
    blobOnMessage = new Blob([fn1], {type: mime})
    blobGetFrame = new Blob([fn2], {type: mime})
    
    # Create URLs to onmessage and _getFrame scripts
    URL = window.URL or window.webkitURL # to appease Safari
    urlOnMessage = URL.createObjectURL(blobOnMessage)
    urlGetFrame = URL.createObjectURL(blobGetFrame)
    
    # Initialize worker
    worker = new Worker(urlOnMessage)
    
    # Define object containing parameters to be passed to worker beginning with first buffer
    msg =
      buffer: buffers[0]
      bitpix: @bitpix
      bzero: @bzero
      bscale: @bscale
      url: urlGetFrame
    
    # Define function for when worker job is complete
    i = 0
    pixels = null
    start = 0
    worker.onmessage = (e) =>
      arr = e.data
      
      # Initialize storage for all pixels
      unless pixels?
        pixels = new arr.constructor(@width * @height)
      pixels.set(arr, start)
      
      # Set start index for next iteration
      start += arr.length
      
      i += 1
      if i is @nBuffers
        @invoke(callback, opts, pixels)
        
        # Clean up urls and worker
        URL.revokeObjectURL(urlOnMessage)
        URL.revokeObjectURL(urlGetFrame)
        worker.terminate()
      else
        msg.buffer = buffers[i]
        worker.postMessage( msg, [ buffers[i] ] )
    
    worker.postMessage( msg, [ buffers[0] ] )
    return
  
  # Read frames from image.  Frames are read sequentially unless nFrame is set.
  # A callback must be provided since there are 1 or more asynchronous processes happening
  # to convert bytes to flux. This is a case where a partially synchronous and
  # completely asynchronous process are abstracted by a single function.
  getFrame: (frame, callback, opts) ->
    @frame = frame or @frame
    
    frameInfo = @frameOffsets[@frame]
    buffers = frameInfo.buffers
    
    # Check if bytes are in memory
    if buffers?.length is @nBuffers
      @_getFrameAsync(buffers, callback, opts)
    else
      
      # Read frame bytes into memory incrementally
      @frameOffsets[@frame].buffers = []
      
      # Slice blob for only current frame bytes
      begin = frameInfo.begin
      blobFrame = @blob.slice(begin, begin + @frameLength)
      
      # Slice blob into chunks to prevent reading too much data in single operation
      blobs = []
      
      nRowsPerBuffer = Math.floor(@height / @nBuffers)
      bytesPerBuffer = nRowsPerBuffer * @bytes * @width
      for i in [0..@nBuffers - 1]
        start = i * bytesPerBuffer
        
        if i is @nBuffers - 1
          blobs.push blobFrame.slice(start)
        else
          blobs.push blobFrame.slice(start, start + bytesPerBuffer)
      
      # Create array for buffers
      buffers = []
      
      # Create file reader and store frame number on object for later reference
      reader = new FileReader()
      reader.frame = @frame
      i = 0
      reader.onloadend = (e) =>
        
        frame = e.target.frame
        buffer = e.target.result
        
        # Store the buffer for later access
        @frameOffsets[frame].buffers.push buffer
        
        i += 1
        if i is @nBuffers
          # Call function again
          @getFrame(frame, callback, opts)
        else
          reader.readAsArrayBuffer( blobs[i] )
      
      reader.readAsArrayBuffer( blobs[0] )
  
  # Reads frames in a data cube in an efficient way that does not
  # overload the browser. The callback passed will be executed once for
  # each frame, in the sequential order of the cube.
  getFrames: (frame, number, callback, opts) ->
    
    # Define callback to pass to getFrame
    cb = (arr, opts) =>
      @invoke(callback, opts, arr)
      
      # Update counters
      number -= 1
      frame += 1
      
      return unless number
      
      # Request another frame
      @getFrame(frame, cb, opts)
    
    # Start reading frames
    @getFrame(frame, cb, opts)
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image 