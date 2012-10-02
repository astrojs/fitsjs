require = window.require

FITS = require("fits")

describe "FITS Binary Table", ->

  it 'can read a bit array', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bit.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      dataunit = fits.getDataUnit()
      row = dataunit.getRow()
      
      bitarray = row[1]
      expect(bitarray[0]).toEqual(1);
      expect(bitarray[31]).toEqual(0);

      row = dataunit.getRow()
      bitarray = row[1]
      expect(bitarray[1]).toEqual(1);
      expect(bitarray[31]).toEqual(0);