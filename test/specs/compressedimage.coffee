window.FITS = astro.FITS

describe "FITS CompressedImage", ->

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
      arr = image.getFrame()
      image.getExtent()
      
      expect(image.min).toBeCloseTo(-2.981497, precision)
      expect(image.max).toBeCloseTo(1273.853638, precision)
      
      expect(image.getPixel(arr, 0, 0)).toBeCloseTo(0.173962, precision)
      expect(image.getPixel(arr, 400, 0)).toBeCloseTo(0.347923, precision)
      expect(image.getPixel(arr, 400, 400)).toBeCloseTo(0.344889, precision)
      expect(image.getPixel(arr, 0, 400)).toBeCloseTo(1.20711267, precision)
      
      # ... and a few other random pixels
      expect(image.getPixel(arr, 33, 205)).toBeCloseTo(0.975486, precision)
      expect(image.getPixel(arr, 44, 149)).toBeCloseTo(-0.774174, precision)
      expect(image.getPixel(arr, 237, 377)).toBeCloseTo(-0.668716, precision)
      expect(image.getPixel(arr, 393, 27)).toBeCloseTo(0.490127, precision)
      
  # it 'can decompress gziped data', ->
  #   
  #   fits = null
  # 
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', 'data/row.fits.fz')
  #   xhr.responseType = 'arraybuffer'
  #   xhr.onload = -> fits = new FITS.File(xhr.response)
  #   xhr.send()
  #   
  #   waitsFor -> return fits?
  # 
  #   runs ->
  #     dataunit = fits.getDataUnit()
  #     dataunit.getFrame()