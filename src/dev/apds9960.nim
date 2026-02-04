## APDS9960 Gesture/Proximity/RGB/Light Sensor Module
## ===================================================
##
## Nim wrapper for the APDS9960 gesture/color/proximity/light sensor.
##
## The APDS9960 is a versatile sensor that can detect gestures (up, down, left, right),
## measure proximity, sense RGB color, and measure ambient light levels.
##
## **Features:**
## - Gesture recognition (up, down, left, right)
## - Proximity detection (0-255 range)
## - RGB color sensing with 16-bit per channel resolution
## - Ambient light sensing
## - I2C interface only
##
## **Example:**
## ```nim
## import nimphea
## import dev/apds9960
##
## var sensor: Apds9960I2C
## var config: Apds9960Config
## 
## # Configure sensor
## config.color_mode = true
## config.prox_mode = true
## config.gesture_mode = false
## config.transport_config.periph = I2C_1
## config.transport_config.scl = getPin(11)
## config.transport_config.sda = getPin(12)
##
## if sensor.init(config) == APDS9960_OK:
##   while true:
##     if sensor.colorDataReady():
##       var r, g, b, c: uint16
##       sensor.getColorData(r.addr, g.addr, b.addr, c.addr)
##     
##     let prox = sensor.readProximity()
##     let gesture = sensor.readGesture()
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(apds9960)

{.push header: "dev/apds9960.h".}

# Constants
const
  APDS9960_ADDRESS* = 0x39'u8  ## I2C address
  APDS9960_UP* = 0x01'u8       ## Gesture: Up
  APDS9960_DOWN* = 0x02'u8     ## Gesture: Down
  APDS9960_LEFT* = 0x03'u8     ## Gesture: Left
  APDS9960_RIGHT* = 0x04'u8    ## Gesture: Right

# Types

