## Fixed-Capacity String Module
## 
## This module provides a stack-allocated, fixed-capacity string type for embedded systems.
## Unlike Nim's standard string type which uses heap allocation, FixedStr stores all data
## on the stack with compile-time determined capacity.
##
## **Key Features:**
## - Zero heap allocation (all data on stack)
## - Compile-time capacity via static int parameter
## - Safe bounds checking on all operations
## - Compatible with standard string operations via `$` operator
## - Ideal for OLED/LCD displays, serial output, and embedded UI
## - Audio-rate safe (no memory allocation)
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import nimphea_fixedstr
##   
##   # Create 32-character fixed string
##   var displayText: FixedStr[32]
##   displayText.init()
##   
##   # Add text
##   displayText.add("Frequency: ")
##   displayText.add("440")
##   displayText.add(" Hz")
##   
##   # Convert to regular string for display
##   echo $displayText  # "Frequency: 440 Hz"
##   
##   # Set new content (replaces existing)
##   displayText.set("Volume: 75%")
##   
##   # Check length
##   if displayText.len() < displayText.capacity():
##     displayText.add("!")
##   
##   # Clear for reuse
##   displayText.clear()
##
## **Performance Notes:**
## - All operations are O(1) or O(n) where n is string length (not capacity)
## - No dynamic memory allocation ever occurs
## - Safe to use in interrupt handlers and audio callbacks
## - Capacity is fixed at compile time - cannot grow
## - Attempting to add beyond capacity truncates (no panic)

type
  FixedStr*[N: static int] = object
    ## Fixed-capacity string with compile-time size.
    ## 
    ## **Template Parameters:**
    ## - N: Maximum capacity in bytes (must be > 0)
    ## 
    ## **Fields:**
    ## - data: Fixed array storing characters
    ## - length: Current number of valid characters (0 to N-1)
    ## 
    ## **Note:** Capacity N should leave room for null terminator if
    ## interfacing with C functions. For display purposes, full N can be used.
    data: array[N, char]
    length: int

proc init*[N: static int](this: var FixedStr[N]) {.inline.} =
  ## Initialize the fixed string to empty state.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance to initialize
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   assert s.len() == 0
  this.length = 0
  # No need to zero data array - length determines valid content

proc clear*[N: static int](this: var FixedStr[N]) {.inline.} =
  ## Clear the string (set length to 0).
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance to clear
  ## 
  ## **Note:** This is O(1) - just resets length, doesn't zero memory.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("hello")
  ##   s.clear()
  ##   assert s.len() == 0
  this.length = 0

proc len*[N: static int](this: FixedStr[N]): int {.inline.} =
  ## Get current length of the string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## Current number of characters in the string (0 to capacity)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   assert s.len() == 0
  ##   s.add("test")
  ##   assert s.len() == 4
  result = this.length

proc capacity*[N: static int](this: FixedStr[N]): int {.inline.} =
  ## Get maximum capacity of the string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## Maximum number of characters this string can hold (always N)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[32]
  ##   assert s.capacity() == 32
  result = N

proc isEmpty*[N: static int](this: FixedStr[N]): bool {.inline.} =
  ## Check if the string is empty.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## true if length is 0, false otherwise
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   assert s.isEmpty()
  ##   s.add("x")
  ##   assert not s.isEmpty()
  result = (this.length == 0)

proc isFull*[N: static int](this: FixedStr[N]): bool {.inline.} =
  ## Check if the string is at full capacity.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## true if length equals capacity, false otherwise
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[4]
  ##   s.init()
  ##   s.add("test")
  ##   assert s.isFull()
  result = (this.length == N)

proc add*[N: static int](this: var FixedStr[N], c: char): bool {.inline.} =
  ## Add a single character to the end of the string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - c: Character to add
  ## 
  ## **Returns:**
  ## true if character was added, false if string was full
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[4]
  ##   s.init()
  ##   assert s.add('H')
  ##   assert s.add('i')
  ##   assert s.len() == 2
  if this.length < N:
    this.data[this.length] = c
    inc(this.length)
    result = true
  else:
    result = false

