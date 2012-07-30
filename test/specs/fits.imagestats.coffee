require = window.require

FITS  = require("fits")
Stats = require("fits.imagestats")

describe "FITS Image Stats", ->

  it 'can compute a histogram', ->
    precision = 8
    
    image = fits.getDataUnit()
    image.rowsRead = 0
    
    stats = new Stats(image)
    histogram = stats.computeHistogram(1000)
    mean      = stats.computeMean()
    std       = stats.computeSTD()
    
    sum = 0
    sum += value for value in histogram
    expect(sum).toEqual(image.naxis[0] * image.naxis[1])
    expect(mean).toBeCloseTo(5868.4076436883452, precision)
    expect(std).toBeCloseTo(2241.2503679376473, precision)
    console.log stats