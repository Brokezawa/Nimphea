## UI Controls - Button and Potentiometer Monitoring
## ===================================================
##
## This module provides template-based monitoring for buttons and potentiometers
## with debouncing, double-click detection, retriggering, and deadband filtering.
## Events are generated in a UiEventQueue for processing by the UI system.
##
## **Features:**
## - ButtonMonitor: Debounced button monitoring with double-click and repeat
## - PotMonitor: Potentiometer monitoring with idle/moving states and deadbands
## - Backend system: Flexible input sources via backend classes
## - Zero-cost abstraction: Template-based, compile-time polymorphism
##
## **Usage Pattern:**
##
## ```nim
## # Define your backend class
## type
##   MyButtonBackend = object
##     pins: array[3, DaisyPin]
##   
## proc isButtonPressed(backend: var MyButtonBackend, buttonId: uint16): bool =
##   # Read from your hardware
##   result = backend.pins[buttonId].read()
##
## # Create and use monitor
## var backend = MyButtonBackend(pins: [PIN_D0, PIN_D1, PIN_D2])
## var queue = initUiEventQueue()
## var monitor = initButtonMonitor[MyButtonBackend, 3](queue, backend)
## 
## # In your main loop:
## while true:
##   monitor.process()
##   # Process events from queue
## ```
##
## **Architecture:**
## - C++ templates are wrapped as Nim generics with importcpp
## - Backend interface is defined as a concept (compile-time duck typing)
## - Template instantiation happens at C++ compile time
## - Zero runtime overhead compared to hand-written code
##
## This module wraps libDaisy's ui/ButtonMonitor.h and ui/PotMonitor.h

import nimphea_macros
import nimphea_ui_events

useNimpheaModules(ui)

{.push header: "ui/ButtonMonitor.h".}

# ButtonMonitor - Template-based button monitoring with events
# ============================================================

type
  ButtonMonitor*[BackendType; numButtons: static int] {.
    importcpp: "daisy::ButtonMonitor<'0, @>",
    bycopy.} = object
    ## Monitors button states and generates events in a UiEventQueue
    ## 
    ## **Template Parameters:**
    ## - `BackendType` - Backend class that implements `IsButtonPressed(uint16): bool`
    ## - `numButtons` - Number of buttons to monitor (compile-time constant)
    ## 
    ## **Features:**
    ## - Software debouncing with configurable timeout
    ## - Double-click detection
    ## - Auto-repeat (retriggering) when held down
    ## - State queries (is button currently pressed?)
    ## 
    ## **Backend Requirements:**
    ## Your BackendType must implement:
    ## ```nim
    ## proc isButtonPressed(backend: var BackendType, buttonId: uint16): bool
    ## ```

proc init*[B, N](this: var ButtonMonitor[B, N],
                 queue: var UiEventQueue,
                 backend: var B,
                 debounceTimeoutMs: uint16 = 50,
                 doubleClickTimeoutMs: uint32 = 500,
                 retriggerTimeoutMs: uint32 = 2000,
                 retriggerPeriodMs: uint32 = 50) {.
  importcpp: "#.Init(@)".}
  ## Initialize the button monitor
  ## 
  ## **Parameters:**
  ## - `queue` - UiEventQueue to post events to
  ## - `backend` - Backend object that provides button states
  ## - `debounceTimeoutMs` - Debounce timeout in ms (default 50ms, 0 to disable)
  ## - `doubleClickTimeoutMs` - Max time between clicks to detect double-click (default 500ms)
  ## - `retriggerTimeoutMs` - Hold time before auto-repeat starts (default 2000ms, 0 to disable)
  ## - `retriggerPeriodMs` - Auto-repeat rate when held (default 50ms = 20 Hz)
  ## 
  ## **Example:**
  ## ```nim
  ## var monitor: ButtonMonitor[MyBackend, 4]
  ## monitor.init(eventQueue, buttonBackend, debounceTimeoutMs = 30)
  ## ```

