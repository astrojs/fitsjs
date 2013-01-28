
class BinaryTable extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  
  
  constructor: (header, view, offset) ->
    super

    for i in [1..@cols]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(@constructor.arrayDescriptorPattern)
      if match?
        do =>
          dataType = match[1]
          accessor = =>
            length    = @view.getInt32(@offset)
            @offset   += 4
            offset    = @view.getInt32(@offset)
            @offset   += 4
            tempOffset = @offset
            @offset = @begin + @tableLength + offset
            data = []
            for i in [1..length]
              [val, @offset] = @dataAccessors[dataType](@view, @offset)
              data.push val
            @offset = tempOffset
            return data
          
          @accessors.push(accessor)
      else
        match = value.match(@constructor.dataTypePattern)
        [length, dataType] = match[1..]
        length = if length then parseInt(length) else 0
        if length in [0, 1]
          do (dataType) =>
            accessor = =>
              [val, @offset] = @dataAccessors[dataType](@view, @offset)
              return val
            @accessors.push(accessor)
        else
          do (dataType, length) =>
            # Handling bit arrays
            if dataType is 'X'
              numBytes = Math.log(length) / Math.log(2)
              accessor = =>
                byte2bits = (byte) ->
                  bitarray = []
                  i = 128
                  while i >= 1
                    bitarray.push (if byte & i then 1 else 0)
                    i /= 2
                  return bitarray
                
                data = []
                for i in [1..numBytes]
                  byte = @view.getUint8(@offset)
                  @offset += 1
                  bitarray = byte2bits(byte)
                  for bit in bitarray
                    data.push bit
                return data[0..length - 1]
            
            # Handle character arrays
            else if dataType is 'A'
              accessor = =>
                data = ''
                for i in [1..length]
                  [val, @offset] = @dataAccessors[dataType](@view, @offset)
                  data += val
                return data.trim()
            else
              accessor = =>
                data = []
                for i in [1..length]
                  [val, @offset] = @dataAccessors[dataType](@view, @offset)
                  data.push val
                return data
            @accessors.push(accessor)


@astro.FITS.BinaryTable = BinaryTable