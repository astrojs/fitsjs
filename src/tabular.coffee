
# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends DataUnit
  typedArray:
    B: Uint8Array
    I: Uint16Array
    J: Int32Array
    E: Float32Array
    D: Float64Array
    1: Uint8Array
    2: Uint16Array
    4: Int32Array
  
  # NOTE: Accessor functions for bit array is better implemented in binary table class
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
  
  
  constructor: (header, view, offset) ->
    super
    
    @rowByteSize  = header.get("NAXIS1")
    @rows         = header.get("NAXIS2")
    @cols         = header.get("TFIELDS")
    @length       = @rowByteSize * @rows
    @rowsRead     = 0
    
    @columns      = @getColumnNames(header)
    @accessors    = []
    @header       = header  # Hopefully this reference is temporary
    
  getRow: (row = null) ->
    @rowsRead = row if row?
    @offset = @begin + @rowsRead * @rowByteSize
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
      columnNames.push header.get(key)
    return columnNames


@astro.FITS.Tabular = Tabular