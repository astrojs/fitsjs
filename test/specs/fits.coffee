require = window.require

describe "Fits", ->
  FITS = require("fits")

  # it 'can parse key/values', ->
  #   xhr = new XMLHttpRequest()
  #   xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits", true)
  #   xhr.responseType = 'arraybuffer'
  #   
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  #   
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
  
  it 'can read both headers from a compressed FITS image', ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://0.0.0.0:9294/data/m101.fits", true)
    xhr.responseType = 'arraybuffer'
    
    xhr.onload = (e) ->
      fits = new FITS.File(xhr.response)
      console.log fits
      tbl = fits.hdus[1]['data']
      console.log tbl.getRow()
      
      
    xhr.send()