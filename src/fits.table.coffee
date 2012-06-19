require('jDataView/src/jdataview')

FITS    = @FITS or require('fits')
Tabular = require('fits.tabular')

# Class to read ASCII tables from FITS files.
class FITS.Table extends Tabular
  @formPattern = /([AIFED])(\d+)\.(\d+)/
  
  @dataAccessors =
    A: (value) -> return value
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
        accessor = =>
          value = ""
          value += @view.getChar() for i in [1..length]
          return FITS.Table.dataAccessors[dataType](value)
        @accessors.push(accessor)


module?.exports = FITS.Table