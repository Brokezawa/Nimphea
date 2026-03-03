## Unit tests for FixedStr module
##
## Tests stack-allocated fixed-capacity string implementation.
## Mirrors libDaisy's FixedCapStr_gtest.cpp test suite.

import unittest2
import nimphea/nimphea_fixedstr

suite "FixedStr - Basics":
  test "Empty string has zero length":
    var str: FixedStr[8]
    str.init()
    check str.len() == 0
    check str.isEmpty()
  
  test "Capacity returns compile-time size":
    var str8: FixedStr[8]
    var str16: FixedStr[16]
    var str32: FixedStr[32]
    check str8.capacity() == 8
    check str16.capacity() == 16
    check str32.capacity() == 32
  
  test "Length reflects current content":
    var str: FixedStr[16]
    str.init()
    discard str.add("test")
    check str.len() == 4
    discard str.add("123")
    check str.len() == 7
  
  test "isEmpty works correctly":
    var str: FixedStr[8]
    str.init()
    check str.isEmpty() == true
    discard str.add('a')
    check str.isEmpty() == false
  
  test "isFull detects full capacity":
    var str: FixedStr[4]
    str.init()
    check str.isFull() == false
    discard str.add("test")
    check str.isFull() == true
  
  test "Clear resets to empty":
    var str: FixedStr[16]
    str.init()
    discard str.add("Hello World")
    check str.len() == 11
    str.clear()
    check str.len() == 0
    check str.isEmpty() == true

suite "FixedStr - Adding Content":
  test "Add single character":
    var str: FixedStr[8]
    str.init()
    check str.add('H') == true
    check str.add('i') == true
    check str.len() == 2
  
  test "Add single character to full string fails":
    var str: FixedStr[2]
    str.init()
    check str.add('A') == true
    check str.add('B') == true
    check str.add('C') == false  # Full, should fail
    check str.len() == 2
  
  test "Add string returns characters added":
    var str: FixedStr[16]
    str.init()
    let added = str.add("Hello")
    check added == 5
    check str.len() == 5
  
  test "Add string truncates at capacity":
    var str: FixedStr[8]
    str.init()
    discard str.add("Hello")  # 5 chars
    let added = str.add("World")  # Try to add 5 more (only 3 fit)
    check added == 3
    check str.len() == 8
    check str.isFull() == true
  
  test "Add integer converts to string":
    var str: FixedStr[16]
    str.init()
    discard str.add("Value: ")
    discard str.add(42)
    check $str == "Value: 42"
  
  test "Add float converts to string":
    var str: FixedStr[16]
    str.init()
    discard str.add("Pi: ")
    discard str.add(3.14)
    # Note: Float formatting may vary, just check it added something
    check str.len() > 4

suite "FixedStr - Conversion":
  test "Dollar operator converts to string":
    var str: FixedStr[16]
    str.init()
    discard str.add("Hello")
    check $str == "Hello"
  
  test "Empty string converts to empty":
    var str: FixedStr[8]
    str.init()
    check $str == ""
  
  test "Full string converts correctly":
    var str: FixedStr[5]
    str.init()
    discard str.add("12345")
    check $str == "12345"

suite "FixedStr - Edge Cases":
  test "Zero-length after clear can be reused":
    var str: FixedStr[16]
    str.init()
    discard str.add("First")
    str.clear()
    discard str.add("Second")
    check $str == "Second"
  
  test "Adding empty string is safe":
    var str: FixedStr[8]
    str.init()
    let added = str.add("")
    check added == 0
    check str.len() == 0
  
  test "Multiple clears are safe":
    var str: FixedStr[8]
    str.init()
    str.clear()
    str.clear()
    str.clear()
    check str.len() == 0
  
  test "Very small capacity (1 char) works":
    var str: FixedStr[1]
    str.init()
    check str.add('A') == true
    check str.add('B') == false  # Full
    check str.len() == 1
    check $str == "A"

suite "FixedStr - Practical Usage":
  test "Display formatting example":
    var display: FixedStr[32]
    display.init()
    discard display.add("Freq: ")
    discard display.add(440)
    discard display.add(" Hz")
    check $display == "Freq: 440 Hz"
  
  test "Parameter display with units":
    var param: FixedStr[16]
    param.init()
    discard param.add("Vol: ")
    discard param.add(75)
    discard param.add("%")
    check $param == "Vol: 75%"
  
  test "Reusing same buffer multiple times":
    var buffer: FixedStr[16]
    
    # First use
    buffer.init()
    discard buffer.add("Line 1")
    check $buffer == "Line 1"
    
    # Second use
    buffer.clear()
    discard buffer.add("Line 2")
    check $buffer == "Line 2"
    
    # Third use
    buffer.clear()
    discard buffer.add("Line 3")
    check $buffer == "Line 3"
