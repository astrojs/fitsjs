require = window.require

describe "FITS", ->
  FITS      = require("fits")
  Visualize = require("fits.visualize")
  ImageSet  = require("fits.imageset")
  
  it 'can initialize a visualize object', ->
    
    # Set up a canvas
    container = document.createElement('div')
    document.getElementsByTagName('body')[0].appendChild(container)
    imageset = new ImageSet()
    
    requestImage = (filename) ->
      xhr = new XMLHttpRequest()
      file = "http://0.0.0.0:9294/data/CFHTLS/" + filename
      xhr.open('GET', file, true)
      xhr.responseType = 'arraybuffer'
      
      xhr.onload = (e) ->
        fits = new FITS.File(xhr.response)
        imageset.addImage(fits)
        
        if imageset.getCount() is 5
          viz = new Visualize(imageset, container)
          viz.stretch('arcsinh')
          viz.scale(0, 1)
          console.log viz
          
      xhr.send()
  
    
    filters = ['u', 'g', 'r', 'i', 'z'];
    for filter in filters
      filename = "CFHTLS_03_#{filter}_sci.fits"
      requestImage(filename)
