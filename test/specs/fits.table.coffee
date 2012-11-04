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
      
      # Read the first row
      row = table.getRow()
      
      expect(row['XI']).toEqual(-3.12)
      expect(row['ETA']).toEqual(-3.12)
      expect(row['XI_CORR']).toEqual(0)
      expect(row['ETA_CORR']).toEqual(0)
      
      # Read the first row again by passing an argument
      row = table.getRow(0)
      expect(row['XI']).toEqual(-3.12)
      expect(row['ETA']).toEqual(-3.12)
      expect(row['XI_CORR']).toEqual(0)
      expect(row['ETA_CORR']).toEqual(0)
      
      # Read the 801th row
      row = table.getRow(800)
      expect(row['XI']).toEqual(-3.12)
      expect(row['ETA']).toEqual(0.08)
      expect(row['XI_CORR']).toEqual(-0.59)
      expect(row['ETA_CORR']).toEqual(0.09)
      
      # Read the last row
      lastrow = table.rows - 1
      row = table.getRow(lastrow)
      expect(row['XI']).toEqual(3.12)
      expect(row['ETA']).toEqual(3.12)
      expect(row['XI_CORR']).toEqual(-0.20)
      expect(row['ETA_CORR']).toEqual(-0.07)
  
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
      
      expect(row.CRVAL1).toBeCloseTo(67.691614473688006, 6)
      expect(row.CRVAL2).toBeCloseTo(64.864541508173005, 6)
      expect(row.CRPIX1).toBeCloseTo(386.5, 6)
      expect(row.CRPIX2).toBeCloseTo(396.0, 6)
      expect(row.CD1_1).toBeCloseTo(2.7593111e-05, 6)
      expect(row.CD1_2).toBeCloseTo(-1.591614e-06, 6)
      expect(row.CD2_1).toBeCloseTo(-1.590081e-06, 6)
      expect(row.CD2_2).toBeCloseTo(-2.7619741e-05, 6)
      expect(row.DATAMIN).toBeCloseTo(0.0, 6)
      expect(row.DATAMAX).toBeCloseTo(0.0, 6)
      expect(row.MIR_REVR).toBe('T')
      expect(row.ORIENTAT).toBeCloseTo(-175.7908, 6)
      expect(row.FILLCNT).toBeCloseTo(0, 6)
      expect(row.ERRCNT).toBeCloseTo(0, 6)
      expect(row.FPKTTIME).toBeCloseTo(51107.40464341591, 6)
      expect(row.LPKTTIME).toBeCloseTo(51107.404811239991, 6)
      expect(row.CTYPE1).toBe('RA---TAN')
      expect(row.CTYPE2).toBe('DEC--TAN')
      expect(row.DETECTOR).toBeCloseTo(4, 6)
      expect(row.DEZERO).toBeCloseTo(310.9922, 4)
      expect(row.BIASEVEN).toBeCloseTo(311.0368, 4)
      expect(row.BIASODD).toBeCloseTo(310.9477, 4)
      expect(row.GOODMIN).toBeCloseTo(-1.677314, 6)
      expect(row.GOODMAX).toBeCloseTo(3652.070, 3)
      expect(row.DATAMEAN).toBeCloseTo(8.1251163, 6)
      expect(row.GPIXELS).toBeCloseTo(558090, 6)
      expect(row.SOFTERRS).toBeCloseTo(0, 6)
      expect(row.CALIBDEF).toBeCloseTo(79828, 6)
      expect(row.STATICD).toBeCloseTo(0, 6)
      expect(row.ATODSAT).toBeCloseTo(134, 6)
      expect(row.DATALOST).toBeCloseTo(0, 6)
      expect(row.BADPIXEL).toBeCloseTo(0, 6)
      expect(row.OVERLAP).toBeCloseTo(0, 6)
      expect(row.PHOTMODE).toBe('WFPC2,4,A2D7,F555W,,CAL')
      expect(row.PHOTFLAM).toBeCloseTo(3.5067081e-18, 6)
      expect(row.PHOTZPT).toBeCloseTo(-21.1, 6)
      expect(row.PHOTPLAM).toBeCloseTo(5442.226, 3)
      expect(row.PHOTBW).toBeCloseTo(522.3256, 4)
      expect(row.MEDIAN).toBeCloseTo(5.009274, 6)
      expect(row.MEDSHADO).toBeCloseTo(-11.75893, 6)
      expect(row.HISTWIDE).toBeCloseTo(3.9197681, 6)
      expect(row.SKEWNESS).toBeCloseTo(0.1215812, 6)
      expect(row.MEANC10).toBeCloseTo(6.7609448, 6)
      expect(row.MEANC25).toBeCloseTo(7.2739491, 6)
      expect(row.MEANC50).toBeCloseTo(10.4921, 6)
      expect(row.MEANC100).toBeCloseTo(10.83396, 6)
      expect(row.MEANC200).toBeCloseTo(9.6577616, 6)
      expect(row.MEANC300).toBeCloseTo(8.9342422, 6)
      expect(row.BACKGRND).toBeCloseTo(4.0813661, 6) 