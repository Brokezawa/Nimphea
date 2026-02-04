## LED Control
## ===========
##
## Single LED control with software PWM and gamma correction.
##
## **Features:**
## - Software PWM for brightness control
## - Automatic gamma correction (cubic curve)
## - Configurable update rate
## - Inversion support (for active-low LEDs)
##
## **Usage:**
## ```nim
## import hid/led
##
## var led: Led
## led.init(D10, false, 1000.0)  # Pin D10, not inverted, 1kHz update rate
##
## # Set brightness (0.0 to 1.0, gamma corrected automatically)
## led.set(0.5)
##
## # In main loop at 1kHz
## while true:
##   led.update()  # Must call at specified sample rate!
##   hw.delayMs(1)
## ```

import nimphea_macros
import nimphea  # For Pin type

useNimpheaModules(led)

type
  Led* {.importcpp: "daisy::Led", header: "hid/led.h".} = object
    ## Single LED with software PWM control

proc init*(this: var Led, pin: Pin, invert: bool, samplerate: cfloat = 1000.0)
  {.importcpp: "#.Init(#, #, #)".} =
  ## Initialize LED on specified pin
  ##
  ## **Parameters:**
  ## - `pin` - Hardware pin for LED
  ## - `invert` - True to invert brightness (for active-low LEDs)
  ## - `samplerate` - Rate at which update() will be called in Hz (default: 1000Hz)
  ##
  ## **Example:**
  ## ```nim
  ## led.init(D10, false, 1000.0)  # Update at 1kHz
  ## ```
  discard

proc set*(this: var Led, val: cfloat) {.importcpp: "#.Set(#)".} =
  ## Set LED brightness
  ##
  ## **Parameters:**
  ## - `val` - Brightness (0.0 = off, 1.0 = full brightness)
  ##
  ## **Note:** Value is cubed for gamma correction, then quantized to 8-bit for PWM
  ##
  ## **Example:**
  ## ```nim
  ## led.set(0.0)   # Off
  ## led.set(0.5)   # Half brightness (gamma corrected)
  ## led.set(1.0)   # Full brightness
  ## ```
  discard

proc update*(this: var Led) {.importcpp: "#.Update()".} =
  ## Update LED PWM state
  ##
  ## **Must be called at the sample rate specified in init()!**
  ##
  ## **Example:**
  ## ```nim
  ## # If samplerate was 1000Hz, call this every 1ms
  ## while true:
  ##   led.update()
  ##   hw.delayMs(1)
  ## ```
  discard

proc setSampleRate*(this: var Led, sample_rate: cfloat)
  {.importcpp: "#.SetSampleRate(#)".} =
  ## Change update sample rate without reinitializing
  ##
  ## **Parameters:**
  ## - `sample_rate` - New update rate in Hz
  discard
