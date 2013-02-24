
class BinaryTable extends Tabular
  
  
  constructor: (header, view, offset) ->
    super
    
    @tableLength = @length
    @columnNames = {}
    tblCols = @getTableColumns(header)
    @setAccessors(tblCols, view)
  
  getTableColumns: (header) ->
    parameters = []
    for i in [1..@cols]
      obj = {}
      form = header.get("TFORM#{i}")
      type = header.get("TTYPE#{i}")
      obj[form] = type
      parameters.push obj
      @columnNames[type] = i - 1
    return parameters
  
  toBits: (byte) ->
    arr = []
    i = 128
    while i >= 1
      arr.push (if byte & i then 1 else 0)
      i /= 2
    return arr
  
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
  
  setAccessors: (tblCols, view) ->
    pattern = /(\d*)([P|Q]*)([L|X|B|I|J|K|A|E|D|C|M]{1})/
    
    for column, i in tblCols
      form = Object.keys(column)[0]
      type = column[form]
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
                astro.FITS.Decompress.Rice(arr, @params["BLOCKSIZE"], @params["BYTEPIX"], pixels, @ztile[0])
                
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
      else
        if count is 1
          # Handle single element
          do (descriptor, count) =>
            accessor = =>
              [value, @offset] = @dataAccessors[descriptor](view, @offset)
              return value
            @accessors.push(accessor)
        else
          # Handle bit arrays
          if descriptor is 'X'
            do (descriptor, count) =>
              nBytes = Math.log(count) / Math.log(2)
              accessor = =>
                # Read from the buffer
                chunk = view.buffer.slice(@offset, @offset + nBytes)
                bytes = new Uint8Array(chunk)
              
                # Get bit representation
                bits = []
                for byte in bytes
                  arr = @toBits(byte)
                  bits = bits.concat(arr)
              
                # Increment the offset
                @offset += nBytes
              
                return bits[0..count - 1]
              @accessors.push(accessor)
        
          # Handle character arrays
          else if descriptor is 'A'
            do (descriptor, count) =>
              accessor = =>
                str = view.getString(@offset, count)
                @offset += count
                return str.trim()
              @accessors.push(accessor)
        
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
                  [value, @offset] = @dataAccessors[descriptor](view, @offset)
                  data.push(value)
                return data
              @accessors.push(accessor)


@astro.FITS.BinaryTable = BinaryTable