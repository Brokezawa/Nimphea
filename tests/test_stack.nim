## Unit tests for Stack (Last-In-First-Out)
##
## Tests the pure Nim implementation of fixed-capacity stack.
## Stack is simpler than FIFO - just push/pop/peek operations.
##
## Run with: nimble test_unit

import unittest2
import std/strutils
import ../src/nimphea_stack

suite "Stack: Basic Properties":
  test "should report correct capacity":
    var stack: Stack[5, int]
    stack.init()
    check stack.capacity() == 5
  
  test "should start empty after init":
    var stack: Stack[8, int]
    stack.init()
    check:
      stack.len() == 0
      stack.isEmpty() == true
      stack.isFull() == false
  
  test "should work with different types":
    var intStack: Stack[4, int]
    var floatStack: Stack[4, float32]
    var boolStack: Stack[4, bool]
    
    intStack.init()
    floatStack.init()
    boolStack.init()
    
    check:
      intStack.isEmpty() == true
      floatStack.isEmpty() == true
      boolStack.isEmpty() == true

suite "Stack: Push and Pop Operations":
  test "should push and pop single item (LIFO order)":
    var stack: Stack[5, int]
    stack.init()
    
    # Push single item
    check stack.push(42) == true
    check:
      stack.len() == 1
      stack.isEmpty() == false
      stack.isFull() == false
    
    # Pop single item
    var value: int
    check stack.pop(value) == true
    check:
      value == 42
      stack.len() == 0
      stack.isEmpty() == true
  
  test "should maintain LIFO order (last-in-first-out)":
    var stack: Stack[5, int]
    stack.init()
    
    # Push three values
    check stack.push(1) == true
    check stack.push(2) == true
    check stack.push(3) == true
    check stack.len() == 3
    
    # Pop in LIFO order (reverse of push order)
    var val1, val2, val3: int
    check stack.pop(val1) == true
    check stack.pop(val2) == true
    check stack.pop(val3) == true
    
    check:
      val1 == 3  # Last in, first out
      val2 == 2
      val3 == 1
  
  test "should fill to capacity":
    var stack: Stack[3, int]
    stack.init()
    
    # Fill completely
    check stack.push(10) == true
    check stack.push(20) == true
    check stack.push(30) == true
    
    check:
      stack.len() == 3
      stack.isFull() == true
      stack.isEmpty() == false
  
  test "should reject push when full":
    var stack: Stack[3, int]
    stack.init()
    
    # Fill to capacity
    check stack.push(1) == true
    check stack.push(2) == true
    check stack.push(3) == true
    check stack.isFull() == true
    
    # Cannot push more
    check stack.push(4) == false
    check stack.len() == 3  # Still only 3 items
  
  test "should return false when popping from empty stack":
    var stack: Stack[3, int]
    stack.init()
    
    var value: int
    check stack.pop(value) == false
    check stack.isEmpty() == true

suite "Stack: Peek Operation":
  test "should peek without removing":
    var stack: Stack[3, int]
    stack.init()
    
    discard stack.push(42)
    
    var value: int
    check stack.peek(value) == true
    check value == 42
    check stack.len() == 1  # Still there
    
    # Can peek again
    check stack.peek(value) == true
    check value == 42
  
  test "should return false when peeking empty stack":
    var stack: Stack[3, int]
    stack.init()
    
    var value: int
    check stack.peek(value) == false
  
  test "should peek at correct top element":
    var stack: Stack[5, int]
    stack.init()
    
    discard stack.push(10)
    discard stack.push(20)
    discard stack.push(30)
    
    var value: int
    check stack.peek(value) == true
    check value == 30  # Top element (last pushed)
    
    # Verify order by popping
    var val1, val2, val3: int
    check stack.pop(val1) == true
    check stack.pop(val2) == true
    check stack.pop(val3) == true
    check:
      val1 == 30
      val2 == 20
      val3 == 10

