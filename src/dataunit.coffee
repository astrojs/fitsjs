
# Base class for FITS data units (e.g. Primary, BINTABLE, TABLE, IMAGE).  Derived classes must
# define an instance attribute called length describing the byte length of the data unit.
class DataUnit extends Module

  constructor: (view, header) ->
    @view   = view
    @begin  = @current = view.tell()
    @length = undefined

@astro.fits.DataUnit = DataUnit