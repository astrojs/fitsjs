fitsjs
======

A JavaScript library for reading the astronomical file format – FITS.  This library depends on [jDataView](https://github.com/vjeux/jDataView).  Other dependencies installed by Node are for testing the library and running a local server.

    # Install the dependencies.
    npm install .
    cake build
    
    # Generate documentation
    groc
    
This library may be used to read various forms of the FITS file type.  This implementation is under active development.  Currently it supports the following features:

* Multiple Header Data Units
* Reading FITS images
* Reading Binary Tables
* Reading ASCII Tables
* Decompressing FITS Images with the Rice algorithm

API
---

### FITS.File

    fits.getHDU()
Returns the first HDU containing a data unit.  An optional argument may be passed to retreive 
a specific HDU
    
    fits.getHeader()
Returns the header associated with the first HDU containing a data unit.  An optional argument
may be passed to point to a specific HDU.

    fits.getDataUnit()
Returns the data object associated with the first HDU containing a data unit.  This method does not read from the array buffer
An optional argument may be passed to point to a specific HDU.

    fits.getData()
Returns the data associated with the first HDU containing a data unit.  An optional argument
may be passed to point to a specific HDU.

### FITS.HDU

    hdu.getCard(key)
Returns the value from the header of the user specifed key.

*More to come ...*

Examples
--------
    
    // Get an array buffer of the FITS file using XHR
    var xhr = new XMLHttpRequest();
    xhr.open('GET', "[/path/to/fits/file]");
    
    // Set the response type to arraybuffer
    xhr.responseType = 'arraybuffer';
    
    // Define the onload function
    xhr.onload = function(e) {
        
        // Initialize the FITS.File object using the array buffer returned from the XHR
        var fits = new FITS.File(xhr.response);
        
        // Grab the first HDU with a data unit
        var hdu = fits.getHDU();
        
        // Read a card from the header
        var bitpix = hdu.getCard("BITPIX");
        
        // or we can read the card from the Header object
        var bitpix = hdu.header["BITPIX"]
        
        // Grab the data object
        var data = hdu.data
    }
    
    // BAM! Send off the request
    xhr.send();

References
----------

Pence, W. D. Binary Table Extension To FITS.

Pence, W. D., L. Chiappetti, C. G. Page, R. a. Shaw, and E. Stobie. 2010. Definition of the Flexible Image Transport System ( FITS ), version 3.0. Astronomy & Astrophysics 524 (November 22): A42. doi:10.1051/0004-6361/201015362. http://www.aanda.org/10.1051/0004-6361/201015362.

Ponz, J.D., Thompson, R.W., Muñoz, J.R. The FITS Image Extension.

White, Richard L, Perry Greenfield, William Pence, Nasa Gsfc, Doug Tody, and Rob Seaman. 2011. Tiled Image Convention for Storing Compressed Images in FITS Binary Tables: 1-17.
