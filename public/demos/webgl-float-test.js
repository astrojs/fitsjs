FITS = require("fits")

$(document).ready(function() {
  var data, width, height, min, max, gl;
  main();
});

function main() {
  
    var xhr = new XMLHttpRequest();
    xhr.open('GET', "http://0.0.0.0:9294/data/m101.fits", true);
    xhr.responseType = 'arraybuffer';
    
    xhr.onload = function (e) {
      
      var fits = new FITS.File(xhr.response);
      data = fits.hdus[0].data.getFrameWebGL()
      width = fits.hdus[0].data.naxis[0];
      height = fits.hdus[0].data.naxis[1];
      var extremes = fits.hdus[0].data.getExtremes();
      min = extremes[0];
      max = extremes[1];
      
      setupUI(min, max);
      setupWebGL();
      
      var stretch = $("#stretch").val()
      render(width, height, stretch, min, max, data);
    };
    
    xhr.send();
}

function setupUI(min, max) {
  $( "#slider-range" ).slider({
    range: true,
    min: min,
    max: max,
    values: [min, max],
    slide: function( event, ui ) {
      console.log(event);
      var stretch = parseFloat($("#stretch").val());
      var extremes = ui.values;
      render(width, height, stretch, extremes[0], extremes[1], data);
    }
  });
  
  $("#stretch").change(function() {
    var stretch = $("#stretch").val();
    var extremes = $("#slider-range").slider("values");
    render(width, height, stretch, extremes[0], extremes[1], data);
  });
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
}