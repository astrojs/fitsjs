window.FITS = astro.FITS

describe "FITS CompressedImage", ->

  it 'can read a FITS compressed image', ->
    precision = 6
    
    ready = false
    
    image = null
    pixels = null
    path = 'data/CFHTLS_03_g_sci.fits.fz'
    fits = new astro.FITS(path, (fits) ->
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        pixels = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      image.getExtent(pixels)
      
      # expect(image.min).toBeCloseTo(-2.935214, precision)
      # expect(image.max).toBeCloseTo(1273.849121, precision)
      
      expect(image.getPixel(pixels, 0, 0)).toBeCloseTo(0.249601, precision)
      expect(image.getPixel(pixels, 400, 0)).toBeCloseTo(0.428947, precision)
      expect(image.getPixel(pixels, 400, 400)).toBeCloseTo(0.358678, precision)
      expect(image.getPixel(pixels, 0, 400)).toBeCloseTo(1.2917231, precision)
      
      # ... and a few other random pixels
      expect(image.getPixel(pixels, 33, 205)).toBeCloseTo(0.939594, precision)
      expect(image.getPixel(pixels, 44, 149)).toBeCloseTo(-0.728912, precision)
      expect(image.getPixel(pixels, 237, 377)).toBeCloseTo(-0.614697, precision)
      expect(image.getPixel(pixels, 393, 27)).toBeCloseTo(0.506017, precision)

  it 'can ready a (troublesome) FITS compressed image', ->
    precision = 6
    
    ready = false
    
    image = null
    pixels = null
    path = 'data/CFHTLS_082_0012_g.fits.fz'
    fits = new astro.FITS(path, (fits) ->
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        pixels = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      image.getExtent(pixels)
      
      
      expect(image.getPixel(pixels, 0, 0)).toBeCloseTo(0.120612, precision)
      expect(image.getPixel(pixels, 400, 0)).toBeCloseTo(0.554542, precision)
      expect(image.getPixel(pixels, 400, 400)).toBeCloseTo(0.392959, precision)
      expect(image.getPixel(pixels, 0, 400)).toBeCloseTo(0.0930691, precision)
      
      # ... and a few other random pixels
      expect(image.getPixel(pixels, 33, 205)).toBeCloseTo(0.112262, precision)
      expect(image.getPixel(pixels, 44, 149)).toBeCloseTo(-0.151564, precision)
      expect(image.getPixel(pixels, 237, 377)).toBeCloseTo(-0.185169, precision)
      expect(image.getPixel(pixels, 393, 27)).toBeCloseTo(-0.0669346, precision)

#   it 'can read a frame by spawning a web worker', ->
#     precision = 6
#     fits = arr = null
#     ready = false
#     
#     path = 'data/CFHTLS_03_g_sci.fits.fz'
#     fits = new FITS.File(path, (f) ->
#       dataunit = f.getDataUnit()
#       
#       dataunit.getFrameAsync(0, (array) ->
#         ready = true
#         arr = array
#       )
#     )
#     waitsFor -> return ready
# 
#     runs ->
#       image = fits.getDataUnit()
#       image.getExtent(arr)
#       
#       expect(image.min).toBeCloseTo(-2.981497, precision)
#       expect(image.max).toBeCloseTo(1273.853638, precision)
#       
#       expect(image.getPixel(arr, 0, 0)).toBeCloseTo(0.173962, precision)
#       expect(image.getPixel(arr, 400, 0)).toBeCloseTo(0.347923, precision)
#       expect(image.getPixel(arr, 400, 400)).toBeCloseTo(0.344889, precision)
#       expect(image.getPixel(arr, 0, 400)).toBeCloseTo(1.20711267, precision)
#       
#       # ... and a few other random pixels
#       expect(image.getPixel(arr, 33, 205)).toBeCloseTo(0.975486, precision)
#       expect(image.getPixel(arr, 44, 149)).toBeCloseTo(-0.774174, precision)
#       expect(image.getPixel(arr, 237, 377)).toBeCloseTo(-0.668716, precision)
#       expect(image.getPixel(arr, 393, 27)).toBeCloseTo(0.490127, precision)
