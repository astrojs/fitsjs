
# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends DataUnit

  constructor: (header, view, offset) ->
    super
    
    # TODO: Abstract some of these variables
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @cols         = header["TFIELDS"]
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead     = 0
    
    @columns      = @getColumnNames(header)
    @accessors    = []

  getRow: (row = null) =>
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
      columnNames.push header[key]
    return columnNames


@astro.FITS.Tabular = Tabular