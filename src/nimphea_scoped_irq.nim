## Scoped IRQ Blocker
## ===================
##
## RAII (Resource Acquisition Is Initialization) interrupt blocking for Daisy hardware.
##
## This module provides safe, automatic interrupt management using C++'s RAII pattern.
## When a `ScopedIrqBlocker` object is created, interrupts are disabled. When the object
## goes out of scope (destroyed), interrupts are automatically restored to their previous state.
##
## Why Disable Interrupts?
## ------------------------
##
## Interrupts can cause **race conditions** and **data corruption** when:
##
## 1. **Sharing data** between main code and interrupt handlers (ISRs)
## 2. **Accessing hardware peripherals** that are also used by ISRs
## 3. **Critical timing sections** that must execute without interruption
##
## **Example problem without protection:**
##
## .. code-block:: nim
##    # Main code
##    var counter = 0
##    counter = 100  # Step 1: Write 100
##    # [INTERRUPT OCCURS HERE - ISR increments counter to 101]
##    # Step 2: Code expects counter = 100, but it's now 101!
##
## **Solution: Disable interrupts during critical section:**
##
## .. code-block:: nim
##    var blocker = ScopedIrqBlocker()  # Interrupts disabled
##    counter = 100
##    # blocker destroyed here - interrupts re-enabled automatically
##
## RAII Pattern Advantages
## -----------------------
##
## Traditional approach (error-prone):
##
## .. code-block:: nim
##    disableInterrupts()
##    criticalOperation()
##    enableInterrupts()  # PROBLEM: If criticalOperation() fails, 
##                        # this line might not execute!
##
## RAII approach (automatic cleanup):
##
## .. code-block:: nim
##    block:
##      var blocker = ScopedIrqBlocker()  # Interrupts disabled
##      criticalOperation()
##      # blocker destroyed automatically at end of block
##      # Interrupts re-enabled even if criticalOperation() fails!
##
## The RAII pattern **guarantees** interrupts are restored, even if:
## - Early return from function
## - Exception raised
## - Code panics
##
## Basic Usage
## -----------
##
## **Example 1: Protect shared variable**
##
## .. code-block:: nim
##    var sharedCounter: uint32 = 0
##    
##    proc incrementCounter() =
##      # ISR might also modify sharedCounter
##      block:
##        var blocker = ScopedIrqBlocker()  # Disable IRQs
##        sharedCounter += 1                 # Atomic operation
##      # blocker destroyed - IRQs restored
##
## **Example 2: Protect hardware access**
##
## .. code-block:: nim
##    proc updateDisplay() =
##      block:
##        var blocker = ScopedIrqBlocker()  # Disable IRQs
##        # SPI bus also used by audio ISR - must protect
##        spi.transmit(displayData.addr, 128)
##      # blocker destroyed - IRQs restored
##
## **Example 3: Multiple operations**
##
## .. code-block:: nim
##    proc updateState() =
##      block:
##        var blocker = ScopedIrqBlocker()
##        # All these operations are atomic
##        state.position = newPosition
##        state.velocity = newVelocity
##        state.timestamp = getNow()
##      # One atomic update - no partial state visible to ISRs
##
## Nim Template Wrapper
## --------------------
##
## This module provides a convenient `withoutInterrupts` template:
##
## .. code-block:: nim
##    withoutInterrupts:
##      # Code here runs with interrupts disabled
##      sharedCounter += 1
##      hardwareRegister.write(value)
##    # Interrupts automatically restored here
##
## This is more idiomatic Nim than creating the blocker object manually.
##
## Performance Considerations
## --------------------------
##
## **Keep critical sections SHORT:**
##
## - ❌ **BAD**: Disable interrupts for milliseconds
## - ✅ **GOOD**: Disable interrupts for microseconds
##
## While interrupts are disabled:
## - Audio callback **cannot run** (causes audio glitches)
## - Timer interrupts **are missed** (timing drift)
## - USB/UART **cannot receive data** (data loss)
##
## **Example: TOO LONG**
##
## .. code-block:: nim
##    withoutInterrupts:
##      delay(10)  # ❌ 10ms with no interrupts = audio glitches!
##
## **Example: APPROPRIATE**
##
## .. code-block:: nim
##    withoutInterrupts:
##      register.bits = value  # ✅ Single instruction, a few cycles
##
## When to Use
## -----------
##
## **✅ Use ScopedIrqBlocker when:**
##
## - Modifying variables shared with ISRs (audio callback, timers)
## - Accessing hardware peripherals used by interrupts
## - Reading/writing multi-word data (must be atomic)
## - Critical timing sections (e.g., bit-banging protocols)
##
## **❌ Do NOT use when:**
##
## - Data is NOT shared with ISRs (unnecessary overhead)
## - Already in an ISR (interrupts are already disabled)
## - Operation takes > 100 microseconds (too long)
## - Better synchronization exists (atomic operations, lock-free queues)
##
## Complete Examples
## -----------------
##
## **Example 1: Ring buffer for audio samples**
##
## .. code-block:: nim
##    type RingBuffer = object
##      data: array[1024, float32]
##      writeIndex: uint32
##      readIndex: uint32
##    
##    var buffer: RingBuffer
##    
##    proc audioCallback(input: ptr float32, output: ptr float32, size: int) =
##      # ISR writes to buffer
##      for i in 0..<size:
##        withoutInterrupts:
##          buffer.data[buffer.writeIndex] = input[i]
##          buffer.writeIndex = (buffer.writeIndex + 1) mod 1024
##    
##    proc processAudio() =
##      # Main loop reads from buffer
##      while true:
##        var sample: float32
##        withoutInterrupts:
##          sample = buffer.data[buffer.readIndex]
##          buffer.readIndex = (buffer.readIndex + 1) mod 1024
##        processSample(sample)
##
## **Example 2: State machine with atomic transitions**
##
## .. code-block:: nim
##    type State = enum
##      IDLE, ATTACK, DECAY, SUSTAIN, RELEASE
##    
##    var currentState = IDLE
##    var stateStartTime: uint32
##    
##    proc changeState(newState: State) =
##      withoutInterrupts:
##        # Atomic state transition
##        currentState = newState
##        stateStartTime = getNow()
##      # Both values updated together - no race condition
##
## **Example 3: Hardware register sequence**
##
## .. code-block:: nim
##    proc configureSpi() =
##      withoutInterrupts:
##        # Multi-step hardware configuration must be atomic
##        spiRegisters.CR1 = 0  # Disable SPI
##        spiRegisters.CR2 = configValue
##        spiRegisters.CR1 = SPI_ENABLE  # Re-enable
##      # Configuration complete before ISR can use SPI
##
## Implementation Details
## ----------------------
##
## The C++ implementation uses ARM Cortex-M PRIMASK register:
##
## 1. **Constructor**: 
##    - Save current PRIMASK (interrupt enable/disable state)
##    - Call `__disable_irq()` (sets PRIMASK bit)
##
## 2. **Destructor**:
##    - If interrupts were previously enabled (PRIMASK was 0)
##    - Call `__enable_irq()` (clears PRIMASK bit)
##
## This ensures **nesting works correctly**:
##
## .. code-block:: nim
##    # Interrupts initially enabled
##    withoutInterrupts:        # Disable (PRIMASK = 1)
##      withoutInterrupts:      # Already disabled, save state
##        criticalOp()
##      # Inner blocker: Don't re-enable (PRIMASK was 1)
##    # Outer blocker: Re-enable (PRIMASK was 0)
##
## See Also
## --------
## - `sys/system <system.html>`_ - Timing functions
## - `examples/system_control.nim` - Interrupt protection examples

