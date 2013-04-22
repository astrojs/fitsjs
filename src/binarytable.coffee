
class BinaryTable extends Tabular
  
  # Look up table for matching appropriate typed array
  typedArray:
    B: Uint8Array
    I: Uint16Array
    J: Int32Array
    E: Float32Array
    D: Float64Array
    1: Uint8Array
    2: Uint16Array
    4: Int32Array
  
  # Define functions for parsing binary tables.
  # NOTE: Accessor function for bit array is better implemented in another function below
  dataAccessors:
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
      val = factor * ((highByte << 32) | lowByte)
      return [val, offset]
    A: (view, offset) ->
      val = view.getUint8(offset)
      val = String.fromCharCode(val)
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
  
  
  constructor: (header, data) ->
    super
    
    # Create reference to length, and add the heap to the total byte length
    @tableLength = @length
    @length += header.get("PCOUNT")
    
    @setAccessors(header)
  
  toBits: (byte) ->
    arr = []
    i = 128
    while i >= 1
      arr.push (if byte & i then 1 else 0)
      i /= 2
    return arr
  
  # Get bytes from the heap that follows the main data structure.  Often used
  # for binary tables and compressed images.
  getFromHeap: (descriptor) ->
    
    # Get length and offset of the heap
    length  = @view.getInt32(@offset)
    @offset += 4
    offset  = @view.getInt32(@offset)
    @offset += 4
    
    heapOffset = @begin + @tableLength + offset
    
    # Read from the buffer
    chunk = @view.buffer.slice(heapOffset, heapOffset + length)
    arr = new @typedArray[descriptor](chunk)
    
    # Swap endian
    i = arr.length
    while i--
      arr[i] = @constructor.swapEndian[descriptor](arr[i])
    
    return arr
  
  setAccessors: (header) ->
    pattern = /(\d*)([P|Q]*)([L|X|B|I|J|K|A|E|D|C|M]{1})/
    
    for i in [1..@cols]
      form  = header.get("TFORM#{i}")
      type  = header.get("TTYPE#{i}")
      match = pattern.exec(form)
      
      count       = parseInt(match[1]) or 1
      isArray     = match[2]
      descriptor  = match[3]
      
      if isArray
        
        # Handle array descriptors
        
        switch type
          
          when "COMPRESSED_DATA"
            do (descriptor, count) =>
              accessor = =>
                arr = @getFromHeap(descriptor)
                
                # Assuming Rice compression
                pixels = new @typedArray[@params["BYTEPIX"]](@ztile[0])
                Decompress.Rice(arr, @params["BLOCKSIZE"], @params["BYTEPIX"], pixels, @ztile[0], Decompress.RiceSetup)
                
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
              @accessors.push(accessor)
          
          else
            do (descriptor, count) =>
              accessor = =>
                return @getFromHeap(descriptor)
              @accessors.push(accessor)
      
      else
        if count is 1
          # Handle single element
          do (descriptor, count) =>
            accessor = (view, offset) =>
              [value, offset] = @dataAccessors[descriptor](view, offset)
              return [value, offset]
            @accessors.push(accessor)
        else
          
          # Handle bit arrays
          if descriptor is 'X'
            do (descriptor, count) =>
              nBytes = Math.log(count) / Math.log(2)
              accessor = (view, offset) =>
                
                # Read from buffer
                buffer = view.buffer.slice(offset, offset + nBytes)
                bytes = new Uint8Array(buffer)
                
                # Get bit representation
                bits = []
                for byte in bytes
                  arr = @toBits(byte)
                  bits = bits.concat(arr)
                
                # Increment the offset
                offset += nBytes
                
                return [bits[0..count - 1], offset]
              @accessors.push(accessor)
        
          # Handle character arrays
          else if descriptor is 'A'
            do (descriptor, count) =>
              accessor = (view, offset) =>
                
                # Read from buffer
                buffer = view.buffer.slice(offset, offset + count)
                arr = new Uint8Array(buffer)
                
                s = ''
                for value in arr
                  s += String.fromCharCode(value)
                s = s.trim()
                
                # Increment offset
                offset += count
                
                return [s, offset]
                
              @accessors.push(accessor)
        
          # Handle all other data types
          else
            do (descriptor, count) =>
              accessor = (view, offset) =>
                i = count
                data = []
                while i--
                  [value, offset] = @dataAccessors[descriptor](view, offset)
                  data.push(value)
                return [data, offset]
              @accessors.push(accessor)

  _getRows: (buffer) ->
    
    # Get the number of rows in buffer
    nRows = buffer.byteLength / @rowByteSize
    
    # Set up view and offset
    view = new DataView(buffer)
    offset = 0
    
    # Storage for rows
    rows = []
    
    # Read each row
    while nRows--
      
      # Storage for current row
      row = {}
      
      for accessor, index in @accessors
        
        # Read value from each column in current row
        [value, offset] = accessor(view, offset)
        row[ @columns[index] ] = value
      # Store row on array
      rows.push row
    
    return rows
    
    
@astro.FITS.BinaryTable = BinaryTable