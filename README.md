fitsjs
======

A JavaScript library for reading the astronomical file format – FITS.  This library depends on [jDataView](https://github.com/vjeux/jDataView).  Other dependencies installed by Node are only for the testing environment and generating documentation.

To install the dependencies and generate documentation:

    # Install the dependencies.
    npm install .
    
    # Generate documentation
    groc
    
To use the library copy public/fits.js to your project and include it using a script tag.  After including the library, the FITS object is exposed by calling require.

    <script src="fits.js" type="text/javascript" charset="utf-8">
    </script>
    
    <script type="text/javascript">
      FITS = require('fits');
    </script>
    
This library may be used to read various forms of the FITS format.  This implementation is under active development.  In its current state it supports the following:

* Multiple Header Data Units
* Reading FITS images
* Reading Binary Tables
* Reading ASCII Tables
* Decompressing FITS Images using the Rice decompression algorithm

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
Returns the data object associated with the first HDU containing a data unit.  This method does not read from the array buffer
An optional argument may be passed to point to a specific HDU.

    fits.getData()
Returns the data associated with the first HDU containing a data unit.  An optional argument
may be passed to point to a specific HDU.

### FITS.HDU

    hdu.getCard(key)
Returns the value from the header of the user specified key.

### FITS.Header

    hdr.get(key)
Returns the index, value, and comment of the key.

    hdr[key]
Returns the value of the key.

    hdr.getIndex(key)
Returns the index of the key.

    hdr.getComment(key)
Returns the comment associated with the key.

    hdr.getComments(key)
Returns the value of all COMMENT fields.

    hdr.getHistory(key)
Returns the value of all HISTORY fields.

    hdr.set(key, value, comment)
Sets the value and comment for a key.  Note: This function is used internally, and not yet suited for use outside of the library.

    hdr.setComment(comment)
Sets a comment associated with the COMMENT key.  Note: This function is used internally, and not yet suited for use outside of the library.

    hdr.setHistory(history)
Sets a history associated with the HISTORY key.  Note: This function is used internally, and not yet suited for use outside of the library.

    hdr.contains(key)
Checks if a key is contained in the header instance.

    hdr.readCard(line)
Parses a string representing a single key, adding it to the instance.

    hdr.hasDataUnit()
Checks if the header has an associated data unit.

*More to come ...*

Examples
--------

    <script src="fits.js" type="text/javascript" charset="utf-8">
    </script>
    
    <script type="text/javascript">
      FITS = require('fits');
      
      // Get an array buffer of the FITS file using XHR
      var xhr = new XMLHttpRequest();
      xhr.open('GET', "[/path/to/fits/file]");
      
      // Set the response type to arraybuffer
      xhr.responseType = 'arraybuffer';
      
      // Define the onload function
      xhr.onload = function(e) {
          
          // Initialize the FITS.File object using
          // the array buffer returned from the XHR
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
      
    </script>

References
----------

Pence, W. D. Binary Table Extension To FITS.

Pence, W. D., L. Chiappetti, C. G. Page, R. a. Shaw, and E. Stobie. 2010. Definition of the Flexible Image Transport System ( FITS ), version 3.0. Astronomy & Astrophysics 524 (November 22): A42. doi:10.1051/0004-6361/201015362. http://www.aanda.org/10.1051/0004-6361/201015362.

Ponz, J.D., Thompson, R.W., Muñoz, J.R. The FITS Image Extension.

White, Richard L, Perry Greenfield, William Pence, Nasa Gsfc, Doug Tody, and Rob Seaman. 2011. Tiled Image Convention for Storing Compressed Images in FITS Binary Tables: 1-17.
