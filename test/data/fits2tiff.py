
import pyfits
import numpy


def fits2tiff():
  
  data = pyfits.getdata("L1448_13CO.fits")
  
  for frames in data:
    


if __name__ == '__main__':
  fits2tiff()
