## Ring Buffer (Circular Buffer)
## ==============================
##
## Pure Nim implementation of a lock-free ring buffer optimized for audio streaming.
##
## **Features:**
## - Fixed capacity at compile time (no dynamic allocation)
## - Lock-free single-producer/single-consumer (SPSC)
## - Audio streaming optimized
## - Configurable overwrite behavior
## - Generic type support via templates
## - ⚠️ **BREAKING CHANGE v0.9.1:** Capacity N must be a power of 2 (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, etc.)
##
## **Performance:**
## - Uses bitwise AND instead of modulo (1 cycle vs 12-30 cycles on ARM Cortex-M7)
## - Compile-time validation ensures power-of-2 sizes
##
## **Use Cases:**
## - Audio sample buffering (delay lines, loopers)
## - Inter-thread communication
## - Streaming data processing
## - Real-time data capture
##
## **Memory:**
## - Stack allocated only
## - Size known at compile time
## - Zero runtime overhead
##
## **Migration from v0.9.0:**
## - If you used non-power-of-2 sizes (e.g., 100, 500), round up to next power of 2
## - Example: `RingBuffer[100, float32]` → `RingBuffer[128, float32]`
## - Example: `RingBuffer[500, float32]` → `RingBuffer[512, float32]`
##
## **Usage:**
## ```nim
## import nimphea_ringbuffer
##
## # Create ring buffer for 1024 samples (MUST be power of 2!)
## var buffer: RingBuffer[1024, float32]
## buffer.init()
##
## # Write samples
## discard buffer.write(0.5)
## discard buffer.write(0.7)
##
## # Read samples
## var sample: float32
## if buffer.read(sample):
##   echo sample  # 0.5
##
## # Block operations
## var samples: array[64, float32]
## let written = buffer.writeBlock(samples)
## let readCount = buffer.readBlock(samples)
## ```

type
  OverwriteMode* = enum
    ## Behavior when buffer is full
    OVERWRITE_OLDEST  ## Overwrite oldest data (circular)
    REJECT_NEW        ## Reject new writes when full

template isPowerOfTwo(n: static int): bool =
  ## Compile-time check if a number is a power of 2
  (n and (n - 1)) == 0 and n > 0

type
  RingBuffer*[N: static int; T] = object
    ## Lock-free circular buffer for audio streaming
    ##
    ## ⚠️ **CRITICAL:** N must be a power of 2 (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, etc.)
    ## This is enforced at compile time for performance (bitwise AND vs modulo).
    ##
    ## **Generic Parameters:**
    ## - `N` - Capacity (MUST be power of 2, checked at compile time)
    ## - `T` - Element type (typically float32 for audio)
    ##
    ## **Fields:**
    ## - `data` - Fixed array storage
    ## - `writeIdx` - Write position
    ## - `readIdx` - Read position
    ## - `mode` - Overwrite behavior
    data: array[N, T]
    writeIdx: int
    readIdx: int
    mode: OverwriteMode

proc init*[N: static int, T](this: var RingBuffer[N, T], 
                              mode: OverwriteMode = OVERWRITE_OLDEST) =
  ## Initialize the ring buffer
  ##
  ## **Parameters:**
  ## - `mode` - Overwrite behavior (default: OVERWRITE_OLDEST)
  when not isPowerOfTwo(N):
    {.error: "RingBuffer size N must be a power of 2 (2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, ...)".}
  ##
  ## **Example:**
  ## ```nim
  ## var buffer: RingBuffer[512, float32]
  ## buffer.init(REJECT_NEW)
  ## ```
  this.writeIdx = 0
  this.readIdx = 0
  this.mode = mode

proc clear*[N: static int, T](this: var RingBuffer[N, T]) =
  ## Clear all data from the buffer
  ##
  ## **Example:**
  ## ```nim
  ## buffer.clear()
  ## ```
  this.writeIdx = 0
  this.readIdx = 0

proc capacity*[N: static int, T](this: RingBuffer[N, T]): int {.inline.} =
  ## Get maximum capacity
  ##
  ## **Returns:** Maximum capacity (compile-time constant N)
  N

proc available*[N: static int, T](this: RingBuffer[N, T]): int {.inline.} =
  ## Get number of samples available to read
  ##
  ## **Returns:** Number of readable samples
  ##
  ## **Example:**
  ## ```nim
  ## echo buffer.available()  # e.g., 128
  ## ```
  if this.writeIdx >= this.readIdx:
    this.writeIdx - this.readIdx
  else:
    N - this.readIdx + this.writeIdx

