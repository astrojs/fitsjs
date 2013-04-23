
# Class to read ASCII tables from FITS files.
class Table extends Tabular
  
  # Define functions for parsing ASCII entries
  dataAccessors:
    A: (value) -> return value.trim()
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  
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
  
  _getRows: (buffer) ->
    
    # Get the number of rows in buffer
    nRows = buffer.byteLength / @rowByteSize
    
    # Interpret the buffer
    arr = new Uint8Array(buffer)
    
    # Storage for rows
    rows = []
    
    # Loop over the number of rows
    for i in [0..nRows - 1]
      
      # Get the subarray for current row
      begin = i * @rowByteSize
      end = begin + @rowByteSize
      subarray = arr.subarray(begin, end)
      
      # Convert to string representation
      line = ''
      for value in subarray
        line += String.fromCharCode(value)
      line = line.trim().split(/\s+/)
      
      # Storage for current row
      row = {}
      
      # Convert to correct data type using accessor functions
      for accessor, index in @accessors
        value = line[index]
        row[ @columns[index] ] = accessor(value)
      
      # Store row on array
      rows.push row
      
    return rows


@astro.FITS.Table = Table