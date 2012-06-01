$(document).ready(function() {
  main();
});


function main() {
  var xhr = new XMLHttpRequest();
  // xhr.open('GET', "http://0.0.0.0:9294/data/L1448_13CO.fits", true);
  xhr.open('GET', "http://0.0.0.0:9294/data/m101.fits", true);
  xhr.responseType = 'arraybuffer';
  
  xhr.onload = function (e) {
    var image;
    var fits = new FITS.File(xhr.response);
    
    fits.hdus[0].data.initArray();
    fits.hdus[0].data.getFrame();
    var data = fits.hdus[0].data.data;
    // console.log(data);
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
    
    render(data, width, height, minOrig, maxOrig);
    
    $("#min-slider").change(function() {
      min = $("#min-slider").val();
      max = $("#max-slider").val();
      
      min = toOriginal(min, minOrig, maxOrig);
      render(data, width, height, min, maxOrig);
      
    });

    $("#max-slider").change(function() {
      min = $("#min-slider").val();
      max = $("#max-slider").val();

      max = toOriginal(max, minOrig, maxOrig);
      render(data, width, height, minOrig, max);
    });
    
    
    
  }
  xhr.send();
}

function toOriginal(value, min, max) {
  return value * (max - min) / 255 + min;
}

function arcsinh(value) {
  return Math.log(value + Math.sqrt(1 + value * value));
}

function render(data, width, height, min, max) {
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
  var midpoint = -0.033
  
  // min = arcsinh(min / midpoint) / arcsinh(1. / midpoint);
  // max = arcsinh(max / midpoint) / arcsinh(1. / midpoint);
  
  for (var i = 0; i < image.data.length; i += 4) {
    index = i / 4;
    value = data[index];
    // value = arcsinh(value / midpoint) / arcsinh(1. / midpoint);

    image.data[i] = 255 * (value - min) / (max - min);
    image.data[i+1] = 255 * (value - min) / (max - min);
    image.data[i+2] = 255 * (value - min) / (max - min);
    image.data[i+3] = 255;
  }

  // setup GLSL program
  vertexShader = createShaderFromScriptElement(gl, "2d-vertex-shader");
  fragmentShader = createShaderFromScriptElement(gl, "2d-fragment-shader");
  program = createProgram(gl, [vertexShader, fragmentShader]);
  gl.useProgram(program);

  // look up where the vertex data needs to go.
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

  var texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

  // lookup uniforms
  var resolutionLocation = gl.getUniformLocation(program, "u_resolution");
  var textureSizeLocation = gl.getUniformLocation(program, "u_textureSize");
  var kernelLocation = gl.getUniformLocation(program, "u_kernel[0]");

  // set the resolution
  gl.uniform2f(resolutionLocation, canvas.width, canvas.height);

  // set the size of the image
  gl.uniform2f(textureSizeLocation, image.width, image.height);

  // Define several convolution kernels
  var kernels = {
    normal: [
      0, 0, 0,
      0, 1, 0,
      0, 0, 0
    ]
  };

  // Create a buffer for the position of the rectangle corners.
  var positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.enableVertexAttribArray(positionLocation);
  gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

  // Set a rectangle the same size as the image.
  setRectangle( gl, 0, 0, image.width, image.height);

  drawWithKernel('normal');

  function drawWithKernel(name) {
    // set the kernel
    gl.uniform1fv(kernelLocation, kernels[name]);

    // Draw the rectangle.
    gl.drawArrays(gl.TRIANGLES, 0, 6);
  }
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