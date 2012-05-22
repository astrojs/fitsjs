(function() {
  var Fits;

  require('jDataView/src/jdataview');

  Fits = (function() {

    Fits.LINEWIDTH = 80;

    Fits.BLOCKLENGTH = 2880;

    Fits.headerPattern = /([A-Z0-9]+)\s*=?\s*([^\/]+)\s*\/?\s*(.*)/;

    Fits.BITPIX = [8, 16, 32, -32, -64];

    Fits.mandatoryKeywords = ['BITPIX', 'NAXIS', 'END'];

    function Fits(buffer) {
      this.length = buffer.byteLength;
      this.view = new jDataView(buffer, void 0, void 0, false);
      this.headers = [];
      this.dataunits = [];
      this.headerNext = true;
      this.eof = false;
      while (this.headerNext) {
        this.readHeader();
      }
      this.readData();
    }

    Fits.readCard = function(row, header) {
      var comment, key, match, value, _ref;
      match = row.match(Fits.headerPattern);
      _ref = match.slice(1), key = _ref[0], value = _ref[1], comment = _ref[2];
      return header[key] = value.trim();
    };

    Fits.excessChars = function(lines) {
      return Fits.BLOCKLENGTH - (lines * Fits.LINEWIDTH) % Fits.BLOCKLENGTH;
    };

    Fits.prototype.readHeader = function() {
      var bitpix, excess, header, i, keyword, line, linesRead, naxis, _i, _len, _ref;
      linesRead = 0;
      header = {};
      while (true) {
        line = this.view.getString(Fits.LINEWIDTH);
        Fits.readCard(line, header);
        linesRead += 1;
        if (line.slice(0, 3) === "END") break;
      }
      this.headers.push(header);
      _ref = Fits.mandatoryKeywords;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        keyword = _ref[_i];
        if (!header.hasOwnProperty(keyword)) {
          throw "FITS does not contain the required keyword " + keyword;
        }
      }
      naxis = parseInt(header["NAXIS"]);
      bitpix = parseInt(header["BITPIX"]);
      i = 1;
      while (i <= naxis) {
        if (!header.hasOwnProperty("NAXIS" + i)) {
          throw "FITS does not contain the required keyword NAXIS" + i;
        }
        i += 1;
      }
      this.headerNext = naxis === 0 ? true : false;
      excess = Fits.excessChars(linesRead);
      this.view.seek(Fits.LINEWIDTH * linesRead + excess);
      return this.checkEOF();
    };

    Fits.prototype.readData = function() {
      var bitpix, data, header, i, naxis, numberOfPixels;
      header = this.headers[this.headers.length - 1];
      bitpix = parseInt(header["BITPIX"]);
      switch (bitpix) {
        case 8:
          this.view.getData = this.view.getUint8;
          break;
        case 16:
          this.view.getData = this.view.getInt16;
          break;
        case 32:
          this.view.getData = this.view.getInt32;
          break;
        case -32:
          this.view.getData = this.view.getFloat32;
          break;
        case -64:
          this.view.getData = this.view.getFloat64;
          break;
        default:
          throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, -32, -64]";
      }
      data = [];
      naxis = parseInt(header["NAXIS"]);
      i = 1;
      numberOfPixels = 1;
      while (i <= naxis) {
        numberOfPixels *= parseInt(header["NAXIS" + i]);
        i += 1;
      }
      numberOfPixels;
      i = 0;
      while (numberOfPixels) {
        data.push(this.view.getData());
        numberOfPixels -= 1;
      }
      this.dataunits.push(data);
      return this.checkEOF();
    };

    Fits.prototype.checkEOF = function() {
      if (this.view.tell() === this.length) return this.eof = true;
    };

    return Fits;

  })();

  module.exports = Fits;

}).call(this);