import nimphea
import nimphea_macros

useNimpheaModules(scoped_irq)

{.push header: "util/scopedirqblocker.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  ScopedIrqBlocker* {.importcpp: "daisy::ScopedIrqBlocker".} = object
    ## RAII interrupt blocker for critical sections.
    ##
    ## When created, disables all interrupts (sets ARM PRIMASK).
    ## When destroyed, restores interrupts to previous state.
    ##
    ## **Usage:**
    ## ```nim
    ## block:
    ##   var blocker = ScopedIrqBlocker()  # IRQs disabled
    ##   criticalOperation()
    ## # blocker destroyed - IRQs restored
    ## ```
    ##
    ## **Internal state:**
    ## - Saves previous PRIMASK value (interrupt enable state)
    ## - Restores PRIMASK on destruction (if interrupts were enabled)
    ##
    ## **Note**: Prefer the `withoutInterrupts` template for cleaner syntax.

{.pop.} # header

# ============================================================================
# C++ Constructor Wrapper
# ============================================================================

proc initScopedIrqBlocker*(): ScopedIrqBlocker {.
  importcpp: "daisy::ScopedIrqBlocker(@)", constructor.}
  ## Create a ScopedIrqBlocker object (disables interrupts).
  ##
  ## **Returns:** ScopedIrqBlocker instance
  ##
  ## **Side effect:** Interrupts are disabled immediately
  ##
  ## **Example:**
  ## ```nim
  ## block:
  ##   var blocker = initScopedIrqBlocker()
  ##   sharedVariable = newValue  # Protected from ISRs
  ## # blocker destroyed - interrupts restored
  ## ```
  ##
  ## **Note**: Usually not called directly - use `withoutInterrupts` template.

# ============================================================================
# Nim Helper Templates
# ============================================================================

template withoutInterrupts*(body: untyped) =
  ## Execute code block with interrupts disabled (RAII protection).
  ##
  ## This is the **recommended way** to use ScopedIrqBlocker in Nim.
  ##
  ## **Guarantees:**
  ## - Interrupts disabled before `body` executes
  ## - Interrupts restored after `body` completes
  ## - Restoration happens even if `body` returns early or raises
  ##
  ## **Parameters:**
  ## - `body` - Code to execute with interrupts disabled
  ##
  ## **Example:**
  ## ```nim
  ## var counter: uint32 = 0
  ## 
  ## withoutInterrupts:
  ##   counter += 1  # Atomic increment
  ## # Interrupts restored here
  ## ```
  ##
  ## **Nested calls work correctly:**
  ## ```nim
  ## withoutInterrupts:
  ##   operation1()
  ##   withoutInterrupts:
  ##     operation2()  # Still protected
  ##   operation3()
  ## # Interrupts restored only once at outermost level
  ## ```
  ##
  ## **Early return is safe:**
  ## ```nim
  ## proc example(): bool =
  ##   withoutInterrupts:
  ##     if errorCondition:
  ##       return false  # Interrupts still restored!
  ##     criticalOp()
  ##   return true
  ## ```
  block:
    var blocker {.used.} = initScopedIrqBlocker()
    body

template criticalSection*(body: untyped) =
  ## Alias for `withoutInterrupts` (alternative name).
  ##
  ## Identical functionality to `withoutInterrupts`, just a different name.
  ## Use whichever reads better in your code.
  ##
  ## **Example:**
  ## ```nim
  ## criticalSection:
  ##   hardwareRegister.write(value)
  ## ```
  withoutInterrupts:
    body

template atomicBlock*(body: untyped) =
  ## Alias for `withoutInterrupts` (alternative name).
  ##
  ## Emphasizes that the code block executes atomically (no interruption).
  ##
  ## **Example:**
  ## ```nim
  ## atomicBlock:
  ##   state.x = newX
  ##   state.y = newY
  ## # Both updated together - no partial state visible to ISRs
  ## ```
  withoutInterrupts:
    body

# ============================================================================
# Usage Patterns
# ============================================================================

when isMainModule:
  ## Compile-time examples (not executable without hardware)
  
  # Example 1: Protect shared variable
  block:
    var sharedCounter: uint32 = 0
    
    proc incrementSafely() =
      withoutInterrupts:
        sharedCounter += 1
    
    incrementSafely()
  
  # Example 2: Atomic multi-field update
  block:
    type Position = object
      x, y: float32
      timestamp: uint32
    
    var currentPosition: Position
    
    proc updatePosition(newX, newY: float32) =
      withoutInterrupts:
        currentPosition.x = newX
        currentPosition.y = newY
        currentPosition.timestamp = 123  # getNow()
  
  # Example 3: Hardware register sequence
  block:
    type Register = object
      value: uint32
    
    var hwRegister: Register
    
    proc configureHardware() =
      withoutInterrupts:
        hwRegister.value = 0x1234
        # Multiple register writes atomic
  
  # Example 4: Nested critical sections
  block:
    var data: uint32
    
    proc inner() =
      withoutInterrupts:  # Nesting is safe
        data = 200
    
    proc outer() =
      withoutInterrupts:
        data = 100
        inner()
    
    outer()
  
  # Example 5: Using alternative names
  block:
    var state: uint32
    
    criticalSection:
      state = 42
    
    atomicBlock:
      state = 43
  
  # Example 6: Ring buffer (shared with ISR)
  block:
    type RingBuffer = object
      data: array[256, float32]
      writeIndex: uint32
      readIndex: uint32
    
    var buffer: RingBuffer
    
    proc writeToBuffer(value: float32) =
      withoutInterrupts:
        buffer.data[buffer.writeIndex] = value
        buffer.writeIndex = (buffer.writeIndex + 1) mod 256
    
    proc readFromBuffer(): float32 =
      withoutInterrupts:
        result = buffer.data[buffer.readIndex]
        buffer.readIndex = (buffer.readIndex + 1) mod 256
    
    writeToBuffer(1.5)
    discard readFromBuffer()
  
  # Example 7: State machine transition
  block:
    type State = enum
      IDLE, ACTIVE, DONE
    
    var currentState = IDLE
    var stateTime: uint32
    
    proc changeState(newState: State) =
      withoutInterrupts:
        currentState = newState
        stateTime = 0  # Reset timer