proc remaining*[N: static int, T](this: RingBuffer[N, T]): int {.inline.} =
  ## Get number of free slots for writing
  ##
  ## **Returns:** Number of writable slots
  ##
  ## **Example:**
  ## ```nim
  ## echo buffer.remaining()  # e.g., 384
  ## ```
  N - this.available() - 1  # -1 to distinguish full from empty

proc isEmpty*[N: static int, T](this: RingBuffer[N, T]): bool {.inline.} =
  ## Check if buffer is empty
  ##
  ## **Returns:** `true` if no data available
  this.writeIdx == this.readIdx

proc isFull*[N: static int, T](this: RingBuffer[N, T]): bool {.inline.} =
  ## Check if buffer is full
  ##
  ## **Returns:** `true` if no space remaining
  ((this.writeIdx + 1) and (N - 1)) == this.readIdx

proc write*[N: static int, T](this: var RingBuffer[N, T], value: T): bool {.inline.} =
  ## Write a single value to the buffer
  ##
  ## **Parameters:**
  ## - `value` - Value to write
  ##
  ## **Returns:** `true` if successful, `false` if full (REJECT_NEW mode)
  ##
  ## **Example:**
  ## ```nim
  ## if not buffer.write(0.5):
  ##   echo "Buffer full"
  ## ```
  let nextWrite = (this.writeIdx + 1) and (N - 1)
  
  if nextWrite == this.readIdx:
    # Buffer full
    if this.mode == REJECT_NEW:
      return false
    else:
      # Overwrite oldest - advance read pointer
      this.readIdx = (this.readIdx + 1) and (N - 1)
  
  this.data[this.writeIdx] = value
  this.writeIdx = nextWrite
  return true

proc read*[N: static int, T](this: var RingBuffer[N, T], value: var T): bool {.inline.} =
  ## Read a single value from the buffer
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the value
  ##
  ## **Returns:** `true` if successful, `false` if empty
  ##
  ## **Example:**
  ## ```nim
  ## var sample: float32
  ## if buffer.read(sample):
  ##   echo sample
  ## ```
  if this.readIdx == this.writeIdx:
    return false
  
  value = this.data[this.readIdx]
  this.readIdx = (this.readIdx + 1) and (N - 1)
  return true

proc writeBlock*[N: static int, T](this: var RingBuffer[N, T], 
                                    data: openArray[T]): int =
  ## Write multiple values to the buffer
  ##
  ## **Parameters:**
  ## - `data` - Array of values to write
  ##
  ## **Returns:** Number of values actually written
  ##
  ## **Example:**
  ## ```nim
  ## var samples: array[64, float32]
  ## # ... fill samples ...
  ## let written = buffer.writeBlock(samples)
  ## echo "Wrote ", written, " samples"
  ## ```
  result = 0
  for i in 0..<data.len:
    if this.write(data[i]):
      result.inc
    else:
      if this.mode == REJECT_NEW:
        break

proc readBlock*[N: static int, T](this: var RingBuffer[N, T], 
                                   data: var openArray[T]): int =
  ## Read multiple values from the buffer
  ##
  ## **Parameters:**
  ## - `data` - Array to fill with read values
  ##
  ## **Returns:** Number of values actually read
  ##
  ## **Example:**
  ## ```nim
  ## var samples: array[64, float32]
  ## let count = buffer.readBlock(samples)
  ## echo "Read ", count, " samples"
  ## ```
  result = 0
  for i in 0..<data.len:
    if this.read(data[i]):
      result.inc
    else:
      break

proc peek*[N: static int, T](this: RingBuffer[N, T], value: var T, 
                              offset: int = 0): bool {.inline.} =
  ## Peek at a value without removing it
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the value
  ## - `offset` - Offset from current read position (default: 0)
  ##
  ## **Returns:** `true` if successful, `false` if offset out of range
  ##
  ## **Example:**
  ## ```nim
  ## var sample: float32
  ## if buffer.peek(sample, 5):
  ##   echo "5 samples ahead: ", sample
  ## ```
  if offset >= this.available():
    return false
  
  let peekIdx = (this.readIdx + offset) and (N - 1)
  value = this.data[peekIdx]
  return true

proc `$`*[N: static int, T](this: RingBuffer[N, T]): string =
  ## Convert ring buffer to string representation (for debugging)
  ##
  ## **Example:**
  ## ```nim
  ## echo buffer  # "RingBuffer[1024, float32](available=128/1024)"
  ## ```
  result = "RingBuffer[" & $N & ", " & $T & "](available=" & 
           $this.available() & "/" & $N & ")"
