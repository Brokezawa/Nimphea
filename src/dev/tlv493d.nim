## TLV493D 3D Magnetic Field Sensor Module
## =========================================
##
## Nim wrapper for the TLV493D 3-axis magnetic field sensor.
##
## The TLV493D is a low-power 3D magnetic sensor that can measure magnetic field
## strength in X, Y, and Z axes. It's useful for position sensing, proximity detection,
## joystick applications, and rotary encoding.
##
## **Features:**
## - 3-axis magnetic field measurement
## - Temperature sensor
## - Low power consumption with multiple power modes
## - I2C interface only
## - Configurable measurement rates
## - Magnetic field resolution: 0.098 mT per LSB
##
## **Example:**
## ```nim
## import nimphea
## import dev/tlv493d
##
## var sensor: Tlv493dI2C
## var config: Tlv493dConfig
## 
## # Configure I2C transport
## config.transport_config.address = TLV493D_ADDRESS1
## config.transport_config.periph = I2C_PERIPH_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = seed.GetPin(11)  # PB8
## config.transport_config.sda = seed.GetPin(12)  # PB9
##
## if sensor.init(config) == TLV493D_OK:
##   while true:
##     sensor.updateData()
##     let x = sensor.getX()        # in mT
##     let y = sensor.getY()        # in mT
##     let z = sensor.getZ()        # in mT
##     let temp = sensor.getTemp()  # in °C
##     let amount = sensor.getAmount()    # total field strength
##     let azimuth = sensor.getAzimuth()  # angle in XY plane
##     # Use sensor data...
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(tlv493d)

{.push header: "dev/tlv493d.h".}

# Constants
const
  TLV493D_ADDRESS1* = 0x5E'u8  ## I2C address 1
  TLV493D_ADDRESS2* = 0x1F'u8  ## I2C address 2
  TLV493D_B_MULT* = 0.098'f32  ## Magnetic field LSB multiplier (mT)

# Enums

type
  Tlv493dAccessMode* {.importcpp: "daisy::Tlv493d<daisy::Tlv493dI2CTransport>::AccessMode_e", size: sizeof(cint).} = enum
    ## Power and measurement access modes
    POWERDOWNMODE = 0        ## Power down mode (1000ms delay)
    FASTMODE = 1             ## Fast mode (no delay)
    LOWPOWERMODE = 2         ## Low power mode (10ms delay)
    ULTRALOWPOWERMODE = 3    ## Ultra low power mode (100ms delay)
    MASTERCONTROLLEDMODE = 4 ## Master controlled mode (10ms delay)

type
  Tlv493dResult* {.importcpp: "daisy::Tlv493d<daisy::Tlv493dI2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    TLV493D_OK  = 0  ## Success
    TLV493D_ERR = 1  ## Error

# I2C Transport Types

type
  Tlv493dI2CTransportConfig* {.importcpp: "daisy::Tlv493dI2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    address* {.importcpp: "address".}: uint8

type
  Tlv493dI2CTransport* {.importcpp: "daisy::Tlv493dI2CTransport", bycopy.} = object
    ## I2C transport for TLV493D

# Device Types

type
  Tlv493dConfig* {.importcpp: "daisy::Tlv493dI2C::Config", bycopy.} = object
    ## TLV493D device configuration
    transport_config* {.importcpp: "transport_config".}: Tlv493dI2CTransportConfig

type
  Tlv493dI2C* {.importcpp: "daisy::Tlv493dI2C", bycopy.} = object
    ## TLV493D sensor with I2C transport

{.pop.}

# Constructors

proc initTlv493dI2CTransportConfig*(): Tlv493dI2CTransportConfig {.constructor,
    importcpp: "daisy::Tlv493dI2CTransport::Config(@)", header: "dev/tlv493d.h".}
  ## Initialize I2C transport config with defaults

proc initTlv493dConfig*(): Tlv493dConfig {.constructor,
    importcpp: "daisy::Tlv493dI2C::Config(@)", header: "dev/tlv493d.h".}
  ## Initialize device config with defaults

# Methods

proc init*(this: var Tlv493dI2C, config: Tlv493dConfig): Tlv493dResult 
  {.importcpp: "#.Init(#)", header: "dev/tlv493d.h".}
  ## Initialize the TLV493D sensor
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with transport settings
  ## 
  ## **Returns:** TLV493D_OK on success, TLV493D_ERR on failure

proc updateData*(this: var Tlv493dI2C) 
  {.importcpp: "#.UpdateData()", header: "dev/tlv493d.h".}
  ## Update sensor readings
  ##
  ## Call this regularly to fetch new magnetic field and temperature data.
  ## Respects the measurement delay based on the current access mode.

proc getX*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetX()", header: "dev/tlv493d.h".}
  ## Get the X-axis magnetic field strength
  ##
  ## **Returns:** X-axis magnetic field in mT (millitesla)

proc getY*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetY()", header: "dev/tlv493d.h".}
  ## Get the Y-axis magnetic field strength
  ##
  ## **Returns:** Y-axis magnetic field in mT (millitesla)

proc getZ*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetZ()", header: "dev/tlv493d.h".}
  ## Get the Z-axis magnetic field strength
  ##
  ## **Returns:** Z-axis magnetic field in mT (millitesla)

proc getTemp*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetTemp()", header: "dev/tlv493d.h".}
  ## Get the temperature reading
  ##
  ## **Returns:** Temperature in degrees Celsius

proc getAmount*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetAmount()", header: "dev/tlv493d.h".}
  ## Get the total magnetic field strength
  ##
  ## Calculates sqrt(x² + y² + z²)
  ##
  ## **Returns:** Total magnetic field magnitude in mT

proc getAzimuth*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetAzimuth()", header: "dev/tlv493d.h".}
  ## Get the azimuth angle in the XY plane
  ##
  ## Calculates arctan(y/x)
  ##
  ## **Returns:** Azimuth angle in radians

proc getPolar*(this: var Tlv493dI2C): cfloat 
  {.importcpp: "#.GetPolar()", header: "dev/tlv493d.h".}
  ## Get the polar angle
  ##
  ## Calculates arctan(z/sqrt(x² + y²))
  ##
  ## **Returns:** Polar angle in radians

proc setAccessMode*(this: var Tlv493dI2C, mode: Tlv493dAccessMode) 
  {.importcpp: "#.SetAccessMode(#)", header: "dev/tlv493d.h".}
  ## Set the power/measurement access mode
  ##
  ## **Parameters:**
  ## - `mode` - Access mode (power down, fast, low power, ultra low power, or master controlled)

proc setInterrupt*(this: var Tlv493dI2C, enable: bool) 
  {.importcpp: "#.SetInterrupt(#)", header: "dev/tlv493d.h".}
  ## Enable or disable interrupts
  ##
  ## **Parameters:**
  ## - `enable` - true to enable interrupts, false to disable

proc enableTemp*(this: var Tlv493dI2C, enable: bool) 
  {.importcpp: "#.EnableTemp(#)", header: "dev/tlv493d.h".}
  ## Enable or disable temperature measurements
  ##
  ## **Parameters:**
  ## - `enable` - true to enable temperature sensor, false to disable

proc getMeasurementDelay*(this: var Tlv493dI2C): uint16 
  {.importcpp: "#.GetMeasurementDelay()", header: "dev/tlv493d.h".}
  ## Get the current measurement delay in milliseconds
  ##
  ## The delay depends on the current access mode.
  ##
  ## **Returns:** Measurement delay in ms