proc process*[B, N](this: var ButtonMonitor[B, N]) {.
  importcpp: "#.Process()".}
  ## Check all buttons and generate events
  ## 
  ## Call this regularly (e.g., from main loop) to poll button states
  ## and generate events. Recommended call rate: 100-1000 Hz (1-10ms interval).
  ## 
  ## **Events Generated:**
  ## - ButtonPressed - when button is pressed (after debounce)
  ## - ButtonReleased - when button is released (after debounce)
  ## - ButtonPressed (repeated) - during auto-repeat phase
  ## 
  ## **Example:**
  ## ```nim
  ## while true:
  ##   buttonMonitor.process()
  ##   daisy.delay(10)  # 100 Hz polling
  ## ```

proc isButtonPressed*[B, N](this: var ButtonMonitor[B, N], 
                            buttonId: uint16): bool {.
  importcpp: "#.IsButtonPressed(#)".}
  ## Query current state of a button (debounced)
  ## 
  ## Returns `true` if button is currently pressed (after debounce timeout),
  ## `false` if released or during debounce transition.
  ## 
  ## **Parameters:**
  ## - `buttonId` - Button ID (0 to numButtons-1)
  ## 
  ## **Returns:** Current debounced button state
  ## 
  ## **Example:**
  ## ```nim
  ## if monitor.isButtonPressed(0):
  ##   echo "Button 0 is pressed"
  ## ```

proc getBackend*[B, N](this: var ButtonMonitor[B, N]): var B {.
  importcpp: "#.GetBackend()".}
  ## Get reference to the backend object
  ## 
  ## Useful for accessing backend-specific functionality or reconfiguring
  ## the backend at runtime.

proc getNumButtonsMonitored*[B, N](this: var ButtonMonitor[B, N]): uint16 {.
  importcpp: "#.GetNumButtonsMonitored()".}
  ## Get number of buttons monitored
  ## 
  ## Returns the template parameter `numButtons`. Useful for generic code
  ## that doesn't know the compile-time constant.

{.pop.} # ButtonMonitor.h

{.push header: "ui/PotMonitor.h".}

# PotMonitor - Template-based potentiometer monitoring with events
# =================================================================

type
  PotMonitor*[BackendType; numPots: static int] {.
    importcpp: "daisy::PotMonitor<'0, @>",
    bycopy.} = object
    ## Monitors potentiometer values and generates events in a UiEventQueue
    ## 
    ## **Template Parameters:**
    ## - `BackendType` - Backend class that implements `GetPotValue(uint16): float`
    ## - `numPots` - Number of potentiometers to monitor (compile-time constant)
    ## 
    ## **Features:**
    ## - Dual deadband system (idle vs moving)
    ## - Activity state tracking (idle/moving)
    ## - Configurable idle timeout
    ## - Movement detection with hysteresis
    ## 
    ## **Backend Requirements:**
    ## Your BackendType must implement:
    ## ```nim
    ## proc getPotValue(backend: var BackendType, potId: uint16): float
    ## ```
    ## Returns value in range 0.0 to 1.0

proc init*[B, N](this: var PotMonitor[B, N],
                 queue: var UiEventQueue,
                 backend: var B,
                 idleTimeoutMs: uint16 = 500,
                 deadBandIdle: cfloat = 0.000977,  # 1.0 / (1 << 10)
                 deadBand: cfloat = 0.000244) {.    # 1.0 / (1 << 12)
  importcpp: "#.Init(@)".}
  ## Initialize the potentiometer monitor
  ## 
  ## **Parameters:**
  ## - `queue` - UiEventQueue to post events to
  ## - `backend` - Backend object that provides pot values (0.0-1.0)
  ## - `idleTimeoutMs` - Time without movement before entering idle state (default 500ms)
  ## - `deadBandIdle` - Deadband when idle (default 1/1024 ≈ 0.001 = 10-bit resolution)
  ## - `deadBand` - Deadband when moving (default 1/4096 ≈ 0.0002 = 12-bit resolution)
  ## 
  ## **Deadband Explanation:**
  ## - **Idle deadband** (larger): Prevents noise from triggering movement when pot is stationary
  ## - **Moving deadband** (smaller): Provides smoother tracking once movement detected
  ## - Choose based on ADC resolution and expected noise level
  ## 
  ## **Example:**
  ## ```nim
  ## var monitor: PotMonitor[MyAdcBackend, 8]
  ## monitor.init(eventQueue, adcBackend,
  ##              idleTimeoutMs = 300,
  ##              deadBandIdle = 0.002,   # 2 ADC counts on 12-bit
  ##              deadBand = 0.0005)       # 0.5 ADC counts on 12-bit
  ## ```

