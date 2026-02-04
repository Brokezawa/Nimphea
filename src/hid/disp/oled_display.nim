## OLED Display (SSD130x) support for libDaisy Nim wrapper
##
## Wraps libDaisy's SSD130xDriver template by using its pre-instantiated typedefs.
## This matches libDaisy's own approach and works reliably with Nim's C++ interop.
##
## LibDaisy defines typedefs like: `using SSD130xI2c128x64Driver = SSD130xDriver<128, 64, SSD130xI2CTransport>`
## We wrap these typedefs and provide a clean Nim API that selects the right one at compile time.
##
## Example - I2C display:
## ```nim
## var display = initOledI2c(128, 64)
## display.fill(false)
## display.drawPixel(64, 32, true)
## display.update()
## ```
##
## Example - SPI display (faster):
## ```nim
## var display = initOledSpi(128, 64)
## while true:
##   display.fill(false)
##   display.drawCircle(64, 32, 10, true)
##   display.update()
##   hw.delay(50)
## ```

import ../../nimphea
import ../../per/i2c
import ../../per/spi

useNimpheaModules(i2c, spi, oled)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # Transport configurations
  SSD130xI2CTransportConfig* {.importcpp: "daisy::SSD130xI2CTransport::Config", bycopy.} = object
    i2c_config* {.importc: "i2c_config".}: I2CConfig
    i2c_address* {.importc: "i2c_address".}: uint8
  
  SSD130xSpiPinConfig* {.importcpp: "daisy::SSD130x4WireSpiTransport::Config::pin_config", bycopy.} = object
    dc* {.importc: "dc".}: Pin
    reset* {.importc: "reset".}: Pin
  
  SSD130x4WireSpiTransportConfig* {.importcpp: "daisy::SSD130x4WireSpiTransport::Config", bycopy.} = object
    spi_config* {.importc: "spi_config".}: SpiConfig
    pin_config* {.importc: "pin_config".}: SSD130xSpiPinConfig
    useDma* {.importc: "useDma".}: bool
  
  # Pre-instantiated OLED Display types from libDaisy
  # I2C variants
  OledDisplay128x64I2c* {.importcpp: "daisy::SSD130xI2c128x64Driver".} = object
  OledDisplay128x32I2c* {.importcpp: "daisy::SSD130xI2c128x32Driver".} = object
  OledDisplay64x48I2c* {.importcpp: "daisy::SSD130xI2c64x48Driver".} = object
  OledDisplay64x32I2c* {.importcpp: "daisy::SSD130xI2c64x32Driver".} = object
  
  # SPI variants
  OledDisplay128x64Spi* {.importcpp: "daisy::SSD130x4WireSpi128x64Driver".} = object
  OledDisplay128x32Spi* {.importcpp: "daisy::SSD130x4WireSpi128x32Driver".} = object
  OledDisplay64x48Spi* {.importcpp: "daisy::SSD130x4WireSpi64x48Driver".} = object
  OledDisplay64x32Spi* {.importcpp: "daisy::SSD130x4WireSpi64x32Driver".} = object
  
  # Config structs
  OledDisplayI2cConfig* {.importcpp: "daisy::SSD130xI2c128x64Driver::Config", bycopy.} = object
    transport_config* {.importc: "transport_config".}: SSD130xI2CTransportConfig
  
  OledDisplaySpiConfig* {.importcpp: "daisy::SSD130x4WireSpi128x64Driver::Config", bycopy.} = object
    transport_config* {.importc: "transport_config".}: SSD130x4WireSpiTransportConfig
  
  # Union type for generic operations
  OledDisplay* = OledDisplay128x64I2c | OledDisplay128x32I2c | OledDisplay64x48I2c | OledDisplay64x32I2c |
                 OledDisplay128x64Spi | OledDisplay128x32Spi | OledDisplay64x48Spi | OledDisplay64x32Spi

{.pop.} # importcpp
{.pop.} # header

