## Momentary/Latching Switch with Debouncing
## ==========================================
##
## Generic class for handling momentary/latching switches with debouncing.
## Inspired by Mutable Instruments Switch classes.
##
## **Features:**
## - Debounced button input
## - Rising/falling edge detection
## - Press duration tracking
## - Toggle or momentary modes
## - Normal or inverted polarity
##
## **Usage:**
## ```nim
## import hid/switch
##
## var button: Switch
## button.init(D0())  # Simple momentary button on pin D0
##
## while true:
##   button.debounce()
##   
##   if button.risingEdge():
##     echo "Button pressed!"
##   
##   if button.pressed():
##     echo "Button held for ", button.timeHeldMs(), " ms"
##   
##   delayMs(1)
## ```

import nimphea_macros
import nimphea  # For Pin type

useNimpheaModules(controls)

{.push header: "daisy_seed.h".}

type
  SwitchType* {.importcpp: "daisy::Switch::Type", size: sizeof(cint).} = enum
    ## Switch behavior type
    TYPE_TOGGLE    ## Toggle/latching switch
    TYPE_MOMENTARY ## Momentary pushbutton (default)

  SwitchPolarity* {.importcpp: "daisy::Switch::Polarity", size: sizeof(cint).} = enum
    ## Switch polarity (which state is "pressed")
    POLARITY_NORMAL   ## HIGH = pressed
    POLARITY_INVERTED ## LOW = pressed (default, common with pull-ups)

  GpioPull* {.importcpp: "daisy::GPIO::Pull", size: sizeof(cint).} = enum
    ## GPIO pull-up/pull-down configuration
    PULL_NOPULL ## No pull resistor
    PULL_UP     ## Pull-up resistor (default)
    PULL_DOWN   ## Pull-down resistor

  Switch* {.importcpp: "daisy::Switch", header: "hid/switch.h".} = object
    ## Debounced switch/button handler

{.pop.} # header

# C++ Init methods
proc Init*(this: var Switch, pin: Pin, update_rate: cfloat, 
           t: SwitchType, pol: SwitchPolarity, pu: GpioPull) 
  {.importcpp: "#.Init(@)", header: "hid/switch.h".}

proc Init*(this: var Switch, pin: Pin, update_rate: cfloat = 0.0) 
  {.importcpp: "#.Init(@)", header: "hid/switch.h".}

proc Debounce*(this: var Switch) 
  {.importcpp: "#.Debounce()", header: "hid/switch.h".}

proc RisingEdge*(this: Switch): bool 
  {.importcpp: "#.RisingEdge()", header: "hid/switch.h".}

proc FallingEdge*(this: Switch): bool 
  {.importcpp: "#.FallingEdge()", header: "hid/switch.h".}

proc Pressed*(this: Switch): bool 
  {.importcpp: "#.Pressed()", header: "hid/switch.h".}

proc RawState*(this: var Switch): bool 
  {.importcpp: "#.RawState()", header: "hid/switch.h".}

proc TimeHeldMs*(this: Switch): cfloat 
  {.importcpp: "#.TimeHeldMs()", header: "hid/switch.h".}

# Nim-friendly wrapper API
proc init*(sw: var Switch, pin: Pin, switchType: SwitchType, 
           polarity: SwitchPolarity, pull: GpioPull) =
  ## Initialize switch with full configuration
  ##
  ## **Parameters:**
  ## - `pin` - GPIO pin for the switch
  ## - `switchType` - TYPE_MOMENTARY or TYPE_TOGGLE
  ## - `polarity` - POLARITY_NORMAL or POLARITY_INVERTED
  ## - `pull` - PULL_NOPULL, PULL_UP, or PULL_DOWN
  ##
  ## **Example:**
  ## ```nim
  ## var button: Switch
  ## button.init(D0(), TYPE_MOMENTARY, POLARITY_INVERTED, PULL_UP)
  ## ```
  sw.Init(pin, 0.0, switchType, polarity, pull)

proc init*(sw: var Switch, pin: Pin) =
  ## Initialize switch with default settings (momentary, inverted, pull-up)
  ##
  ## **Parameters:**
  ## - `pin` - GPIO pin for the switch
  ##
  ## **Example:**
  ## ```nim
  ## var button: Switch
  ## button.init(D0())
  ## ```
  sw.Init(pin, 0.0)

proc debounce*(sw: var Switch) =
  ## Update switch state with debouncing
  ##
  ## Call this regularly (e.g., every 1ms) to update the switch state.
  ## Must be called for edge detection and timing to work correctly.
  ##
  ## **Example:**
  ## ```nim
  ## while true:
  ##   button.debounce()
  ##   # Check button state...
  ##   delayMs(1)
  ## ```
  sw.Debounce()

proc risingEdge*(sw: Switch): bool =
  ## Check if button was just pressed
  ##
  ## **Returns:** true for one cycle when button transitions from released to pressed
  ##
  ## **Example:**
  ## ```nim
  ## if button.risingEdge():
  ##   echo "Button pressed!"
  ## ```
  sw.RisingEdge()

proc fallingEdge*(sw: Switch): bool =
  ## Check if button was just released
  ##
  ## **Returns:** true for one cycle when button transitions from pressed to released
  ##
  ## **Example:**
  ## ```nim
  ## if button.fallingEdge():
  ##   echo "Button released!"
  ## ```
  sw.FallingEdge()

proc pressed*(sw: Switch): bool =
  ## Check if button is currently held down
  ##
  ## **Returns:** true while button is pressed (after debouncing)
  ##
  ## **Example:**
  ## ```nim
  ## if button.pressed():
  ##   echo "Button is down"
  ## ```
  sw.Pressed()

proc rawState*(sw: var Switch): bool =
  ## Read raw button state without debouncing
  ##
  ## **Returns:** true if button is physically pressed (without debounce)
  ##
  ## **Note:** Usually you want `pressed()` instead
  sw.RawState()

proc timeHeldMs*(sw: Switch): float =
  ## Get how long the button has been held
  ##
  ## **Returns:** Time in milliseconds that button has been pressed (0 if not pressed)
  ##
  ## **Example:**
  ## ```nim
  ## if button.pressed():
  ##   echo "Held for ", button.timeHeldMs(), " ms"
  ## ```
  sw.TimeHeldMs().float
