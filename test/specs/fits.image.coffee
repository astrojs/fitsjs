require = window.require

FITS = require("fits")

describe "FITS Image", ->

  it 'can read a FITS image', ->
    
    image = fits.getDataUnit()
    image.getFrame()
    
    # Check the values of the corner pixels ...
    expect(image.getPixel(0, 0)).toEqual(3852)
    expect(image.getPixel(890, 0)).toEqual(4223)
    expect(image.getPixel(890, 892)).toEqual(4015)
    expect(image.getPixel(0, 892)).toEqual(3898)
    
    # ... and a few other random pixels
    expect(image.getPixel(405, 600)).toEqual(9128)
    expect(image.getPixel(350, 782)).toEqual(4351)
    expect(image.getPixel(108, 345)).toEqual(4380)
    expect(image.getPixel(720, 500)).toEqual(5527)