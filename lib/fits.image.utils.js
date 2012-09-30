(function() {
  var ImageUtils;

  ImageUtils = {
    initArray: function(arrayType) {
      return this.data = new arrayType(this.width * this.height);
    },
    getExtremes: function() {
      var index, max, min, value, _ref, _ref2;
      if ((this.min != null) && (this.max != null)) return [this.min, this.max];
      index = this.data.length;
      while (index--) {
        value = this.data[index];
        if (isNaN(value)) continue;
        _ref = [value, value], min = _ref[0], max = _ref[1];
        break;
      }
      while (index--) {
        value = this.data[index];
        if (isNaN(value)) continue;
        if (value < min) min = value;
        if (value > max) max = value;
      }
      _ref2 = [min, max], this.min = _ref2[0], this.max = _ref2[1];
      return [this.min, this.max];
    },
    getPixel: function(x, y) {
      return this.data[y * this.width + x];
    }
  };

  if (typeof module !== "undefined" && module !== null) {
    module.exports = ImageUtils;
  }

}).call(this);
