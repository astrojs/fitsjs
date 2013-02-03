
class BinaryTable extends Tabular
  
  
  constructor: (header, view, offset) ->
    super
    @setAccessors(header)
  
  toBits: (byte) ->
    arr = []
    i = 128
    while i >= 1
      arr.push (if byte & i then 1 else 0)
      i /= 2
    return arr
  
  setAccessors: (header) ->
    for i in [1..@cols]
      key = "TFORM#{i}"
      value = header.get(key)
      
      # Last character specifies the data type
      descriptor = value.slice(-1)
      
      # first character specifies the count
      count = if value[0] is descriptor then 1 else parseInt(value.slice(0, -1))
      
      if descriptor in ['P', 'Q']
        # Handle array descriptors
        do (descriptor, count) =>
          # TODO: Test this function, need FITS file with array descriptor
          accessor = =>
            # Get length and offset of the heap
            length  = @view.getInt32(@offset)
            @offset += 4
            offset  = @view.getInt32(@offset)
            @offset += 4
            
            heapOffset = @begin + @tableLength + offset
            
            # Read from the buffer
            chunk = @view.buffer.slice(heapOffset, heapOffset + length)
            return new @typedArray(chunk)
          @accessors.push(accessor)
      else
        if count is 1
          # Handle single element
          do (descriptor, count) =>
            accessor = =>
              [value, @offset] = @dataAccessors[descriptor](@view, @offset)
              return value
            @accessors.push(accessor)
        else
          # Handle bit arrays
          if descriptor is 'X'
            do (descriptor, count) =>
              nBytes = Math.log(count) / Math.log(2)
              accessor = =>
                # Read from the buffer
                chunk = @view.buffer.slice(@offset, @offset + nBytes)
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
                str = @view.getString(@offset, count)
                @offset += count
                return str.trim()
              @accessors.push(accessor)
        
          # Handle all other data types
          else
            do (descriptor, count) =>
              accessor = =>
                data = []
                while count--
                  [value, @offset] = @dataAccessors[descriptor](@view, @offset)
                  data.push(value)
                return data
              @accessors.push(accessor)


@astro.FITS.BinaryTable = BinaryTable