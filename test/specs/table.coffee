window.FITS = astro.FITS

describe "FITS ASCII Table", ->

  it 'can read the column names and knows buffer is in memory', ->
    ready = false
    
    table = null
    path = 'data/m101.fits'
    fits = new astro.FITS(path, (fits) ->
      table = fits.getDataUnit(1)
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      names = ['XI', 'ETA', 'XI_CORR', 'ETA_CORR']
      for name, index in names
        expect(table.columns[index]).toEqual(name)
      expect(table.rowsInMemory()).toBeTruthy()


  it 'can read rows from an ASCII table', ->
    ready = false
    
    table = null
    path = 'data/m101.fits'
    fits = new astro.FITS(path, (fits) ->
      table = fits.getDataUnit(1)
      ready = true
    )
    
    waitsFor ->
      return ready
    
    runs ->
      
      # Get all the rows in this table
      rows = table.getRows(0, 1600)
      
      row = rows[0]
      expect(row['XI']).toEqual(-3.12)
      expect(row['ETA']).toEqual(-3.12)
      expect(row['XI_CORR']).toEqual(0)
      expect(row['ETA_CORR']).toEqual(0)
      
      # Read the 801th row
      row = rows[800]
      expect(row['XI']).toEqual(-3.12)
      expect(row['ETA']).toEqual(0.08)
      expect(row['XI_CORR']).toEqual(-0.59)
      expect(row['ETA_CORR']).toEqual(0.09)
      
      # Read the last row
      row = rows[1599]
      expect(row['XI']).toEqual(3.12)
      expect(row['ETA']).toEqual(3.12)
      expect(row['XI_CORR']).toEqual(-0.20)
      expect(row['ETA_CORR']).toEqual(-0.07)