proc process*[B, N](this: var PotMonitor[B, N]) {.
  importcpp: "#.Process()".}
  ## Check all potentiometers and generate events
  ## 
  ## Call this regularly (e.g., from main loop) to poll pot values
  ## and generate events. Recommended call rate: 100-1000 Hz.
  ## 
  ## **Events Generated:**
  ## - PotMoved - when pot value changes beyond deadband
  ## - PotActivityChanged - when pot transitions idle↔moving
  ## 
  ## **Example:**
  ## ```nim
  ## while true:
  ##   potMonitor.process()
  ##   daisy.delay(10)  # 100 Hz polling
  ## ```

proc isMoving*[B, N](this: var PotMonitor[B, N], potId: uint16): bool {.
  importcpp: "#.IsMoving(#)".}
  ## Query if potentiometer is currently being moved
  ## 
  ## Returns `true` if pot has moved within the idle timeout period,
  ## `false` if pot has been stationary for longer than timeout.
  ## 
  ## **Parameters:**
  ## - `potId` - Potentiometer ID (0 to numPots-1)
  ## 
  ## **Returns:** `true` if moving, `false` if idle
  ## 
  ## **Use Case:**
  ## Useful for UI feedback (highlight active controls) or parameter locking
  ## (ignore MIDI changes while user is touching the pot).
  ## 
  ## **Example:**
  ## ```nim
  ## if monitor.isMoving(potId):
  ##   display.drawHighlight(potId)
  ## ```

proc getCurrentPotValue*[B, N](this: var PotMonitor[B, N], 
                               potId: uint16): cfloat {.
  importcpp: "#.GetCurrentPotValue(#)".}
  ## Get the last debounced value of a potentiometer
  ## 
  ## Returns the value (0.0-1.0) that was most recently posted to the event queue.
  ## This is the debounced, filtered value, not the raw backend value.
  ## 
  ## **Parameters:**
  ## - `potId` - Potentiometer ID (0 to numPots-1)
  ## 
  ## **Returns:** Value in range 0.0 to 1.0, or -1.0 if potId is invalid
  ## 
  ## **Example:**
  ## ```nim
  ## let volume = monitor.getCurrentPotValue(POT_VOLUME)
  ## setAudioGain(volume)
  ## ```

proc getBackend*[B, N](this: var PotMonitor[B, N]): var B {.
  importcpp: "#.GetBackend()".}
  ## Get reference to the backend object
  ## 
  ## Useful for accessing backend-specific functionality.

proc getNumPotsMonitored*[B, N](this: var PotMonitor[B, N]): uint16 {.
  importcpp: "#.GetNumPotsMonitored()".}
  ## Get number of potentiometers monitored
  ## 
  ## Returns the template parameter `numPots`.

{.pop.} # PotMonitor.h

# Nim Helper Types - Common Backend Patterns
# ===========================================

## These are example backend implementations that can be used directly
## or serve as templates for custom backends.

