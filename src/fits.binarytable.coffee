Tabular = require('fits.tabular')

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
            accessor = =>
              data = []
              for i in [1..length]
                data.push BinaryTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)

module?.exports = BinaryTable