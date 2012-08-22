require = window.require

FITS = require("fits")

describe "FITS CompImage", ->

  it 'can read a FITS compressed image', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/CFHTLS_03_g_sci.fits.fz')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      data = fits.getDataUnit()
      data.getFrame()
    
      # Check the values of the corner pixels ...
      expect(data.getPixel(0, 0)).toEqual(3852)
      expect(data.getPixel(890, 0)).toEqual(4223)
      expect(data.getPixel(890, 892)).toEqual(4015)
      expect(data.getPixel(0, 892)).toEqual(3898)
    
      # ... and a few other random pixels
      expect(data.getPixel(405, 600)).toEqual(9128)
      expect(data.getPixel(350, 782)).toEqual(4351)
      expect(data.getPixel(108, 345)).toEqual(4380)
      expect(data.getPixel(720, 500)).toEqual(5527)