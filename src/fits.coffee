require('jDataView/src/jdataview')
Module      = require('module')
Decompress  = require('fits.decompress')
Header      = require('fits.header')
Data        = require('fits.data')
Image       = require('fits.image')
BinTable    = require('fits.bintable')
Table       = require('fits.table')

class HDU

  constructor: (header, data)->
    @header = header
    @data   = data

class File
  @LINEWIDTH   = 80
  @BLOCKLENGTH = 2880
  @BITPIX = [8, 16, 32, 64, -32, -64]

  constructor: (buffer) ->
    @length     = buffer.byteLength
    @view       = new jDataView buffer, undefined, undefined, false
    @hdus       = []
    @eof        = false

    loop
      header = @readHeader()
      data = @readData(header)
      hdu = new HDU(header, data)
      @hdus.push(hdu)
      break if @eof

  # ##Class Methods

  # Determine the number of characters following a header or data unit
  @excessBytes: (length) -> return File.BLOCKLENGTH - (length) % File.BLOCKLENGTH

  # ##Instance Methods

  # Read a header unit
  readHeader: ->
    linesRead = 0
    header = new Header()
    loop
      line = @view.getString(File.LINEWIDTH)
      linesRead += 1
      header.readCard(line)
      break if line[0..3] is "END "

    # Seek to the next relavant block in file
    excess = File.excessBytes(linesRead * File.LINEWIDTH)
    @view.seek(@view.tell() + excess)
    @checkEOF()

    return header

  # Read a data unit
  readData: (header) ->
    
    return unless header.hasDataUnit()
    if header.isPrimary()
      data = new Image(@view, header)
    else if header.isExtension()
      if header.extensionType is "BINTABLE"
        data = new BinTable(@view, header)
      else if header.extensionType is "TABLE"
        data = new Table(@view, header)
    excess = File.excessBytes(data.length)

    # Forward to the next HDU
    @view.seek(@view.tell() + data.length + excess)
    @checkEOF()
    return data

  checkEOF: -> @eof = true if @view.tell() is @length

FITS = @FITS    = {}
module?.exports = FITS

FITS.version    = '0.0.1'
FITS.File       = File