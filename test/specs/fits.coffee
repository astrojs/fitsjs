require = window.require

describe "Fits", ->
  Fits = require("fits")

  it 'can parse key/values', ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits", true)
    xhr.responseType = 'arraybuffer'

    xhr.onload = (e) ->
      fits = new Fits(xhr.response)

    xhr.send()
    
  it 'can read both headers from a compressed FITS image', ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits.fz", true)
    xhr.responseType = 'arraybuffer'

    xhr.onload = (e) ->
      fits = new Fits(xhr.response)

    xhr.send()