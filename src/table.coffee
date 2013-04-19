
# Class to read ASCII tables from FITS files.
class Table extends Tabular
  
  # Define functions for parsing ASCII entries
  dataAccessors:
    A: (value) -> return value.trim()
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  constructor: (header, data) ->
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
    
    # Check if row is specified, otherwise, default to sequential reading.
    @rowsRead = row if row?
    
    # Get the byte offset based on the number of rows read.
    offset = @rowsRead * @rowByteSize
    
    line = @view.getUint8()
    line = @view.getString(@offset, @rowByteSize).trim().split(/\s+/)
    
    row = {}
    for value, index in line
      row[@columns[index]] = @accessors[index](value)
      
    @offset += @rowByteSize
    @rowsRead += 1
    return row


@astro.FITS.Table = Table