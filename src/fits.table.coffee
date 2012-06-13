require('jDataView/src/jdataview')

FITS = @FITS or require('fits')
Data  = require('fits.data')

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
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead = 0
        
    @accessors = []
    for i in [1..header["TFIELDS"]]
      form = header["TFORM#{i}"]
      match = form.match(Table.formPattern)
      do =>
        [dataType, length, decimals] = match[1..]
        accessor = =>
          console.log 'blah'
          value = @view.getString(length)
          return @dataAccessors[dataType](value)
        @accessors.push(accessor)

  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    for i in [0..@accessors.length-1]
      data = @accessors[i]()
      row.push(data)
    @rowsRead += 1
    return row

module?.exports = FITS.Table