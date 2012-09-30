(function() {
  var BinaryTable, Tabular,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Tabular = require('./fits.tabular');

  BinaryTable = (function(_super) {

    __extends(BinaryTable, _super);

    BinaryTable.dataTypePattern = /(\d*)([L|X|B|I|J|K|A|E|D|C|M])/;

    BinaryTable.arrayDescriptorPattern = /[0,1]*P([L|X|B|I|J|K|A|E|D|C|M])\((\d*)\)/;

    function BinaryTable(view, header) {
      var dataType, i, keyword, length, match, value, _ref, _ref2,
        _this = this;
      BinaryTable.__super__.constructor.apply(this, arguments);
      for (i = 1, _ref = this.cols; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        keyword = "TFORM" + i;
        value = header[keyword];
        match = value.match(BinaryTable.arrayDescriptorPattern);
        if (match != null) {
          (function() {
            var accessor, dataType;
            dataType = match[1];
            accessor = function() {
              var data, i, length, offset;
              length = _this.view.getInt32();
              offset = _this.view.getInt32();
              _this.current = _this.view.tell();
              _this.view.seek(_this.begin + _this.tableLength + offset);
              data = [];
              for (i = 1; 1 <= length ? i <= length : i >= length; 1 <= length ? i++ : i--) {
                data.push(BinaryTable.dataAccessors[dataType](_this.view));
              }
              _this.view.seek(_this.current);
              return data;
            };
            return _this.accessors.push(accessor);
          })();
        } else {
          match = value.match(BinaryTable.dataTypePattern);
          _ref2 = match.slice(1), length = _ref2[0], dataType = _ref2[1];
          length = length ? parseInt(length) : 0;
          if (length === 0 || length === 1) {
            (function(dataType) {
              var accessor;
              accessor = function() {
                var data;
                data = BinaryTable.dataAccessors[dataType](_this.view);
                return data;
              };
              return _this.accessors.push(accessor);
            })(dataType);
          } else {
            (function(dataType) {
              var accessor;
              if (dataType === 'X') {
                length = Math.log(length) / Math.log(2);
                accessor = function() {
                  var byte2bits, data, i;
                  byte2bits = function(byte) {
                    var bitarray;
                    bitarray = [];
                    i = 128;
                    while (i >= 1) {
                      bitarray.push((byte & i ? 1 : 0));
                      i /= 2;
                    }
                    return bitarray;
                  };
                  data = [];
                  for (i = 0; 0 <= length ? i <= length : i >= length; 0 <= length ? i++ : i--) {
                    data.push(_this.view.getUint8());
                  }
                  return data;
                };
              } else {
                accessor = function() {
                  var data, i;
                  data = [];
                  for (i = 1; 1 <= length ? i <= length : i >= length; 1 <= length ? i++ : i--) {
                    data.push(BinaryTable.dataAccessors[dataType](_this.view));
                  }
                  return data;
                };
              }
              return _this.accessors.push(accessor);
            })(dataType);
          }
        }
      }
    }

    return BinaryTable;

  })(Tabular);

  if (typeof module !== "undefined" && module !== null) {
    module.exports = BinaryTable;
  }

}).call(this);
