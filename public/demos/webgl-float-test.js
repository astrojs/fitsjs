FITS = require("fits")
require("fits.imageset")

$(document).ready(function() {
  var images;
  var data, width, height, min, max, gl;
  var program, fragmentShader;
  
  /*
  var xhr = new XMLHttpRequest();
  var file = "http://0.0.0.0:9294/data/Deep_32.fits"
  xhr.open('GET', file, true);
  xhr.responseType = 'arraybuffer'

  xhr.onload = function (e) {
    var fits = new FITS.File(xhr.response);
    var image = fits.hdus[0].data
    var data = image.getFrameWebGL();
    var extremes = image.getExtremes();
    width = fits.hdus[0].header["NAXIS1"];
    height = fits.hdus[0].header["NAXIS2"];
    
    setupUI(extremes[0], extremes[1]);
    setupWebGL();

    // images.addImage(fits);
    // if (images.getCount() == 5) {
    //   images.getExtremes();
    //   width = images.getWidth();
    //   height = images.getHeight();
    //   setupUI(images.minimum, images.maximum);
    //   setupWebGL();
    // }
  }
  xhr.send();
  */
  
  
  images = new FITS.ImageSet();
  
  filters = ['u', 'g', 'r', 'i', 'z'];
  for (var i = 0; i < filters.length; i += 1) {
    filename = "CFHTLS_03_" + filters[i] + "_sci.fits";
    requestImage(filename);
  }
  
  function requestImage(filename) {
    var xhr = new XMLHttpRequest();
    var file = "http://0.0.0.0:9294/data/CFHTLS/" + filename
    xhr.open('GET', file, true);
    xhr.responseType = 'arraybuffer';

    xhr.onload = function (e) {
      var fits = new FITS.File(xhr.response);
      images.addImage(fits);
      if (images.getCount() == 5) {
        images.getExtremes();
        width = images.getWidth();
        height = images.getHeight();
        setupUI(images.minimum, images.maximum);
        setupWebGL();
      }
    }
    xhr.send();
  }
  
  function setupWebGL() {
    var canvas = document.getElementById("canvas");

    gl = getWebGLContext(canvas);
    if (!gl) {
        alert("no WebGL");
        return;
    }

    var ext = gl.getExtension("OES_texture_float");
    if (!ext) {
        alert("no OES_texture_float");
        return;
    }
  }
  
  function activeFilters() {
    active = [];
    $(".filter-toggle").each(function(index, value) {
      var filter = $(value).data('filter');
      var id = $(value).attr('id');
      var selector = "label[for='" + id + "']";
      var pressed = $(selector).attr('aria-pressed');
      if (pressed === "true") {
        active.push(filter);
      }
    })
    return active;
  }
  
  function setupUI(min, max) {

    $("#canvas").attr("width", width);
    $("#canvas").attr("height", height);
    
    for (var key in images.images) {
      var id = key.replace(/[^a-zA-Z0-9]/g, "");
      var html = "<input type='checkbox' id='" + id + "' class='filter-toggle' data-filter='" + key + "' /><label for='" + id + "'>" + key + "</label>";
      $("#filter-toggle").append(html);
    }
    $("#filter-toggle").buttonset();
    
    $(".filter-toggle").click(function(e) {
      var active = activeFilters();
      if (active.length == 0) {
        $(this).attr('checked', true);
        var id = $(this).attr('id');
        var selector = "label[for='" + id + "']";
        $(selector).attr('aria-pressed', 'true').addClass('ui-state-active');
        return;
      }
      
      var self = this;
      $(".filter-toggle").each(function(index, value) {
        if ($(self).attr('id') != $(value).attr('id')) {
          $(this).attr('checked', false);
          var id = $(this).attr('id');
          var selector = "label[for='" + id + "']";
          $(selector).attr('aria-pressed', 'false').removeClass('ui-state-active');
        }
      });
      
      active = activeFilters();
      dataArray = [];
      for (var i = 0; i < active.length; i += 1)
        dataArray.push(images.getData(active[i]));
      console.log(dataArray);
      
      var stretch = $("#stretch").val();
      var extremes = $("#slider-range").slider("values");
      render(width, height, stretch, extremes[0], extremes[1], dataArray[0]);
    });
    
    $("#slider-range").slider({
      range: true,
      min: min,
      max: max,
      values: [min, max],
      slide: function (event, ui) {
        var stretch = $("#stretch").val();
        var extremes = ui.values;
        var extremesLocation = gl.getUniformLocation(program, "u_extremes");
        gl.uniform2f(extremesLocation, extremes[0], extremes[1]);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
      }
    });
    
    $(".ui-slider-horizontal").css("width", width);
    
    $("#stretch").change(function () {
      var stretch = $("#stretch").val();
      var extremes = $("#slider-range").slider("values");
      render(width, height, stretch, extremes[0], extremes[1], data);
    });
    
    $("#gri").click(function () {
      var extremes = $("#slider-range").slider("values");
      data_g = images.getData('g.MP9401');
      data_r = images.getData('r.MP9601');
      data_i = images.getData('i.MP9702');
      
      renderComposite(width, height, extremes[0], extremes[1], data_g, data_r, data_i);
    });
  }

  function renderColor(width, height, min, max, dataArray) {
    vertexShader = createShaderFromScriptElement(gl, "2d-vertex-shader");
    fragmentShader = createShaderFromScriptElement(gl, "2d-fragment-shader-color");
    program = createProgram(gl, [vertexShader, fragmentShader]);
    gl.useProgram(program);
    
    var positionLocation = gl.getAttribLocation(program, "a_position");
    var resolutionLocation = gl.getUniformLocation(program, "u_resolution");
    gl.uniform2f(resolutionLocation, width, height);
    
    var extremesLocation = gl.getUniformLocation(program, "u_extremes");
    gl.uniform2f(extremesLocation, min, max);
    
    var buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
         -1, -1, 1, -1, -1, 1,
         -1,  1, 1, -1,  1, 1]), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
    
    var textures = [];
    for (var i = 0; i < dataArray; i += 1) {
      gl.activeTexture(gl.TEXTURE0 + i);
      var texture = gl.createTexture();
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, dataArray[i]);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      
      var uData = gl.getUniformLocation(program, 'u_texture' + i);
      gl.uniform1i(uData_g, 0);
      textures.push(texture);
    }
    
  }

  function renderComposite(width, height, min, max, data_g, data_r, data_i) {
    
    vertexShader = createShaderFromScriptElement(gl, "2d-vertex-shader");
    fragmentShader = createShaderFromScriptElement(gl, "2d-fragment-shader-composite");
    program = createProgram(gl, [vertexShader, fragmentShader]);
    gl.useProgram(program);
    
    var positionLocation = gl.getAttribLocation(program, "a_position");
    var resolutionLocation = gl.getUniformLocation(program, "u_resolution");
    gl.uniform2f(resolutionLocation, width, height);
    
    var extremesLocation = gl.getUniformLocation(program, "u_extremes");
    gl.uniform2f(extremesLocation, min, max);
    
    var buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
         -1, -1, 1, -1, -1, 1,
         -1,  1, 1, -1,  1, 1]), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    gl.activeTexture(gl.TEXTURE0);
    var tex_g = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex_g);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, data_g);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    
    gl.activeTexture(gl.TEXTURE1);
    var tex_r = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex_r);    
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, data_r);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    
    gl.activeTexture(gl.TEXTURE2);
    var tex_i = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex_i);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, data_i);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    var uData_g = gl.getUniformLocation(program, 'u_tex_g');
    var uData_r = gl.getUniformLocation(program, 'u_tex_r');
    var uData_i = gl.getUniformLocation(program, 'u_tex_i');
    gl.uniform1i(uData_g, 0);
    gl.uniform1i(uData_r, 1);
    gl.uniform1i(uData_i, 2);

    gl.drawArrays(gl.TRIANGLES, 0, 6);
    console.log(gl.getError());
  }

  function render(width, height, stretch, min, max, data) {

    vertexShader = createShaderFromScriptElement(gl, "2d-vertex-shader");
    fragmentShader = createShaderFromScriptElement(gl, stretch);
    program = createProgram(gl, [vertexShader, fragmentShader]);
    gl.useProgram(program);

    var positionLocation = gl.getAttribLocation(program, "a_position");
    var resolutionLocation = gl.getUniformLocation(program, "u_resolution");
    gl.uniform2f(resolutionLocation, width, height);

    var extremesLocation = gl.getUniformLocation(program, "u_extremes");
    gl.uniform2f(extremesLocation, min, max);

    var buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
         -1, -1, 1, -1, -1, 1,
         -1,  1, 1, -1,  1, 1]), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(positionLocation);
    gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

    var tex = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, tex);

    gl.texImage2D(
        gl.TEXTURE_2D, 0, 
        gl.LUMINANCE, width, height, 0,
        gl.LUMINANCE, gl.FLOAT, data);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    gl.drawArrays(gl.TRIANGLES, 0, 6);
    console.log(gl.getError());
    // var dataTransfer = new Uint8Array(4 * width);
    // gl.readPixels(0, 0, width, 1, gl.RGBA, gl.UNSIGNED_BYTE, dataTransfer);
    // console.log(dataTransfer);
  }  
  
});

