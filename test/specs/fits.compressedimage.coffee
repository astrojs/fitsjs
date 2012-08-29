require = window.require

FITS = require("fits")

describe "FITS CompImage", ->

  it 'can read a FITS compressed image', ->
    precision = 6
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/CFHTLS_03_g_sci.fits.fz')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      
      image = fits.getDataUnit()
      image.getFrame()
    
      # Check the values of the corner pixels ...
      image.getExtremes()
      
      expect(image.min).toBeCloseTo(-2.981497, precision)
      expect(image.max).toBeCloseTo(1273.853638, precision)
      
      expect(image.getPixel(0, 1)).toBeCloseTo(0.173962, precision)
      expect(image.getPixel(400, 1)).toBeCloseTo(0.347923, precision)
      expect(image.getPixel(400, 400)).toBeCloseTo(0.365571, precision)
      expect(image.getPixel(0, 400)).toBeCloseTo(-0.913929, precision)
      
      # ... and a few other random pixels
      # expect(data.getPixel(405, 600)).toEqual(9128)
      # expect(data.getPixel(350, 782)).toEqual(4351)
      # expect(data.getPixel(108, 345)).toEqual(4380)
      # expect(data.getPixel(720, 500)).toEqual(5527)