type
  Apds9960Result* {.importcpp: "daisy::Apds9960<daisy::Apds9960I2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    APDS9960_OK  = 0  ## Success
    APDS9960_ERR = 1  ## Error

type
  Apds9960I2CTransportConfig* {.importcpp: "daisy::Apds9960I2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin

type
  Apds9960I2CTransport* {.importcpp: "daisy::Apds9960I2CTransport", bycopy.} = object
    ## I2C transport for APDS9960

type
  Apds9960Config* {.importcpp: "daisy::Apds9960I2C::Config", bycopy.} = object
    ## APDS9960 configuration
    integrationTimeMs* {.importcpp: "integrationTimeMs".}: uint16
    adcGain* {.importcpp: "adcGain".}: uint8  ## (0-3): 1x, 4x, 16x, 64x
    gestureDimensions* {.importcpp: "gestureDimensions".}: uint8  ## (0-2): all, up/down, left/right
    gestureFifoThresh* {.importcpp: "gestureFifoThresh".}: uint8  ## (0-3): 1, 2, 3, 4 datasets
    gestureGain* {.importcpp: "gestureGain".}: uint8  ## (0-3): 1x, 2x, 4x, 8x
    gestureProximityThresh* {.importcpp: "gestureProximityThresh".}: uint16
    color_mode* {.importcpp: "color_mode".}: bool
    prox_mode* {.importcpp: "prox_mode".}: bool
    gesture_mode* {.importcpp: "gesture_mode".}: bool
    transport_config* {.importcpp: "transport_config".}: Apds9960I2CTransportConfig

type
  Apds9960I2C* {.importcpp: "daisy::Apds9960I2C", bycopy.} = object
    ## APDS9960 sensor with I2C transport

{.pop.}

# Constructors

proc initApds9960I2CTransportConfig*(): Apds9960I2CTransportConfig {.constructor,
    importcpp: "daisy::Apds9960I2CTransport::Config(@)", header: "dev/apds9960.h".}
  ## Initialize I2C transport config with defaults

proc initApds9960Config*(): Apds9960Config {.constructor,
    importcpp: "daisy::Apds9960I2C::Config(@)", header: "dev/apds9960.h".}
  ## Initialize sensor config with defaults

# Methods

proc init*(this: var Apds9960I2C, config: Apds9960Config): Apds9960Result 
  {.importcpp: "#.Init(#)", header: "dev/apds9960.h".}
  ## Initialize the APDS9960 sensor
  ## 
  ## **Returns:** APDS9960_OK on success, APDS9960_ERR on failure

proc enable*(this: var Apds9960I2C, en: bool = true) 
  {.importcpp: "#.Enable(#)", header: "dev/apds9960.h".}
  ## Enable or disable the sensor (power on/off)

proc enableGesture*(this: var Apds9960I2C, en: bool) 
  {.importcpp: "#.EnableGesture(#)", header: "dev/apds9960.h".}
  ## Enable or disable gesture recognition

proc enableProximity*(this: var Apds9960I2C, en: bool) 
  {.importcpp: "#.EnableProximity(#)", header: "dev/apds9960.h".}
  ## Enable or disable proximity detection

proc enableColor*(this: var Apds9960I2C, en: bool) 
  {.importcpp: "#.EnableColor(#)", header: "dev/apds9960.h".}
  ## Enable or disable color/light sensing

proc readGesture*(this: var Apds9960I2C): uint8 
  {.importcpp: "#.ReadGesture()", header: "dev/apds9960.h".}
  ## Read detected gesture
  ##
  ## **Returns:** 0 (none), APDS9960_UP, APDS9960_DOWN, APDS9960_LEFT, or APDS9960_RIGHT

proc gestureValid*(this: var Apds9960I2C): bool 
  {.importcpp: "#.GestureValid()", header: "dev/apds9960.h".}
  ## Check if gesture data is valid
  ##
  ## **Returns:** true if gesture data ready

proc readProximity*(this: var Apds9960I2C): uint8 
  {.importcpp: "#.ReadProximity()", header: "dev/apds9960.h".}
  ## Read proximity value (0-255)
  ##
  ## **Returns:** Proximity value (0 = far, 255 = very close)

proc colorDataReady*(this: var Apds9960I2C): bool 
  {.importcpp: "#.ColorDataReady()", header: "dev/apds9960.h".}
  ## Check if color data is ready
  ##
  ## **Returns:** true if color data available

proc getColorDataRed*(this: var Apds9960I2C): uint16 
  {.importcpp: "#.GetColorDataRed()", header: "dev/apds9960.h".}
  ## Get red channel value (16-bit)

proc getColorDataGreen*(this: var Apds9960I2C): uint16 
  {.importcpp: "#.GetColorDataGreen()", header: "dev/apds9960.h".}
  ## Get green channel value (16-bit)

proc getColorDataBlue*(this: var Apds9960I2C): uint16 
  {.importcpp: "#.GetColorDataBlue()", header: "dev/apds9960.h".}
  ## Get blue channel value (16-bit)

proc getColorDataClear*(this: var Apds9960I2C): uint16 
  {.importcpp: "#.GetColorDataClear()", header: "dev/apds9960.h".}
  ## Get clear/ambient light value (16-bit)

proc getColorData*(this: var Apds9960I2C, r, g, b, c: ptr uint16) 
  {.importcpp: "#.GetColorData(#, #, #, #)", header: "dev/apds9960.h".}
  ## Get all color channel values at once
  ##
  ## **Parameters:**
  ## - `r` - Pointer to store red value
  ## - `g` - Pointer to store green value
  ## - `b` - Pointer to store blue value
  ## - `c` - Pointer to store clear value

proc calculateColorTemperature*(this: var Apds9960I2C, r, g, b: uint16): uint16 
  {.importcpp: "#.CalculateColorTemperature(#, #, #)", header: "dev/apds9960.h".}
  ## Convert RGB to color temperature in Kelvin
  ##
  ## **Returns:** Color temperature in degrees Kelvin

proc calculateLux*(this: var Apds9960I2C, r, g, b: uint16): uint16 
  {.importcpp: "#.CalculateLux(#, #, #)", header: "dev/apds9960.h".}
  ## Calculate ambient light level in lux
  ##
  ## **Returns:** Illuminance in lux

proc setADCIntegrationTime*(this: var Apds9960I2C, timeMs: uint16) 
  {.importcpp: "#.SetADCIntegrationTime(#)", header: "dev/apds9960.h".}
  ## Set ADC integration time in milliseconds

proc getADCIntegrationTime*(this: var Apds9960I2C): cfloat 
  {.importcpp: "#.GetADCIntegrationTime()", header: "dev/apds9960.h".}
  ## Get current ADC integration time
  ##
  ## **Returns:** Integration time in milliseconds

proc setADCGain*(this: var Apds9960I2C, gain: uint8) 
  {.importcpp: "#.SetADCGain(#)", header: "dev/apds9960.h".}
  ## Set ADC gain (0-3 for 1x, 4x, 16x, 64x)

proc setProxGain*(this: var Apds9960I2C, gain: uint8) 
  {.importcpp: "#.SetProxGain(#)", header: "dev/apds9960.h".}
  ## Set proximity gain (0-3)

proc getProxGain*(this: var Apds9960I2C): uint8 
  {.importcpp: "#.GetProxGain()", header: "dev/apds9960.h".}
  ## Get current proximity gain

proc setGestureOffset*(this: var Apds9960I2C, up, down, left, right: uint8) 
  {.importcpp: "#.SetGestureOffset(#, #, #, #)", header: "dev/apds9960.h".}
  ## Set gesture sensor offsets for calibration

proc setLED*(this: var Apds9960I2C, drive, boost: uint8) 
  {.importcpp: "#.SetLED(#, #)", header: "dev/apds9960.h".}
  ## Set LED brightness for proximity/gesture
  ##
  ## **Parameters:**
  ## - `drive` - LED drive (0-3): 100mA, 50mA, 25mA, 12.5mA
  ## - `boost` - LED boost (0-3): 100%, 150%, 200%, 300%

proc clearInterrupt*(this: var Apds9960I2C) 
  {.importcpp: "#.ClearInterrupt()", header: "dev/apds9960.h".}
  ## Clear interrupts
