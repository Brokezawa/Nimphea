## Logger
## ======
##
## USB and UART logging for debugging Daisy applications.
##
## This module provides simple logging capabilities to output debug information
## via USB serial or UART. Useful for debugging without a hardware debugger.
##
## Logger Destinations
## -------------------
##
## The Logger supports multiple output destinations:
##
## - **LOGGER_INTERNAL** - Internal USB port (most common, built into Daisy Seed)
## - **LOGGER_EXTERNAL** - External USB port (if available on your board)
## - **LOGGER_SEMIHOST** - stdout (requires debugger connection)
## - **LOGGER_NONE** - Muted (all logging disabled, zero overhead)
##
## Basic Usage
## -----------
##
## **Step 1: Import and create logger**
##
## .. code-block:: nim
##    import hid/logger
##    
##    # UsbLogger is a built-in type alias for LoggerInternal
##
## **Step 2: Start logging session**
##
## .. code-block:: nim
##    proc main() =
##      UsbLogger.startLog(false)  # Don't wait for PC connection
##      # Or: UsbLogger.startLog(true)  # Block until PC connects
##
## **Step 3: Log messages**
##
## .. code-block:: nim
##    UsbLogger.print("Hello from Daisy!")
##    UsbLogger.printLine("This adds a newline")
##
## Complete Example
## ----------------
##
## .. code-block:: nim
##    import nimphea
##    import hid/logger
##    import std/strformat  # For string formatting
##    
##    # UsbLogger is built-in, no need to define
##    
##    proc main() =
##      var hw = initDaisy()
##      
##      # Start logger (don't block)
##      UsbLogger.startLog(false)
##      
##      UsbLogger.printLine("=== Daisy Seed Startup ===")
##      UsbLogger.printLine("Firmware v1.0.0")
##      
##      var counter = 0
##      while true:
##        hw.delay(1000)
##        
##        # Use Nim's string formatting
##        let msg = &"Counter: {counter}"
##        UsbLogger.printLine(cstring(msg))
##        
##        counter += 1
##    
##    when isMainModule:
##      main()
##
## String Formatting in Nim
## -------------------------
##
## This module uses **Nim's string formatting**, not C printf-style formatting.
##
## **Available formatting options:**
##
## **Option 1: String concatenation with `&` operator**
##
## .. code-block:: nim
##    let value = 42
##    let voltage = 3.14159
##    
##    UsbLogger.printLine(cstring("Value: " & $value))
##    UsbLogger.printLine(cstring("Voltage: " & $voltage & " V"))
##
## **Option 2: `strformat` module (recommended)**
##
## .. code-block:: nim
##    import std/strformat
##    
##    let temp = 25.3
##    let humidity = 67
##    
##    let msg = &"Temperature: {temp:.1f}°C, Humidity: {humidity}%"
##    UsbLogger.printLine(cstring(msg))
##    # Output: "Temperature: 25.3°C, Humidity: 67%"
##
## **Option 3: `strutils` module functions**
##
## .. code-block:: nim
##    import std/strutils
##    
##    let freq = 440.0
##    let msg = "Frequency: " & formatFloat(freq, ffDecimal, 2) & " Hz"
##    UsbLogger.printLine(cstring(msg))
##    # Output: "Frequency: 440.00 Hz"
##
## Performance Profiling Example
## ------------------------------
##
## Use Logger with System timing functions for performance analysis:
##
## .. code-block:: nim
##    import nimphea_system
##    import hid/logger
##    import std/strformat
##    
##    type UsbLogger = Logger[LOGGER_INTERNAL]
##    
##    proc benchmarkFunction() =
##      # ... some code to benchmark
##      for i in 0..<1000:
##        discard i * 2
##    
##    proc main() =
##      UsbLogger.startLog()
##      
##      let startUs = getUs()
##      benchmarkFunction()
##      let endUs = getUs()
##      let duration = endUs - startUs
##      
##      let msg = &"Benchmark took {duration} microseconds"
##      UsbLogger.printLine(cstring(msg))
##
## Logging Best Practices
## ----------------------
##
## **1. Use `printLine()` for most messages** (adds newline automatically)
##
## .. code-block:: nim
##    UsbLogger.printLine("Starting initialization...")  # Good
##    UsbLogger.print("Done\n")  # Avoid manual newlines
##
## **2. Don't log in audio callback** (causes glitches)
##
## .. code-block:: nim
##    proc audioCallback(input, output: ptr float32, size: int) =
##      # ❌ BAD: Logging in ISR
##      # UsbLogger.printLine("Audio callback")
##      
##      processAudio(input, output, size)
##
## **3. Use LOGGER_NONE for production builds** (zero overhead)
##
## .. code-block:: nim
##    when defined(release):
##      type AppLogger = Logger[LOGGER_NONE]  # Muted
##    else:
##      type AppLogger = Logger[LOGGER_INTERNAL]  # Active
##
## **4. Convert to cstring for C++ compatibility**
##
## .. code-block:: nim
##    let nimString = "Hello"
##    UsbLogger.print(cstring(nimString))  # Explicit conversion
##
## Viewing Log Output
## ------------------
##
## **On Linux/macOS:**
##
## .. code-block:: bash
##    # Find the USB serial port
##    ls /dev/tty.usb*  # macOS
##    ls /dev/ttyACM*   # Linux
##    
##    # Connect with screen
##    screen /dev/tty.usbmodem12345 115200
##    
##    # Or use minicom
##    minicom -D /dev/ttyACM0 -b 115200
##
## **On Windows:**
##
## - Use PuTTY, TeraTerm, or Arduino Serial Monitor
## - Baud rate: 115200 (actual rate doesn't matter for USB CDC)
##
## Multiple Logger Instances
## --------------------------
##
## You can create multiple logger types for different destinations:
##
## .. code-block:: nim
##    type
##      UsbLogger = Logger[LOGGER_INTERNAL]
##      UartLogger = Logger[LOGGER_EXTERNAL]
##      NullLogger = Logger[LOGGER_NONE]
##    
##    UsbLogger.startLog()
##    UartLogger.startLog()
##    
##    UsbLogger.printLine("Via internal USB")
##    UartLogger.printLine("Via external USB")
##    NullLogger.printLine("This is discarded (no overhead)")
##
## Technical Details
## -----------------
##
## - **Buffer size**: 128 bytes (internal buffer)
## - **Newline sequence**: "\\r\\n" (Windows-style, works everywhere)
## - **Blocking behavior**: Initially non-blocking, becomes blocking after sync
## - **USB CDC class**: No baud rate configuration needed
##
## See Also
## --------
## - `sys/system <system.html>`_ - Timing functions for profiling
## - `examples/advanced_logging.nim` - Performance profiling example
## - Nim's `strformat` module - Modern string interpolation
## - Nim's `strutils` module - String formatting utilities

