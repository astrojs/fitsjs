# window.FITS = astro.FITS
# 
# describe "FITS Image", ->
# 
#   beforeEach ->
#     @addMatchers {
#       toBeNaN: (expected) -> return isNaN(@actual) == isNaN(expected)
#     }
#   
#   it 'can read a FITS image', ->
#     fits = null
#     
#     xhr = new XMLHttpRequest()
#     xhr.open('GET', 'data/m101.fits')
#     xhr.responseType = 'arraybuffer'
#     xhr.onload = -> fits = new FITS.File(xhr.response)
#     xhr.send()
#     
#     waitsFor -> return fits?
#     
#     runs ->
#       console.log fits
#       
#       image = fits.getDataUnit()
#       image.getFrame()
#           
#       # Check the values of the corner pixels ...
#       expect(image.getPixel(0, 0)).toEqual(3852)
#       expect(image.getPixel(890, 0)).toEqual(4223)
#       expect(image.getPixel(890, 892)).toEqual(4015)
#       expect(image.getPixel(0, 892)).toEqual(3898)
#           
#       # ... and a few other random pixels
#       expect(image.getPixel(405, 600)).toEqual(9128)
#       expect(image.getPixel(350, 782)).toEqual(4351)
#       expect(image.getPixel(108, 345)).toEqual(4380)
#       expect(image.getPixel(720, 500)).toEqual(5527)
#   
#   it 'can read a FITS data cube', ->
#     precision = 6
#     fits = null
#     
#     xhr = new XMLHttpRequest()
#     xhr.open('GET', 'data/L1448_13CO.fits')
#     xhr.responseType = 'arraybuffer'
#     xhr.onload = -> fits = new FITS.File(xhr.response)
#     xhr.send()
#     
#     waitsFor -> return fits?
#     
#     runs ->
#       image = fits.getDataUnit()
#     
#       # Make sure the file is a data cube
#       expect(image.isDataCube()).toBeTruthy()
#     
#       # First Frame
#       frame1 = image.getFrame()
#     
#       # Check the values of the corner pixels ...
#       expect(image.getPixel(0, 0)).toBeNaN()
#       expect(image.getPixel(106, 0)).toBeNaN()
#       expect(image.getPixel(106, 106)).toBeNaN()
#       expect(image.getPixel(0, 106)).toBeNaN()
#       
#       # ... and a few other random pixels
#       expect(image.getPixel(54, 36)).toBeCloseTo(0.0340614, precision)
#       expect(image.getPixel(100, 7)).toBeCloseTo(-0.0275259, precision)
#       expect(image.getPixel(42, 68)).toBeCloseTo(-0.0534229, precision)
#       expect(image.getPixel(92, 24)).toBeCloseTo(0.153861, precision)
#       
#       # Second Frame
#       frame2 = image.getFrame()
#       
#       # Check the values of the corner pixels ...
#       expect(image.getPixel(0, 0, 1)).toBeNaN()
#       expect(image.getPixel(106, 0, 1)).toBeNaN()
#       expect(image.getPixel(106, 106, 1)).toBeNaN()
#       expect(image.getPixel(0, 106, 1)).toBeNaN()
#       
#       # ... and a few other random pixels
#       expect(image.getPixel(54, 36, 1)).toBeCloseTo(0.0329713, precision)
#       expect(image.getPixel(100, 7, 1)).toBeCloseTo(0.0763166, precision)
#       expect(image.getPixel(42, 68, 1)).toBeCloseTo(-0.103573, precision)
#       expect(image.getPixel(92, 24, 1)).toBeCloseTo(0.0360738, precision)
#       
#       # ... Last Frame
#       frame3 = image.getFrame(601)
#           
#       # Check the values of the corner pixels ...
#       expect(image.getPixel(0, 0, 601)).toBeNaN()
#       expect(image.getPixel(106, 0, 601)).toBeNaN()
#       expect(image.getPixel(106, 106, 601)).toBeNaN()
#       expect(image.getPixel(0, 106, 601)).toBeNaN()
#           
#       # ... and a few other random pixels
#       expect(image.getPixel(54, 36, 601)).toBeCloseTo(-0.105564, precision)
#       expect(image.getPixel(100, 7, 601)).toBeCloseTo(0.202304, precision)
#       expect(image.getPixel(42, 68, 601)).toBeCloseTo(0.221437, precision)
#       expect(image.getPixel(92, 24, 601)).toBeCloseTo(-0.163851, precision)
#       
#       #
#       # New interface to access data from FITS image
#       #
#       # Why?
#       #
#       # 1) The FITS object already keeps the arraybuffer, no need to keep the derived contents too
#       # 2) Data cubes require initializing an extremely large typed array.  Implementing getFrame in
#       #    a way that accepts an index allows for smaller arrays to be initialized multiple times, rather 
#       #    than sucking out loads of memory at one time.
#       # 3) getPixel can search through the arraybuffer to extract the correct value instead of computing the index.
#         
#         
#   # it 'can get extremes, seek, then get data without blowing up', ->
#   #   fits = null
#   #   
#   #   xhr = new XMLHttpRequest()
#   #   xhr.open('GET', 'data/m101.fits')
#   #   xhr.responseType = 'arraybuffer'
#   #   xhr.onload = -> fits = new FITS.File(xhr.response)
#   #   xhr.send()
#   #   
#   #   waitsFor -> return fits?
#   #   
#   #   runs ->
#   #     image = fits.getDataUnit()
#   #     expect(image.frame).toEqual(0)
#   #   
#   #     image.seek()
#   #     expect(image.frame).toEqual(0)
#   #   
#   #     # Grab the data
#   #     image.getFrame()
#   #     
#   #     # Get and check the extremes
#   #     image.getExtent()
#   #     
#   #     expect(image.min).toEqual(2396)
#   #     expect(image.max).toEqual(26203)
#   #         
#   #     # Check the values of the corner pixels ...
#   #     expect(image.getPixel(0, 0)).toEqual(3852)
#   #     expect(image.getPixel(890, 0)).toEqual(4223)
#   #     expect(image.getPixel(890, 892)).toEqual(4015)
#   #     expect(image.getPixel(0, 892)).toEqual(3898)
#   #         
#   #     # ... and a few other random pixels
#   #     expect(image.getPixel(405, 600)).toEqual(9128)
#   #     expect(image.getPixel(350, 782)).toEqual(4351)
#   #     expect(image.getPixel(108, 345)).toEqual(4380)
#   #     expect(image.getPixel(720, 500)).toEqual(5527)
#   # 
#   # it 'can read an image with BSCALE and BZERO params', ->
#   #   fits = null
#   #   
#   #   xhr = new XMLHttpRequest()
#   #   xhr.open('GET', 'data/m101_scaleparams.fits')
#   #   xhr.responseType = 'arraybuffer'
#   #   xhr.onload = -> fits = new FITS.File(xhr.response)
#   #   xhr.send()
#   #   
#   #   waitsFor -> return fits?
#   #   
#   #   runs ->
#   #     image = fits.getDataUnit()
#   #   
#   #     # Grab the data
#   #     image.getFrame()
#   #     
#   #     # Get and check the extremes
#   #     image.getExtent()
#   #     
#   #     expect(image.min).toEqual(1298.0)
#   #     expect(image.max).toEqual(13201.5)
#   #     
#   #     expect(image.getPixel(0, 0)).toEqual(2026)
# 
#   # it 'can read a file with an IMAGE extension', ->
#   #   fits = null
#   # 
#   #   xhr = new XMLHttpRequest()
#   #   xhr.open('GET', 'data/HST_10098_09_ACS_WFC_F555W_drz.fits')
#   #   xhr.responseType = 'arraybuffer'
#   #   xhr.onload = -> fits = new FITS.File(xhr.response)
#   #   xhr.send()
#   # 
#   #   waitsFor -> return fits?
#   # 
#   #   runs ->
#   #     image = fits.getDataUnit()
#   #     image.getFrame()
#   #     image.getExtremes()
#   #     
#   #     expect(image.min).toBeCloseTo(-60.139053, 6)
#   #     expect(image.max).toBeCloseTo(1660.3833, 4)
