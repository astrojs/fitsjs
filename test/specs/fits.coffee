require = window.require

describe "FITS", ->
  FITS = require("fits")
  
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
      expect(fits.eof).toBeTruthy()
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
      expect(fits.eof).toBeTruthy()
      expect(fits.hdus[0].data).toBeUndefined()
      expect(fits.hdus[1].data.constructor.name).toBe("CompImage")

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
      expect(fits.eof).toBeTruthy()
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