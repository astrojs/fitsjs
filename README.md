fitsjs
======

A standalone JavaScript library for reading the astronomical file format – FITS.  This library is built for modern browsers supporting the DataView object.  These include at least Chrome 9, Firefox 15, and Safari 6.

To use the library copy lib/fits.js to your project and include it using a script tag.  After including the library, the FITS object is exposed by calling require.

    <script src="fits.js" type="text/javascript" charset="utf-8">
    </script>
    
    <script type="text/javascript">
      FITS = require('fits');
    </script>

This library may be used to read various forms of the FITS format.  This implementation is under active development.  In its current state it supports the following:

* Reading of multiple header data units
* Reading of FITS images
* Reading of data cubes
* Reading of binary tables
* Reading of ASCII Tables
* Decompressing images using the Rice algorithm

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


Notes
-----
Currently rendering data as WebGL textures requires the use of Uint8 arrays or Float32 arrays.  Declare the data type:

    var dataType = gl.UNSIGNED_BYTE;  # for Uint8 (BITPIX = 8)
    var dataType = gl.FLOAT;          # for Uint16, Float32 (BITPIX 16, 32, -32)
    
    # Set parameters and data to texture
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, dataType, pixels);

Documentation at [Khronos](http://www.khronos.org/registry/webgl/specs/latest/#5.14.8) states the following are supported formats, however they do not appear to render when used as textures.

  * gl.UNSIGNED_BYTE (Uint8Array)
  * gl.UNSIGNED_SHORT_5_6_5 (Uint16Array)
  * gl.UNSIGNED_SHORT_4_4_4_4 (Uint16Array)
  * gl.UNSIGNED_SHORT_5_5_5_1 (Uint16Array)
  * gl.FLOAT (Float32Array)