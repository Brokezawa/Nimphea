## ICM20948 9-Axis IMU Sensor Module
## ==================================
##
## Nim wrapper for the ICM20948 9-axis IMU sensor.
##
## The ICM20948 combines a 3-axis accelerometer, 3-axis gyroscope, and 3-axis
## magnetometer (AK09916) in a single package.
##
## **Features:**
## - 3-axis gyroscope with configurable ranges (250, 500, 1000, 2000 DPS)
## - 3-axis accelerometer with configurable ranges (±2g, ±4g, ±8g, ±16g)
## - 3-axis magnetometer with configurable data rates (10Hz to 100Hz)
## - Temperature sensor
## - Both I2C and SPI transport options
## - Integrated auxiliary I2C bus for magnetometer
##
## **Example:**
## ```nim
## import nimphea
## import dev/icm20948
##
## var imu: Icm20948I2C
## var config: Icm20948I2CConfig
## 
## # Configure I2C transport
## config.transport_config.address = ICM20948_I2CADDR_DEFAULT
## config.transport_config.periph = I2C_PERIPH_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = seed.GetPin(11)  # PB8
## config.transport_config.sda = seed.GetPin(12)  # PB9
##
## if imu.init(config) == ICM20948_OK:
##   discard imu.setupMag()
##   
##   while true:
##     imu.process()
##     let accel = imu.getAccelVect()
##     let gyro = imu.getGyroVect()
##     let mag = imu.getMagVect()
##     let temp = imu.getTemp()
##     # Use sensor data...
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c
import ../per/spi

useNimpheaModules(icm20948)

{.push header: "dev/icm20948.h".}

# Constants
const
  ICM20948_CHIP_ID* = 0xEA'u8           ## ICM20948 chip ID
  ICM20948_I2CADDR_DEFAULT* = 0x69'u8   ## Default I2C address
  ICM20948_MAG_ID* = 0x09'u8            ## Magnetometer chip ID
  ICM20948_UT_PER_LSB* = 0.15'f32       ## Magnetometer LSB value

# Enums

type
  Icm20948AccelRange* {.importcpp: "daisy::Icm20948<daisy::Icm20948I2CTransport>::icm20948_accel_range_t", size: sizeof(cint).} = enum
    ## Accelerometer measurement range
    ICM20948_ACCEL_RANGE_2_G  = 0  ## ±2g
    ICM20948_ACCEL_RANGE_4_G  = 1  ## ±4g
    ICM20948_ACCEL_RANGE_8_G  = 2  ## ±8g
    ICM20948_ACCEL_RANGE_16_G = 3  ## ±16g

type
  Icm20948GyroRange* {.importcpp: "daisy::Icm20948<daisy::Icm20948I2CTransport>::icm20948_gyro_range_t", size: sizeof(cint).} = enum
    ## Gyroscope measurement range
    ICM20948_GYRO_RANGE_250_DPS  = 0  ## ±250 degrees per second
    ICM20948_GYRO_RANGE_500_DPS  = 1  ## ±500 degrees per second
    ICM20948_GYRO_RANGE_1000_DPS = 2  ## ±1000 degrees per second
    ICM20948_GYRO_RANGE_2000_DPS = 3  ## ±2000 degrees per second

type
  Ak09916DataRate* {.importcpp: "daisy::Icm20948<daisy::Icm20948I2CTransport>::ak09916_data_rate_t", size: sizeof(cint).} = enum
    ## Magnetometer data rate
    AK09916_MAG_DATARATE_SHUTDOWN = 0x0  ## Stops measurement updates
    AK09916_MAG_DATARATE_SINGLE   = 0x1  ## Single measurement
    AK09916_MAG_DATARATE_10_HZ    = 0x2  ## 10 Hz updates
    AK09916_MAG_DATARATE_20_HZ    = 0x4  ## 20 Hz updates
    AK09916_MAG_DATARATE_50_HZ    = 0x6  ## 50 Hz updates
    AK09916_MAG_DATARATE_100_HZ   = 0x8  ## 100 Hz updates

