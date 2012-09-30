(function() {
  var Table, Tabular,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Tabular = require('./fits.tabular');

  Table = (function(_super) {

    __extends(Table, _super);

    Table.formPattern = /([AIFED])(\d+)\.(\d+)/;

    Table.dataAccessors = {
      A: function(value) {
        return value;
      },
      I: function(value) {
        return parseInt(value);
      },
      F: function(value) {
        return parseFloat(value);
      },
      E: function(value) {
        return parseFloat(value);
      },
      D: function(value) {
        return parseFloat(value);
      }
    };

    function Table(view, header) {
      var form, i, match, _fn, _ref,
        _this = this;
      Table.__super__.constructor.apply(this, arguments);
      _fn = function() {
        var accessor, dataType, decimals, length, _ref2;
        _ref2 = match.slice(1), dataType = _ref2[0], length = _ref2[1], decimals = _ref2[2];
        accessor = function() {
          var i, value;
          value = "";
          for (i = 1; 1 <= length ? i <= length : i >= length; 1 <= length ? i++ : i--) {
            value += _this.view.getChar();
          }
          return Table.dataAccessors[dataType](value);
        };
        return _this.accessors.push(accessor);
      };
      for (i = 1, _ref = this.cols; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        form = header["TFORM" + i];
        match = form.match(Table.formPattern);
        _fn();
      }
    }

    return Table;

  })(Tabular);

  if (typeof module !== "undefined" && module !== null) module.exports = Table;

}).call(this);
