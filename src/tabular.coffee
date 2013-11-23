
# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends DataUnit
  
  # The maximum amount of memory to hold on object when
  # reading a local file. 8 MBs.
  # maxMemory: 8388608
  maxMemory: 1048576
  
  
  constructor: (header, data) ->
    super
    
    @rowByteSize  = header.get("NAXIS1")
    @rows         = header.get("NAXIS2")
    @cols         = header.get("TFIELDS")
    
    # Get bytes size of the data unit and column names
    @length     = @rowByteSize * @rows
    @heapLength = header.get("PCOUNT")
    @columns    = @getColumns(header)
    
    # Store information about the buffer
    if @buffer?
      
      # Define function at run time that checks if row is in memory
      @rowsInMemory = @_rowsInMemoryBuffer
      
      # Keep separate buffer for heap
      # NOTE: This causes a duplication of the buffer in memory. Find better solution.
      @heap = @buffer.slice(@length, @length + @heapLength)
    
    else
      @rowsInMemory = @_rowsInMemoryBlob
      
      # No rows are in memory
      @firstRowInBuffer = @lastRowInBuffer = 0
      
      # Use maxMemory to get the number of rows to hold in memory
      @nRowsInBuffer = Math.floor(@maxMemory / @rowByteSize)
    
    # Storage for accessor functions, descriptors and offsets for each column
    @accessors    = []
    @descriptors  = []
    @elementByteLengths = []
    
    @setAccessors(header)
    
  # Determine if the row is in memory. For tables initialized with an array buffer, all rows
  # are in memory, so there is no need to check. For tables initialized with a blob, this check
  # is needed to determine if the file needs to be read before accessing data.
  _rowsInMemoryBuffer: -> return true
  _rowsInMemoryBlob: (firstRow, lastRow) ->
    return false if firstRow < @firstRowInBuffer
    return false if lastRow > @lastRowInBuffer
    return true

  # Get the column names from the header
  getColumns: (header) ->
    columns = []
    for i in [1..@cols]
      key = "TTYPE#{i}"
      return null unless header.contains(key)
      columns.push header.get(key)
    return columns
  
  # Get column of data specified by parameters.
  getColumn: (name, callback, opts) ->
    # Check for blob
    if @blob?
      
      # Storage for column using typed array when able
      index = @columns.indexOf(name)
      
      descriptor = @descriptors[index]
      accessor = @accessors[index]
      elementByteLength = @elementByteLengths[index]
      elementByteOffset = @elementByteLengths.slice(0, index)
      if elementByteOffset.length is 0
        elementByteOffset = 0
      else
        elementByteOffset = elementByteOffset.reduce( (a, b) -> a + b)
      
      column = if @typedArray[descriptor]? then new @typedArray[descriptor](@rows) else []
      
      # Read rows in ~8 MB chunks
      rowsPerIteration = ~~(@maxMemory / @rowByteSize)
      rowsPerIteration = Math.min(rowsPerIteration, @rows)
      
      # Get number of iterations needed to read entire file
      factor = @rows / rowsPerIteration
      iterations = if Math.floor(factor) is factor then factor else Math.floor(factor) + 1
      i = 0
      index = 0
      
      # Define callback to pass to getRows
      cb = (buffer, opts) =>
        nRows = buffer.byteLength / @rowByteSize
        view = new DataView(buffer)
        offset = elementByteOffset
        
        # Read only the column value from the buffer
        while nRows--
          column[i] = accessor(view, offset)[0]
          i += 1
          offset += @rowByteSize
        
        # Update counters
        iterations -= 1
        index += 1
        
        # Request another buffer of rows
        if iterations
          startRow = index * rowsPerIteration
          @getTableBuffer(startRow, rowsPerIteration, cb, opts)
        else
          @invoke(callback, opts, column)
          return
      
      # Start reading rows
      @getTableBuffer(0, rowsPerIteration, cb, opts)
      
    else
      # Table already in memory.  Get column using getRows method
      cb = (rows, opts) =>
        column = rows.map( (d) -> d[name])
        @invoke(callback, opts, column)
      
      @getRows(0, @rows, cb, opts)
  
  # Get buffer representing a number of rows. The resulting buffer
  # should be passed to another function for either row or column access.
  # NOTE: Using only for local files that are not in memory.
  getTableBuffer: (row, number, callback, opts) ->
    
    # Get the number of remaining rows
    number = Math.min(@rows - row, number)
    
    # Get the offsets to slice the blob. Note the API allows for more memory to be allocated
    # by the developer if the number of rows is greater than the default heap size.
    begin = row * @rowByteSize
    end = begin + number * @rowByteSize
    
    # Slice blob for only relevant bytes
    blobRows = @blob.slice(begin, end)
    
    # Create file reader and store row and number on object for later reference
    reader = new FileReader()
    reader.row = row
    reader.number = number
    reader.onloadend = (e) =>
      # Pass arraybuffer to a parser function via callback
      @invoke(callback, opts, e.target.result)
    reader.readAsArrayBuffer(blobRows)
  
  # Get rows of data specified by parameters.  In the case where
  # the data is not yet in memory, a callback must be provided to
  # expose the results. This is due to the asynchonous reading of
  # the file.
  getRows: (row, number, callback, opts) ->
    
    # Check if rows are in memory
    if @rowsInMemory(row, row + number)
      
      # Buffer needs slicing if entire file is in memory
      if @blob?
        buffer = @buffer
      else
        begin = row * @rowByteSize
        end = begin + number * @rowByteSize
        buffer = @buffer.slice(begin, end)
      
      # Derived classes must implement this function
      rows = @_getRows(buffer, number)
      
      @invoke(callback, opts, rows)
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
        # TODO: Double check this as it might result in failure to GC
        @buffer = target.result
        
        @firstRowInBuffer = @lastRowInBuffer = target.row
        @lastRowInBuffer += target.number
        
        # Call function again
        @getRows(row, number, callback, opts)
        
      reader.readAsArrayBuffer(blobRows)


@astro.FITS.Tabular = Tabular