type
  GpioButtonBackend*[N: static int] = object
    ## Simple GPIO backend for buttons
    ## Buttons should be wired with pull-ups (active-low)
    pins*: array[N, uint8]  # GPIO pin numbers
    inverted*: bool         # true if buttons are active-low

  AdcPotBackend*[N: static int] = object
    ## Simple ADC backend for potentiometers
    ## Reads from ADC channels and scales to 0.0-1.0
    channels*: array[N, uint8]  # ADC channel numbers
    minValue*: cfloat            # Min ADC value (default 0.0)
    maxValue*: cfloat            # Max ADC value (default 1.0)

# These helper procs would be implemented by the user or in a separate module
# proc isButtonPressed*(backend: var GpioButtonBackend, buttonId: uint16): bool
# proc getPotValue*(backend: var AdcPotBackend, potId: uint16): cfloat

# Template Helpers for Common Patterns
# =====================================

template createButtonMonitor*[B; N: static int](
    backendType: typedesc[B],
    numButtons: static int): untyped =
  ## Template to create a ButtonMonitor type with less boilerplate
  ## 
  ## **Example:**
  ## ```nim
  ## type MyMonitor = createButtonMonitor(GpioButtonBackend, 4)
  ## var monitor: MyMonitor
  ## ```
  ButtonMonitor[B, N]

template createPotMonitor*[B; N: static int](
    backendType: typedesc[B],
    numPots: static int): untyped =
  ## Template to create a PotMonitor type with less boilerplate
  ## 
  ## **Example:**
  ## ```nim
  ## type MyMonitor = createPotMonitor(AdcPotBackend, 8)
  ## var monitor: MyMonitor
  ## ```
  PotMonitor[B, N]

# Usage Examples in Documentation
# ================================

when false:  # Documentation examples (not compiled)
  
  # Example 1: Button Monitor with GPIO Backend
  # --------------------------------------------
  
  type
    ButtonId = enum
      btnOkay = 0
      btnCancel = 1
      btnStart = 2
    
    MyButtonBackend = object
      pins: array[3, uint8]
  
  proc isButtonPressed(backend: var MyButtonBackend, buttonId: uint16): bool =
    # Read GPIO pin (implement with actual GPIO read)
    # Return true if button is pressed
    result = false  # Placeholder
  
  var buttonBackend = MyButtonBackend(pins: [0'u8, 1, 2])
  var eventQueue = initUiEventQueue()
  var buttonMonitor: ButtonMonitor[MyButtonBackend, 3]
  
  buttonMonitor.init(eventQueue, buttonBackend,
                     debounceTimeoutMs = 30,
                     doubleClickTimeoutMs = 400)
  
  # In main loop:
  while true:
    buttonMonitor.process()
    
    # Process events
    while eventQueue.getNumEvents() > 0:
      let event = eventQueue.popEvent()
      if event.eventType == EVT_BUTTON_PRESSED:
        case event.asButtonPressed.id
        of btnOkay.ord.uint16:
          echo "OK button pressed"
        of btnCancel.ord.uint16:
          echo "Cancel button pressed"
        else:
          discard
  
  # Example 2: Potentiometer Monitor with ADC Backend
  # --------------------------------------------------
  
  type
    PotId = enum
      potVolume = 0
      potTone = 1
      potGain = 2
      potPan = 3
    
    MyAdcBackend = object
      values: array[4, cfloat]  # Cached ADC values
  
  proc getPotValue(backend: var MyAdcBackend, potId: uint16): cfloat =
    # Return cached value (updated elsewhere by ADC ISR)
    backend.values[potId]
  
  var adcBackend = MyAdcBackend()
  var potMonitor: PotMonitor[MyAdcBackend, 4]
  
  potMonitor.init(eventQueue, adcBackend,
                  idleTimeoutMs = 500)
  
  # In main loop:
  while true:
    potMonitor.process()
    
    # Check if volume pot is being moved
    if potMonitor.isMoving(potVolume.ord.uint16):
      let value = potMonitor.getCurrentPotValue(potVolume.ord.uint16)
      echo "Volume changing: ", value
