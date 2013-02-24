
# Base class for FITS data units (e.g. Primary, BINTABLE, TABLE, IMAGE).  Derived classes must
# define an instance attribute called length describing the byte length of the data unit.
class DataUnit extends Module
  
  @swapEndian:
    B: (value) -> return value
    I: (value) -> return (value << 8) | (value >> 8)
    J: (value) -> return ((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value >> 8) & 0xFF00) | ((value >> 24) & 0xFF)
  
  @swapEndian[8] = @swapEndian['B']
  @swapEndian[16] = @swapEndian['I']
  @swapEndian[32] = @swapEndian['J']
  
  
  constructor: (header, @view, @offset) ->
    @begin = @offset


@astro.FITS.DataUnit = DataUnit