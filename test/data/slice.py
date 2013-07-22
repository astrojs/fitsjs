
import struct


def slice():
  
  # Open a troublesome file
  f = open("/Users/akapadia/Downloads/cfitsio/CFHTLS_082_0001_i.fits.fz", 'rb')
  
  # Read the bytes into memory
  data = f.read()
  
  # Set the starting byte of the first data unit.
  # This data unit is a compressed FITS image
  # stored in a binary table.
  start = 14400
  
  # Set the end of the table.  Since this is a compressed image,
  # those pixels are stored in a heap at the end of the table.
  # This offset is also the starting byte of the heap.
  end = start + 10560
  
  # The heap stores unsigned 8 bit integers that were compressed by fpack.
  # The first row has a length of 275 (I know this file intimately, trust this number).
  length = 275
  
  # Get the byte stream corresponding to the first row of compressed values.
  # This stream needs to be read as unsigned 8 bit integers, then decompressed.
  stream = data[end: end + length]
  
  # Using the standard struct module to unpack the integers.
  row = struct.unpack("!%dB" % length, stream)
  
  # Now, these values are incorrect in the same way as in javascript!!!  That's
  # a good sign.  The C implementation is doing something to these values.
  print row
  
if __name__ == '__main__':
  slice()