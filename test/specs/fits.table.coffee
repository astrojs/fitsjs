require = window.require

FITS = require("fits")

describe "FITS Table", ->

  it 'can read the column names', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/m101.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      table = fits.getDataUnit(1)
    
      names = ['XI', 'ETA', 'XI_CORR', 'ETA_CORR']
      for name, index in names
        expect(table.columns[index]).toEqual(name)

  it 'can read a FITS table', ->
    fits = null
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/m101.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    runs ->
      table = fits.getDataUnit(1)
      
      for i in [0..table.rows - 1]
        row = table.getRow()

        # Check the first row ...
        if i is 0
          expect(row[0]).toEqual(-3.12)
          expect(row[1]).toEqual(-3.12)
          expect(row[2]).toEqual(0)
          expect(row[3]).toEqual(0)
      
        # ... and a random row ...      
        if i is 800
          expect(row[0]).toEqual(-3.12)
          expect(row[1]).toEqual(0.08)
          expect(row[2]).toEqual(-0.59)
          expect(row[3]).toEqual(0.09)
        
      # ... and the last row
      expect(row[0]).toEqual(3.12)
      expect(row[1]).toEqual(3.12)
      expect(row[2]).toEqual(-0.20)
      expect(row[3]).toEqual(-0.07)
  
  it 'can fix a problem with 555mos', ->
    fits = null
    precision = 6
    
    xhr = new XMLHttpRequest()
    xhr.open('GET', 'data/555wmos.fits')
    xhr.responseType = 'arraybuffer'
    xhr.onload = -> fits = new FITS.File(xhr.response)
    xhr.send()
    
    waitsFor -> return fits?
    
    runs ->
      
      dataunit = fits.getDataUnit(1)
      row = dataunit.getRow()
      console.log row
      
      expect(row[0]).toBeCloseTo(67.691614473688006, 6)
      expect(row[1]).toBeCloseTo(64.864541508173005, 6)
      expect(row[2]).toBeCloseTo(386.5, 6)
      expect(row[3]).toBeCloseTo(396.0, 6)
      expect(row[4]).toBeCloseTo(2.7593111e-05, 6)
      expect(row[5]).toBeCloseTo(-1.591614e-06, 6)
      expect(row[6]).toBeCloseTo(-1.590081e-06, 6)
      expect(row[7]).toBeCloseTo(-2.7619741e-05, 6)
      expect(row[8]).toBeCloseTo(0.0, 6)
      expect(row[9]).toBeCloseTo(0.0, 6)
      expect(row[10]).toBe('T')
      expect(row[11]).toBeCloseTo(-175.7908, 6)
      expect(row[12]).toBeCloseTo(0, 6)
      expect(row[13]).toBeCloseTo(0, 6)
      expect(row[14]).toBeCloseTo(51107.40464341591, 6)
      expect(row[15]).toBeCloseTo(51107.404811239991, 6)
      expect(row[16]).toBe('RA---TAN')
      expect(row[17]).toBe('DEC--TAN')
      expect(row[18]).toBeCloseTo(4, 6)
      expect(row[19]).toBeCloseTo(310.9922, 4)
      expect(row[20]).toBeCloseTo(311.0368, 4)
      expect(row[21]).toBeCloseTo(310.9477, 4)
      expect(row[22]).toBeCloseTo(-1.677314, 6)
      expect(row[23]).toBeCloseTo(3652.070, 3)
      expect(row[24]).toBeCloseTo(8.1251163, 6)
      expect(row[25]).toBeCloseTo(558090, 6)
      expect(row[26]).toBeCloseTo(0, 6)
      expect(row[27]).toBeCloseTo(79828, 6)
      expect(row[28]).toBeCloseTo(0, 6)
      expect(row[29]).toBeCloseTo(134, 6)
      expect(row[30]).toBeCloseTo(0, 6)
      expect(row[31]).toBeCloseTo(0, 6)
      expect(row[32]).toBeCloseTo(0, 6)
      expect(row[33]).toBe('WFPC2,4,A2D7,F555W,,CAL')
      expect(row[34]).toBeCloseTo(3.5067081e-18, 6)
      expect(row[35]).toBeCloseTo(-21.1, 6)
      expect(row[36]).toBeCloseTo(5442.226, 3)
      expect(row[37]).toBeCloseTo(522.3256, 4)
      expect(row[38]).toBeCloseTo(5.009274, 6)
      expect(row[39]).toBeCloseTo(-11.75893, 6)
      expect(row[40]).toBeCloseTo(3.9197681, 6)
      expect(row[41]).toBeCloseTo(0.1215812, 6)
      expect(row[42]).toBeCloseTo(6.7609448, 6)
      expect(row[43]).toBeCloseTo(7.2739491, 6)
      expect(row[44]).toBeCloseTo(10.4921, 6)
      expect(row[45]).toBeCloseTo(10.83396, 6)
      expect(row[46]).toBeCloseTo(9.6577616, 6)
      expect(row[47]).toBeCloseTo(8.9342422, 6)
      expect(row[48]).toBeCloseTo(4.0813661, 6)
      
      
    