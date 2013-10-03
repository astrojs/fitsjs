window.FITS = astro.FITS

describe "FITS Image", ->

  beforeEach ->
    @addMatchers {
      toBeNaN: (expected) -> return isNaN(@actual) == isNaN(expected)
    }
  
  it 'can read Orion2MASS_K', ->
    path = "data/Orion2MASS_K.fits"
    new astro.FITS(path, (f) ->
      header = f.getHeader()
      image = f.getDataUnit()
      image.getFrame(0, (arr) ->
        console.log arr
      )
      
    )
  
  it 'can read an 8 bit integer image', ->
    ready = false
    
    image = null
    data = null
    path = 'data/bitpix/m101_uint8.fits'
    fits = new astro.FITS(path, (fits) ->
      
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        data = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(image.getPixel(data, 0, 0)).toEqual(3727)
      expect(image.getPixel(data, 500, 500)).toEqual(13493)
      expect(image.getPixel(data, 270, 400)).toEqual(7068)
      expect(image.getPixel(data, 760, 800)).toEqual(4498)
      expect(image.getPixel(data, 672, 284)).toEqual(6040)
  
  it 'can read a 16 bit integer image', ->
    ready = false
    
    image = null
    data = null
    
    path = 'data/bitpix/m101_uint16.fits'
    fits = new astro.FITS(path, (fits) ->
      
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        data = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(image.getPixel(data, 0, 0)).toEqual(3852)
      expect(image.getPixel(data, 500, 500)).toEqual(13492)
      expect(image.getPixel(data, 270, 400)).toEqual(7067)
      expect(image.getPixel(data, 760, 800)).toEqual(4426)
      expect(image.getPixel(data, 672, 284)).toEqual(6007)
      
  it 'can read a 32 bit integer image', ->
    ready = false
    
    image = null
    data = null
    
    path = 'data/bitpix/m101_uint32.fits'
    fits = new astro.FITS(path, (fits) ->
      
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        data = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(image.getPixel(data, 0, 0)).toEqual(3852)
      expect(image.getPixel(data, 500, 500)).toEqual(13492)
      expect(image.getPixel(data, 270, 400)).toEqual(7067)
      expect(image.getPixel(data, 760, 800)).toEqual(4426)
      expect(image.getPixel(data, 672, 284)).toEqual(6007)

  it 'can read a 32 bit float image', ->
    ready = false
    
    image = null
    data = null
    
    path = 'data/bitpix/m101_float32.fits'
    fits = new astro.FITS(path, (fits) ->
      
      image = fits.getDataUnit()
      image.getFrame(0, (arr) ->
        data = arr
        ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(image.getPixel(data, 0, 0)).toEqual(3852)
      expect(image.getPixel(data, 500, 500)).toEqual(13492)
      expect(image.getPixel(data, 270, 400)).toEqual(7067)
      expect(image.getPixel(data, 760, 800)).toEqual(4426)
      expect(image.getPixel(data, 672, 284)).toEqual(6007)

  it 'can read a FITS data cube', ->
    precision = 6
    
    ready = false
    image = null
    frames = []
    
    path = 'data/L1448_13CO.fits'
    fits = new astro.FITS(path, (fits) ->
      
      image = fits.getDataUnit()
      image.getFrames(0, 4, (arr) ->
        frames.push(arr)
        if frames.length is 4
          ready = true
      )
    )
    
    waitsFor ->
      return ready
    
    runs ->
      
      frame1 = frames[0]
      frame2 = frames[1]
      frame3 = frames[2]
      frame4 = frames[3]
      
      # First Frame
      
      # Check the values of the corner pixels ...
      expect(image.getPixel(frame1, 0, 0)).toBeNaN()
      expect(image.getPixel(frame1, 106, 0)).toBeNaN()
      expect(image.getPixel(frame1, 106, 106)).toBeNaN()
      expect(image.getPixel(frame1, 0, 106)).toBeNaN()
      
      # ... and a few other random pixels
      expect(image.getPixel(frame1, 54, 36)).toBeCloseTo(0.0340614, precision)
      expect(image.getPixel(frame1, 100, 7)).toBeCloseTo(-0.0275259, precision)
      expect(image.getPixel(frame1, 42, 68)).toBeCloseTo(-0.0534229, precision)
      expect(image.getPixel(frame1, 92, 24)).toBeCloseTo(0.153861, precision)
      
      # Second Frame
      
      # Check the values of the corner pixels ...
      expect(image.getPixel(frame2, 0, 0)).toBeNaN()
      expect(image.getPixel(frame2, 106, 0)).toBeNaN()
      expect(image.getPixel(frame2, 106, 106)).toBeNaN()
      expect(image.getPixel(frame2, 0, 106)).toBeNaN()
      
      # ... and a few other random pixels
      expect(image.getPixel(frame2, 54, 36)).toBeCloseTo(0.0329713, precision)
      expect(image.getPixel(frame2, 100, 7)).toBeCloseTo(0.0763166, precision)
      expect(image.getPixel(frame2, 42, 68)).toBeCloseTo(-0.103573, precision)
      expect(image.getPixel(frame2, 92, 24)).toBeCloseTo(0.0360738, precision)
      
      # # ... Last Frame
      # 
      # # Check the values of the corner pixels ...
      # expect(image.getPixel(frame3, 0, 0)).toBeNaN()
      # expect(image.getPixel(frame3, 106, 0)).toBeNaN()
      # expect(image.getPixel(frame3, 106, 106)).toBeNaN()
      # expect(image.getPixel(frame3, 0, 106)).toBeNaN()
      #   
      # # ... and a few other random pixels
      # expect(image.getPixel(frame3, 54, 36)).toBeCloseTo(-0.105564, precision)
      # expect(image.getPixel(frame3, 100, 7)).toBeCloseTo(0.202304, precision)
      # expect(image.getPixel(frame3, 42, 68)).toBeCloseTo(0.221437, precision)
      # expect(image.getPixel(frame3, 92, 24)).toBeCloseTo(-0.163851, precision)
      # 
      # # back to second frame
      # 
      # # Check the values of the corner pixels ...
      # expect(image.getPixel(frame2, 0, 0)).toBeNaN()
      # expect(image.getPixel(frame2, 106, 0)).toBeNaN()
      # expect(image.getPixel(frame2, 106, 106)).toBeNaN()
      # expect(image.getPixel(frame2, 0, 106)).toBeNaN()
      # 
      # # ... and a few other random pixels
      # expect(image.getPixel(frame2, 54, 36)).toBeCloseTo(0.0329713, precision)
      # expect(image.getPixel(frame2, 100, 7)).toBeCloseTo(0.0763166, precision)
      # expect(image.getPixel(frame2, 42, 68)).toBeCloseTo(-0.103573, precision)
      # expect(image.getPixel(frame2, 92, 24)).toBeCloseTo(0.0360738, precision)
      
      