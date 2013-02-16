window.FITS = astro.FITS

describe "FITS", ->
  
  it 'can open a FITS file with image and ASCII table', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/m101.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      expect(fits.hdus.length).toEqual(2)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.hdus[0].data.constructor.name).toBe("Image")
      expect(fits.hdus[1].data.constructor.name).toBe("Table")

  it 'can open a FITS file storing a compressed image', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/CFHTLS_03_g_sci.fits.fz')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      expect(fits.hdus.length).toEqual(2)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.hdus[0].data).toBeUndefined()
      expect(fits.hdus[1].data.constructor.name).toBe("CompressedImage")

  it 'can open a FITS file storing a binary table', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bit.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      expect(fits.hdus.length).toEqual(2)
      expect(fits.isEOF()).toBeTruthy()
      expect(fits.hdus[0].data).toBeUndefined()
      expect(fits.hdus[1].data.constructor.name).toBe("BinaryTable")
  
  it 'can read a bit array', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/spec-0406-51869-0012.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      console.log fits
  
  it 'can initialize with a url', ->
    
    # Should be on the same domain as site, or handle CORS requests
    location = 'data/m101.fits'
    new FITS.File(location, (f) ->
      expect(f.hdus.length).toEqual(2)
      expect(f.isEOF()).toBeTruthy()
      expect(f.hdus[0].data.constructor.name).toBe("Image")
      expect(f.hdus[1].data.constructor.name).toBe("Table")
    )
  
  it 'can write file back for download', ->
    
    url = 'data/m101.fits'
    fits = new FITS.File(url, (f) ->
      
      # File is ready, add value to header
      header = fits.getHeader()
      header.set('AUTHOR', 'Amit Kapadia', 'some comment')
      
      fits.save()
    )
    
    
    