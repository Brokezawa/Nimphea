## Unit tests for FIFO (First-In-First-Out) queue
##
## Tests the pure Nim implementation of fixed-capacity FIFO.
## Follows libDaisy FIFO_gtest.cpp patterns where applicable.
##
## Run with: nimble test_unit

import unittest2
import std/strutils
import ../src/nimphea_fifo

suite "FIFO: Basic Properties":
  test "should report correct capacity":
    var fifo: Fifo[3, int]
    fifo.init()
    check fifo.capacity() == 3
  
  test "should start empty after init":
    var fifo: Fifo[5, int]
    fifo.init()
    check:
      fifo.len() == 0
      fifo.isEmpty() == true
      fifo.isFull() == false
  
  test "should work with different types":
    var intFifo: Fifo[4, int]
    var floatFifo: Fifo[4, float32]
    var boolFifo: Fifo[4, bool]
    
    intFifo.init()
    floatFifo.init()
    boolFifo.init()
    
    check:
      intFifo.isEmpty() == true
      floatFifo.isEmpty() == true
      boolFifo.isEmpty() == true

suite "FIFO: Push and Pop Operations":
  test "should push and pop single item (FIFO order)":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # Push single item
    check fifo.push(42) == true
    check:
      fifo.len() == 1
      fifo.isEmpty() == false
      fifo.isFull() == false
    
    # Pop single item
    var value: int
    check fifo.pop(value) == true
    check:
      value == 42
      fifo.len() == 0
      fifo.isEmpty() == true
  
  test "should maintain FIFO order (first-in-first-out)":
    var fifo: Fifo[5, int]
    fifo.init()
    
    # Push three values
    check fifo.push(1) == true
    check fifo.push(2) == true
    check fifo.push(3) == true
    check fifo.len() == 3
    
    # Pop in FIFO order
    var val1, val2, val3: int
    check fifo.pop(val1) == true
    check fifo.pop(val2) == true
    check fifo.pop(val3) == true
    
    check:
      val1 == 1  # First in, first out
      val2 == 2
      val3 == 3
  
  test "should fill to capacity":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # Fill completely
    check fifo.push(10) == true
    check fifo.push(20) == true
    check fifo.push(30) == true
    
    check:
      fifo.len() == 3
      fifo.isFull() == true
      fifo.isEmpty() == false
  
  test "should reject push when full":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # Fill to capacity
    check fifo.push(1) == true
    check fifo.push(2) == true
    check fifo.push(3) == true
    check fifo.isFull() == true
    
    # Cannot push more
    check fifo.push(4) == false
    check fifo.len() == 3  # Still only 3 items
  
  test "should return false when popping from empty queue":
    var fifo: Fifo[3, int]
    fifo.init()
    
    var value: int
    check fifo.pop(value) == false
    check fifo.isEmpty() == true

suite "FIFO: Wraparound Behavior":
  test "should wrap around buffer correctly":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # Fill queue
    check fifo.push(1) == true
    check fifo.push(2) == true
    check fifo.push(3) == true
    check fifo.isFull() == true
    
    # Pop one item (head advances)
    var val: int
    check fifo.pop(val) == true
    check val == 1
    check fifo.len() == 2
    
    # Push another (tail wraps around)
    check fifo.push(4) == true
    check fifo.len() == 3
    check fifo.isFull() == true
    
    # Pop all and verify order
    var val2, val3, val4: int
    check fifo.pop(val2) == true
    check fifo.pop(val3) == true
    check fifo.pop(val4) == true
    
    check:
      val2 == 2
      val3 == 3
      val4 == 4  # Wraparound worked correctly
  
  test "should handle multiple wraparounds":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # First cycle: Fill queue
    discard fifo.push(1)
    discard fifo.push(2)
    discard fifo.push(3)
    
    # Pop two items
    var val: int
    discard fifo.pop(val)  # Remove 1
    discard fifo.pop(val)  # Remove 2
    # Queue now has: 3
    
    # Second cycle: Add more (wraps around buffer)
    discard fifo.push(4)
    discard fifo.push(5)
    # Queue now has: 3, 4, 5 (full)
    
    # Pop one
    discard fifo.pop(val)  # Remove 3
    # Queue now has: 4, 5
    
    # Third cycle: Add more (wraps around again)
    discard fifo.push(6)
    # Queue now has: 4, 5, 6 (full)
    
    # Verify final state
    var v1, v2, v3: int
    check fifo.pop(v1) == true
    check fifo.pop(v2) == true
    check fifo.pop(v3) == true
    
    check:
      v1 == 4
      v2 == 5
      v3 == 6

