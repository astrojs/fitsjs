
# Class to read ASCII tables from FITS files.
class Table extends Tabular
  formPattern: /([AIFED])(\d+)\.*(\d+)*/
  dataAccessors:
    A: (value) -> return value.trim()
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  constructor: (header, view, offset) ->
    super
    
    for i in [1..@cols]
      form = header.get("TFORM#{i}")
      match = form.match(@formPattern)
      do =>
        [dataType, length, decimals] = match[1..]
        accessor = (value) =>
          return @dataAccessors[dataType](value)
        @accessors.push(accessor)

  getRow: (row = null) =>
    @rowsRead = row if row?
    @offset = @begin + @rowsRead * @rowByteSize
    line = ""
    for i in [1..@rowByteSize]
      line += @view.getChar(@offset)
      @offset += 1
    line = line.trim().split(/\s+/)
    
    row = {}
    for value, index in line
      row[@columns[index]] = @accessors[index](value)

    @rowsRead += 1
    return row


@astro.FITS.Table = Table