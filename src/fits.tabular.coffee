Data  = require('./fits.data')

# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends Data
  @dataAccessors =
    L: (view) ->
      return if view.getInt8() is 84 then true else false
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
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @cols         = header["TFIELDS"]
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead     = 0
    
    @columns      = @getColumnNames(header)
    @accessors    = []

  getRow: (row = null) =>
    @rowsRead = row if row?
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = {}
    for accessor, index in @accessors
      row[@columns[index]] = accessor()
    @rowsRead += 1
    return row

  getColumnNames: (header) ->
    columnNames = []
    for i in [1..@cols]
      key = "TTYPE#{i}"
      return null unless header.contains(key)
      columnNames.push header[key]
    return columnNames

module?.exports = Tabular