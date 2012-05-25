(function() {
  var BinTable, Data, FITS, File, HDU, Header, Image,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  require('jDataView/src/jdataview');

  Header = (function() {

    Header.keywordPattern = /([A-Z0-9]+)\s*=?\s*(.*)/;

    Header.nonStringPattern = /([^\/]*)\s*\/*(.*)/;

    Header.stringPattern = /'(.*)'\s*\/*(.*)/;

    Header.principalMandatoryKeywords = ['BITPIX', 'NAXIS', 'END'];

    Header.extensionKeywords = ['BITPIX', 'NAXIS', 'PCOUNT', 'GCOUNT'];

    Header.arrayKeywords = ['BSCALE', 'BZERO', 'BUNIT', 'BLANK', 'CTYPEn', 'CRPIXn', 'CRVALn', 'CDELTn', 'CROTAn', 'DATAMAX', 'DATAMIN'];

    Header.otherReservedKeywords = ['DATE', 'ORIGIN', 'BLOCKED', 'DATE-OBS', 'TELESCOP', 'INSTRUME', 'OBSERVER', 'OBJECT', 'EQUINOX', 'EPOCH', 'AUTHOR', 'REFERENC', 'COMMENT', 'HISTORY', 'EXTNAME', 'EXTVER', 'EXTLEVEL'];

    function Header() {
      this.cards = {};
      this.cardIndex = 0;
      this.primary = false;
      this.extension = false;
    }

    Header.prototype.get = function(key) {
      if (this.cards.hasOwnProperty(key)) {
        return this.cards[key];
      } else {
        return console.warn("Header does not contain the key " + key);
      }
    };

    Header.prototype.getIndex = function(key) {
      if (this.cards.hasOwnProperty(key)) {
        return this.cards[key][0];
      } else {
        return console.warn("Header does not contain the key " + key);
      }
    };

    Header.prototype.getValue = function(key) {
      if (this.cards.hasOwnProperty(key)) {
        return this.cards[key][1];
      } else {
        return console.warn("Header does not contain the key " + key);
      }
    };

    Header.prototype.getComment = function(key) {
      if (this.cards.hasOwnProperty(key)) {
        if (this.cards[key][2] != null) {
          return this.cards[key][2];
        } else {
          return console.warn("" + key + " does not contain a comment");
        }
      } else {
        return console.warn("Header does not contain the key " + key);
      }
    };

    Header.prototype.getComments = function() {
      if (this.cards.hasOwnProperty(key)) {
        return this.cards['COMMENT'];
      } else {
        return console.warn("Header does not contain any COMMENT fields");
      }
    };

    Header.prototype.getHistory = function() {
      if (this.cards.hasOwnProperty(key)) {
        return this.cards['HISTORY'];
      } else {
        return console.warn("Header does not contain any HISTORY fields");
      }
    };

    Header.prototype.set = function(key, value, comment) {
      if (comment) {
        this.cards[key] = [this.cardIndex, value, comment];
      } else {
        this.cards[key] = [this.cardIndex, value];
      }
      return this.cardIndex += 1;
    };

    Header.prototype.setComment = function(comment) {
      if (!this.cards.hasOwnProperty("COMMENT")) {
        this.cards["COMMENT"] = [];
        this.cardIndex += 1;
      }
      return this.cards["COMMENT"].push(comment);
    };

    Header.prototype.setHistory = function(history) {
      if (!this.cards.hasOwnProperty("HISTORY")) {
        this.cards["HISTORY"] = [];
        this.cardIndex += 1;
      }
      return this.cards["HISTORY"].push(history);
    };

    Header.prototype.readCard = function(line) {
      var comment, key, match, value, _ref, _ref2;
      match = line.match(Header.keywordPattern);
      _ref = match.slice(1), key = _ref[0], value = _ref[1];
      if (value[0] === "'") {
        match = value.match(Header.stringPattern);
      } else {
        match = value.match(Header.nonStringPattern);
      }
      _ref2 = match.slice(1), value = _ref2[0], comment = _ref2[1];
      switch (key) {
        case "COMMENT":
          return this.setComment(value.trim());
        case "HISTORY":
          return this.setHistory(value.trim());
        default:
          return this.set(key, value.trim(), comment.trim());
      }
    };

    Header.prototype.verify = function() {
      var axisIndex, cardIndex, keyword, keywords, naxisKeyword, type, _i, _len, _results;
      if (this.cards.hasOwnProperty("SIMPLE")) {
        type = "SIMPLE";
        this.primary = true;
        keywords = Header.principalMandatoryKeywords;
      } else {
        type = "XTENSION";
        this.extension = true;
        keywords = Header.extensionKeywords;
      }
      cardIndex = 0;
      if (this.getIndex(type) !== cardIndex) {
        console.warn("" + type + " should be the first keyword in the header");
        cardIndex -= 1;
      }
      cardIndex += 1;
      _results = [];
      for (_i = 0, _len = keywords.length; _i < _len; _i++) {
        keyword = keywords[_i];
        if (!this.cards.hasOwnProperty(keyword)) {
          throw "Header does not contain the required keyword " + keyword;
        }
        if (keyword === "END") {
          if (this.getIndex(keyword) !== this.cardIndex - 1) {
            console.warn("" + keyword + " is not in the correct order");
          }
        } else {
          if (this.getIndex(keyword) !== cardIndex) {
            console.warn("" + keyword + " is not in the correct order");
          }
        }
        cardIndex += 1;
        if (keyword === "NAXIS") {
          axisIndex = 1;
          _results.push((function() {
            var _results2;
            _results2 = [];
            while (axisIndex <= parseInt(this.getValue("NAXIS"))) {
              naxisKeyword = keyword + axisIndex;
              if (!this.cards.hasOwnProperty(naxisKeyword)) {
                throw "Header does not contain the required keyword " + naxisKeyword;
              }
              if (this.getIndex(naxisKeyword) !== cardIndex) {
                console.warn("" + naxisKeyword + " is not in the correct order");
              }
              cardIndex += 1;
              _results2.push(axisIndex += 1);
            }
            return _results2;
          }).call(this));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Header.prototype.hasDataUnit = function() {
      if (parseInt(this.getValue("NAXIS")) === 0) {
        return false;
      } else {
        return true;
      }
    };

    Header.prototype.isPrimary = function() {
      return this.primary;
    };

    Header.prototype.isExtension = function() {
      return this.extension;
    };

    return Header;

  })();

  Data = (function() {

    function Data(begin, header) {
      this.begin = begin;
    }

    return Data;

  })();

  Image = (function(_super) {

    __extends(Image, _super);

    function Image(begin, header) {
      var bitpix, i, naxis, numberOfPixels;
      Image.__super__.constructor.apply(this, arguments);
      naxis = parseInt(header.getValue("NAXIS"));
      bitpix = parseInt(header.getValue("BITPIX"));
      i = 1;
      numberOfPixels = 1;
      while (i <= naxis) {
        numberOfPixels *= parseInt(header.getValue("NAXIS" + i));
        i += 1;
      }
      this.length = numberOfPixels * Math.abs(bitpix) / 8;
      switch (bitpix) {
        case 8:
          this.accessor = 'getUint8';
          break;
        case 16:
          this.accessor = 'getInt16';
          break;
        case 32:
          this.accessor = 'getInt32';
          break;
        case -32:
          this.accessor = 'getFloat32';
          break;
        case -64:
          this.accessor = 'getFloat64';
          break;
        default:
          throw "FITS keyword BITPIX does not conform to one of the following set values [8, 16, 32, -32, -64]";
      }
    }

    return Image;

  })(Data);

  BinTable = (function(_super) {

    __extends(BinTable, _super);

    function BinTable(begin, header) {
      var naxis1, naxis2;
      BinTable.__super__.constructor.apply(this, arguments);
      naxis1 = parseInt(header.getValue("NAXIS1"));
      naxis2 = parseInt(header.getValue("NAXIS2"));
      console.log('naxis1', naxis1);
      console.log('naxis2', naxis2);
      this.length = naxis1 * naxis2;
    }

    return BinTable;

  })(Data);

  HDU = (function() {

    function HDU(header, data) {
      this.header = header;
      this.data = data;
    }

    return HDU;

  })();

  File = (function() {

    File.LINEWIDTH = 80;

    File.BLOCKLENGTH = 2880;

    File.BITPIX = [8, 16, 32, -32, -64];

    function File(buffer) {
      var data, hdu, header;
      this.length = buffer.byteLength;
      this.view = new jDataView(buffer, void 0, void 0, false);
      this.hdus = [];
      this.eof = false;
      while (true) {
        header = this.readHeader();
        console.log(header);
        data = this.readData(header);
        hdu = new HDU(header, data);
        this.hdus.push(hdu);
        if (this.eof) break;
      }
    }

    File.excessChars = function(lines) {
      return File.BLOCKLENGTH - (lines * File.LINEWIDTH) % File.BLOCKLENGTH;
    };

    File.prototype.readHeader = function() {
      var excess, header, line, linesRead;
      linesRead = 0;
      header = new Header();
      while (true) {
        line = this.view.getString(File.LINEWIDTH);
        linesRead += 1;
        header.readCard(line);
        if (line.slice(0, 3) === "END") break;
      }
      header.verify();
      excess = File.excessChars(linesRead);
      this.view.seek(File.LINEWIDTH * linesRead + excess);
      this.checkEOF();
      return header;
    };

    File.prototype.readData = function(header) {
      var data;
      if (!header.hasDataUnit()) return;
      if (header.isPrimary()) {
        data = new Image(this.view.tell(), header);
      } else {
        data = new BinTable(this.view.tell(), header);
      }
      this.view.seek(this.view.tell() + data.length);
      this.checkEOF();
      return data;
    };

    File.prototype.checkEOF = function() {
      if (this.view.tell() === this.length) return this.eof = true;
    };

    return File;

  })();

  FITS = this.FITS = {};

  if (typeof module !== "undefined" && module !== null) module.exports = FITS;

  FITS.version = '0.0.1';

  FITS.File = File;

  FITS.Header = Header;

  FITS.Data = Data;

  FITS.Image = Image;

  FITS.BinTable = BinTable;

}).call(this);
