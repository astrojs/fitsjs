FITS = require("fits")

$(document).ready(function() {
  main();
});


function main() {
  var xhr = new XMLHttpRequest();
  xhr.open('GET', "http://0.0.0.0:9294/data/m101.fits", true);
  xhr.responseType = 'arraybuffer';
  
  xhr.onload = function (e) {
    var image;
    var fits = new FITS.File(xhr.response);
    
    // fits.hdus[0].data.initArray();
    // fits.hdus[0].data.getFrame();
    // var data = fits.hdus[0].data.data;
    
    var data = fits.hdus[0].data.getFrameWebGL()
    var width = fits.hdus[0].data.naxis[0];
    var height = fits.hdus[0].data.naxis[1];
    
    // Find the min and max pixels in the file
    var minOrig;
    var maxOrig;
    for (var i = 0; i < data.length; i += 1) {
      value = data[i];
      if (isNaN(value))
        continue
      minOrig = data[i];
      maxOrig = data[i];
      break
    }

    for (var i = 0; i < data.length; i += 1) {
      value = data[i];

      if (isNaN(value))
        continue
      if (value < minOrig)
        min = value;
      if (value > maxOrig)
        maxOrig = value;
    }
    
    render(data, width, height, minOrig, maxOrig, 0);
    
    $("#min-slider").change(function() {
      min = $("#min-slider").val();
      max = $("#max-slider").val();
      stretch = $("#stretch").val();
      
      min = toOriginal(min, minOrig, maxOrig);
      render(data, width, height, min, maxOrig, stretch);
      
    });

    $("#max-slider").change(function() {
      min = $("#min-slider").val();
      max = $("#max-slider").val();
      stretch = $("#stretch").val();
      
      max = toOriginal(max, minOrig, maxOrig);
      render(data, width, height, minOrig, max, stretch);
    });
    
    $("#stretch").change(function() {
      min = $("#min-slider").val();
      max = $("#max-slider").val();
      stretch = $("#stretch").val();
      
      render(data, width, height, minOrig, max, stretch);
    });
    
  }
  xhr.send();
}

function toOriginal(value, min, max) {
  return value * (max - min) / 255 + min;
}

function linear (value) {
  return value;
}

function log10 (value) {
  return Math.log(value) / Math.log(10);
}

function logarithm (value) {
  midpoint = 0.05
  return log10(value / midpoint + 1.) / log10(1. / midpoint + 1.);
}

function sqrt (value) {
  return Math.sqrt(value);
}

function arcsinh (value) {
  return Math.log(value + Math.sqrt(1 + value * value));
}

function power (value) {
  return Math.pow(value, 2);
}

function render(data, width, height, min, max, mapping) {
  // Get A WebGL context
  var canvas = document.getElementById("fitsbaby");
  canvas.width = width;
  canvas.height = height;
  
  var buffer = document.createElement('canvas');
  var gl = getWebGLContext(canvas);
  var context = buffer.getContext("2d")

  if (!gl) {
    return;
  }
  
  // Map to 8 bit integer space
  var image = context.createImageData(canvas.width, canvas.height);
  var index;
  
  var stretch = [linear, logarithm, sqrt, arcsinh, power];
  mapping = parseInt(mapping);
  min = stretch[mapping](min);
  max = stretch[mapping](max);
  
  for (var i = 0; i < image.data.length; i += 4) {
    index = i / 4;
    value = data[index];
    value = stretch[mapping](value);

    image.data[i] = 255 * (value - min) / (max - min);
    image.data[i+1] = 255 * (value - min) / (max - min);
    image.data[i+2] = 255 * (value - min) / (max - min);
    image.data[i+3] = 255;
  }

  // Setup GLSL program
  vertexShader = createShaderFromScriptElement(gl, "2d-vertex-shader");
  fragmentShader = createShaderFromScriptElement(gl, "2d-fragment-shader");
  program = createProgram(gl, [vertexShader, fragmentShader]);
  gl.useProgram(program);

  // Look up where the vertex data needs to go
  var positionLocation = gl.getAttribLocation(program, "a_position");
  var texCoordLocation = gl.getAttribLocation(program, "a_texCoord");

  // provide texture coordinates for the rectangle.
  var texCoordBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, texCoordBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
      0.0,  0.0,
      1.0,  0.0,
      0.0,  1.0,
      0.0,  1.0,
      1.0,  0.0,
      1.0,  1.0]), gl.STATIC_DRAW);
  gl.enableVertexAttribArray(texCoordLocation);
  gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, 0);

  //
  //  TESTING: passing pixels to WebGL buffer
  //


  var texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, texture);
  
  // void texImage2D(
  //     GLenum target,
  //     GLint level,
  //     GLenum internalformat,
  //     GLsizei width,
  //     GLsizei height,
  //     GLint border,
  //     GLenum format,
  //     GLenum type,
  //     ArrayBufferView? pixels
  //   )
  
  // void texImage2D(GLenum target, GLint level, GLenum internalformat,
  //                 GLenum format, GLenum type, ImageData? pixels);
  
  // gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  
  var width = 64;
  var height = 64;
  var pixels = new Float32Array(width * height);
  for (var y = 0; y < height; ++y) {
      for (var x = 0; x < width; ++x) {
          var offset = y * width + x;
          pixels[offset] = (x / width + y / height) * 0.5;
      }
  }
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, pixels);
  
  // gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, width, height, 0, gl.LUMINANCE, gl.FLOAT, data);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

  // Lookup uniforms
  var resolutionLocation = gl.getUniformLocation(program, "u_resolution");
  var textureSizeLocation = gl.getUniformLocation(program, "u_textureSize");

  // Set the resolution
  gl.uniform2f(resolutionLocation, canvas.width, canvas.height);

  // Set the size of the image
  gl.uniform2f(textureSizeLocation, image.width, image.height);

  // Create a buffer for the position of the rectangle corners.
  var positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

  // Set a rectangle the same size as the image.
  setRectangle(gl, 0, 0, image.width, image.height);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
}

function setRectangle(gl, x, y, width, height) {
  var x1 = x;
  var x2 = x + width;
  var y1 = y;
  var y2 = y + height;
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
     x1, y1,
     x2, y1,
     x1, y2,
     x1, y2,
     x2, y1,
     x2, y2]), gl.STATIC_DRAW);
}