
describe "Feature Test", ->
  
  it 'can initialize typed arrays using buffers', ->
    
    method1 = (buffer) ->
      img = new Uint16Array(buffer)
      length = img.length
      for index in [0..length-1]
        value = img[index]
        img[index] = (((value & 0xFF) << 8) | ((value >> 8) & 0xFF))
      
      return img
    
    method2 = (buffer) ->
      view = new DataView(buffer)
      pixels = buffer.byteLength / 2
      img = new Uint16Array(pixels)
      for value, index in img
        img[index] = view.getInt16(2 * index)
      
      return img
      
    buffer = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/m101.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> buffer = xhr.response
    xhr.send()
    
    waitsFor -> return buffer?
    
    runs ->
      
      width = 891
      height = 893
      
      begin = 14400
      end = begin + 2 * width * height
      imgBuffer1 = buffer.slice(begin, end)
      imgBuffer2 = buffer.slice(begin, end)
      
      s1 = new Date().getTime()
      img1 = method1(imgBuffer1)
      e1 = new Date().getTime()
      
      s2 = new Date().getTime()
      img2 = method2(imgBuffer2)
      e2 = new Date().getTime()
      
      console.log img1[0], (e1 - s1)
      console.log img2[0], (e2 - s2)
      
      # This interprets bytes in little endian format
      # img = new Uint16Array(imgBuffer)
      # 
      # # This interprets bytes in big endian format
      # view = new DataView(imgBuffer)
      # pixels = width * height
      # imgarr = new Uint16Array(pixels)
      # for i in [0..pixels-1]
      #   imgarr[i] = view.getInt16(2 * i)
      