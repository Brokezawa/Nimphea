## MPR121 12-Channel Capacitive Touch Sensor Module
## ==================================================
##
## Nim wrapper for the MPR121 capacitive touch sensor.
##
## The MPR121 provides 12 individual capacitive touch sensor inputs with
## automatic baseline tracking and configurable touch/release thresholds.
## Perfect for building custom touch interfaces and musical instruments.
##
## **Features:**
## - 12 capacitive touch sensor channels
## - Automatic baseline tracking
## - Configurable touch and release thresholds
## - Filtered and baseline data readback
## - I2C interface only
## - Touch status register for reading all channels at once
##
## **Example:**
## ```nim
## import nimphea
## import dev/mpr121
##
## var sensor: Mpr121I2C
## var config: Mpr121Config
## 
## # Configure I2C transport
## config.transport_config.dev_addr = MPR121_I2CADDR_DEFAULT
## config.transport_config.periph = I2C_PERIPH_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = seed.GetPin(11)  # PB8
## config.transport_config.sda = seed.GetPin(12)  # PB9
## config.touch_threshold = 12
## config.release_threshold = 6
##
## if sensor.init(config) == MPR121_OK:
##   while true:
##     let touched = sensor.touched()
##     for i in 0..11:
##       if (touched and (1 shl i)) != 0:
##         # Channel i is touched
##         discard
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(mpr121)

{.push header: "dev/mpr121.h".}

# Constants
const
  MPR121_I2CADDR_DEFAULT* = 0x5A'u8      ## Default I2C address
  MPR121_TOUCH_THRESHOLD_DEFAULT* = 12'u8   ## Default touch threshold value
  MPR121_RELEASE_THRESHOLD_DEFAULT* = 6'u8  ## Default release threshold value

# Enums

type
  Mpr121Result* {.importcpp: "daisy::Mpr121<daisy::Mpr121I2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    MPR121_OK  = 0  ## Success
    MPR121_ERR = 1  ## Error

# I2C Transport Types

type
  Mpr121I2CTransportConfig* {.importcpp: "daisy::Mpr121I2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    mode* {.importcpp: "mode".}: I2CMode
    dev_addr* {.importcpp: "dev_addr".}: uint8

type
  Mpr121I2CTransport* {.importcpp: "daisy::Mpr121I2CTransport", bycopy.} = object
    ## I2C transport for MPR121

# Device Types

type
  Mpr121Config* {.importcpp: "daisy::Mpr121I2C::Config", bycopy.} = object
    ## MPR121 device configuration
    transport_config* {.importcpp: "transport_config".}: Mpr121I2CTransportConfig
    touch_threshold* {.importcpp: "touch_threshold".}: uint8
    release_threshold* {.importcpp: "release_threshold".}: uint8

type
  Mpr121I2C* {.importcpp: "daisy::Mpr121I2C", bycopy.} = object
    ## MPR121 sensor with I2C transport

{.pop.}

# Constructors

proc initMpr121I2CTransportConfig*(): Mpr121I2CTransportConfig {.constructor,
    importcpp: "daisy::Mpr121I2CTransport::Config(@)", header: "dev/mpr121.h".}
  ## Initialize I2C transport config with defaults

proc initMpr121Config*(): Mpr121Config {.constructor,
    importcpp: "daisy::Mpr121I2C::Config(@)", header: "dev/mpr121.h".}
  ## Initialize device config with defaults

# Methods

proc init*(this: var Mpr121I2C, config: Mpr121Config): Mpr121Result 
  {.importcpp: "#.Init(#)", header: "dev/mpr121.h".}
  ## Initialize the MPR121 sensor
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with transport and threshold settings
  ## 
  ## **Returns:** MPR121_OK on success, MPR121_ERR on failure

proc setThresholds*(this: var Mpr121I2C, touch: uint8, release: uint8) 
  {.importcpp: "#.SetThresholds(#, #)", header: "dev/mpr121.h".}
  ## Set touch and release thresholds for all channels
  ##
  ## **Parameters:**
  ## - `touch` - Touch threshold value (0-255)
  ## - `release` - Release threshold value (0-255)

proc filteredData*(this: var Mpr121I2C, channel: uint8): uint16 
  {.importcpp: "#.FilteredData(#)", header: "dev/mpr121.h".}
  ## Read the filtered data from a channel
  ##
  ## The ADC raw data is filtered through 3 levels of digital filtering
  ## to remove high and low frequency noise.
  ##
  ## **Parameters:**
  ## - `channel` - Channel number (0-12)
  ##
  ## **Returns:** 10-bit filtered reading

proc baselineData*(this: var Mpr121I2C, channel: uint8): uint16 
  {.importcpp: "#.BaselineData(#)", header: "dev/mpr121.h".}
  ## Read the baseline value for a channel
  ##
  ## **Parameters:**
  ## - `channel` - Channel number (0-12)
  ##
  ## **Returns:** Baseline data value

proc touched*(this: var Mpr121I2C): uint16 
  {.importcpp: "#.Touched()", header: "dev/mpr121.h".}
  ## Read the touch status of all 13 channels
  ##
  ## Each bit represents the touch status of one channel.
  ## Bit 0 = channel 0, bit 1 = channel 1, etc.
  ##
  ## **Returns:** 12-bit value with touch status (bit set = touched)

proc readRegister8*(this: var Mpr121I2C, reg: uint8): uint8 
  {.importcpp: "#.ReadRegister8(#)", header: "dev/mpr121.h".}
  ## Read an 8-bit register value
  ##
  ## **Parameters:**
  ## - `reg` - Register address to read
  ##
  ## **Returns:** 8-bit register value

proc readRegister16*(this: var Mpr121I2C, reg: uint8): uint16 
  {.importcpp: "#.ReadRegister16(#)", header: "dev/mpr121.h".}
  ## Read a 16-bit register value
  ##
  ## **Parameters:**
  ## - `reg` - Register address to read
  ##
  ## **Returns:** 16-bit register value

proc writeRegister*(this: var Mpr121I2C, reg: uint8, value: uint8) 
  {.importcpp: "#.WriteRegister(#, #)", header: "dev/mpr121.h".}
  ## Write an 8-bit value to a register
  ##
  ## Automatically handles stop mode requirements.
  ##
  ## **Parameters:**
  ## - `reg` - Register address to write
  ## - `value` - Value to write
