window.FITS = astro.FITS

describe "FITS", ->
  
  it 'can open a FITS image', ->
    ready = false
    
    path = 'data/Deep_32.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(fits.hdus.length).toEqual(1)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.getDataUnit().constructor.name).toBe("Image")
    
  it 'can open a FITS Binary Table', ->
    ready = false
    
    path = 'data/plates-dr9.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(fits.hdus.length).toEqual(2)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.getDataUnit().constructor.name).toBe("BinaryTable")
    
  it 'can open a FITS file with multiple header dataunits', ->
    ready = false
    
    path = 'data/m101.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      expect(fits.hdus.length).toEqual(2)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.getDataUnit(0).constructor.name).toBe("Image")
      expect(fits.getDataUnit(1).constructor.name).toBe("Table")
  