import os
import sys
import re
import numpy
import pyfits

def generate():
    """
    Generate test data for FITS images for every value of BITPIX
    
    BITPIX  Numpy Data Type
    ------  ---------------
    8       numpy.uint8
    16      numpy.int16
    32      numpy.int32
    -32     numpy.float32
    -64     numpy.float64
    """
    
    # dtypes = [numpy.uint8, numpy.int16, numpy.int32, numpy.float32, numpy.float64]
    dtypes = [numpy.uint8, numpy.int16, numpy.int32, numpy.float32]
    dimension = 100
    
    a = numpy.random.random(dimension * dimension)
    
    for dtype in dtypes:
        bits = int(re.search('\d+', dtype.__name__).group(0))
        maxvalue = numpy.float64(numpy.power(2, bits) - 1)
        data = (a * maxvalue).reshape((dimension, dimension)).astype(dtype)
        
        hdu = pyfits.PrimaryHDU(data = data)
        hdu.writeto("image-%s.fits" % dtype.__name__)
    

if __name__ == '__main__':
    generate()