proc add*[N: static int](this: var FixedStr[N], str: string): int {.inline.} =
  ## Add a string to the end of the fixed string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - str: String to add
  ## 
  ## **Returns:**
  ## Number of characters actually added (may be less than str.len if capacity reached)
  ## 
  ## **Note:** If string doesn't fit completely, adds as many characters as possible.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[8]
  ##   s.init()
  ##   let added = s.add("Hello")
  ##   assert added == 5
  ##   let more = s.add("World")  # Only 3 chars fit
  ##   assert more == 3
  ##   assert s.len() == 8
  result = 0
  for c in str:
    if this.length < N:
      this.data[this.length] = c
      inc(this.length)
      inc(result)
    else:
      break

proc add*[N: static int](this: var FixedStr[N], value: int): int {.inline.} =
  ## Add an integer value as string to the end of the fixed string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - value: Integer to convert and add
  ## 
  ## **Returns:**
  ## Number of characters actually added
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("Value: ")
  ##   s.add(42)
  ##   assert $s == "Value: 42"
  result = this.add($value)

proc add*[N: static int](this: var FixedStr[N], value: float): int {.inline.} =
  ## Add a float value as string to the end of the fixed string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - value: Float to convert and add
  ## 
  ## **Returns:**
  ## Number of characters actually added
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("Freq: ")
  ##   s.add(440.0)
  ##   assert $s == "Freq: 440.0"
  result = this.add($value)

proc set*[N: static int](this: var FixedStr[N], str: string): int {.inline.} =
  ## Replace entire contents with new string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - str: New string content
  ## 
  ## **Returns:**
  ## Number of characters actually set (may be less than str.len if capacity exceeded)
  ## 
  ## **Note:** This clears existing content first, then adds new string.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("old")
  ##   s.set("new content")
  ##   assert $s == "new content"
  this.clear()
  result = this.add(str)

proc `[]`*[N: static int](this: FixedStr[N], index: int): char {.inline.} =
  ## Get character at specified index.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - index: Index of character to retrieve (0-based)
  ## 
  ## **Returns:**
  ## Character at the specified index
  ## 
  ## **Note:** No bounds checking - caller must ensure index < len()
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("hello")
  ##   assert s[0] == 'h'
  ##   assert s[4] == 'o'
  result = this.data[index]

proc `[]=`*[N: static int](this: var FixedStr[N], index: int, c: char) {.inline.} =
  ## Set character at specified index.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## - index: Index of character to set (0-based)
  ## - c: New character value
  ## 
  ## **Note:** No bounds checking - caller must ensure index < len()
  ## Does not change string length.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("hello")
  ##   s[0] = 'H'
  ##   assert $s == "Hello"
  this.data[index] = c

proc `$`*[N: static int](this: FixedStr[N]): string =
  ## Convert FixedStr to regular Nim string.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## String containing the current contents
  ## 
  ## **Note:** This allocates a new string on the heap. Use for display/debugging only,
  ## not in audio callbacks.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[16]
  ##   s.init()
  ##   s.add("test")
  ##   echo $s  # Prints "test"
  result = newString(this.length)
  for i in 0 ..< this.length:
    result[i] = this.data[i]

proc toCString*[N: static int](this: var FixedStr[N]): cstring {.inline.} =
  ## Get a null-terminated C string pointer.
  ## 
  ## **Parameters:**
  ## - this: The FixedStr instance
  ## 
  ## **Returns:**
  ## Pointer to null-terminated character array
  ## 
  ## **Warning:** Only safe if capacity N was allocated with room for null terminator
  ## and string length < N. This does NOT automatically add null terminator.
  ## User must ensure data[length] is set to '\0' before calling.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var s: FixedStr[17]  # 16 chars + null
  ##   s.init()
  ##   s.add("display text")
  ##   s.data[s.len()] = '\0'  # Add null terminator
  ##   let cs = s.toCString()  # Safe for C functions
  result = cast[cstring](addr this.data[0])
