
# Class to read ASCII tables from FITS files.
class Table extends Tabular
  dataAccessors:
    A: (value) -> return value.trim()
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  constructor: (header, view, offset) ->
    super
    @setAccessors(header)
  
  setAccessors: (header) ->
    pattern = /([AIFED])(\d+)\.*(\d+)*/
    
    for i in [1..@cols]
      form  = header.get("TFORM#{i}")
      type  = header.get("TTYPE#{i}")
      match = pattern.exec(form)
      
      descriptor  = match[1]
      
      do (descriptor) =>
        accessor = (value) =>
          return @dataAccessors[descriptor](value)
        @accessors.push(accessor)
  
  getRow: (row = null) =>
    @rowsRead = row if row?
    @offset = @begin + @rowsRead * @rowByteSize
    line = @view.getString(@offset, @rowByteSize).trim().split(/\s+/)
    
    row = {}
    for value, index in line
      row[@columns[index]] = @accessors[index](value)
      
    @offset += @rowByteSize
    @rowsRead += 1
    return row


@astro.FITS.Table = Table