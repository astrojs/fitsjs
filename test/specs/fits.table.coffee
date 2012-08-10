require = window.require

FITS = require("fits")

describe "FITS Table", ->

  it 'can read the column names', ->
    table = fits.getDataUnit(1)
    
    names = ['XI', 'ETA', 'XI_CORR', 'ETA_CORR']
    for name, index in names
      expect(table.columns[index]).toEqual(name)

  it 'can read a FITS table', ->
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