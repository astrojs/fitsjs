require('jDataView/src/jdataview')

FITS        = @FITS or require('fits')
Tabular     = require('fits.tabular')
Decompress  = require('fits.decompress')

class FITS.BinTable extends Tabular
  @dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/
  @arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/
  
  @dataAccessors =
    L: (view) ->
      value = if view.getInt8() is 84 then true else false
      return value
    X: (view) ->
      throw "Data type not yet implemented"
    B: (view) ->
      return view.getUint8()
    I: (view) ->
      return view.getInt16()
    J: (view) ->
      return view.getInt32()
    K: (view) ->
      highByte = Math.abs view.getInt32()
      lowByte = Math.abs view.getInt32()
      mod = highByte % 10
      factor = if mod then -1 else 1
      highByte -= mod
      value = factor * ((highByte << 32) | lowByte)
      console.warn "Something funky happens here when dealing with 64 bit integers.  Be wary!!!"
      return value
    A: (view) ->
      return view.getChar()
    E: (view) ->
      return view.getFloat32()
    D: (view) ->
      return view.getFloat64()
    C: (view) ->
      return [view.getFloat32(), view.getFloat32()]
    M: (view) ->
      return [view.getFloat64(), view.getFloat64()]
      
  constructor: (view, header) ->
    super

    for i in [1..@cols]
      keyword = "TFORM#{i}"
      value = header[keyword]
      match = value.match(FITS.BinTable.arrayDescriptorPattern)
      if match?
        do =>
          dataType = match[1]
          accessor = =>
            # TODO: Find out how to pass dataType
            length  = @view.getInt32()
            offset  = @view.getInt32()
            @current = @view.tell()
            # Troublesome
            # TODO: Find a way to preserve the dataType in this function for each column
            @view.seek(@begin + @tableLength + offset)
            data = []
            for i in [1..length]
              data.push FITS.BinTable.dataAccessors[dataType](@view)
            @view.seek(@current)
            return data
          @accessors.push(accessor)
      else
        match = value.match(FITS.BinTable.dataTypePattern)
        [r, dataType] = match[1..]
        r = if r then parseInt(r) else 0
        if r is 0
          do =>
            dataType = match[2]
            accessor = (dt) =>
              data = FITS.BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)
        else
          do =>
            dataType = match[2]
            accessor = =>
              data = []
              for i in [1..r]
                data.push FITS.BinTable.dataAccessors[dataType](@view)
              return data
            @accessors.push(accessor)

module?.exports = FITS.BinTable