import nimphea
import nimphea_macros

when isMainModule:
  discard  # Examples removed for simplicity

useNimpheaModules(logger)

{.push header: "hid/logger.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  # Individual Logger types for each destination
  # NOTE: We don't import LoggerDestination enum because the Logger template
  # in C++ uses non-type template parameters, which don't map well to Nim generics.
  # Instead, we provide pre-instantiated types for each destination.
  
  LoggerNone* {.importcpp: "daisy::Logger<daisy::LOGGER_NONE>",
                header: "hid/logger.h".} = object
    ## Logger with no output (all calls optimized away).
    ## Use for production builds to eliminate logging overhead.
  
  LoggerInternal* {.importcpp: "daisy::Logger<daisy::LOGGER_INTERNAL>",
                    header: "hid/logger.h".} = object
    ## Logger using internal USB port (most common).
    ## Built into Daisy Seed, appears as virtual serial port.
  
  LoggerExternal* {.importcpp: "daisy::Logger<daisy::LOGGER_EXTERNAL>",
                    header: "hid/logger.h".} = object
    ## Logger using external USB port (if supported by hardware).
  
  LoggerSemihost* {.importcpp: "daisy::Logger<daisy::LOGGER_SEMIHOST>",
                    header: "hid/logger.h".} = object
    ## Logger using semihosting (debugger stdout).
    ## Requires active debugger connection.

{.pop.} # header

# ============================================================================
# Type Aliases for Convenience
# ============================================================================

type
  UsbLogger* = LoggerInternal
    ## Alias for LoggerInternal (most common use case).
    ## Logs to internal USB port on Daisy Seed.
  
  NullLogger* = LoggerNone
    ## Alias for LoggerNone (disabled logging).
    ## All logging calls are optimized away at compile time.

# ============================================================================
# C++ Method Wrappers - LoggerInternal (most common)
# ============================================================================

proc print*(T: typedesc[LoggerInternal], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_INTERNAL>::Print(@)".}
  ## Print formatted string (no newline added).
  ##
  ## **Parameters:**
  ## - `format` - C-string to print
  ##
  ## **Example:**
  ## ```nim
  ## UsbLogger.print("Hello ")
  ## UsbLogger.print("World")  # Same line
  ## ```

proc printLine*(T: typedesc[LoggerInternal], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_INTERNAL>::PrintLine(@)".}
  ## Print formatted string with newline appended.
  ##
  ## **Parameters:**
  ## - `format` - C-string to print
  ##
  ## **Example:**
  ## ```nim
  ## UsbLogger.printLine("Line 1")
  ## UsbLogger.printLine("Line 2")
  ## ```

proc startLog*(T: typedesc[LoggerInternal], wait_for_pc: bool = false) {.
  importcpp: "daisy::Logger<daisy::LOGGER_INTERNAL>::StartLog(@)".}
  ## Start the logging session.
  ##
  ## **Parameters:**
  ## - `wait_for_pc` - If true, block until PC terminal connects (default: false)
  ##
  ## **Example:**
  ## ```nim
  ## UsbLogger.startLog(false)  # Non-blocking (recommended)
  ## # Or:
  ## UsbLogger.startLog(true)   # Wait for serial terminal
  ## ```

# ============================================================================
# C++ Method Wrappers - LoggerExternal
# ============================================================================

proc print*(T: typedesc[LoggerExternal], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_EXTERNAL>::Print(@)".}
  ## Print to external USB port (no newline).

proc printLine*(T: typedesc[LoggerExternal], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_EXTERNAL>::PrintLine(@)".}
  ## Print to external USB port (with newline).

proc startLog*(T: typedesc[LoggerExternal], wait_for_pc: bool = false) {.
  importcpp: "daisy::Logger<daisy::LOGGER_EXTERNAL>::StartLog(@)".}
  ## Start logging to external USB port.

# ============================================================================
# C++ Method Wrappers - LoggerSemihost
# ============================================================================

proc print*(T: typedesc[LoggerSemihost], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_SEMIHOST>::Print(@)".}
  ## Print to debugger stdout (no newline).

proc printLine*(T: typedesc[LoggerSemihost], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_SEMIHOST>::PrintLine(@)".}
  ## Print to debugger stdout (with newline).

proc startLog*(T: typedesc[LoggerSemihost], wait_for_pc: bool = false) {.
  importcpp: "daisy::Logger<daisy::LOGGER_SEMIHOST>::StartLog(@)".}
  ## Start semihosting logging.

# ============================================================================
# C++ Method Wrappers - LoggerNone (no-ops, optimized away)
# ============================================================================

proc print*(T: typedesc[LoggerNone], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_NONE>::Print(@)".}
  ## No-op (optimized away at compile time).

proc printLine*(T: typedesc[LoggerNone], format: cstring) {.
  importcpp: "daisy::Logger<daisy::LOGGER_NONE>::PrintLine(@)".}
  ## No-op (optimized away at compile time).

proc startLog*(T: typedesc[LoggerNone], wait_for_pc: bool = false) {.
  importcpp: "daisy::Logger<daisy::LOGGER_NONE>::StartLog(@)".}
  ## No-op (optimized away at compile time).

# ============================================================================
# Nim Helper Functions
# ============================================================================

template log*(T: typedesc[LoggerInternal], msg: string) =
  ## Log a Nim string with newline (convenience wrapper).
  T.printLine(cstring(msg))

template log*(T: typedesc[LoggerExternal], msg: string) =
  ## Log a Nim string with newline (convenience wrapper).
  T.printLine(cstring(msg))

template log*(T: typedesc[LoggerSemihost], msg: string) =
  ## Log a Nim string with newline (convenience wrapper).
  T.printLine(cstring(msg))

template log*(T: typedesc[LoggerNone], msg: string) =
  ## No-op (optimized away at compile time).
  T.printLine(cstring(msg))

# ============================================================================
# Usage Examples
# ============================================================================

when isMainModule:
  ## Compile-time examples (not executable without hardware)
  
  # Example 1: Basic logging
  block:
    type MyLogger = LoggerInternal
    
    MyLogger.startLog(false)
    MyLogger.print("Hello ")
    MyLogger.printLine("World!")
  
  # Example 2: Using the convenience alias
  block:
    UsbLogger.startLog()
    UsbLogger.printLine("Firmware v1.0.0")
    UsbLogger.printLine("Ready")
