(function() {
  var Fits;

  Fits = (function() {

    Fits.LINEWIDTH = 80;

    Fits.BLOCKLENGTH = 2880;

    function Fits(buffer) {
      this.view = new jDataView(buffer, void 0, void 0, false);
      this.hdus = {};
    }

    Fits.prototype.parseHeaders = function() {
      var bitpix, columns, excess, headerString, key, line, linesRead, rows, value, _ref;
      linesRead = 0;
      headerString = "";
      while (true) {
        line = this.view.getString(this.LINEWIDTH);
        headerString += line;
        linesRead += 1;
        _ref = line.split("="), key = _ref[0], value = _ref[1];
        if (key.match("BITPIX")) bitpix = Fits.readCard(value, 'int');
        if (key.match("NAXIS1")) columns = Fits.readCard(value, 'int');
        if (key.match("NAXIS2")) rows = Fits.readCard(value, 'int');
        if (line.slice(0, 3) === "END") break;
      }
      excess = Fits.excessChars(linesRead);
      return this.view.seek(this.LINEWIDTH * linesRead + excess);
    };

    Fits.readCard = function(str) {
      var card, key, line, value;
      card = {};
      line = line.split('=');
      key = line[0].trim();
      card['key'] = key;
      card['data'] = {};
      if (line[1] != null) {
        value = line[1];
        value = value.split('/');
        card['data']['value'] = value[0].trim();
        if (value[1] != null) card['data']['comment'] = value[1].trim();
      }
      return card;
    };

    Fits.excessChars = function(lines) {
      return this.BLOCKLENGTH - (lines * this.LINEWIDTH) % this.BLOCKLENGTH;
    };

    return Fits;

  })();

  window.Fits = Fits;

}).call(this);
