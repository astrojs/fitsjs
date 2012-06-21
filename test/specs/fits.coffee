require = window.require

describe "FITS", ->
  FITS            = require("fits")
  FITS.Visualize  = require("fits.visualize")
  FITS.ImageSet   = require("fits.imageset")
  
  # it 'can open a FITS file', ->
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', "http://0.0.0.0:9294/data/m101.fits", true)
  #   xhr.responseType = 'arraybuffer'
  #   
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     
  #     # This file contains 2 HDUs, an image and ASCII table
  #     expect(fits.hdus.length).toEqual(2)
  #     expect(fits.eof).toBeTruthy()
  #     expect(fits.hdus[0].data.constructor.name).toBe("Image")
  #     expect(fits.hdus[1].data.constructor.name).toBe("Table")
  #   xhr.send()
    
  # it 'can parse key/values', ->
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', "http://0.0.0.0:9294/data/L1448_13CO.fits", true)
  #   xhr.responseType = 'arraybuffer'
  # 
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  #     fits.hdus[0].data.initArray()
  #     
  #     fits.hdus[0].data.getFrame()
  #     console.log fits.hdus[0].data.data
  #     
  #   xhr.send()

  # it 'can read both headers from a FITS binary table', ->
  #   xhr = new XMLHttpRequest()
  #   # xhr.open('GET', "http://0.0.0.0:9294/data/spec-0406-51869-0012.fits", true)
  #   xhr.open('GET', "http://0.0.0.0:9294/data/test-data.fits", true)
  #   xhr.responseType = 'arraybuffer'
  # 
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  #     tbl = fits.hdus[1]['data']
  #     table = []
  #     for i in [1..tbl.rows]
  #       table.push(tbl.getRow())
  #     console.log table
  #   xhr.send()

  # it 'can read both headers from a compressed FITS image', ->
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits.fz", true)
  #   xhr.responseType = 'arraybuffer'
  #   
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  #     tbl = fits.hdus[1]['data']
  # 
  #   xhr.send()

  # it 'can read both headers from a compressed FITS image', ->
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', "http://0.0.0.0:9294/data/smallblock.fits.fz", true)
  #   xhr.responseType = 'arraybuffer'
  #   
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  #     tbl = fits.hdus[1]['data']
  #     for i in [1..tbl.rows]
  #       tbl.getRow()
  #     
  #   xhr.send()
  
  it 'can parse a compressed FITS images', ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://0.0.0.0:9294/data/compressed/CFHTLS_03_g_sci.fits.fz")
    # xhr.open('GET', "http://0.0.0.0:9294/data/compressed/Arp245_EMMI_R.fits.fz")
    xhr.responseType = 'arraybuffer'
    
    xhr.onload = (e) ->
      fits = new FITS.File(xhr.response)
      hdu = fits.getHDU()
      
      # hdu.data.rowsRead = 1500
      console.log hdu.data.getRow()
      
  
    xhr.send()
    
  # it 'can initialize a visualize object', ->
  # 
  #   canvas = document.createElement('canvas')
  #   imageset = new FITS.ImageSet()
  #   
  #   requestImage = (filename) ->
  #     xhr = new XMLHttpRequest()
  #     file = "http://0.0.0.0:9294/data/CFHTLS/" + filename
  #     xhr.open('GET', file, true)
  #     xhr.responseType = 'arraybuffer'
  #     
  #     xhr.onload = (e) ->
  #       fits = new FITS.File(xhr.response)
  #       imageset.addImage(fits)
  #       
  #       # if imageset.getCount() is 5
  #         # viz = new FITS.Visualize(imageset, canvas)
  #         # console.log viz
  #         
  #     xhr.send()
  # 
  #   
  #   filters = ['u', 'g', 'r', 'i', 'z'];
  #   for filter in filters
  #     filename = "CFHTLS_03_#{filter}_sci.fits"
  #     requestImage(filename)
    