## Unit tests for RingBuffer (Circular Buffer)
##
## Tests the pure Nim implementation of lock-free ring buffer.
## RingBuffer is optimized for audio streaming with power-of-2 sizes.
##
## Run with: nimble test_unit

import unittest2
import std/strutils
import ../src/nimphea_ringbuffer

suite "RingBuffer: Basic Properties":
  test "should report correct capacity":
    var buffer: RingBuffer[8, int]
    buffer.init()
    check buffer.capacity() == 8
  
  test "should start empty after init":
    var buffer: RingBuffer[16, int]
    buffer.init()
    check:
      buffer.available() == 0
      buffer.isEmpty() == true
      buffer.isFull() == false
  
  test "should work with different types":
    var intBuffer: RingBuffer[4, int]
    var floatBuffer: RingBuffer[4, float32]
    
    intBuffer.init()
    floatBuffer.init()
    
    check:
      intBuffer.isEmpty() == true
      floatBuffer.isEmpty() == true
  
  test "should enforce power-of-2 size at compile time":
    # These should compile (power of 2)
    var buf2: RingBuffer[2, int]
    var buf4: RingBuffer[4, int]
    var buf8: RingBuffer[8, int]
    var buf16: RingBuffer[16, int]
    var buf32: RingBuffer[32, int]
    var buf64: RingBuffer[64, int]
    var buf128: RingBuffer[128, int]
    var buf256: RingBuffer[256, int]
    var buf512: RingBuffer[512, int]
    var buf1024: RingBuffer[1024, int]
    
    buf2.init()
    buf4.init()
    buf8.init()
    buf16.init()
    buf32.init()
    buf64.init()
    buf128.init()
    buf256.init()
    buf512.init()
    buf1024.init()
    
    check:
      buf2.capacity() == 2
      buf1024.capacity() == 1024
    
    # Note: Non-power-of-2 sizes (3, 5, 6, 7, 9, 100, 500) would fail at compile time

suite "RingBuffer: Write and Read Operations":
  test "should write and read single value":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    check buffer.write(42) == true
    check:
      buffer.available() == 1
      buffer.isEmpty() == false
    
    var value: int
    check buffer.read(value) == true
    check:
      value == 42
      buffer.isEmpty() == true
  
  test "should maintain FIFO order":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    check buffer.write(1) == true
    check buffer.write(2) == true
    check buffer.write(3) == true
    check buffer.available() == 3
    
    var val1, val2, val3: int
    check buffer.read(val1) == true
    check buffer.read(val2) == true
    check buffer.read(val3) == true
    
    check:
      val1 == 1  # First in, first out
      val2 == 2
      val3 == 3
  
  test "should return false when reading from empty buffer":
    var buffer: RingBuffer[4, int]
    buffer.init()
    
    var value: int
    check buffer.read(value) == false

suite "RingBuffer: Overwrite Modes":
  test "should overwrite oldest in OVERWRITE_OLDEST mode":
    var buffer: RingBuffer[4, int]
    buffer.init(OVERWRITE_OLDEST)
    
    # Fill buffer (capacity - 1 due to full/empty distinction)
    check buffer.write(1) == true
    check buffer.write(2) == true
    check buffer.write(3) == true
    check buffer.isFull() == true
    
    # Write more - should overwrite oldest
    check buffer.write(4) == true  # Overwrites 1
    check buffer.write(5) == true  # Overwrites 2
    
    # Read back - should get newer values
    var val: int
    check buffer.read(val) == true
    check val == 3  # Oldest remaining
    check buffer.read(val) == true
    check val == 4
    check buffer.read(val) == true
    check val == 5
  
  test "should reject new writes in REJECT_NEW mode":
    var buffer: RingBuffer[4, int]
    buffer.init(REJECT_NEW)
    
    # Fill buffer
    check buffer.write(1) == true
    check buffer.write(2) == true
    check buffer.write(3) == true
    check buffer.isFull() == true
    
    # Cannot write more
    check buffer.write(4) == false
    check buffer.write(5) == false
    
    # Original data preserved
    var val: int
    check buffer.read(val) == true
    check val == 1  # Original oldest value

