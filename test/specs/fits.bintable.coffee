require = window.require

FITS = require("fits")

describe "FITS Binary Table", ->
  
  it 'can read a binary table with various data types', ->
    fits = null
    precision = 6
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bintable.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      dataunit = fits.getDataUnit()
      row = dataunit.getRow()
      
      expect(row[0]).toBe(94)
      expect(row[1]).toBe('301')
      expect(row[2]).toBe(5)
      expect(row[3]).toBe('r')
      expect(row[4]).toBeCloseTo(286.855205, precision)
      expect(row[5]).toBeCloseTo(0.009477, precision)
      expect(row[6][0]).toBe(2048)
      expect(row[6][1]).toBe(1489)
      expect(row[7]).toBe(131)
      expect(row[8]).toBeCloseTo(354.390815336, precision)
      expect(row[9]).toBeCloseTo(0.00010995007974, precision)
      expect(row[10]).toBeCloseTo(-9.26176274637e-09, precision)
      expect(row[11]).toBeCloseTo(0.627071383277, precision)
      expect(row[12]).toBeCloseTo(1.71043815877e-08, precision)
      expect(row[13]).toBeCloseTo(0.000110028591677, precision)
      expect(row[14]).toBeCloseTo(-0.0203976398036, precision)
      expect(row[15]).toBeCloseTo(-5.13449819376e-05, precision)
      expect(row[16]).toBeCloseTo(7.19458270897e-08, precision)
      expect(row[17]).toBeCloseTo(-1.19736549738e-11, precision)
      expect(row[18]).toBeCloseTo(-0.0412158724848, precision)
      expect(row[19]).toBeCloseTo(0.000573034589514, precision)
      expect(row[20]).toBeCloseTo(-8.71818177838e-07, precision)
      expect(row[21]).toBeCloseTo(3.14935254059e-10, precision)
      expect(row[22]).toBeCloseTo(-0.000351191274755, precision)
      expect(row[23]).toBeCloseTo(0.0213547138549, precision)
      expect(row[24]).toBeCloseTo(-0.0351191274755, precision)
      expect(row[25]).toBeCloseTo(2.13547138549, precision)
      expect(row[26]).toBeCloseTo(100.0, precision)
      expect(row[27]).toBeCloseTo(51075.2829609, precision)
      expect(row[28]).toBeCloseTo(1.17920071906, precision)
      expect(row[29]).toBeCloseTo(0.045941, precision)
      expect(row[30]).toBeCloseTo(0.038667, precision)

  it 'can read a binary table with various data types II', ->
    fits = null
    precision = 6

    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/allskytable.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()

    waitsFor -> return fits?

    runs ->
      dataunit = fits.getDataUnit()
      [allsky, xinterp, yinterp] = dataunit.getRow()
      
      expect(allsky[0]).toBeCloseTo(187.24862671, precision)
      expect(xinterp[0]).toBeCloseTo(-4.37500000e-01, precision)
      expect(yinterp[0]).toBeCloseTo(0.5625, 4)
      
          
  it 'can read a bit array', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/bit.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      dataunit = fits.getDataUnit()
      row = dataunit.getRow()
      
      bitarray = row[1]
      expect(bitarray[0]).toEqual(1);
      expect(bitarray[31]).toEqual(0);

      row = dataunit.getRow()
      bitarray = row[1]
      expect(bitarray[1]).toEqual(1);
      expect(bitarray[31]).toEqual(0);