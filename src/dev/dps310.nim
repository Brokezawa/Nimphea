## DPS310 Barometric Pressure & Altitude Sensor Module
## =====================================================
##
## Nim wrapper for the DPS310 barometric pressure and altitude sensor.
##
## The DPS310 is a high-precision barometric pressure sensor that can measure
## absolute pressure and calculate altitude. It supports both I2C and SPI interfaces.
##
## **Features:**
## - High-precision pressure measurement (±2 Pa, equivalent to ±0.5 m)
## - Temperature sensor for compensation
## - Configurable measurement rates (1Hz to 128Hz)
## - Configurable oversampling (1 to 128 samples)
## - Both I2C and SPI transport options
## - Continuous and one-shot measurement modes
##
## **Example:**
## ```nim
## import nimphea
## import dev/dps310
##
## var sensor: Dps310I2C
## var config: Dps310I2CConfig
## 
## # Configure I2C transport
## config.transport_config.address = DPS310_I2CADDR_DEFAULT
## config.transport_config.periph = I2C_PERIPH_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = seed.GetPin(11)  # PB8
## config.transport_config.sda = seed.GetPin(12)  # PB9
##
## if sensor.init(config) == DPS310_OK:
##   while true:
##     sensor.process()
##     let pressure = sensor.getPressure()      # in hPa
##     let temperature = sensor.getTemperature() # in °C
##     let altitude = sensor.getAltitude(1013.25) # sea level pressure
##     # Use sensor data...
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c
import ../per/spi

useNimpheaModules(dps310)

{.push header: "dev/dps310.h".}

# Constants
const
  DPS310_I2CADDR_DEFAULT* = 0x77'u8  ## Default I2C address

# Enums

type
  Dps310Rate* {.importcpp: "daisy::Dps310<daisy::Dps310I2CTransport>::dps310_rate_t", size: sizeof(cint).} = enum
    ## Measurement rate
    DPS310_1HZ   = 0  ## 1 Hz
    DPS310_2HZ   = 1  ## 2 Hz
    DPS310_4HZ   = 2  ## 4 Hz
    DPS310_8HZ   = 3  ## 8 Hz
    DPS310_16HZ  = 4  ## 16 Hz
    DPS310_32HZ  = 5  ## 32 Hz
    DPS310_64HZ  = 6  ## 64 Hz
    DPS310_128HZ = 7  ## 128 Hz

type
  Dps310Oversample* {.importcpp: "daisy::Dps310<daisy::Dps310I2CTransport>::dps310_oversample_t", size: sizeof(cint).} = enum
    ## Oversample rate
    DPS310_1SAMPLE    = 0  ## 1 sample
    DPS310_2SAMPLES   = 1  ## 2 samples
    DPS310_4SAMPLES   = 2  ## 4 samples
    DPS310_8SAMPLES   = 3  ## 8 samples
    DPS310_16SAMPLES  = 4  ## 16 samples
    DPS310_32SAMPLES  = 5  ## 32 samples
    DPS310_64SAMPLES  = 6  ## 64 samples
    DPS310_128SAMPLES = 7  ## 128 samples

type
  Dps310Mode* {.importcpp: "daisy::Dps310<daisy::Dps310I2CTransport>::dps310_mode_t", size: sizeof(cint).} = enum
    ## Operating mode
    DPS310_IDLE            = 0b000  ## Stopped/idle
    DPS310_ONE_PRESSURE    = 0b001  ## Single pressure measurement
    DPS310_ONE_TEMPERATURE = 0b010  ## Single temperature measurement
    DPS310_CONT_PRESSURE   = 0b101  ## Continuous pressure measurements
    DPS310_CONT_TEMP       = 0b110  ## Continuous temperature measurements
    DPS310_CONT_PRESTEMP   = 0b111  ## Continuous temp+pressure measurements