suite "FIFO: Peek Operation":
  test "should peek without removing":
    var fifo: Fifo[3, int]
    fifo.init()
    
    discard fifo.push(42)
    
    var value: int
    check fifo.peek(value) == true
    check value == 42
    check fifo.len() == 1  # Still there
    
    # Can peek again
    check fifo.peek(value) == true
    check value == 42
  
  test "should return false when peeking empty queue":
    var fifo: Fifo[3, int]
    fifo.init()
    
    var value: int
    check fifo.peek(value) == false
  
  test "should peek at correct front element":
    var fifo: Fifo[3, int]
    fifo.init()
    
    discard fifo.push(10)
    discard fifo.push(20)
    discard fifo.push(30)
    
    var value: int
    check fifo.peek(value) == true
    check value == 10  # Front element (FIFO)

suite "FIFO: Clear Operation":
  test "should clear all elements":
    var fifo: Fifo[5, int]
    fifo.init()
    
    # Add some elements
    discard fifo.push(1)
    discard fifo.push(2)
    discard fifo.push(3)
    check fifo.len() == 3
    
    # Clear
    fifo.clear()
    
    check:
      fifo.len() == 0
      fifo.isEmpty() == true
      fifo.isFull() == false
  
  test "should be reusable after clear":
    var fifo: Fifo[3, int]
    fifo.init()
    
    # First use
    discard fifo.push(1)
    discard fifo.push(2)
    fifo.clear()
    
    # Second use
    check fifo.push(10) == true
    check fifo.push(20) == true
    
    var val1, val2: int
    check fifo.pop(val1) == true
    check fifo.pop(val2) == true
    
    check:
      val1 == 10
      val2 == 20

suite "FIFO: Edge Cases":
  test "should handle size 1 queue":
    var fifo: Fifo[1, int]
    fifo.init()
    
    check fifo.push(42) == true
    check fifo.isFull() == true
    check fifo.push(99) == false  # Can't push more
    
    var value: int
    check fifo.pop(value) == true
    check value == 42
    check fifo.isEmpty() == true
  
  test "should handle alternating push/pop":
    var fifo: Fifo[2, int]
    fifo.init()
    
    var value: int
    
    # Cycle 1
    check fifo.push(1) == true
    check fifo.pop(value) == true
    check value == 1
    
    # Cycle 2
    check fifo.push(2) == true
    check fifo.pop(value) == true
    check value == 2
    
    # Cycle 3
    check fifo.push(3) == true
    check fifo.pop(value) == true
    check value == 3
    
    check fifo.isEmpty() == true
  
  test "should handle float32 values":
    var fifo: Fifo[3, float32]
    fifo.init()
    
    check fifo.push(3.14) == true
    check fifo.push(2.71) == true
    
    var val: float32
    check fifo.pop(val) == true
    check abs(val - 3.14) < 0.001

suite "FIFO: String Representation":
  test "should convert to string for debugging":
    var fifo: Fifo[8, int]
    fifo.init()
    
    let emptyStr = $fifo
    check "Fifo[8, int]" in emptyStr
    check "count=0/8" in emptyStr
    
    discard fifo.push(1)
    discard fifo.push(2)
    
    let filledStr = $fifo
    check "count=2/8" in filledStr

suite "FIFO: Practical Usage":
  test "should work as event queue":
    var eventQueue: Fifo[16, int]
    eventQueue.init()
    
    # Simulate events arriving
    discard eventQueue.push(101)  # Event ID 101
    discard eventQueue.push(102)
    discard eventQueue.push(103)
    
    # Process events in order
    var event: int
    var processedEvents: seq[int] = @[]
    
    while eventQueue.pop(event):
      processedEvents.add(event)
    
    check processedEvents == @[101, 102, 103]
  
  test "should work as circular buffer for streaming":
    var buffer: Fifo[4, float32]
    buffer.init()
    
    # Fill buffer
    discard buffer.push(1.0)
    discard buffer.push(2.0)
    discard buffer.push(3.0)
    discard buffer.push(4.0)
    
    # Stream: remove old, add new
    var old: float32
    discard buffer.pop(old)
    discard buffer.push(5.0)
    
    # Verify streaming behavior
    var values: seq[float32] = @[]
    var val: float32
    while buffer.pop(val):
      values.add(val)
    
    check values == @[2.0'f32, 3.0'f32, 4.0'f32, 5.0'f32]
