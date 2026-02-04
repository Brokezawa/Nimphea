## RGB LED Control
## ================
##
## 3-channel RGB LED control with software PWM.
##
## **Features:**
## - Control 3 LEDs as RGB unit
## - Software PWM with gamma correction
## - Integration with Color module
## - Per-channel or combined control
##
## **Usage:**
## ```nim
## import hid/rgb_led
## import nimphea_color
##
## var rgb: RgbLed
## rgb.init(D10, D11, D12, false)  # R, G, B pins, not inverted
##
## # Set by channels
## rgb.set(1.0, 0.0, 0.0)  # Red
##
## # Set by color object
## var purple = createColor(0.5, 0.0, 0.5)
## rgb.setColor(purple)
##
## # In main loop at 1kHz
## while true:
##   rgb.update()
##   hw.delayMs(1)
## ```

import nimphea_macros
import nimphea  # For Pin type
import nimphea_color  # For Color type

useNimpheaModules(rgb_led)

type
  RgbLed* {.importcpp: "daisy::RgbLed", header: "hid/rgb_led.h".} = object
    ## RGB LED (3x LED configured as RGB unit)

proc init*(this: var RgbLed, red, green, blue: Pin, invert: bool)
  {.importcpp: "#.Init(#, #, #, #)".} =
  ## Initialize RGB LED with 3 pins
  ##
  ## **Parameters:**
  ## - `red` - Pin for red channel
  ## - `green` - Pin for green channel
  ## - `blue` - Pin for blue channel
  ## - `invert` - True to invert all channels (for common anode LEDs)
  discard

proc set*(this: var RgbLed, r, g, b: cfloat) {.importcpp: "#.Set(#, #, #)".} =
  ## Set RGB LED color by channels
  ##
  ## **Parameters:**
  ## - `r` - Red brightness (0.0 to 1.0)
  ## - `g` - Green brightness (0.0 to 1.0)
  ## - `b` - Blue brightness (0.0 to 1.0)
  ##
  ## **Example:**
  ## ```nim
  ## rgb.set(1.0, 0.0, 0.0)  # Red
  ## rgb.set(0.0, 1.0, 0.0)  # Green
  ## rgb.set(1.0, 1.0, 0.0)  # Yellow
  ## ```
  discard

proc setRed*(this: var RgbLed, val: cfloat) {.importcpp: "#.SetRed(#)".} =
  ## Set red channel only
  discard

proc setGreen*(this: var RgbLed, val: cfloat) {.importcpp: "#.SetGreen(#)".} =
  ## Set green channel only
  discard

proc setBlue*(this: var RgbLed, val: cfloat) {.importcpp: "#.SetBlue(#)".} =
  ## Set blue channel only
  discard

proc setColor*(this: var RgbLed, c: Color) {.importcpp: "#.SetColor(#)".} =
  ## Set RGB LED using a Color object
  ##
  ## **Parameters:**
  ## - `c` - Color object
  ##
  ## **Example:**
  ## ```nim
  ## import nimphea_color
  ## 
  ## var purple = createColor(0.5, 0.0, 0.5)
  ## rgb.setColor(purple)
  ##
  ## # Or with preset
  ## var red = createColor()
  ## red.init(COLOR_RED)
  ## rgb.setColor(red)
  ## ```
  discard

proc update*(this: var RgbLed) {.importcpp: "#.Update()".} =
  ## Update all 3 LED PWM states
  ##
  ## **Must be called at regular interval (typically 1kHz)!**
  discard
