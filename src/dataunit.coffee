
# Base class for FITS data units (e.g. Primary, BINTABLE, TABLE, IMAGE).  Derived classes must
# define an instance attribute called length describing the byte length of the data unit.
class DataUnit extends Module

  constructor: (header, @view, @offset) ->
    @begin = @offset


@astro.FITS.DataUnit = DataUnit