suite "Stack: Clear Operation":
  test "should clear all elements":
    var stack: Stack[5, int]
    stack.init()
    
    # Add some elements
    discard stack.push(1)
    discard stack.push(2)
    discard stack.push(3)
    check stack.len() == 3
    
    # Clear
    stack.clear()
    
    check:
      stack.len() == 0
      stack.isEmpty() == true
      stack.isFull() == false
  
  test "should be reusable after clear":
    var stack: Stack[3, int]
    stack.init()
    
    # First use
    discard stack.push(1)
    discard stack.push(2)
    stack.clear()
    
    # Second use
    check stack.push(10) == true
    check stack.push(20) == true
    
    var val1, val2: int
    check stack.pop(val1) == true
    check stack.pop(val2) == true
    
    check:
      val1 == 20  # LIFO order
      val2 == 10

suite "Stack: Edge Cases":
  test "should handle size 1 stack":
    var stack: Stack[1, int]
    stack.init()
    
    check stack.push(42) == true
    check stack.isFull() == true
    check stack.push(99) == false  # Can't push more
    
    var value: int
    check stack.pop(value) == true
    check value == 42
    check stack.isEmpty() == true
  
  test "should handle alternating push/pop":
    var stack: Stack[2, int]
    stack.init()
    
    var value: int
    
    # Cycle 1
    check stack.push(1) == true
    check stack.pop(value) == true
    check value == 1
    
    # Cycle 2
    check stack.push(2) == true
    check stack.pop(value) == true
    check value == 2
    
    # Cycle 3
    check stack.push(3) == true
    check stack.pop(value) == true
    check value == 3
    
    check stack.isEmpty() == true
  
  test "should handle float32 values":
    var stack: Stack[3, float32]
    stack.init()
    
    check stack.push(3.14) == true
    check stack.push(2.71) == true
    
    var val: float32
    check stack.pop(val) == true
    check abs(val - 2.71) < 0.001  # Last in, first out
  
  test "should maintain correct len() after multiple operations":
    var stack: Stack[5, int]
    stack.init()
    
    check stack.len() == 0
    
    discard stack.push(1)
    check stack.len() == 1
    
    discard stack.push(2)
    discard stack.push(3)
    check stack.len() == 3
    
    var val: int
    discard stack.pop(val)
    check stack.len() == 2
    
    discard stack.pop(val)
    discard stack.pop(val)
    check stack.len() == 0

suite "Stack: String Representation":
  test "should convert to string for debugging":
    var stack: Stack[10, int]
    stack.init()
    
    let emptyStr = $stack
    check "Stack[10, int]" in emptyStr
    check "count=0/10" in emptyStr
    
    discard stack.push(1)
    discard stack.push(2)
    discard stack.push(3)
    
    let filledStr = $stack
    check "count=3/10" in filledStr

suite "Stack: Practical Usage":
  test "should work as undo stack":
    var undoStack: Stack[16, int]
    undoStack.init()
    
    # Simulate user actions
    discard undoStack.push(100)  # Action 1
    discard undoStack.push(200)  # Action 2
    discard undoStack.push(300)  # Action 3
    
    # Undo in reverse order
    var action: int
    var undoneActions: seq[int] = @[]
    
    while undoStack.pop(action):
      undoneActions.add(action)
    
    check undoneActions == @[300, 200, 100]  # LIFO order
  
  test "should work for expression evaluation (RPN calculator)":
    var evalStack: Stack[8, int]
    evalStack.init()
    
    # Evaluate: 5 3 + 2 *  (i.e., (5+3)*2 = 16)
    discard evalStack.push(5)
    discard evalStack.push(3)
    
    # Pop for addition
    var b, a: int
    discard evalStack.pop(b)  # 3
    discard evalStack.pop(a)  # 5
    discard evalStack.push(a + b)  # Push 8
    
    discard evalStack.push(2)
    
    # Pop for multiplication
    discard evalStack.pop(b)  # 2
    discard evalStack.pop(a)  # 8
    discard evalStack.push(a * b)  # Push 16
    
    var result: int
    discard evalStack.pop(result)
    check result == 16
    check evalStack.isEmpty() == true
  
  test "should work for temporary value storage":
    var tempStack: Stack[4, float32]
    tempStack.init()
    
    # Store intermediate calculations
    discard tempStack.push(1.5)
    discard tempStack.push(2.0)
    discard tempStack.push(3.5)
    
    # Retrieve in reverse order for processing
    var sum: float32 = 0.0
    var val: float32
    
    while tempStack.pop(val):
      sum += val
    
    check abs(sum - 7.0) < 0.001
