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
  
  # it 'can read both headers from a FITS binary table', ->
  #   xhr = new XMLHttpRequest()
  #   # xhr.open('GET', "http://0.0.0.0:9294/data/spec-0406-51869-0012.fits", true)
  #   xhr.open('GET', "http://0.0.0.0:9294/data/test-data.fits", true)
  #   xhr.responseType = 'arraybuffer'
  # 
  #   xhr.onload = (e) ->
  #     fits = new FITS.File(xhr.response)
  #     console.log fits
  # 
  #   xhr.send()

  it 'can read both headers from a compressed FITS image', ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits.fz", true)
    xhr.responseType = 'arraybuffer'
    
    xhr.onload = (e) ->
      fits = new FITS.File(xhr.response)
      console.log fits
      tbl = fits.hdus[1]['data']
      console.log tbl.begin
      console.log tbl.getRow()
      console.log tbl.getRow()
  
    xhr.send()