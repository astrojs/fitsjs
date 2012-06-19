require('jDataView/src/jdataview')

FITS = @FITS or require('fits')
Data  = require('fits.data')

# Class to read ASCII tables from FITS files.
# TODO: Make this work ...
class FITS.Table extends Data
  @formPattern = /([AIFED])(\d+)\.(\d+)/
  
  @dataAccessors =
    A: (value) -> return value
    I: (value) -> return parseInt(value)
    F: (value) -> return parseFloat(value)
    E: (value) -> return parseFloat(value)
    D: (value) -> return parseFloat(value)
  
  constructor: (view, header) ->
    super
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @cols         = header["TFIELDS"]
    @length       = @rowByteSize * @rows
    @rowsRead     = 0
    
    @accessors = []
    for i in [1..header["TFIELDS"]]
      form = header["TFORM#{i}"]
      match = form.match(Table.formPattern)
      do =>
        [dataType, length, decimals] = match[1..]
        accessor = =>
          value = ""
          value += @view.getChar() for i in [1..length]
          return FITS.Table.dataAccessors[dataType](value)
        @accessors.push(accessor)

  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    row.push accessor() for accessor in @accessors
    @rowsRead += 1
    return row

module?.exports = FITS.Table