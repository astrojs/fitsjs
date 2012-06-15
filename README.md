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

    # in progress ...

Examples
--------
    
    // Get an array buffer of the FITS file using XHR
    var xhr = new XMLHttpRequest();
    xhr.open('GET', "[/path/to/fits/file]");
    
    // Set the response type to arraybuffer
    xhr.responseType = 'arraybuffer';
    
    // Define the onload function
    xhr.onload = function(e) {
        var fits = new FITS.File(xhr.response);
        var hdu = fits.getHDU();
    }
    
    // BAM! Send off the request
    xhr.send();

References
----------

Pence, W. D. Binary Table Extension To FITS.

Pence, W. D., L. Chiappetti, C. G. Page, R. a. Shaw, and E. Stobie. 2010. Definition of the Flexible Image Transport System ( FITS ), version 3.0. Astronomy & Astrophysics 524 (November 22): A42. doi:10.1051/0004-6361/201015362. http://www.aanda.org/10.1051/0004-6361/201015362.

Ponz, J.D., Thompson, R.W., MuÃ±oz, J.R. The FITS Image Extension.

White, Richard L, Perry Greenfield, William Pence, Nasa Gsfc, Doug Tody, and Rob Seaman. 2011. Tiled Image Convention for Storing Compressed Images in FITS Binary Tables: 1-17.
