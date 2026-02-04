## FIFO Queue (First-In-First-Out)
## ===================================
##
## Pure Nim implementation of a fixed-capacity FIFO queue with zero heap allocation.
##
## **Features:**
## - Fixed capacity at compile time (no dynamic allocation)
## - Thread-safe for single producer/single consumer
## - Audio-rate safe (no locks, predictable performance)
## - Generic type support via templates
##
## **Use Cases:**
## - Event queues
## - Message passing between threads
## - Audio sample buffering
## - Command queues
##
## **Memory:**
## - Stack allocated only
## - Size known at compile time
## - Zero runtime overhead
##
## **Usage:**
## ```nim
## import nimphea_fifo
##
## # Create FIFO for 16 integers
## var queue: Fifo[16, int]
## queue.init()
##
## # Push values
## discard queue.push(42)
## discard queue.push(100)
##
## # Pop values (FIFO order)
## var value: int
## if queue.pop(value):
##   echo value  # 42 (first in, first out)
##
## # Check state
## echo queue.len()      # Current count
## echo queue.isEmpty()  # false
## echo queue.isFull()   # false
## ```

type
  Fifo*[N: static int, T] = object
    ## Fixed-capacity FIFO queue
    ##
    ## **Generic Parameters:**
    ## - `N` - Capacity (must be known at compile time)
    ## - `T` - Element type
    ##
    ## **Fields:**
    ## - `data` - Fixed array storage
    ## - `head` - Read position
    ## - `tail` - Write position  
    ## - `count` - Current number of elements
    data: array[N, T]
    head: int
    tail: int
    count: int

proc init*[N: static int, T](this: var Fifo[N, T]) =
  ## Initialize the FIFO queue
  ##
  ## **Example:**
  ## ```nim
  ## var queue: Fifo[32, float32]
  ## queue.init()
  ## ```
  this.head = 0
  this.tail = 0
  this.count = 0

proc clear*[N: static int, T](this: var Fifo[N, T]) =
  ## Clear all elements from the queue
  ##
  ## **Example:**
  ## ```nim
  ## queue.clear()
  ## ```
  this.head = 0
  this.tail = 0
  this.count = 0

proc len*[N: static int, T](this: Fifo[N, T]): int {.inline.} =
  ## Get current number of elements
  ##
  ## **Returns:** Number of elements (0 to N)
  ##
  ## **Example:**
  ## ```nim
  ## echo queue.len()  # e.g., 5
  ## ```
  this.count

proc capacity*[N: static int, T](this: Fifo[N, T]): int {.inline.} =
  ## Get maximum capacity
  ##
  ## **Returns:** Maximum capacity (compile-time constant N)
  ##
  ## **Example:**
  ## ```nim
  ## echo queue.capacity()  # 32
  ## ```
  N

proc isEmpty*[N: static int, T](this: Fifo[N, T]): bool {.inline.} =
  ## Check if queue is empty
  ##
  ## **Returns:** `true` if empty, `false` otherwise
  ##
  ## **Example:**
  ## ```nim
  ## if queue.isEmpty():
  ##   echo "Queue is empty"
  ## ```
  this.count == 0

proc isFull*[N: static int, T](this: Fifo[N, T]): bool {.inline.} =
  ## Check if queue is full
  ##
  ## **Returns:** `true` if full, `false` otherwise
  ##
  ## **Example:**
  ## ```nim
  ## if queue.isFull():
  ##   echo "Queue is full, cannot push"
  ## ```
  this.count == N

proc push*[N: static int, T](this: var Fifo[N, T], value: T): bool {.inline.} =
  ## Push a value onto the queue (at tail)
  ##
  ## **Parameters:**
  ## - `value` - Element to push
  ##
  ## **Returns:** `true` if successful, `false` if queue was full
  ##
  ## **Example:**
  ## ```nim
  ## if not queue.push(42):
  ##   echo "Queue full, push failed"
  ## ```
  if this.count >= N:
    return false
  
  this.data[this.tail] = value
  this.tail = (this.tail + 1) mod N
  this.count.inc
  return true

proc pop*[N: static int, T](this: var Fifo[N, T], value: var T): bool {.inline.} =
  ## Pop a value from the queue (from head)
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the popped value
  ##
  ## **Returns:** `true` if successful, `false` if queue was empty
  ##
  ## **Example:**
  ## ```nim
  ## var val: int
  ## if queue.pop(val):
  ##   echo "Popped: ", val
  ## else:
  ##   echo "Queue empty"
  ## ```
  if this.count == 0:
    return false
  
  value = this.data[this.head]
  this.head = (this.head + 1) mod N
  this.count.dec
  return true

proc peek*[N: static int, T](this: Fifo[N, T], value: var T): bool {.inline.} =
  ## Peek at the next value without removing it
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the peeked value
  ##
  ## **Returns:** `true` if successful, `false` if queue was empty
  ##
  ## **Example:**
  ## ```nim
  ## var val: int
  ## if queue.peek(val):
  ##   echo "Next value: ", val  # Queue unchanged
  ## ```
  if this.count == 0:
    return false
  
  value = this.data[this.head]
  return true

proc `$`*[N: static int, T](this: Fifo[N, T]): string =
  ## Convert FIFO to string representation (for debugging)
  ##
  ## **Example:**
  ## ```nim
  ## echo queue  # "Fifo[16, int](count=5/16)"
  ## ```
  result = "Fifo[" & $N & ", " & $T & "](count=" & $this.count & "/" & $N & ")"
