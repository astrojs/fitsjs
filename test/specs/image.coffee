window.FITS = astro.FITS

describe "FITS Image", ->

  beforeEach ->
    @addMatchers {
      toBeNaN: (expected) -> return isNaN(@actual) == isNaN(expected)
    }
  
  
  it 'can read an 8 bit integer image', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bitpix/m101_uint8.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = ->
      fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      image = fits.getDataUnit()
      arr = image.getFrame()
      
      expect(image.getPixel(arr, 0, 0)).toEqual(3727)
      expect(image.getPixel(arr, 500, 500)).toEqual(13493)
      expect(image.getPixel(arr, 270, 400)).toEqual(7068)
      expect(image.getPixel(arr, 760, 800)).toEqual(4498)
      expect(image.getPixel(arr, 672, 284)).toEqual(6040)


  it 'can read a 16 bit integer image', ->
    fits = null

    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bitpix/m101_uint16.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()

    waitsFor -> return fits?

    runs ->
      image = fits.getDataUnit()
      arr = image.getFrame()
      
      expect(image.getPixel(arr, 0, 0)).toEqual(3852)
      expect(image.getPixel(arr, 500, 500)).toEqual(13492)
      expect(image.getPixel(arr, 270, 400)).toEqual(7067)
      expect(image.getPixel(arr, 760, 800)).toEqual(4426)
      expect(image.getPixel(arr, 672, 284)).toEqual(6007)
      
  it 'can read a 32 bit integer image', ->
    fits = null

    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bitpix/m101_uint32.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()

    waitsFor -> return fits?

    runs ->
      image = fits.getDataUnit()
      arr = image.getFrame()
      
      expect(image.getPixel(arr, 0, 0)).toEqual(3852)
      expect(image.getPixel(arr, 500, 500)).toEqual(13492)
      expect(image.getPixel(arr, 270, 400)).toEqual(7067)
      expect(image.getPixel(arr, 760, 800)).toEqual(4426)
      expect(image.getPixel(arr, 672, 284)).toEqual(6007)

  it 'can read a 32 bit float image', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bitpix/m101_float32.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      image = fits.getDataUnit()
      arr = image.getFrame()
      
      expect(image.getPixel(arr, 0, 0)).toEqual(3852)
      expect(image.getPixel(arr, 500, 500)).toEqual(13492)
      expect(image.getPixel(arr, 270, 400)).toEqual(7067)
      expect(image.getPixel(arr, 760, 800)).toEqual(4426)
      expect(image.getPixel(arr, 672, 284)).toEqual(6007)

  it 'can read a frame by spawning a web worker', ->
    precision = 6
    fits = arr = null
    ready = false
    location = 'data/m101.fits'
    fits = new FITS.File(location, (f) ->
      f.getDataUnit().getFrameAsync(undefined, (array, width, height) ->
        ready = true
        arr = array
      )
    )
    waitsFor -> return ready
    
    runs ->
      image = fits.getDataUnit()
      expect(image.getPixel(arr, 0, 0)).toEqual(3852)
      expect(image.getPixel(arr, 500, 500)).toEqual(13492)
      expect(image.getPixel(arr, 270, 400)).toEqual(7067)
      expect(image.getPixel(arr, 760, 800)).toEqual(4426)
      expect(image.getPixel(arr, 672, 284)).toEqual(6007)

  it 'can read a FITS data cube', ->
    precision = 6
    fits = null
  
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/L1448_13CO.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
  
    waitsFor -> return fits?
  
    runs ->
      image = fits.getDataUnit()
  
      # Make sure the file is a data cube
      expect(image.isDataCube()).toBeTruthy()
  
      # First Frame
      arr = image.getFrame()
  
      # Check the values of the corner pixels ...
      expect(image.getPixel(arr, 0, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 106)).toBeNaN()
      expect(image.getPixel(arr, 0, 106)).toBeNaN()
      
      # ... and a few other random pixels
      expect(image.getPixel(arr, 54, 36)).toBeCloseTo(0.0340614, precision)
      expect(image.getPixel(arr, 100, 7)).toBeCloseTo(-0.0275259, precision)
      expect(image.getPixel(arr, 42, 68)).toBeCloseTo(-0.0534229, precision)
      expect(image.getPixel(arr, 92, 24)).toBeCloseTo(0.153861, precision)
      
      # Second Frame
      arr = image.getFrame()
      
      # Check the values of the corner pixels ...
      expect(image.getPixel(arr, 0, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 106)).toBeNaN()
      expect(image.getPixel(arr, 0, 106)).toBeNaN()
      
      # ... and a few other random pixels
      expect(image.getPixel(arr, 54, 36)).toBeCloseTo(0.0329713, precision)
      expect(image.getPixel(arr, 100, 7)).toBeCloseTo(0.0763166, precision)
      expect(image.getPixel(arr, 42, 68)).toBeCloseTo(-0.103573, precision)
      expect(image.getPixel(arr, 92, 24)).toBeCloseTo(0.0360738, precision)
      
      # ... Last Frame
      arr = image.getFrame(601)
        
      # Check the values of the corner pixels ...
      expect(image.getPixel(arr, 0, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 106)).toBeNaN()
      expect(image.getPixel(arr, 0, 106)).toBeNaN()
        
      # ... and a few other random pixels
      expect(image.getPixel(arr, 54, 36)).toBeCloseTo(-0.105564, precision)
      expect(image.getPixel(arr, 100, 7)).toBeCloseTo(0.202304, precision)
      expect(image.getPixel(arr, 42, 68)).toBeCloseTo(0.221437, precision)
      expect(image.getPixel(arr, 92, 24)).toBeCloseTo(-0.163851, precision)
      
      # Second Frame
      arr = image.getFrame(1)
      
      # Check the values of the corner pixels ...
      expect(image.getPixel(arr, 0, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 0)).toBeNaN()
      expect(image.getPixel(arr, 106, 106)).toBeNaN()
      expect(image.getPixel(arr, 0, 106)).toBeNaN()
      
      # ... and a few other random pixels
      expect(image.getPixel(arr, 54, 36)).toBeCloseTo(0.0329713, precision)
      expect(image.getPixel(arr, 100, 7)).toBeCloseTo(0.0763166, precision)
      expect(image.getPixel(arr, 42, 68)).toBeCloseTo(-0.103573, precision)
      expect(image.getPixel(arr, 92, 24)).toBeCloseTo(0.0360738, precision)
      
      