# Generic C++ member functions
proc Init[T, C](display: var T, config: C) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc Width[T](display: T): csize_t {.importcpp: "#.Width()", header: "daisy_seed.h".}
proc Height[T](display: T): csize_t {.importcpp: "#.Height()", header: "daisy_seed.h".}
proc DrawPixel[T](display: var T, x: uint8, y: uint8, on: bool) {.importcpp: "#.DrawPixel(@)", header: "daisy_seed.h".}
proc Fill[T](display: var T, on: bool) {.importcpp: "#.Fill(@)", header: "daisy_seed.h".}
proc Update[T](display: var T) {.importcpp: "#.Update()", header: "daisy_seed.h".}

# Constructors
proc cppNew128x64I2c(): OledDisplay128x64I2c {.importcpp: "daisy::SSD130xI2c128x64Driver()", constructor, header: "daisy_seed.h".}
proc cppNew128x32I2c(): OledDisplay128x32I2c {.importcpp: "daisy::SSD130xI2c128x32Driver()", constructor, header: "daisy_seed.h".}
proc cppNew64x48I2c(): OledDisplay64x48I2c {.importcpp: "daisy::SSD130xI2c64x48Driver()", constructor, header: "daisy_seed.h".}
proc cppNew64x32I2c(): OledDisplay64x32I2c {.importcpp: "daisy::SSD130xI2c64x32Driver()", constructor, header: "daisy_seed.h".}

proc cppNew128x64Spi(): OledDisplay128x64Spi {.importcpp: "daisy::SSD130x4WireSpi128x64Driver()", constructor, header: "daisy_seed.h".}
proc cppNew128x32Spi(): OledDisplay128x32Spi {.importcpp: "daisy::SSD130x4WireSpi128x32Driver()", constructor, header: "daisy_seed.h".}
proc cppNew64x48Spi(): OledDisplay64x48Spi {.importcpp: "daisy::SSD130x4WireSpi64x48Driver()", constructor, header: "daisy_seed.h".}
proc cppNew64x32Spi(): OledDisplay64x32Spi {.importcpp: "daisy::SSD130x4WireSpi64x32Driver()", constructor, header: "daisy_seed.h".}

proc cppNewI2cConfig(): OledDisplayI2cConfig {.importcpp: "daisy::SSD130xI2c128x64Driver::Config()", constructor, header: "daisy_seed.h".}
proc cppNewSpiConfig(): OledDisplaySpiConfig {.importcpp: "daisy::SSD130x4WireSpi128x64Driver::Config()", constructor, header: "daisy_seed.h".}

