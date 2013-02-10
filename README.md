fitsjs
======

A standalone JavaScript library for reading the astronomical file format – FITS.  This library is built for modern browsers supporting the DataView API.  These include at least Chrome 9, Firefox 15, and Safari 6.

To use the library copy `lib/fits.js` to your project and include it with a script tag.  The FITS object is exposed under the `astro` namespace.

    <script src="fits.js" type="text/javascript" charset="utf-8">
    </script>
    
    <script type="text/javascript">
      var FITS = astro.FITS;
    </script>

This library may be used to read various forms of the FITS format.  This implementation is under active development.  Currently it supports:

* Reading multiple header data units
* Reading images
* Reading data cubes
* Reading binary tables
* Reading ASCII Tables
* Reading Rice compressed images

Please let me know if you incorporate this library in your project, and please share your application with the rest of the astronomy community.

API
---

### FITS.File

    fits.getHDU()
Returns the first HDU containing a data unit.  An optional argument may be passed to retrieve 
a specific HDU.

    fits.getHeader()
Returns the header associated with the first HDU containing a data unit.  An optional argument
may be passed to point to a specific HDU.

    fits.getDataUnit()
Returns the data object associated with the first HDU containing a data unit.  This method does not read from the array buffer.
An optional argument may be passed to point to a specific HDU.

    fits.getData()
Returns the data associated with the first HDU containing a data unit.  An optional argument
may be passed to point to a specific HDU.

### FITS.HDU

    hdu.getCard(key)
Returns the value from the header of the user specified key.

### FITS.Header

    hdr.get(key)
Returns the value of the key.

    hdr.contains(key)
Checks if a key is contained in the header instance.

    hdr.hasDataUnit()
Checks if the header has an associated data unit.


Examples
--------
    <script src="fits.js" type="text/javascript" charset="utf-8"></script>
    
    <script type="text/javascript">
      var FITS = astro.FITS;
      
      // Define a callback function for when the FITS file is received
      fn = function() {
        
        // Get the first header-dataunit containing a dataunit
        var hdu = this.getHDU();
        
        // Get the first header
        var header = this.getHeader();
        
        // or we can do
        var header = hdu.header;
        
        // Read a card from the header
        var bitpix = header.get('BITPIX');
        
        // Get the dataunit object
        var dataunit = hdu.data;
        
        // or we can do
        var dataunit = this.getDataUnit();
        
        // Do some wicked client side processing ...
      }
      
      // Set path to FITS file
      var url = "/some/FITS/file/on/your/server.fits";
      
      // Initialize a new FITS File object
      var fits = new FITS.File(url, fn);
      
      // Alternatively, the FITS.File object may be initialized with a buffer
      // using the HTML5 File API or an XML HTTP request.  In this case, no callback function
      // is required.
      var fits = new FITS.File(buffer);
      
    </script>

References
----------

Pence, W. D. Binary Table Extension To FITS.

Pence, W. D., L. Chiappetti, C. G. Page, R. a. Shaw, and E. Stobie. 2010. Definition of the Flexible Image Transport System ( FITS ), version 3.0. Astronomy & Astrophysics 524 (November 22): A42. doi:10.1051/0004-6361/201015362. http://www.aanda.org/10.1051/0004-6361/201015362.

Ponz, J.D., Thompson, R.W., Muñoz, J.R. The FITS Image Extension.

White, Richard L, Perry Greenfield, William Pence, Nasa Gsfc, Doug Tody, and Rob Seaman. 2011. Tiled Image Convention for Storing Compressed Images in FITS Binary Tables: 1-17.
