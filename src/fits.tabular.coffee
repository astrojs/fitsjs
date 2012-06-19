require('jDataView/src/jdataview')

FITS  = @FITS or require('fits')
Data  = require('fits.data')

# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class FITS.Tabular extends Data
  
  constructor: (view, header) ->
    super
    @rowByteSize  = header["NAXIS1"]
    @rows         = header["NAXIS2"]
    @cols         = header["TFIELDS"]
    @length       = @tableLength = @rowByteSize * @rows
    @rowsRead     = 0
    
    @accessors = []
    
  getRow: ->
    @current = @begin + @rowsRead * @rowByteSize
    @view.seek(@current)
    row = []
    row.push accessor() for accessor in @accessors
    @rowsRead += 1
    return row

module?.exports = FITS.Tabular