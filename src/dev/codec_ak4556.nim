## AK4556 Codec
## =============
##
## Nim wrapper for the AK4556 24-bit stereo audio codec.
##
## The AK4556 is the default codec used on Daisy Seed 1.0 hardware.
## It provides basic stereo audio I/O with minimal configuration required.
##
## **Features:**
## - 24-bit stereo ADC and DAC
## - Simple reset pin initialization
## - No I2C configuration required
##
## **Example:**
## ```nim
## import ../src/nimphea
## import ../src/dev/codec_ak4556
## import ../src/per/gpio
##
## var codec: Ak4556
## codec.init(seed.GetPin(0))  # Initialize with reset pin
## # ... configure audio ...
## codec.deInit()  # Clean up when done
## ```

import ../nimphea
import ../nimphea_macros

useNimpheaModules(codec_ak4556)

{.push header: "dev/codec_ak4556.h".}

# Type definition moved to libdaisy.nim to prevent ambiguity
# type
#   Ak4556* {.importcpp: "daisy::Ak4556".} = object
#     ## AK4556 codec driver
#     ## 
#     ## Simple codec requiring only a reset pin for initialization.
#     ## Used on Daisy Seed 1.0 and other basic audio platforms.

{.pop.}

proc init*(this: var Ak4556, resetPin: Pin) {.importcpp: "#.Init(#)".}
  ## Initialize the AK4556 codec with the specified reset pin
  ## 
  ## **Parameters:**
  ## - `resetPin` - GPIO pin connected to the codec's reset line
  ## 
  ## **Example:**
  ## ```nim
  ## var codec: Ak4556
  ## codec.init(seed.GetPin(0))
  ## ```

proc deInit*(this: var Ak4556) {.importcpp: "#.DeInit()".}
  ## Deinitialize the AK4556 codec
  ## 
  ## Releases resources and resets the codec to its default state.