suite "RingBuffer: Wraparound Behavior":
  test "should wrap around buffer correctly":
    var buffer: RingBuffer[4, int]
    buffer.init()
    
    # First cycle
    check buffer.write(1) == true
    check buffer.write(2) == true
    check buffer.write(3) == true
    
    # Read some
    var val: int
    check buffer.read(val) == true
    check val == 1
    
    # Write more (wraps around)
    check buffer.write(4) == true
    check buffer.write(5) == true  # Should overwrite oldest
    
    # Read remaining
    var vals: seq[int] = @[]
    while buffer.read(val):
      vals.add(val)
    
    check vals == @[3, 4, 5]  # 2 was overwritten
  
  test "should handle multiple wraparounds":
    var buffer: RingBuffer[4, int]
    buffer.init(OVERWRITE_OLDEST)
    
    # Multiple write/read cycles
    for cycle in 0..<10:
      let base = cycle * 10
      discard buffer.write(base + 1)
      discard buffer.write(base + 2)
      
      var val: int
      if cycle > 0:
        discard buffer.read(val)
    
    # Buffer should still work correctly
    check buffer.available() > 0

suite "RingBuffer: Available and Remaining":
  test "should report correct available count":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    check buffer.available() == 0
    
    discard buffer.write(1)
    check buffer.available() == 1
    
    discard buffer.write(2)
    discard buffer.write(3)
    check buffer.available() == 3
    
    var val: int
    discard buffer.read(val)
    check buffer.available() == 2
  
  test "should report correct remaining space":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    # Empty buffer has capacity-1 remaining (due to full/empty distinction)
    check buffer.remaining() == 7
    
    discard buffer.write(1)
    check buffer.remaining() == 6
    
    discard buffer.write(2)
    discard buffer.write(3)
    check buffer.remaining() == 4

suite "RingBuffer: Block Operations":
  test "should write block of values":
    var buffer: RingBuffer[16, int]
    buffer.init()
    
    var data: array[5, int] = [10, 20, 30, 40, 50]
    let written = buffer.writeBlock(data)
    
    check:
      written == 5
      buffer.available() == 5
  
  test "should read block of values":
    var buffer: RingBuffer[16, int]
    buffer.init()
    
    # Write some data
    discard buffer.write(1)
    discard buffer.write(2)
    discard buffer.write(3)
    discard buffer.write(4)
    
    # Read as block
    var data: array[4, int]
    let readCount = buffer.readBlock(data)
    
    check:
      readCount == 4
      data == [1, 2, 3, 4]
      buffer.isEmpty() == true
  
  test "should handle partial block writes when buffer gets full":
    var buffer: RingBuffer[4, int]
    buffer.init(REJECT_NEW)
    
    # Write 3 items (buffer capacity is 4, but can only hold 3 due to full/empty distinction)
    var data: array[5, int] = [1, 2, 3, 4, 5]
    let written = buffer.writeBlock(data)
    
    check written == 3  # Only 3 fit
  
  test "should handle partial block reads when buffer has less data":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    # Write 3 items
    discard buffer.write(10)
    discard buffer.write(20)
    discard buffer.write(30)
    
    # Try to read 5
    var data: array[5, int]
    let readCount = buffer.readBlock(data)
    
    check:
      readCount == 3  # Only 3 available
      data[0] == 10
      data[1] == 20
      data[2] == 30

suite "RingBuffer: Peek Operation":
  test "should peek without removing":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    discard buffer.write(42)
    discard buffer.write(99)
    
    var value: int
    check buffer.peek(value) == true
    check value == 42
    check buffer.available() == 2  # Still there
  
  test "should peek with offset":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    discard buffer.write(10)
    discard buffer.write(20)
    discard buffer.write(30)
    discard buffer.write(40)
    
    var val: int
    check buffer.peek(val, 0) == true
    check val == 10  # First element
    
    check buffer.peek(val, 1) == true
    check val == 20  # Second element
    
    check buffer.peek(val, 2) == true
    check val == 30  # Third element
    
    check buffer.peek(val, 3) == true
    check val == 40  # Fourth element
    
    check buffer.peek(val, 4) == false  # Out of range
  
  test "should return false when peeking empty buffer":
    var buffer: RingBuffer[4, int]
    buffer.init()
    
    var value: int
    check buffer.peek(value) == false