type
  Icm20948Result* {.importcpp: "daisy::Icm20948<daisy::Icm20948I2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    ICM20948_OK  = 0  ## Success
    ICM20948_ERR = 1  ## Error

# I2C Transport Types

type
  Icm20948I2CTransportConfig* {.importcpp: "daisy::Icm20948I2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    address* {.importcpp: "address".}: uint8

type
  Icm20948I2CTransport* {.importcpp: "daisy::Icm20948I2CTransport", bycopy.} = object
    ## I2C transport for ICM20948

# SPI Transport Types

type
  Icm20948SpiTransportConfig* {.importcpp: "daisy::Icm20948SpiTransport::Config", bycopy.} = object
    ## SPI transport configuration
    periph* {.importcpp: "periph".}: SpiPeripheral
    sclk* {.importcpp: "sclk".}: Pin
    miso* {.importcpp: "miso".}: Pin
    mosi* {.importcpp: "mosi".}: Pin
    nss* {.importcpp: "nss".}: Pin

type
  Icm20948SpiTransport* {.importcpp: "daisy::Icm20948SpiTransport", bycopy.} = object
    ## SPI transport for ICM20948

# Device Types

type
  Icm20948Vect* {.importcpp: "daisy::Icm20948<daisy::Icm20948I2CTransport>::Icm20948Vect", bycopy.} = object
    ## 3D vector for sensor data
    x* {.importcpp: "x".}: cfloat
    y* {.importcpp: "y".}: cfloat
    z* {.importcpp: "z".}: cfloat

type
  Icm20948I2CConfig* {.importcpp: "daisy::Icm20948I2C::Config", bycopy.} = object
    ## I2C device configuration
    transport_config* {.importcpp: "transport_config".}: Icm20948I2CTransportConfig

type
  Icm20948I2C* {.importcpp: "daisy::Icm20948I2C", bycopy.} = object
    ## ICM20948 sensor with I2C transport

type
  Icm20948SpiConfig* {.importcpp: "daisy::Icm20948Spi::Config", bycopy.} = object
    ## SPI device configuration
    transport_config* {.importcpp: "transport_config".}: Icm20948SpiTransportConfig

type
  Icm20948Spi* {.importcpp: "daisy::Icm20948Spi", bycopy.} = object
    ## ICM20948 sensor with SPI transport

{.pop.}

# Constructors

proc initIcm20948I2CTransportConfig*(): Icm20948I2CTransportConfig {.constructor,
    importcpp: "daisy::Icm20948I2CTransport::Config(@)", header: "dev/icm20948.h".}
  ## Initialize I2C transport config with defaults

proc initIcm20948SpiTransportConfig*(): Icm20948SpiTransportConfig {.constructor,
    importcpp: "daisy::Icm20948SpiTransport::Config(@)", header: "dev/icm20948.h".}
  ## Initialize SPI transport config with defaults

proc initIcm20948I2CConfig*(): Icm20948I2CConfig {.constructor,
    importcpp: "daisy::Icm20948I2C::Config(@)", header: "dev/icm20948.h".}
  ## Initialize I2C device config with defaults

proc initIcm20948SpiConfig*(): Icm20948SpiConfig {.constructor,
    importcpp: "daisy::Icm20948Spi::Config(@)", header: "dev/icm20948.h".}
  ## Initialize SPI device config with defaults

# Methods - I2C variant

proc init*(this: var Icm20948I2C, config: Icm20948I2CConfig): Icm20948Result 
  {.importcpp: "#.Init(#)", header: "dev/icm20948.h".}
  ## Initialize the ICM20948 sensor
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with transport and sensor settings
  ## 
  ## **Returns:** ICM20948_OK on success, ICM20948_ERR on failure

proc reset*(this: var Icm20948I2C) 
  {.importcpp: "#.Reset()", header: "dev/icm20948.h".}
  ## Reset the sensor to default settings

proc setupMag*(this: var Icm20948I2C): Icm20948Result 
  {.importcpp: "#.SetupMag()", header: "dev/icm20948.h".}
  ## Setup the magnetometer
  ##
  ## Must be called after init() to enable magnetometer readings.
  ##
  ## **Returns:** ICM20948_OK on success, ICM20948_ERR on failure

proc process*(this: var Icm20948I2C) 
  {.importcpp: "#.Process()", header: "dev/icm20948.h".}
  ## Update all sensor readings
  ##
  ## Call this regularly to fetch new data from the sensor.

proc getAccelVect*(this: var Icm20948I2C): Icm20948Vect 
  {.importcpp: "#.GetAccelVect()", header: "dev/icm20948.h".}
  ## Get the latest accelerometer reading in m/s²
  ##
  ## **Returns:** Vector with x, y, z acceleration values

proc getGyroVect*(this: var Icm20948I2C): Icm20948Vect 
  {.importcpp: "#.GetGyroVect()", header: "dev/icm20948.h".}
  ## Get the latest gyroscope reading in rad/s
  ##
  ## **Returns:** Vector with x, y, z rotation values

proc getMagVect*(this: var Icm20948I2C): Icm20948Vect 
  {.importcpp: "#.GetMagVect()", header: "dev/icm20948.h".}
  ## Get the latest magnetometer reading in µT
  ##
  ## **Returns:** Vector with x, y, z magnetic field values

proc getTemp*(this: var Icm20948I2C): cfloat 
  {.importcpp: "#.GetTemp()", header: "dev/icm20948.h".}
  ## Get the latest temperature reading in °C
  ##
  ## **Returns:** Temperature in degrees Celsius

proc setAccelRange*(this: var Icm20948I2C, range: Icm20948AccelRange) 
  {.importcpp: "#.SetAccelRange(#)", header: "dev/icm20948.h".}
  ## Set the accelerometer measurement range
  ##
  ## **Parameters:**
  ## - `range` - Measurement range (2g, 4g, 8g, or 16g)

proc getAccelRange*(this: var Icm20948I2C): Icm20948AccelRange 
  {.importcpp: "#.GetAccelRange()", header: "dev/icm20948.h".}
  ## Get the current accelerometer measurement range
  ##
  ## **Returns:** Current accelerometer range

proc setGyroRange*(this: var Icm20948I2C, range: Icm20948GyroRange) 
  {.importcpp: "#.SetGyroRange(#)", header: "dev/icm20948.h".}
  ## Set the gyroscope measurement range
  ##
  ## **Parameters:**
  ## - `range` - Measurement range (250, 500, 1000, or 2000 DPS)

proc getGyroRange*(this: var Icm20948I2C): Icm20948GyroRange 
  {.importcpp: "#.GetGyroRange()", header: "dev/icm20948.h".}
  ## Get the current gyroscope measurement range
  ##
  ## **Returns:** Current gyroscope range

proc setMagDataRate*(this: var Icm20948I2C, rate: Ak09916DataRate): bool 
  {.importcpp: "#.SetMagDataRate(#)", header: "dev/icm20948.h".}
  ## Set the magnetometer data rate
  ##
  ## **Parameters:**
  ## - `rate` - Data rate (10Hz, 20Hz, 50Hz, or 100Hz)
  ##
  ## **Returns:** true on success, false on failure

proc getMagDataRate*(this: var Icm20948I2C): Ak09916DataRate 
  {.importcpp: "#.GetMagDataRate()", header: "dev/icm20948.h".}
  ## Get the current magnetometer data rate
  ##
  ## **Returns:** Current magnetometer data rate

proc setAccelRateDivisor*(this: var Icm20948I2C, divisor: uint16) 
  {.importcpp: "#.SetAccelRateDivisor(#)", header: "dev/icm20948.h".}
  ## Set the accelerometer sample rate divisor
  ##
  ## Rate = 1125Hz / (1 + divisor)
  ##
  ## **Parameters:**
  ## - `divisor` - Rate divisor (0-4095)

proc setGyroRateDivisor*(this: var Icm20948I2C, divisor: uint8) 
  {.importcpp: "#.SetGyroRateDivisor(#)", header: "dev/icm20948.h".}
  ## Set the gyroscope sample rate divisor
  ##
  ## Rate = 1100Hz / (1 + divisor)
  ##
  ## **Parameters:**
  ## - `divisor` - Rate divisor (0-255)

# Methods - SPI variant

proc init*(this: var Icm20948Spi, config: Icm20948SpiConfig): Icm20948Result 
  {.importcpp: "#.Init(#)", header: "dev/icm20948.h".}
  ## Initialize the ICM20948 sensor via SPI

proc reset*(this: var Icm20948Spi) 
  {.importcpp: "#.Reset()", header: "dev/icm20948.h".}
  ## Reset the sensor to default settings

proc setupMag*(this: var Icm20948Spi): Icm20948Result 
  {.importcpp: "#.SetupMag()", header: "dev/icm20948.h".}
  ## Setup the magnetometer

proc process*(this: var Icm20948Spi) 
  {.importcpp: "#.Process()", header: "dev/icm20948.h".}
  ## Update all sensor readings

proc getAccelVect*(this: var Icm20948Spi): Icm20948Vect 
  {.importcpp: "#.GetAccelVect()", header: "dev/icm20948.h".}
  ## Get the latest accelerometer reading in m/s²

proc getGyroVect*(this: var Icm20948Spi): Icm20948Vect 
  {.importcpp: "#.GetGyroVect()", header: "dev/icm20948.h".}
  ## Get the latest gyroscope reading in rad/s

proc getMagVect*(this: var Icm20948Spi): Icm20948Vect 
  {.importcpp: "#.GetMagVect()", header: "dev/icm20948.h".}
  ## Get the latest magnetometer reading in µT

proc getTemp*(this: var Icm20948Spi): cfloat 
  {.importcpp: "#.GetTemp()", header: "dev/icm20948.h".}
  ## Get the latest temperature reading in °C

proc setAccelRange*(this: var Icm20948Spi, range: Icm20948AccelRange) 
  {.importcpp: "#.SetAccelRange(#)", header: "dev/icm20948.h".}
  ## Set the accelerometer measurement range

proc getAccelRange*(this: var Icm20948Spi): Icm20948AccelRange 
  {.importcpp: "#.GetAccelRange()", header: "dev/icm20948.h".}
  ## Get the current accelerometer measurement range

proc setGyroRange*(this: var Icm20948Spi, range: Icm20948GyroRange) 
  {.importcpp: "#.SetGyroRange(#)", header: "dev/icm20948.h".}
  ## Set the gyroscope measurement range

proc getGyroRange*(this: var Icm20948Spi): Icm20948GyroRange 
  {.importcpp: "#.GetGyroRange()", header: "dev/icm20948.h".}
  ## Get the current gyroscope measurement range

proc setMagDataRate*(this: var Icm20948Spi, rate: Ak09916DataRate): bool 
  {.importcpp: "#.SetMagDataRate(#)", header: "dev/icm20948.h".}
  ## Set the magnetometer data rate

proc getMagDataRate*(this: var Icm20948Spi): Ak09916DataRate 
  {.importcpp: "#.GetMagDataRate()", header: "dev/icm20948.h".}
  ## Get the current magnetometer data rate

proc setAccelRateDivisor*(this: var Icm20948Spi, divisor: uint16) 
  {.importcpp: "#.SetAccelRateDivisor(#)", header: "dev/icm20948.h".}
  ## Set the accelerometer sample rate divisor

proc setGyroRateDivisor*(this: var Icm20948Spi, divisor: uint8) 
  {.importcpp: "#.SetGyroRateDivisor(#)", header: "dev/icm20948.h".}
  ## Set the gyroscope sample rate divisor
