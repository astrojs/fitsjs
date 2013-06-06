
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
    @offsets      = []
    
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
  getColumn: (name, row, number, callback, opts) ->
    
    # Get index of column
    columnIndex = @columns.indexOf(name)
    
    # Store row byte size locally
    rowByteSize = @rowByteSize
    
    # Store byte length for single column value
    descriptor = @descriptors[columnIndex]
    length = @offsets[columnIndex]
    
    # Get byte offset from starting row
    byteOffset = rowByteSize * row
    
    # Get the offset from the start of the row
    for i in [0..columnIndex]
      byteOffset += @offsets[i]
    byteOffset -= length
    
    # Get the accessor function from the column name
    accessor = @accessors[columnIndex]
    
    # Storage for column using typed array when able
    # column = if @typedArray.hasOwnProperty(descriptor) then new @typedArray[descriptor](number) else []
    column = new Array(number)
    
    # Check for blob
    if @blob?
      
      # Request bytes using File API
      reader = new FileReader()
      index = 0
      
      reader.onloadend = (e) =>
        
        # Initialize DataView object
        view = new DataView(e.target.result)
        [value, offset] = accessor(view, 0)
        column[index] = value
        
        if index is number
          @invoke(callback, opts, column)
          return column
        
        # Compute the next byte offsets
        index += 1
        byteOffset += rowByteSize
        slice = @blob.slice(byteOffset, byteOffset + length)
        reader.readAsArrayBuffer(slice)
        
      # Get the bytes associated with the first requested element
      slice = @blob.slice(byteOffset, byteOffset + length)
      reader.readAsArrayBuffer(slice)
    else
      # Table already in memory.  Get column using getRows method
      cb = (rows, opts) =>
        column = rows.map( (d) -> d[name])
        @invoke(callback, opts, column)
      
      @getRows(row, number, cb, opts)
  
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
        @buffer = target.result
        
        @firstRowInBuffer = @lastRowInBuffer = target.row
        @lastRowInBuffer += target.number
        
        # Call function again
        @getRows(row, number, callback, opts)
        
      reader.readAsArrayBuffer(blobRows)


@astro.FITS.Tabular = Tabular