suite "RingBuffer: Clear Operation":
  test "should clear all data":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    discard buffer.write(1)
    discard buffer.write(2)
    discard buffer.write(3)
    check buffer.available() == 3
    
    buffer.clear()
    
    check:
      buffer.available() == 0
      buffer.isEmpty() == true
  
  test "should be reusable after clear":
    var buffer: RingBuffer[8, int]
    buffer.init()
    
    # First use
    discard buffer.write(1)
    discard buffer.write(2)
    buffer.clear()
    
    # Second use
    check buffer.write(10) == true
    check buffer.write(20) == true
    
    var val: int
    check buffer.read(val) == true
    check val == 10

suite "RingBuffer: Edge Cases":
  test "should handle size 2 buffer (minimum power of 2)":
    var buffer: RingBuffer[2, int]
    buffer.init()
    
    # Can only hold 1 item (due to full/empty distinction)
    check buffer.write(42) == true
    check buffer.isFull() == true
    
    var value: int
    check buffer.read(value) == true
    check value == 42
  
  test "should handle alternating write/read":
    var buffer: RingBuffer[4, int]
    buffer.init()
    
    var value: int
    
    for i in 1..100:
      check buffer.write(i) == true
      check buffer.read(value) == true
      check value == i
    
    check buffer.isEmpty() == true
  
  test "should handle float32 values":
    var buffer: RingBuffer[8, float32]
    buffer.init()
    
    check buffer.write(3.14) == true
    check buffer.write(2.71) == true
    
    var val: float32
    check buffer.read(val) == true
    check abs(val - 3.14) < 0.001

suite "RingBuffer: String Representation":
  test "should convert to string for debugging":
    var buffer: RingBuffer[16, int]
    buffer.init()
    
    let emptyStr = $buffer
    check "RingBuffer[16, int]" in emptyStr
    check "available=0/16" in emptyStr
    
    discard buffer.write(1)
    discard buffer.write(2)
    discard buffer.write(3)
    
    let filledStr = $buffer
    check "available=3/16" in filledStr

suite "RingBuffer: Practical Usage":
  test "should work as audio delay line":
    var delayLine: RingBuffer[1024, float32]
    delayLine.init()
    
    # Fill with audio samples
    for i in 0..<512:
      discard delayLine.write(float32(i) * 0.01)
    
    check delayLine.available() == 512
    
    # Read delayed samples
    var sample: float32
    check delayLine.read(sample) == true
    check abs(sample - 0.0) < 0.001
  
  test "should work for inter-thread communication":
    var messageQueue: RingBuffer[32, int]
    messageQueue.init()
    
    # Producer writes messages
    var messages: array[10, int] = [101, 102, 103, 104, 105, 106, 107, 108, 109, 110]
    let written = messageQueue.writeBlock(messages)
    check written == 10
    
    # Consumer reads messages
    var received: array[10, int]
    let readCount = messageQueue.readBlock(received)
    
    check:
      readCount == 10
      received == messages
  
  test "should work for streaming data processing":
    var streamBuffer: RingBuffer[64, float32]
    streamBuffer.init()
    
    # Simulate streaming: write chunk, process chunk, repeat
    for chunk in 0..<5:
      # Write chunk
      var input: array[8, float32]
      for i in 0..<8:
        input[i] = float32(chunk * 8 + i)
      
      let written = streamBuffer.writeBlock(input)
      check written == 8
      
      # Process chunk
      var output: array[8, float32]
      let readCount = streamBuffer.readBlock(output)
      check readCount == 8
      
      # Verify data integrity
      for i in 0..<8:
        check abs(output[i] - input[i]) < 0.001