type
  Dps310Result* {.importcpp: "daisy::Dps310<daisy::Dps310I2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    DPS310_OK  = 0  ## Success
    DPS310_ERR = 1  ## Error

# I2C Transport Types

type
  Dps310I2CTransportConfig* {.importcpp: "daisy::Dps310I2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    address* {.importcpp: "address".}: uint8

type
  Dps310I2CTransport* {.importcpp: "daisy::Dps310I2CTransport", bycopy.} = object
    ## I2C transport for DPS310

# SPI Transport Types

type
  Dps310SpiTransportConfig* {.importcpp: "daisy::Dps310SpiTransport::Config", bycopy.} = object
    ## SPI transport configuration
    periph* {.importcpp: "periph".}: SpiPeripheral
    sclk* {.importcpp: "sclk".}: Pin
    miso* {.importcpp: "miso".}: Pin
    mosi* {.importcpp: "mosi".}: Pin
    nss* {.importcpp: "nss".}: Pin

type
  Dps310SpiTransport* {.importcpp: "daisy::Dps310SpiTransport", bycopy.} = object
    ## SPI transport for DPS310

# Device Types

type
  Dps310I2CConfig* {.importcpp: "daisy::Dps310I2C::Config", bycopy.} = object
    ## I2C device configuration
    transport_config* {.importcpp: "transport_config".}: Dps310I2CTransportConfig

type
  Dps310I2C* {.importcpp: "daisy::Dps310I2C", bycopy.} = object
    ## DPS310 sensor with I2C transport

type
  Dps310SpiConfig* {.importcpp: "daisy::Dps310Spi::Config", bycopy.} = object
    ## SPI device configuration
    transport_config* {.importcpp: "transport_config".}: Dps310SpiTransportConfig

type
  Dps310Spi* {.importcpp: "daisy::Dps310Spi", bycopy.} = object
    ## DPS310 sensor with SPI transport

{.pop.}

# Constructors

proc initDps310I2CTransportConfig*(): Dps310I2CTransportConfig {.constructor,
    importcpp: "daisy::Dps310I2CTransport::Config(@)", header: "dev/dps310.h".}
  ## Initialize I2C transport config with defaults

proc initDps310SpiTransportConfig*(): Dps310SpiTransportConfig {.constructor,
    importcpp: "daisy::Dps310SpiTransport::Config(@)", header: "dev/dps310.h".}
  ## Initialize SPI transport config with defaults

proc initDps310I2CConfig*(): Dps310I2CConfig {.constructor,
    importcpp: "daisy::Dps310I2C::Config(@)", header: "dev/dps310.h".}
  ## Initialize I2C device config with defaults

proc initDps310SpiConfig*(): Dps310SpiConfig {.constructor,
    importcpp: "daisy::Dps310Spi::Config(@)", header: "dev/dps310.h".}
  ## Initialize SPI device config with defaults

# Methods - I2C variant

proc init*(this: var Dps310I2C, config: Dps310I2CConfig): Dps310Result 
  {.importcpp: "#.Init(#)", header: "dev/dps310.h".}
  ## Initialize the DPS310 sensor
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with transport settings
  ## 
  ## **Returns:** DPS310_OK on success, DPS310_ERR on failure

proc reset*(this: var Dps310I2C) 
  {.importcpp: "#.reset()", header: "dev/dps310.h".}
  ## Perform a software reset

proc process*(this: var Dps310I2C) 
  {.importcpp: "#.Process()", header: "dev/dps310.h".}
  ## Update sensor readings
  ##
  ## Call this regularly to fetch new pressure and temperature data.

proc getPressure*(this: var Dps310I2C): cfloat 
  {.importcpp: "#.GetPressure()", header: "dev/dps310.h".}
  ## Get the latest pressure reading
  ##
  ## **Returns:** Pressure in hPa (hectopascals)

proc getTemperature*(this: var Dps310I2C): cfloat 
  {.importcpp: "#.GetTemperature()", header: "dev/dps310.h".}
  ## Get the latest temperature reading
  ##
  ## **Returns:** Temperature in degrees Celsius

proc getAltitude*(this: var Dps310I2C, seaLevelhPa: cfloat): cfloat 
  {.importcpp: "#.GetAltitude(#)", header: "dev/dps310.h".}
  ## Calculate approximate altitude using barometric pressure
  ##
  ## **Parameters:**
  ## - `seaLevelhPa` - Current sea level pressure in hPa (typically 1013.25)
  ##
  ## **Returns:** Approximate altitude above sea level in meters

proc setMode*(this: var Dps310I2C, mode: Dps310Mode) 
  {.importcpp: "#.setMode(#)", header: "dev/dps310.h".}
  ## Set the operational mode
  ##
  ## **Parameters:**
  ## - `mode` - Operating mode (idle, one-shot, or continuous)

proc configurePressure*(this: var Dps310I2C, rate: Dps310Rate, oversample: Dps310Oversample) 
  {.importcpp: "#.configurePressure(#, #)", header: "dev/dps310.h".}
  ## Configure pressure measurement parameters
  ##
  ## **Parameters:**
  ## - `rate` - Sample rate (1Hz to 128Hz)
  ## - `oversample` - Oversampling rate (1 to 128 samples)

proc configureTemperature*(this: var Dps310I2C, rate: Dps310Rate, oversample: Dps310Oversample) 
  {.importcpp: "#.configureTemperature(#, #)", header: "dev/dps310.h".}
  ## Configure temperature measurement parameters
  ##
  ## **Parameters:**
  ## - `rate` - Sample rate (1Hz to 128Hz)
  ## - `oversample` - Oversampling rate (1 to 128 samples)

proc pressureAvailable*(this: var Dps310I2C): bool 
  {.importcpp: "#.pressureAvailable()", header: "dev/dps310.h".}
  ## Check if new pressure data is available
  ##
  ## **Returns:** true if new pressure data ready to read

proc temperatureAvailable*(this: var Dps310I2C): bool 
  {.importcpp: "#.temperatureAvailable()", header: "dev/dps310.h".}
  ## Check if new temperature data is available
  ##
  ## **Returns:** true if new temperature data ready to read

proc getTransportError*(this: var Dps310I2C): Dps310Result 
  {.importcpp: "#.GetTransportError()", header: "dev/dps310.h".}
  ## Get and reset the transport error flag
  ##
  ## **Returns:** DPS310_ERR if transport error occurred, DPS310_OK otherwise

# Methods - SPI variant

proc init*(this: var Dps310Spi, config: Dps310SpiConfig): Dps310Result 
  {.importcpp: "#.Init(#)", header: "dev/dps310.h".}
  ## Initialize the DPS310 sensor via SPI

proc reset*(this: var Dps310Spi) 
  {.importcpp: "#.reset()", header: "dev/dps310.h".}
  ## Perform a software reset

proc process*(this: var Dps310Spi) 
  {.importcpp: "#.Process()", header: "dev/dps310.h".}
  ## Update sensor readings

proc getPressure*(this: var Dps310Spi): cfloat 
  {.importcpp: "#.GetPressure()", header: "dev/dps310.h".}
  ## Get the latest pressure reading in hPa

proc getTemperature*(this: var Dps310Spi): cfloat 
  {.importcpp: "#.GetTemperature()", header: "dev/dps310.h".}
  ## Get the latest temperature reading in °C

proc getAltitude*(this: var Dps310Spi, seaLevelhPa: cfloat): cfloat 
  {.importcpp: "#.GetAltitude(#)", header: "dev/dps310.h".}
  ## Calculate approximate altitude using barometric pressure

proc setMode*(this: var Dps310Spi, mode: Dps310Mode) 
  {.importcpp: "#.setMode(#)", header: "dev/dps310.h".}
  ## Set the operational mode

proc configurePressure*(this: var Dps310Spi, rate: Dps310Rate, oversample: Dps310Oversample) 
  {.importcpp: "#.configurePressure(#, #)", header: "dev/dps310.h".}
  ## Configure pressure measurement parameters

proc configureTemperature*(this: var Dps310Spi, rate: Dps310Rate, oversample: Dps310Oversample) 
  {.importcpp: "#.configureTemperature(#, #)", header: "dev/dps310.h".}
  ## Configure temperature measurement parameters

proc pressureAvailable*(this: var Dps310Spi): bool 
  {.importcpp: "#.pressureAvailable()", header: "dev/dps310.h".}
  ## Check if new pressure data is available

proc temperatureAvailable*(this: var Dps310Spi): bool 
  {.importcpp: "#.temperatureAvailable()", header: "dev/dps310.h".}
  ## Check if new temperature data is available

proc getTransportError*(this: var Dps310Spi): Dps310Result 
  {.importcpp: "#.GetTransportError()", header: "dev/dps310.h".}
  ## Get and reset the transport error flag
