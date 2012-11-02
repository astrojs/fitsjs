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
      
      expect(row['RUN']).toBe(94)
      expect(row['RERUN']).toBe('301')
      expect(row['CAMCOL']).toBe(5)
      expect(row['FILTER']).toBe('r')
      expect(row['NODE']).toBeCloseTo(286.855205, precision)
      expect(row['INCL']).toBeCloseTo(0.009477, precision)
      expect(row['NAXIS'][0]).toBe(2048)
      expect(row['NAXIS'][1]).toBe(1489)
      expect(row['FIELD']).toBe(131)
      expect(row['A']).toBeCloseTo(354.390815336, precision)
      expect(row['B']).toBeCloseTo(0.00010995007974, precision)
      expect(row['C']).toBeCloseTo(-9.26176274637e-09, precision)
      expect(row['D']).toBeCloseTo(0.627071383277, precision)
      expect(row['E']).toBeCloseTo(1.71043815877e-08, precision)
      expect(row['F']).toBeCloseTo(0.000110028591677, precision)
      expect(row['DROW0']).toBeCloseTo(-0.0203976398036, precision)
      expect(row['DROW1']).toBeCloseTo(-5.13449819376e-05, precision)
      expect(row['DROW2']).toBeCloseTo(7.19458270897e-08, precision)
      expect(row['DROW3']).toBeCloseTo(-1.19736549738e-11, precision)
      expect(row['DCOL0']).toBeCloseTo(-0.0412158724848, precision)
      expect(row['DCOL1']).toBeCloseTo(0.000573034589514, precision)
      expect(row['DCOL2']).toBeCloseTo(-8.71818177838e-07, precision)
      expect(row['DCOL3']).toBeCloseTo(3.14935254059e-10, precision)
      expect(row['CSROW']).toBeCloseTo(-0.000351191274755, precision)
      expect(row['CSCOL']).toBeCloseTo(0.0213547138549, precision)
      expect(row['CCROW']).toBeCloseTo(-0.0351191274755, precision)
      expect(row['CCCOL']).toBeCloseTo(2.13547138549, precision)
      expect(row['RICUT']).toBeCloseTo(100.0, precision)
      expect(row['MJD']).toBeCloseTo(51075.2829609, precision)
      expect(row['AIRMASS']).toBeCloseTo(1.17920071906, precision)
      expect(row['MUERR']).toBeCloseTo(0.045941, precision)
      expect(row['NUERR']).toBeCloseTo(0.038667, precision)

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
      row = dataunit.getRow()
      
      expect(row['ALLSKY'][0]).toBeCloseTo(187.24862671, precision)
      expect(row['XINTERP'][0]).toBeCloseTo(-4.37500000e-01, precision)
      expect(row['YINTERP'][0]).toBeCloseTo(0.5625, 4)
      
          
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
      
      bitarray = row['status']
      expect(bitarray[0]).toEqual(1);
      expect(bitarray[31]).toEqual(0);

      row = dataunit.getRow()
      bitarray = row['status']
      expect(bitarray[1]).toEqual(1);
      expect(bitarray[31]).toEqual(0);