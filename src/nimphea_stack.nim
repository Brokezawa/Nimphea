## Stack (Last-In-First-Out)
## ==========================
##
## Pure Nim implementation of a fixed-capacity stack with zero heap allocation.
##
## **Features:**
## - Fixed capacity at compile time (no dynamic allocation)
## - Standard LIFO operations (push/pop/peek)
## - Audio-rate safe (predictable performance)
## - Generic type support via templates
##
## **Use Cases:**
## - Undo/redo systems
## - Expression evaluation
## - Function call tracking
## - Temporary value storage
##
## **Memory:**
## - Stack allocated only
## - Size known at compile time
## - Zero runtime overhead
##
## **Usage:**
## ```nim
## import nimphea_stack
##
## # Create stack for 32 floats
## var stack: Stack[32, float32]
## stack.init()
##
## # Push values
## discard stack.push(1.5)
## discard stack.push(2.7)
##
## # Pop values (LIFO order)
## var value: float32
## if stack.pop(value):
##   echo value  # 2.7 (last in, first out)
##
## # Peek without removing
## if stack.peek(value):
##   echo value  # 1.5 (next value, still on stack)
## ```

type
  Stack*[N: static int, T] = object
    ## Fixed-capacity stack
    ##
    ## **Generic Parameters:**
    ## - `N` - Capacity (must be known at compile time)
    ## - `T` - Element type
    ##
    ## **Fields:**
    ## - `data` - Fixed array storage
    ## - `top` - Current stack top index (-1 when empty)
    data: array[N, T]
    top: int

proc init*[N: static int, T](this: var Stack[N, T]) =
  ## Initialize the stack
  ##
  ## **Example:**
  ## ```nim
  ## var stack: Stack[16, int]
  ## stack.init()
  ## ```
  this.top = -1

proc clear*[N: static int, T](this: var Stack[N, T]) =
  ## Clear all elements from the stack
  ##
  ## **Example:**
  ## ```nim
  ## stack.clear()
  ## ```
  this.top = -1

proc len*[N: static int, T](this: Stack[N, T]): int {.inline.} =
  ## Get current number of elements
  ##
  ## **Returns:** Number of elements (0 to N)
  ##
  ## **Example:**
  ## ```nim
  ## echo stack.len()  # e.g., 10
  ## ```
  this.top + 1

proc capacity*[N: static int, T](this: Stack[N, T]): int {.inline.} =
  ## Get maximum capacity
  ##
  ## **Returns:** Maximum capacity (compile-time constant N)
  ##
  ## **Example:**
  ## ```nim
  ## echo stack.capacity()  # 32
  ## ```
  N

proc isEmpty*[N: static int, T](this: Stack[N, T]): bool {.inline.} =
  ## Check if stack is empty
  ##
  ## **Returns:** `true` if empty, `false` otherwise
  ##
  ## **Example:**
  ## ```nim
  ## if stack.isEmpty():
  ##   echo "Stack is empty"
  ## ```
  this.top == -1

proc isFull*[N: static int, T](this: Stack[N, T]): bool {.inline.} =
  ## Check if stack is full
  ##
  ## **Returns:** `true` if full, `false` otherwise
  ##
  ## **Example:**
  ## ```nim
  ## if stack.isFull():
  ##   echo "Stack is full, cannot push"
  ## ```
  this.top == N - 1

proc push*[N: static int, T](this: var Stack[N, T], value: T): bool {.inline.} =
  ## Push a value onto the stack
  ##
  ## **Parameters:**
  ## - `value` - Element to push
  ##
  ## **Returns:** `true` if successful, `false` if stack was full
  ##
  ## **Example:**
  ## ```nim
  ## if not stack.push(42):
  ##   echo "Stack full, push failed"
  ## ```
  if this.top >= N - 1:
    return false
  
  this.top.inc
  this.data[this.top] = value
  return true

proc pop*[N: static int, T](this: var Stack[N, T], value: var T): bool {.inline.} =
  ## Pop a value from the stack
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the popped value
  ##
  ## **Returns:** `true` if successful, `false` if stack was empty
  ##
  ## **Example:**
  ## ```nim
  ## var val: int
  ## if stack.pop(val):
  ##   echo "Popped: ", val
  ## else:
  ##   echo "Stack empty"
  ## ```
  if this.top == -1:
    return false
  
  value = this.data[this.top]
  this.top.dec
  return true

proc peek*[N: static int, T](this: Stack[N, T], value: var T): bool {.inline.} =
  ## Peek at the top value without removing it
  ##
  ## **Parameters:**
  ## - `value` - Output parameter to receive the peeked value
  ##
  ## **Returns:** `true` if successful, `false` if stack was empty
  ##
  ## **Example:**
  ## ```nim
  ## var val: int
  ## if stack.peek(val):
  ##   echo "Top value: ", val  # Stack unchanged
  ## ```
  if this.top == -1:
    return false
  
  value = this.data[this.top]
  return true

proc `$`*[N: static int, T](this: Stack[N, T]): string =
  ## Convert stack to string representation (for debugging)
  ##
  ## **Example:**
  ## ```nim
  ## echo stack  # "Stack[32, float32](count=10/32)"
  ## ```
  result = "Stack[" & $N & ", " & $T & "](count=" & $(this.top + 1) & "/" & $N & ")"
