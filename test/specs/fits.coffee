require = window.require

describe "FITS", ->
  FITS            = require("fits")
  FITS.Visualize  = require("fits.visualize")
  FITS.ImageSet   = require("fits.imageset")
  
  it 'can open a FITS file with image and ASCII table', ->
    expect(fits.hdus.length).toEqual(2)
    expect(fits.eof).toBeTruthy()
    expect(fits.hdus[0].data.constructor.name).toBe("Image")
    expect(fits.hdus[1].data.constructor.name).toBe("Table")

  it 'can open a FITS file storing a compressed image', ->
    expect(compimg.hdus.length).toEqual(2)
    expect(compimg.eof).toBeTruthy()
    expect(compimg.hdus[0].data).toBeUndefined()
    expect(compimg.hdus[1].data.constructor.name).toBe("CompImage")

  it 'can open a FITS file storing a binary table', ->
    expect(bintable.hdus.length).toEqual(2)
    expect(bintable.eof).toBeTruthy()
    expect(bintable.hdus[0].data).toBeUndefined()
    expect(bintable.hdus[1].data.constructor.name).toBe("BinTable")
  
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
    