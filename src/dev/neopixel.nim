## NeoPixel RGB LED Module
## =======================
##
## Nim wrapper for libDaisy NeoPixel support (WS2812B).
## This module uses the Adafruit Seesaw I2C bridge (e.g. NeoTrellis).
##
## **Note**: This is NOT for direct GPIO control of WS2812B LEDs.
## For direct control, you would need a different driver (currently not in libDaisy).
##
## Usage Example:
## ```nim
## import nimphea
## import dev/neopixel
##
## var neopixel: NeoPixelI2C
## var config: NeoPixelI2CConfig
##
## # Configure defaults (I2C1, 400kHz, 16 LEDs)
## config.transport_config.periph = I2C_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = D11()
## config.transport_config.sda = D12()
## config.numLEDs = 16
##
## neopixel.init(config)
##
## # Set first pixel to red
## neopixel.setPixelColor(0, 255, 0, 0)
## neopixel.show()
## ```

import ../nimphea
import ../per/i2c
import ../nimphea_macros

useNimpheaModules(neopixel, i2c)

{.push header: "dev/neopixel.h".}

# Constants for pixel type
const
  NEO_RGB* = ((0'u16 shl 6) or (0'u16 shl 4) or (1'u16 shl 2) or 2)
  NEO_GRB* = ((1'u16 shl 6) or (1'u16 shl 4) or (0'u16 shl 2) or 2)
  NEO_RGBW* = ((3'u16 shl 6) or (0'u16 shl 4) or (1'u16 shl 2) or 2)
  NEO_KHZ800* = 0x0000'u16
  NEO_KHZ400* = 0x0100'u16

type
  NeoPixelResult* {.importcpp: "daisy::NeoPixel<daisy::NeoPixelI2CTransport>::Result", size: sizeof(cint).} = enum
    NEO_OK = 0
    NEO_ERR = 1

  # Transport Configuration
  NeoPixelI2CTransportConfig* {.importcpp: "daisy::NeoPixelI2CTransport::Config", bycopy.} = object
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    address* {.importcpp: "address".}: uint8

  # NeoPixel Configuration (templated)
  # We specialize for I2C transport since that's the main use case
  NeoPixelI2CConfig* {.importcpp: "daisy::NeoPixel<daisy::NeoPixelI2CTransport>::Config", bycopy.} = object
    transport_config* {.importcpp: "transport_config".}: NeoPixelI2CTransportConfig
    type_flags* {.importcpp: "type".}: uint16
    numLEDs* {.importcpp: "numLEDs".}: uint16
    output_pin* {.importcpp: "output_pin".}: int8

  # Main NeoPixel class specialized for I2C
  NeoPixelI2C* {.importcpp: "daisy::NeoPixelI2C", byref.} = object

# Constructors
proc newNeoPixelI2CTransportConfig*(): NeoPixelI2CTransportConfig {.importcpp: "daisy::NeoPixelI2CTransport::Config()", constructor.}
proc newNeoPixelI2CConfig*(): NeoPixelI2CConfig {.importcpp: "daisy::NeoPixel<daisy::NeoPixelI2CTransport>::Config()", constructor.}

# Methods
proc init*(this: var NeoPixelI2C, config: NeoPixelI2CConfig): NeoPixelResult {.importcpp: "#.Init(@)".}

proc setPixelColor*(this: var NeoPixelI2C, n: uint16, r, g, b: uint8) {.importcpp: "#.SetPixelColor(@)".}
proc setPixelColor*(this: var NeoPixelI2C, n: uint16, r, g, b, w: uint8) {.importcpp: "#.SetPixelColor(@)".}
proc setPixelColor*(this: var NeoPixelI2C, n: uint16, color: uint32) {.importcpp: "#.SetPixelColor(@)".}

proc getPixelColor*(this: var NeoPixelI2C, n: uint16): uint32 {.importcpp: "#.GetPixelColor(@)".}

proc show*(this: var NeoPixelI2C) {.importcpp: "#.Show()".}
proc clear*(this: var NeoPixelI2C) {.importcpp: "#.Clear()".}
proc setBrightness*(this: var NeoPixelI2C, b: uint8) {.importcpp: "#.SetBrightness(@)".}
proc numPixels*(this: var NeoPixelI2C): uint16 {.importcpp: "#.NumPixels()".}

# Color helper
proc color*(r, g, b: uint8): uint32 {.importcpp: "daisy::NeoPixel<daisy::NeoPixelI2CTransport>::Color(@)".}
proc color*(r, g, b, w: uint8): uint32 {.importcpp: "daisy::NeoPixel<daisy::NeoPixelI2CTransport>::Color(@)".}

{.pop.}

# Helper to create config with defaults
proc defaultConfig*(): NeoPixelI2CConfig =
  result = newNeoPixelI2CConfig()
  # Defaults are set by C++ constructor, but we can override commonly used ones here if needed
