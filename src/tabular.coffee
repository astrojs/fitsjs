
# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends DataUnit
  
  # The maximum amount of memory to hold on object when
  # reading a local file. 8 MBs.
  maxMemory: 8388608
  
  
  constructor: (header, data) ->
    super
    
    @rowByteSize  = header.get("NAXIS1")
    @rows         = header.get("NAXIS2")
    @cols         = header.get("TFIELDS")
    
    # Get bytes size of the data unit and column names
    @length   = @rowByteSize * @rows
    @columns  = @getColumns(header)
    
    # Store functions needed to access each entry
    @accessors  = []
    
    # Store information about the buffer
    if @buffer?
      
      # Define function at run time that checks if row is in memory
      @rowsInMemory = @_rowsInMemoryBuffer
    
    else
      @rowsInMemory = @_rowsInMemoryBlob
      
      # No rows are in memory
      @firstRowInBuffer = @lastRowInBuffer = 0
      
      # Use maxMemory to get the number of rows to hold in memory
      @nRowsInBuffer = Math.floor(@maxMemory / @rowByteSize)
  
  # Get the column names from the header
  getColumns: (header) ->
    columns = []
    for i in [1..@cols]
      key = "TTYPE#{i}"
      return null unless header.contains(key)
      columns.push header.get(key)
    return columns
  
  # Get rows of data specified by parameters.  In the case where
  # the data is not yet in memory, a callback must be provided to
  # expose the results. This is due to the asynchonous reading of
  # the file.
  getRows: (row, number, callback, opts) ->
    
    # Check if rows are in memory
    if @rowsInMemory(row, row + number)
      
      # Slice the buffer
      begin = row * @rowByteSize
      end = begin + number * @rowByteSize
      buffer = @buffer.slice(begin, end)
      
      # Derived classes must implement this function
      rows = @_getRows(buffer)
      
      @runCallback(callback, opts, rows)
      return rows
    else
      
      # Get the offsets to slice the blob. Note the API allows for more memory to be allocated
      # by the developer if the number of rows is greater than the default heap size.
      begin = row * @rowByteSize
      end = begin + Math.max(@nRowsInBuffer * @rowByteSize, number * @rowByteSize)
      
      # Slice blob for only bytes
      blobRows = @blob.slice(begin, end)
      
      # Create file reader and store row and number on object for later reference
      reader = new FileReader()
      reader.row = row
      reader.number = number
      reader.onloadend = (e) =>
        target = e.target
        
        # Store the array buffer on the object
        @buffer = target.result
        
        @firstRowInBuffer = @lastRowInBuffer = target.row
        @lastRowInBuffer += target.number
        
        # Call function again
        @getRows(row, number, callback, opts)
        
      reader.readAsArrayBuffer(blobRows)
  
  # Determine if the row is in memory. For tables initialized with an array buffer, all rows
  # are in memory, so there is no need to check. For tables initialized with a blob, this check
  # is needed to determine if the file needs to be read before accessing data.
  _rowsInMemoryBuffer: -> return true
  _rowsInMemoryBlob: (firstRow, lastRow) ->
    return false if firstRow < @firstRowInBuffer
    return false if lastRow > @lastRowInBuffer
    return true


@astro.FITS.Tabular = Tabular