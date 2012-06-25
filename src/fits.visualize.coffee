# Helper class for initializng a WebGL viewer for a FITS image
class Visualize
  @GET_A_WEBGL_BROWSER = '' + 'This page requires a browser that supports WebGL.<br/>' + '<a href="http://get.webgl.org">Click here to upgrade your browser.</a>'
  @OTHER_PROBLEM = '' + "It doesn't appear your computer can support WebGL.<br/>" + '<a href="http://get.webgl.org/troubleshooting/">Click here for more information.</a>'

  # WebGL Vertex Shader
  @vertexShader = [
    "attribute vec2 a_position;",
    "void main() {",
        "gl_Position = vec4(a_position, 0, 1);",
    "}"
  ].join("\n")

  # WebGL Fragment Shaders
  @fragmentShaders =
    linear: [
      "precision mediump float;",
      
      "uniform vec2 u_resolution;",
      "uniform sampler2D u_tex;",
      "uniform vec2 u_extremes;",
      
      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v = texture2D(u_tex, texCoord);",
      
          "float min = u_extremes[0];",
          "float max = u_extremes[1];",
          "float pixel = (pixel_v[0] - min) / (max - min);",
      
          "gl_FragColor = vec4(pixel, pixel, pixel, 1.0);",
      "}"
    ].join("\n")
    logarithm: [
      "precision mediump float;"
      "uniform vec2 u_resolution;"
      "uniform sampler2D u_tex;"
      "uniform vec2 u_extremes;"

      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v = texture2D(u_tex, texCoord);",

          "float min = log(u_extremes[0]);",
          "float max = log(u_extremes[1]);",

          "float pixel = (log(pixel_v[0]) - min) / (max - min);",

          "gl_FragColor = vec4(pixel, pixel, pixel, 1.0);",
      "}"
    ].join("\n")
    sqrt: [
      "precision mediump float;",
      "uniform vec2 u_resolution;",
      "uniform sampler2D u_tex;",
      "uniform vec2 u_extremes;",

      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v = texture2D(u_tex, texCoord);",

          "float min = sqrt(u_extremes[0]);",
          "float max = sqrt(u_extremes[1]);",

          "float pixel = (sqrt(pixel_v[0]) - min) / (max - min);",

          "gl_FragColor = vec4(pixel, pixel, pixel, 1.0);",
      "}"
    ].join("\n")
    arcsinh: [
      "precision mediump float;",
      "uniform vec2 u_resolution;",
      "uniform sampler2D u_tex;",
      "uniform vec2 u_extremes;",

      "float arcsinh(float value) {",
          "return log(value + sqrt(1.0 + value * value));",
      "}",

      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v = texture2D(u_tex, texCoord);",

          "float min = arcsinh(u_extremes[0]);",
          "float max = arcsinh(u_extremes[1]);",
          "float value = arcsinh(pixel_v[0]);",

          "float pixel = (value - min) / (max - min);",

          "gl_FragColor = vec4(pixel, pixel, pixel, 1.0);",
      "}"
    ].join("\n")
    power: [
      "precision mediump float;",
      "uniform vec2 u_resolution;",
      "uniform sampler2D u_tex;",
      "uniform vec2 u_extremes;",

      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v = texture2D(u_tex, texCoord);",

          "float min = pow(u_extremes[0], 2.0);",
          "float max = pow(u_extremes[1], 2.0);",

          "float pixel = (pow(pixel_v[0], 2.0) - min) / (max - min);",

          "gl_FragColor = vec4(pixel, pixel, pixel, 1.0);",
      "}"
    ].join("\n")
    color: [
      "precision mediump float;",
      "uniform vec2 u_resolution;",

      "uniform sampler2D u_tex_g;",
      "uniform sampler2D u_tex_r;",
      "uniform sampler2D u_tex_i;",
      "uniform vec2 u_extremes;",

      "float arcsinh(float value) {",
          "return log(value + sqrt(1.0 + value * value));",
      "}",

      "float f(float minimum, float maximum, float value) {",
          "float pixel = clamp(value, minimum, maximum);",
          "float alpha = 0.02;",
          "float Q = 8.0;",
          "return arcsinh(alpha * Q * (pixel - minimum)) / Q;",
      "}",

      "void main() {",
          "vec2 texCoord = gl_FragCoord.xy / u_resolution;",
          "vec4 pixel_v_g = texture2D(u_tex_g, texCoord);",
          "vec4 pixel_v_r = texture2D(u_tex_r, texCoord);",
          "vec4 pixel_v_i = texture2D(u_tex_i, texCoord);",

          "float minimum = u_extremes[0];",
          "float maximum = u_extremes[1];",
          "float g = pixel_v_g[0];",
          "float r = pixel_v_r[0];",
          "float i = pixel_v_i[0];",
          "float I = (g + r + i) / 3.0;",
          "float fI = f(minimum, maximum, I);",
          "float fII = fI / I;",

          "float R = i * fII;",
          "float G = r * fII;",
          "float B = g * fII;",

          "float RGBmax = max(max(R, G), B);",

          "if (RGBmax > 1.0) {",
            "R = R / RGBmax;",
            "G = G / RGBmax;",
            "B = B / RGBmax;",
          "}",
          "if (I == 0.0) {",
            "R = 0.0;",
            "G = 0.0;",
            "B = 0.0;",
          "}",

          "gl_FragColor = vec4(R, G, B, 1.0);",
      "}"
    ].join("\n")
  
  # Initializes the Visualize object and starts a WebGL program
  constructor: (@imgset, @el) ->
    @imgset.getExtremes()
    @width    = @imgset.getWidth()
    @height   = @imgset.getHeight()
    @minimum  = @imgset.minimum
    @maximum  = @imgset.maximum
    @setupUI(@width, @height)

    @gl = @setupWebGL()
    unless @gl
      alert "No WebGL"
      return null
    
    @ext = @gl.getExtension("OES_texture_float")
    unless @ext
      alert "No OES_texture_float"
      return null

    vertexShader    = @loadShader(Visualize.vertexShader, @gl.VERTEX_SHADER)
    @fragmentShader  = @loadShader(Visualize.fragmentShaders["linear"], @gl.FRAGMENT_SHADER)
    @createProgram([vertexShader, @fragmentShader])
    @gl.useProgram(@program)
    
    positionLocation    = @gl.getAttribLocation(@program, "a_position")
    resolutionLocation  = @gl.getUniformLocation(@program, "u_resolution")
    @stretchLocation    = @gl.getUniformLocation(@program, "u_stretch")
    @gl.uniform2f(resolutionLocation, @width, @height)

    @extremesLocation = @gl.getUniformLocation(@program, "u_extremes")
    @gl.uniform2f(@extremesLocation, @minimum, @maximum)

    buffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, buffer)
    @gl.bufferData(@gl.ARRAY_BUFFER, new Float32Array([
         -1, -1, 1, -1, -1, 1,
         -1,  1, 1, -1,  1, 1]), @gl.STATIC_DRAW)
    @gl.enableVertexAttribArray(positionLocation)
    @gl.vertexAttribPointer(positionLocation, 2, @gl.FLOAT, false, 0, 0)

    tex = @gl.createTexture()
    @gl.bindTexture(@gl.TEXTURE_2D, tex)
    
    @gl.texImage2D(@gl.TEXTURE_2D, 0, @gl.LUMINANCE, @width, @height, 0, @gl.LUMINANCE, @gl.FLOAT, @imgset[3].getHDU().data.getFrameWebGL())
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.NEAREST)
    @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.NEAREST)

    @gl.drawArrays(@gl.TRIANGLES, 0, 6)
    console.log(@gl.getError())

  setupWebGL: (opt_attribs) ->
    
    showLink = (str) ->
      container = @canvas.parentNode
      if container
        container.innerHTML = @makeFailHTML(str)
    
    unless window.WebGLRenderingContext
      showLink(Visualize.GET_A_WEBGL_BROWSER)
      return null
    
    context = @create3DContext(@canvas, opt_attribs)
    showLink(Visualize.OTHER_PROBLEM) unless context
    
    return context
  
  create3DContext: (opt_attribs) ->
    names = ["webgl", "experimental-webgl"]
    context = null
    
    for name, index in names
      try
        context = @canvas.getContext(name, opt_attribs)
      catch e
      break if (context)
    
    return context

  makeFailHTML: (msg) ->
    return '' +
      '<table style="background-color: #8CE; width: 100%; height: 100%;"><tr>' +
      '<td align="center">' +
      '<div style="display: table-cell; vertical-align: middle;">' +
      '<div style="">' + msg + '</div>' +
      '</div>' +
      '</td></tr></table>'

  createProgram: (shaders, opt_attribs, opt_locations) ->
    @program = @gl.createProgram()
    
    @gl.attachShader(@program, shader) for shader, index in shaders
    
    if opt_attribs?
      for attribute, index in opt_attribs
        options = if opt_locations? then opt_locations[index] else index
        @gl.bindAttribLocation(@program, options, attribute)
    @gl.linkProgram(@program)

    # Check the link status
    linked = @gl.getProgramParameter(@program, @gl.LINK_STATUS)
    unless linked
      throw "Error in program linking: #{@gl.getProgramInfoLog(@program)}"
      @gl.deleteProgram(@program)
      return null
  
  loadShader: (shaderSource, shaderType) ->
    
    # Create, load and compile the shader object
    shader = @gl.createShader(shaderType)
    @gl.shaderSource(shader, shaderSource)
    @gl.compileShader(shader)

    # Check the compile status
    compiled = @gl.getShaderParameter(shader, @gl.COMPILE_STATUS)
    
    unless compiled
      # Something went wrong during compilation
      lastError = @gl.getShaderInfoLog(shader)
      throw "Error compiling shader #{shader}: #{lastError}"
      @gl.deleteShader(shader)
      return null
    
    return shader

  setupUI: (width, height) ->
    parent = document.createElement("div")
    parent.setAttribute("class", "fits-viewer")
    
    @canvas = document.createElement("canvas")
    @canvas.setAttribute("width", width)
    @canvas.setAttribute("height", height)
    
    @el.appendChild(parent)
    parent.appendChild(@canvas)
  
  # Scale the image according to minimum and maximum arguments
  scale: (minimum, maximum) ->
    @gl.uniform2f(@extremesLocation, minimum, maximum)
    @gl.drawArrays(@gl.TRIANGLES, 0, 6)
    
  # Apply a stretch to the image.  Valid arguments include: linear, logarithm, sqrt, arcsinh, power, color
  stretch: (value) ->
    @gl.detachShader(@program, @fragmentShader)
    @gl.deleteShader(@fragmentShader)
    
    @fragmentShader = @loadShader(Visualize.fragmentShaders[value], @gl.FRAGMENT_SHADER)
    @gl.attachShader(@program, @fragmentShader)
    @gl.drawArrays(@gl.TRIANGLES, 0, 6)
    
    

module?.exports = Visualize