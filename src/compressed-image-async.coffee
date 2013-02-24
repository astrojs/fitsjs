
# An extension to the CompressedImage class adding getFrameAsync
CompressedImage = @astro.FITS.CompressedImage

CompressedImage::getFrameAsync = (@frame = @frame, callback) ->
  
  # Define the function to be executed on the worker thread
  onmessage = (e) ->
    # Cache variables
    data          = e.data
    tableLength   = data.tableLength
    tableColumns  = data.tableColumns
    columnNames   = data.columnNames
    params        = data.params
    ztile         = data.ztile
    rowByteSize   = data.rowByteSize
    zblank        = data.zblank
    bscale        = data.bscale
    bzero         = data.bzero
    width         = data.width
    height        = data.height
    blank         = data.blank
    bitpix        = data.bitpix
    buffer        = data.buffer
    
    dataAccessors =
      L: (view, offset) ->
        x = view.getInt8(offset)
        offset += 1
        val = if x is 84 then true else false
        return [val, offset]
      B: (view, offset) ->
        val = view.getUint8(offset)
        offset += 1
        return [val, offset]
      I: (view, offset) ->
        val = view.getInt16(offset)
        offset += 2
        return [val, offset]
      J: (view, offset) ->
        val = view.getInt32(offset)
        offset += 4
        return [val, offset]
      K: (view, offset) ->
        highByte = Math.abs view.getInt32(offset)
        offset += 4
        lowByte = Math.abs view.getInt32(offset)
        offset += 4
        mod = highByte % 10
        factor = if mod then -1 else 1
        highByte -= mod
        console.warn "Precision for 64 bit integers may be incorrect."
        val = factor * ((highByte << 32) | lowByte)
        return [val, offset]
      A: (view, offset) ->
            val = view.getChar(offset)
            offset += 1
            return [val, offset]
      E: (view, offset) ->
        val = view.getFloat32(offset)
        offset += 4
        return [val, offset]
      D: (view, offset) ->
        val = view.getFloat64(offset)
        offset += 8
        return [val, offset]
      C: (view, offset) ->
        val1 = view.getFloat32(offset)
        offset += 4
        val2 = view.getFloat32(offset)
        offset += 4
        val = [val1, val2]
        return [val, offset]
      M: (view, offset) ->
        val1 = view.getFloat64(offset)
        offset += 8
        val2 = view.getFloat64(offset)
        offset += 8
        val = [val1, val2]
        return [val, offset]
    
    RiceSetup =
      # Set up for bytepix = 1
      1: (array) ->
        pointer = 0
        fsbits = 3
        fsmax = 6

        lastpix = array[pointer]
        pointer += 1

        return [fsbits, fsmax, lastpix, pointer]

      # Set up for bytepix = 2
      2: (array) ->
        pointer = 0
        fsbits = 4
        fsmax = 14

        lastpix = 0
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | (bytevalue << 8)
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | bytevalue

        return [fsbits, fsmax, lastpix, pointer]

      # Set up for bytepix = 4
      4: (array) ->
        pointer = 0
        fsbits = 5
        fsmax = 25

        lastpix = 0
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | (bytevalue << 24)
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | (bytevalue << 16)
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | (bytevalue << 8)
        bytevalue = array[pointer]
        pointer += 1
        lastpix = lastpix | bytevalue

        return [fsbits, fsmax, lastpix, pointer]
    
    
    Rice = (array, blocksize, bytepix, pixels, nx) ->

      bbits = 1 << fsbits

      [fsbits, fsmax, lastpix, pointer] = RiceSetup[bytepix](array)

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
      b = array[pointer]
      pointer += 1

      # Number of bits remaining in b
      nbits = 8

      i = 0
      while i < nx

        nbits -= fsbits
        while nbits < 0
          b = (b << 8) | (array[pointer])
          pointer += 1
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
              b = array[pointer]
              pointer += 1
              diff |= b << k
              k -= 8
            if nbits > 0
              b = array[pointer]
              pointer += 1
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
              b = array[pointer]
              pointer += 1
            nzero = nbits - nonzeroCount[b]
            nbits -= nzero + 1
            b ^= 1 << nbits
            nbits -= fs
            while nbits < 0
              b = (b << 8) | (array[pointer])
              pointer += 1
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
    
    
    # Define object of typed array constructors
    typedArray =
      B: Uint8Array
      I: Uint16Array
      J: Int32Array
      E: Float32Array
      D: Float64Array
      1: Uint8Array
      2: Uint16Array
      4: Int32Array
    
    # Set variables
    offset = 0
    rowsRead = 0
    accessors = []
    
    # Initialize a DataView object
    view = new DataView(buffer)
    
    #
    # Define various functions
    # NOTE: These function cannot use any instance variables.
    #
    
    # Define swap endian functions
    switch Math.abs(bitpix)
      when 16
        swapEndian = (value) ->
          return (value << 8) | (value >> 8)
      when 32
        swapEndian = (value) ->
          return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
      else
        swapEndian = (value) -> return value
    
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
    
    setAccessors = ->
      pattern = /(\d*)([P|Q]*)([L|X|B|I|J|K|A|E|D|C|M]{1})/
      for column, i in tableColumns
        form = Object.keys(column)[0]
        type = column[form]
        match = pattern.exec(form)
        
        count       = parseInt(match[1]) or 1
        isArray     = match[2]
        descriptor  = match[3]
        
        if isArray  # Rarely will this be false for compressed images
          # Handle array descriptors
          switch type
            when "COMPRESSED_DATA"
              do (descriptor, count) =>
                accessor = =>
                  arr = getFromHeap(descriptor)
                  
                  # Assuming Rice compression
                  pixels = new typedArray[params["BYTEPIX"]](ztile[0])
                  
                  # Bring in Rice using technique at
                  # http://stackoverflow.com/questions/11909934/how-to-pass-functions-to-javascript-web-worker
                  Rice(arr, params["BLOCKSIZE"], params["BYTEPIX"], pixels, ztile[0])
                  
                  return pixels
                accessors.push(accessor)
            when "GZIP_COMPRESSED_DATA"
              # TODO: Implement GZIP
              do (descriptor, count) =>
                accessor = =>
                  # arr = @getFromHeap(descriptor)
                  
                  # Temporarily padding with NaNs until GZIP is implemented
                  arr = new Float32Array(width)
                  i = arr.length
                  while i--
                    arr[i] = NaN
                  return arr
                accessors.push('accessor')
            else
              do (descriptor, count) =>
                accessor = =>
                  return getFromHeap(descriptor)
                accessors.push('accessor')
        else
          if count is 1
            # Handle single element
            do (descriptor, count) =>
              accessor = =>
                [value, offset] = dataAccessors[descriptor](view, offset)
                return value
              accessors.push(accessor)
          else
            # Handle bit arrays
            if descriptor is 'X'
              do (descriptor, count) =>
                nBytes = Math.log(count) / Math.log(2)
                accessor = =>
                  # Read from the buffer
                  chunk = view.buffer.slice(offset, offset + nBytes)
                  bytes = new Uint8Array(chunk)
                  
                  # Get bit representation
                  bits = []
                  for byte in bytes
                    arr = @toBits(byte)
                    bits = bits.concat(arr)
                    
                  # Increment the offset
                  offset += nBytes
                  
                  return bits[0..count - 1]
                accessors.push(accessor)
                
            # Handle character arrays
            else if descriptor is 'A'
              do (descriptor, count) =>
                accessor = =>
                  str = view.getString(offset, count)
                  @offset += count
                  return str.trim()
                accessors.push(accessor)
                
            # Handle all other data types
            else
              do (descriptor, count) =>
                accessor = =>
                  # TypedArray = @typedArray[descriptor]
                  # 
                  # # Read from the buffer
                  # length = count * TypedArray.BYTES_PER_ELEMENT
                  # chunk = view.buffer.slice(@offset, @offset + length)
                  # @offset += length
                  # 
                  # return new TypedArray(chunk)
                  
                  data = []
                  while count--
                    [value, offset] = dataAccessors[descriptor](view, offset)
                    data.push(value)
                  return data
                accessors.push(accessor)
                
    getTableRow = ->
      offset = rowsRead * rowByteSize
      row = []
      for accessor in accessors
        row.push accessor()
        
      data  = row[columnNames["COMPRESSED_DATA"]] or row[columnNames["UNCOMPRESSED_DATA"]] or row[columnNames["GZIP_COMPRESSED_DATA"]]
      blank = row[columnNames["ZBLANK"]] or zblank
      scale = row[columnNames["ZSCALE"]] or bscale
      zero  = row[columnNames["ZZERO"]] or bzero
      return [data, blank, scale, zero]
   
    # TODO: Test this function.  Need example file with blanks.
    getRowHasBlanks = (arr) ->
      [data, blank, scale, zero] = getTableRow()
      
      offset = rowsRead * width
      for value, index in data
        i = offset + index
        arr[i] = if value is blank then NaN else (zero + scale * value)
      rowsRead += 1
      
    getRowNoBlanks = (arr) ->
      [data, blank, scale, zero] = getTableRow()
      
      offset = rowsRead * width
      for value, index in data
        i = offset + index
        arr[i] = zero + scale * value
      rowsRead += 1
    
    defGetRow = ->
      hasBlanks = zblank? or blank? or columnNames.hasOwnProperty("ZBLANK")
      return if hasBlanks then getRowHasBlanks else getRowNoBlanks
    
    getFrame = ->
      arr = new Float32Array(width * height)
      
      rowsRead = 0
      while height--
        getRow(arr)
        
      return arr
    
    setAccessors(tableColumns, view)
    getRow = defGetRow()
    
    arr = getFrame()
    data =
      offset: offset
      arr: arr
    postMessage(data)
  
  # Trick to format function for worker
  fn = onmessage.toString().split('').reverse().join('').replace(' nruter', '')
  fn = fn.split('').reverse().join('')
  fn = "onmessage = #{fn}"
  
  # Prefix for Safari
  URL = URL or webkitURL
  
  # Construct blob for Rice algorithm
  algoBlob = new Blob([astro.FITS.Decompress], {type: "application/javascript"})
  algoBlobUrl = URL.createObjectURL(algoBlob)
  
  # Construct blob for an inline worker
  blob = new Blob([fn], {type: "application/javascript"})
  blobUrl = URL.createObjectURL(blob)
  
  # Initialize worker
  worker = new Worker(blobUrl)
  
  # Define function for when worker job is complete
  worker.onmessage = (e) ->
    arr = e.data.arr
    
    # Execute callback
    callback.call(@, arr) if callback?
    
    # Clean up blob urls and worker
    URL.revokeObjectURL(blobUrl)
    URL.revokeObjectURL(algoBlobUrl)
    worker.terminate()
  
  # Information to pass to worker
  data =
    decompression: algoBlobUrl
    buffer: @view.buffer.slice(@begin, @begin + @length)
    tableLength: @tableLength
    tableColumns: @tableColumns
    columnNames: @columnNames
    params: @params
    ztile: @ztile
    rowByteSize: @rowByteSize
    zblank: @zblank
    bscale: @bscale
    bzero: @bzero
    width: @width
    height: @height
    blank: @blank
  
  # Pass object to worker
  worker.postMessage(data)
