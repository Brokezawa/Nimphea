## Data Structures Example
## 
## This example demonstrates the zero-heap-allocation data structures:
## - FIFO (First-In-First-Out queue)
## - Stack (Last-In-First-Out)
## - RingBuffer (Circular buffer for audio)
## - FixedStr (Stack-allocated string)
##
## All structures use compile-time fixed capacity for predictable memory usage
## and audio-rate safety (no heap allocation).

import ../src/nimphea
import ../src/nimphea_fifo
import ../src/nimphea_stack
import ../src/nimphea_ringbuffer
import ../src/nimphea_fixedstr

useNimpheaNamespace()

# Audio buffer example - delay line using RingBuffer
const DELAY_SAMPLES = 4096  # 85.3ms at 48kHz (nearest power of 2)

var
  daisy: DaisySeed
  delayBuffer: RingBuffer[DELAY_SAMPLES, float32]
  eventQueue: Fifo[16, int]  # Queue for MIDI-like events
  undoStack: Stack[8, float32]  # Undo stack for parameter changes
  displayText: FixedStr[32]  # Text for display
  sampleCounter: int = 0

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Audio callback demonstrating RingBuffer for delay effect
  for i in 0 ..< size:
    let drySignal = input[0][i]  # Left channel input
    
    # Read delayed signal from ring buffer
    var delayedSignal: float32 = 0.0
    discard delayBuffer.read(delayedSignal)
    
    # Write current input to ring buffer
    discard delayBuffer.write(drySignal)
    
    # Mix dry and delayed signals (50/50 mix)
    output[0][i] = (drySignal * 0.5) + (delayedSignal * 0.5)
    output[1][i] = output[0][i]  # Mono to stereo
  
  inc(sampleCounter)

proc demonstrateFifo() =
  ## Demonstrate FIFO queue for event handling
  echo "=== FIFO Queue Demo ==="
  
  var fifo: Fifo[8, int]
  fifo.init()
  
  # Push events
  echo "Pushing events: 1, 2, 3, 4"
  assert fifo.push(1)
  assert fifo.push(2)
  assert fifo.push(3)
  assert fifo.push(4)
  echo "Queue length: ", fifo.len(), " / ", fifo.capacity()
  
  # Pop events (FIFO order)
  var event: int
  while fifo.pop(event):
    echo "Processing event: ", event
  
  echo "Queue is now empty: ", fifo.isEmpty()
  echo ""

proc demonstrateStack() =
  ## Demonstrate Stack for undo/redo
  echo "=== Stack (Undo/Redo) Demo ==="
  
  var paramHistory: Stack[5, float32]
  paramHistory.init()
  
  # Record parameter changes
  echo "Recording parameter values: 0.0, 0.5, 0.7, 1.0"
  assert paramHistory.push(0.0)
  assert paramHistory.push(0.5)
  assert paramHistory.push(0.7)
  assert paramHistory.push(1.0)
  
  echo "History depth: ", paramHistory.len()
  
  # Undo (pop in reverse order)
  var value: float32
  echo "Undoing changes:"
  while paramHistory.pop(value):
    echo "  Restored value: ", value
  
  echo ""

proc demonstrateRingBuffer() =
  ## Demonstrate RingBuffer for audio buffering
  echo "=== RingBuffer (Audio Buffer) Demo ==="
  
  var audioBuffer: RingBuffer[16, float32]
  audioBuffer.init()
  
  # Write audio samples
  let samples = [0.1'f32, 0.2'f32, 0.3'f32, 0.4'f32, 0.5'f32]
  let written = audioBuffer.writeBlock(samples)
  echo "Wrote ", written, " samples to ring buffer"
  echo "Buffer contains: ", audioBuffer.available(), " / ", audioBuffer.capacity(), " samples"
  
  # Read back samples
  var readBuffer: array[5, float32]
  let readCount = audioBuffer.readBlock(readBuffer)
  echo "Read ", readCount, " samples:"
  for i in 0 ..< readCount:
    echo "  Sample[", i, "] = ", readBuffer[i]
  
  echo ""

proc demonstrateFixedStr() =
  ## Demonstrate FixedStr for display text
  echo "=== FixedStr (Display Text) Demo ==="
  
  var text: FixedStr[32]
  text.init()
  
  # Build display string
  discard text.add("Freq: ")
  discard text.add(440)
  discard text.add(" Hz")
  
  echo "Display text: '", $text, "'"
  echo "Length: ", text.len(), " / ", text.capacity()
  
  # Replace content
  discard text.set("Volume: 75%")
  echo "Updated text: '", $text, "'"
  
  # Character access
  text[0] = 'v'  # lowercase 'v'
  echo "Modified text: '", $text, "'"
  
  echo ""

proc demonstrateCapacityLimits() =
  ## Demonstrate capacity limits and overflow handling
  echo "=== Capacity Limits Demo ==="
  
  var smallFifo: Fifo[4, int]
  smallFifo.init()
  
  # Fill to capacity
  echo "Filling FIFO (capacity 4)..."
  for i in 0..3:
    if smallFifo.push(i):
      echo "  Pushed ", i, " (size: ", smallFifo.len(), ")"
  
  echo "FIFO is full: ", smallFifo.isFull()
  
  # Try to overflow
  if not smallFifo.push(99):
    echo "  Rejected value 99 - FIFO is full!"
  
  # Free space and add
  var dummy: int
  discard smallFifo.pop(dummy)
  echo "Popped one element, size now: ", smallFifo.len()
  
  if smallFifo.push(99):
    echo "  Successfully pushed 99 after freeing space"
  
  echo ""

proc main() =
  echo "======================================"
  echo "  Nimphea Data Structures Demo"
  echo "======================================"
  echo ""
  
  # Initialize hardware
  daisy.init()
  daisy.setBlockSize(48)
  
  # Initialize data structures
  delayBuffer.init()
  eventQueue.init()
  undoStack.init()
  displayText.init()
  
  # Run demonstrations
  demonstrateFifo()
  demonstrateStack()
  demonstrateRingBuffer()
  demonstrateFixedStr()
  demonstrateCapacityLimits()
  
  # Set up display text
  discard displayText.set("Delay: 100ms")
  echo "======================================"
  echo "Starting audio with delay effect..."
  echo "Display shows: '", $displayText, "'"
  echo "======================================"
  echo ""
  
  # Start audio processing with delay effect
  daisy.startAudio(audioCallback)
  
  # Main loop - blink LED to show running
  var ledState = false
  var loopCount = 0
  
  while true:
    ledState = not ledState
    daisy.setLed(ledState)
    daisy.delay(1000)
    
    inc(loopCount)
    
    # Print statistics every 5 seconds
    if loopCount mod 5 == 0:
      let seconds = loopCount
      let samplesProcessed = sampleCounter * 48  # 48 samples per callback
      echo "Runtime: ", seconds, "s | Samples: ", samplesProcessed, " | Buffer: ", delayBuffer.available()

when isMainModule:
  main()
