
# Abstract class for tabular FITS extensions (e.g. TABLE, BINTABLE)
class Tabular extends DataUnit
  
  # The maximum amount of memory to hold on object when
  # reading a local file. 8 MBs.
  maxMemory: 8388608
  
  typedArray:
    B: Uint8Array
    I: Uint16Array
    J: Int32Array
    E: Float32Array
    D: Float64Array
    1: Uint8Array
    2: Uint16Array
    4: Int32Array
  
  # NOTE: Accessor functions for bit array is better implemented in binary table class
  dataAccessors:
    L: (view, offset) ->
      x = view.getInt8(offset)
      offset += 1
      val = if x is 84 then true else false
      return [val, offset]
    B: (view, offset) ->
      val = view.getUint8(offset)
      offset += 1
      return [val, offset]
    I: (view, offset) ->
      val = view.getInt16(offset)
      offset += 2
      return [val, offset]
    J: (view, offset) ->
      val = view.getInt32(offset)
      offset += 4
      return [val, offset]
    K: (view, offset) ->
      highByte = Math.abs view.getInt32(offset)
      offset += 4
      lowByte = Math.abs view.getInt32(offset)
      offset += 4
      mod = highByte % 10
      factor = if mod then -1 else 1
      highByte -= mod
      console.warn "Precision for 64 bit integers may be incorrect."
      val = factor * ((highByte << 32) | lowByte)
      return [val, offset]
    A: (view, offset) ->
      val = view.getUint8(offset)
      val = String.fromCharCode(val)
      offset += 1
      return [val, offset]
    E: (view, offset) ->
      val = view.getFloat32(offset)
      offset += 4
      return [val, offset]
    D: (view, offset) ->
      val = view.getFloat64(offset)
      offset += 8
      return [val, offset]
    C: (view, offset) ->
      val1 = view.getFloat32(offset)
      offset += 4
      val2 = view.getFloat32(offset)
      offset += 4
      val = [val1, val2]
      return [val, offset]
    M: (view, offset) ->
      val1 = view.getFloat64(offset)
      offset += 8
      val2 = view.getFloat64(offset)
      offset += 8
      val = [val1, val2]
      return [val, offset]
  
  
  constructor: (header, data) ->
    super
    
    @rowByteSize  = header.get("NAXIS1")
    @rows         = header.get("NAXIS2")
    @cols         = header.get("TFIELDS")
    
    # Bytes size of the data unit
    @length = @rowByteSize * @rows
    
    # Number of rows read and column names
    @rowsRead = 0
    @columns  = @getColumns(header)
    
    # Store functions needed to access each entry
    @accessors  = []
    
    # Store information about the buffer
    if @buffer?
      
      # Define function at run time that checks if row is in memory
      @isRowInMemory = @_rowsInMemoryBuffer
    
    else
      @isRowInMemory = @_rowsInMemoryBlob
      
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
    
    # Check if row is in memory
    if @rowsInMemory(row, row + number)
      @rowsRead = row
      
      # Storage for rows
      rows = []
      
      while number--
        row = {}
        for accessor, index in @accessors
          row[@columns[index]] = accessor()
        @rowsRead += 1
      
      # Execute callback
      context = if opts?.context? then opts.context else @
      callback.call(context, rows, opts) if callback?
      
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