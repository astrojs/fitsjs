window.FITS = astro.FITS

describe "FITS Binary Table", ->
  
  it 'can read a binary table with various data types', ->
    precision = 6
    
    ready = false
    
    path = 'data/bintable.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      table = fits.getDataUnit()
      rows = table.getRows(0, 1)
      
      row = rows[0]
      
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
    precision = 6
    
    ready = false
    
    path = 'data/allskytable.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      
      table = fits.getDataUnit()
      rows = table.getRows(0, 1)
      
      row = rows[0]
      
      expect(row['ALLSKY'][0]).toBeCloseTo(187.24862671, precision)
      expect(row['XINTERP'][0]).toBeCloseTo(-4.37500000e-01, precision)
      expect(row['YINTERP'][0]).toBeCloseTo(0.5625, 4)
      
  it 'can read a bit array', ->
    ready = false
    
    path = 'data/bit.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      table = fits.getDataUnit()
      rows = table.getRows(0, 1)
      
      row = rows[0]
      
      bitarray = row['status']
      expect(bitarray[0]).toEqual(1)
      expect(bitarray[31]).toEqual(0)
      
      rows = table.getRows(1, 1)
      row = rows[0]
      
      bitarray = row['status']
      expect(bitarray[1]).toEqual(1)
      expect(bitarray[31]).toEqual(0)
      
  it 'can read a column of data', ->
    ready = false
    
    path = 'data/plates-dr9.fits'
    fits = new astro.FITS(path, (fits) ->
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      table = fits.getDataUnit()
      table.getColumn('RACEN', (column) ->
        console.log "column", column
      )
  