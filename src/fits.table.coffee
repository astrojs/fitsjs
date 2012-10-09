Tabular = require('./fits.tabular')

# Class to read ASCII tables from FITS files.
class Table extends Tabular
  @formPattern = /([AIFED])(\d+)\.*(\d+)*/
  
  @dataAccessors =
    A: (value) -> return value.trim()
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  constructor: (view, header) ->
    super
    for i in [1..@cols]
      form = header["TFORM#{i}"]
      match = form.match(Table.formPattern)
      do =>
        [dataType, length, decimals] = match[1..]
        accessor = (value) =>
          return Table.dataAccessors[dataType](value)
        @accessors.push(accessor)

  getRow: =>
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = ""
    row += @view.getChar() for i in [1..@rowByteSize]
    row = row.trim().split(/\s+/)
    
    for value, index in row
      row[index] = @accessors[index](value)
    @rowsRead += 1
    return row

module?.exports = Table