# Transport defaults
proc Defaults*(config: var SSD130xI2CTransportConfig) {.importcpp: "#.Defaults()", header: "daisy_seed.h".}
proc Defaults*(config: var SSD130x4WireSpiTransportConfig) {.importcpp: "#.Defaults()", header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim API - compile-time dispatch to correct template instantiation
# =============================================================================

template initOledI2c*(width, height: static[int], 
                      sclPin: Pin = newPin(PORTB, 8), 
                      sdaPin: Pin = newPin(PORTB, 9), 
                      address: uint8 = 0x3C): untyped =
  ## Initialize OLED via I2C - selects correct template instantiation at compile time
  when (width, height) == (128, 64):
    block:
      var result = cppNew128x64I2c()
      var config = cppNewI2cConfig()
      config.transport_config.Defaults()
      config.transport_config.i2c_config.pin_config.scl = sclPin
      config.transport_config.i2c_config.pin_config.sda = sdaPin
      config.transport_config.i2c_address = address
      result.Init(config)
      result
  elif (width, height) == (128, 32):
    block:
      var result = cppNew128x32I2c()
      var config = cppNewI2cConfig()
      config.transport_config.Defaults()
      config.transport_config.i2c_config.pin_config.scl = sclPin
      config.transport_config.i2c_config.pin_config.sda = sdaPin
      config.transport_config.i2c_address = address
      result.Init(config)
      result
  elif (width, height) == (64, 48):
    block:
      var result = cppNew64x48I2c()
      var config = cppNewI2cConfig()
      config.transport_config.Defaults()
      config.transport_config.i2c_config.pin_config.scl = sclPin
      config.transport_config.i2c_config.pin_config.sda = sdaPin
      config.transport_config.i2c_address = address
      result.Init(config)
      result
  elif (width, height) == (64, 32):
    block:
      var result = cppNew64x32I2c()
      var config = cppNewI2cConfig()
      config.transport_config.Defaults()
      config.transport_config.i2c_config.pin_config.scl = sclPin
      config.transport_config.i2c_config.pin_config.sda = sdaPin
      config.transport_config.i2c_address = address
      result.Init(config)
      result
  else:
    {.error: "Unsupported size. Use: 128x64, 128x32, 64x48, 64x32".}

template initOledSpi*(width, height: static[int],
                      dcPin: Pin = newPin(PORTB, 4),
                      resetPin: Pin = newPin(PORTB, 15),
                      sclkPin: Pin = newPin(PORTG, 11),
                      mosiPin: Pin = newPin(PORTB, 5),
                      nssPin: Pin = newPin(PORTG, 10)): untyped =
  ## Initialize OLED via SPI - selects correct template instantiation at compile time
  when (width, height) == (128, 64):
    block:
      var result = cppNew128x64Spi()
      var config = cppNewSpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  elif (width, height) == (128, 32):
    block:
      var result = cppNew128x32Spi()
      var config = cppNewSpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  elif (width, height) == (64, 48):
    block:
      var result = cppNew64x48Spi()
      var config = cppNewSpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  elif (width, height) == (64, 32):
    block:
      var result = cppNew64x32Spi()
      var config = cppNewSpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  else:
    {.error: "Unsupported size. Use: 128x64, 128x32, 64x48, 64x32".}

# Generic procs work on any OledDisplay (union type)
proc width*(display: OledDisplay): int {.inline.} = display.Width().int
proc height*(display: OledDisplay): int {.inline.} = display.Height().int
proc drawPixel*(display: var OledDisplay, x, y: int, on: bool = true) = display.DrawPixel(x.uint8, y.uint8, on)
proc fill*(display: var OledDisplay, on: bool = true) = display.Fill(on)
proc update*(display: var OledDisplay) = display.Update()

# Drawing helpers
proc drawLine*(display: var OledDisplay, x0, y0, x1, y1: int, on: bool = true) =
  var x0 = x0; var y0 = y0
  let dx = abs(x1 - x0); let dy = abs(y1 - y0)
  let sx = if x0 < x1: 1 else: -1
  let sy = if y0 < y1: 1 else: -1
  var err = dx - dy
  while true:
    display.drawPixel(x0, y0, on)
    if x0 == x1 and y0 == y1: break
    let e2 = 2 * err
    if e2 > -dy: err -= dy; x0 += sx
    if e2 < dx: err += dx; y0 += sy

proc drawRect*(display: var OledDisplay, x, y, w, h: int, on: bool = true) =
  for i in 0..<w:
    display.drawPixel(x + i, y, on)
    display.drawPixel(x + i, y + h - 1, on)
  for i in 0..<h:
    display.drawPixel(x, y + i, on)
    display.drawPixel(x + w - 1, y + i, on)

proc fillRect*(display: var OledDisplay, x, y, w, h: int, on: bool = true) =
  for j in 0..<h:
    for i in 0..<w:
      display.drawPixel(x + i, y + j, on)

proc drawCircle*(display: var OledDisplay, x0, y0, radius: int, on: bool = true) =
  var x = radius; var y = 0; var err = 0
  while x >= y:
    display.drawPixel(x0 + x, y0 + y, on)
    display.drawPixel(x0 + y, y0 + x, on)
    display.drawPixel(x0 - y, y0 + x, on)
    display.drawPixel(x0 - x, y0 + y, on)
    display.drawPixel(x0 - x, y0 - y, on)
    display.drawPixel(x0 - y, y0 - x, on)
    display.drawPixel(x0 + y, y0 - x, on)
    display.drawPixel(x0 + x, y0 - y, on)
    if err <= 0: inc y; err += 2 * y + 1
    if err > 0: dec x; err -= 2 * x + 1

const
  OLED_I2C_ADDRESS_DEFAULT* = 0x3C
  OLED_I2C_ADDRESS_ALT* = 0x3D
