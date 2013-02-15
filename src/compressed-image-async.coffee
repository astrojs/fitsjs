
# An extension to the CompressedImage class adding getFrameAsync
CompressedImage = @astro.FITS.CompressedImage

CompressedImage::getFrameAsync = (@frame = @frame, callback) ->
  console.log 'getFrameAsync'
  
  # Define the function to be executed on the worker thread
  onmessage = (e) ->
    # Cache variables
    data        = e.data
    cols        = data.cols
    typedArray  = data.typedArray
    tableLength = data.tableLength
    
    bitpix  = data.bitpix
    buffer  = data.buffer
    
    # Set variables
    offset = 0
    columnNames = {}
    
    # Initialize a DataView object
    view = new DataView(buffer)
    
    #
    # Define various functions
    #
    setAccessors = ->
      pattern = /(\d*)([P|Q]*)([L|X|B|I|J|K|A|E|D|C|M]{1})/
      for i in [1..cols]
        form  = data["TFORM#{i}"]
        type  = data["TTYPE#{i}"]
        match = pattern.exec(form)

        count       = parseInt(match[1]) or 1
        isArray     = match[2]
        descriptor  = match[3]
        
        columnNames[type] = i - 1
        
        if isArray  # Rarely will this be false
          # Handle array descriptors
          switch type
            when "COMPRESSED_DATA"
              do (descriptor, count) =>
                accessor = =>
                  arr = getFromHeap(descriptor)

                  # Assuming Rice compression
                  pixels = new @typedArray[@params["BYTEPIX"]](@ztile[0])
                  
                  # Bring in Rice using technique at
                  # http://stackoverflow.com/questions/11909934/how-to-pass-functions-to-javascript-web-worker
                  @constructor.Rice(arr, @params["BLOCKSIZE"], @params["BYTEPIX"], pixels, @ztile[0])

                  return pixels
                @accessors.push(accessor)
            when "GZIP_COMPRESSED_DATA"
              # TODO: Implement GZIP
              do (descriptor, count) =>
                accessor = =>
                  # arr = @getFromHeap(descriptor)

                  # Temporarily padding with NaNs until GZIP is implemented
                  arr = new Float32Array(@width)
                  i = arr.length
                  while i--
                    arr[i] = NaN
                  return arr
                @accessors.push('accessor')
            else
              do (descriptor, count) =>
                accessor = =>
                  return @getFromHeap(descriptor)
                @accessors.push('accessor')
    
    # Swap endian functions
    switch Math.abs(bitpix)
      when 16
        swapEndian = (value) ->
          return (value << 8) | (value >> 8)
      when 32
        swapEndian = (value) ->
          return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
      else
        swapEndian = (value) -> return value
    
    # Get from heap
    getFromHeap = (descriptor) ->
      # Get length and offset of the heap
      length = view.getInt32(offset)
      offset += 4
      heapOffset = view.getInt32(offset)
      offset += 4
      
      chunkOffset = tableLength + heapOffset
      
      # Read from the buffer
      chunk = view.buffer.slice(chunkOffset, chunkOffset + length)
      arr = new typedArray[descriptor](chunk)
      
      # Swap endian
      i = arr.length
      while i--
        arr[i] = swapEndian(arr[i])
      
      return arr
    
    postMessage(offset)
  
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
  
  # Gather information to pass to worker
  data =
    buffer: @view.buffer.slice(@begin, @begin + @length)
    cols: @header.get("TFIELDS")
    tableLength: @tableLength
  
  for i in [1..data.cols]
    data["TFORM#{i}"] = @header.get("TFORM#{i}")
    data["TTYPE#{i}"] = @header.get("TTYPE#{i}")
  
  console.log data
  # Pass object to worker
  worker.postMessage(data)
