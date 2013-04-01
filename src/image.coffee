
# Image represents a standard image stored in the data unit of a FITS file
class Image extends DataUnit
  @include ImageUtils
  
  
  constructor: ->
    
    if arguments.length is 3
      # Arguments are (header, view, offset)
      super
      [header, view, offset] = arguments
    else
      # Arguments are (header, blob)
      
      # Set begin to allow new functionality of working with blobs to
      # work with current methods.
      @begin = 0
      [header, @blob] = arguments
    
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
  
  # Temporary method when FITS objects are initialized using a File instance.  This method must be called
  # by the developer before getFrame(Async), otherwise the Image instance will not have access to the representing
  # arraybuffer.
  start: ->
    # Initialize a reader for the blob
    reader = new FileReader()
    
    # Define the callback
    reader.onloadend = (e) =>
      
      # Whoa! What a hack!
      @view = {}
      @view.buffer = e.target.result
    
    reader.readAsArrayBuffer(@blob)
  
  # Shared method for Image class and also for Web Worker.  Cannot reference any instance variables
  @_getFrame: (buffer, width, height, offset, frame, bytes, bitpix, bzero, bscale) ->
    
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
    fn2 = Image._getFrame.toString()
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
      callback.call(@, arr, opts) if callback?
      
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
  
  getFrame: (@frame = @frame) ->
    arr = Image._getFrame(@view.buffer, @width, @height, @offset, @frame, @bytes, @bitpix, @bzero, @bscale)
    @frame += 1 if @isDataCube()
    
    return arr
  
  # Checks if the image is a data cube
  isDataCube: ->
    return if @naxis.length > 2 then true else false 


@astro.FITS.Image = Image 