Tabular = require('./fits.tabular')

class BinaryTable extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  
  constructor: (view, header) ->
    super

    for i in [1..@cols]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(BinaryTable.arrayDescriptorPattern)
      if match?
        do =>
          dataType = match[1]
          accessor = =>
            length    = @view.getInt32()
            offset    = @view.getInt32()
            @current  = @view.tell()
            @view.seek(@begin + @tableLength + offset)
            data = []
            for i in [1..length]
              data.push BinaryTable.dataAccessors[dataType](@view)
            @view.seek(@current)
            return data
          @accessors.push(accessor)
      else
        match = value.match(BinaryTable.dataTypePattern)
        [length, dataType] = match[1..]
        length = if length then parseInt(length) else 0
        if length in [0, 1]
          do (dataType) =>
            accessor = =>
              data = BinaryTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)
        else
          do (dataType) =>
            # Not interpretting data yet.  Just updating the offset appropriately.
            if dataType is 'X'
              length = Math.log(length) / Math.log(2)
              accessor = =>
                byte2bits = (byte) ->
                  bitarray = []
                  i = 128
                  while i >= 1
                    bitarray.push (if byte & i then 1 else 0)
                    i /= 2
                  return bitarray
                
                data = []
                for i in [0..length]
                  data.push @view.getUint8()
                return data
            else
              accessor = =>
                data = []
                for i in [1..length]
                  data.push BinaryTable.dataAccessors[dataType](@view)
                return data
            @accessors.push(accessor)

module?.exports = BinaryTable