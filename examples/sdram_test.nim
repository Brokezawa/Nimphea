## SDRAM Test Example
## 
## This example demonstrates using external SDRAM for large data buffers.
## It allocates a buffer in SDRAM, fills it with test data, and verifies access.
## LED blinks to indicate different states:
## - Fast blink (100ms): SDRAM init failed
## - Slow blink (500ms): Memory test failed
## - 3 quick blinks then steady on: Test passed

import ../src/nimphea
import ../src/sys/sdram
useNimpheaNamespace()


# Allocate 1MB buffer in SDRAM BSS (uninitialized)
var testBuffer {.codegenDecl: "$# $# __attribute__((section(\".sdram_bss\")))".}: array[262144, float32]  # 1MB = 262144 floats

proc testMemoryAccess(): bool =
  ## Test basic SDRAM read/write operations
  # Write test pattern to first 1000 elements
  for i in 0..<1000:
    testBuffer[i] = float32(i * 2)
  
  # Verify written data
  for i in 0..<1000:
    if testBuffer[i] != float32(i * 2):
      return false
  
  # Write and verify at end of buffer
  let lastIdx = len(testBuffer) - 1
  testBuffer[lastIdx] = 999.999
  if testBuffer[lastIdx] != 999.999:
    return false
  
  return true

proc main() =
  var daisy = initDaisy()
  var sdram = newSdramHandle()
  
  # Initialize SDRAM
  if sdram.init() != SDRAM_OK:
    # Init failed - fast blink
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)
  
  # Clear SDRAM BSS section
  clearSdramBss()
  
  daisy.delay(100)
  
  # Run memory test
  let testPassed = testMemoryAccess()
  
  if not testPassed:
    # Test failed - slow blink
    while true:
      daisy.setLed(true)
      daisy.delay(500)
      daisy.setLed(false)
      daisy.delay(500)
  
  # Success! Quick blinks 3 times
  for i in 0..2:
    daisy.setLed(true)
    daisy.delay(100)
    daisy.setLed(false)
    daisy.delay(100)
  
  # LED on steady to indicate success
  daisy.setLed(true)
  
  # Main loop - fill buffer with pattern
  var counter: int = 0
  while true:
    # Fill a portion of buffer each iteration
    let start = (counter mod 256) * 1024
    for i in 0..<1024:
      if start + i < len(testBuffer):
        testBuffer[start + i] = float32(counter)
    
    counter.inc
    daisy.delay(10)

when isMainModule:
  main()
