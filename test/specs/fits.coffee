require = window.require

describe "Fits", ->
  Fits = require("fits")

  it 'can parse key/values', ->
    xhr = new XMLHttpRequest()
    console.log('blah');
    xhr.open('GET', "http://0.0.0.0:9294/data/2MASS_NGC_6872_H.fits", true)
    xhr.responseType = 'arraybuffer'
    xhr.onload = (e) ->
      console.log(xhr.response)
      fits = new Fits(xhr.response)
      console.log fits
    xhr.send()