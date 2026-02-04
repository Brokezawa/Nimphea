## SSD1327 Grayscale OLED Display driver for libDaisy Nim wrapper
##
## The SSD1327 is a 128x128 grayscale OLED controller with 16 gray levels (4-bit per pixel).
## Unlike monochrome displays, each pixel can display shades from black (0x0) to white (0xF).
##
## **Features:**
## - 128x128 resolution
## - 16 grayscale levels (4-bit per pixel)
## - SPI transport only (no I2C variant)
## - Compact framebuffer: 2 pixels per byte (8192 bytes total)
## - Compatible drawing API with other OLED drivers
##
## **Hardware Notes:**
## - Common in higher-end OLED modules
## - Buffer format: packed 4-bit pixels (upper nibble = even pixel, lower = odd pixel)
## - Default grayscale level: 0xF (white)
##
## Example - Basic usage:
## ```nim
## import nimphea
## import dev/oled_ssd1327
##
## var display = initSSD1327Spi(128, 128)
## display.fill(false)
## display.setGrayscale(0x8)  # Medium gray
## display.drawCircle(64, 64, 30, true)
## display.setGrayscale(0xF)  # White
## display.drawPixel(64, 64, true)
## display.update()
## ```
##
## Example - Grayscale gradient:
## ```nim
## # Draw gradient from black to white
## for x in 0..<128:
##   let gray = uint8(x div 8)  # 0-15
##   display.setGrayscale(gray)
##   display.drawLine(x, 0, x, 127, true)
## display.update()
## ```

import ../nimphea
import ../per/spi
import ../nimphea_macros

useNimpheaModules(spi, ssd1327)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # SPI transport configuration
  SSD1327SpiPinConfig* {.importcpp: "daisy::SSD13274WireSpiTransport::Config::pin_config", bycopy.} = object
    dc* {.importc: "dc".}: Pin
    reset* {.importc: "reset".}: Pin
  
  SSD13274WireSpiTransportConfig* {.importcpp: "daisy::SSD13274WireSpiTransport::Config", bycopy.} = object
    spi_config* {.importc: "spi_config".}: SpiConfig
    pin_config* {.importc: "pin_config".}: SSD1327SpiPinConfig
  
  # Pre-instantiated SSD1327 Display type from libDaisy
  # Using the short typedef defined in the macro system (SSD1327Spi128x128)
  SSD1327Spi128x128* {.importcpp: "SSD1327Spi128x128".} = object
  
  # Config struct
  SSD1327SpiConfig* {.importcpp: "SSD1327Spi128x128::Config", bycopy.} = object
    transport_config* {.importc: "transport_config".}: SSD13274WireSpiTransportConfig

{.pop.} # importcpp
{.pop.} # header

# Generic C++ member functions
proc Init[T, C](display: var T, config: C) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc Width[T](display: T): csize_t {.importcpp: "#.Width()", header: "daisy_seed.h".}
proc Height[T](display: T): csize_t {.importcpp: "#.Height()", header: "daisy_seed.h".}
proc DrawPixel[T](display: var T, x: uint8, y: uint8, on: bool) {.importcpp: "#.DrawPixel(@)", header: "daisy_seed.h".}
proc Fill[T](display: var T, on: bool) {.importcpp: "#.Fill(@)", header: "daisy_seed.h".}
proc Update[T](display: var T) {.importcpp: "#.Update()", header: "daisy_seed.h".}
proc Set_Color[T](display: var T, color: uint8) {.importcpp: "#.Set_Color(@)", header: "daisy_seed.h".}

# Constructors
proc cppNewSSD1327Spi(): SSD1327Spi128x128 {.importcpp: "SSD1327Spi128x128()", constructor, header: "daisy_seed.h".}
proc cppNewSSD1327SpiConfig(): SSD1327SpiConfig {.importcpp: "SSD1327Spi128x128::Config()", constructor, header: "daisy_seed.h".}

# Transport defaults
proc Defaults*(config: var SSD13274WireSpiTransportConfig) {.importcpp: "#.Defaults()", header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim API
# =============================================================================

template initSSD1327Spi*(width, height: static[int],
                         dcPin: Pin = newPin(PORTB, 4),
                         resetPin: Pin = newPin(PORTB, 15),
                         sclkPin: Pin = newPin(PORTG, 11),
                         mosiPin: Pin = newPin(PORTB, 5),
                         nssPin: Pin = newPin(PORTG, 10)): untyped =
  ## Initialize SSD1327 OLED via SPI
  ## 
  ## **Parameters:**
  ## - `width`, `height` - Display dimensions (only 128x128 supported)
  ## - `dcPin` - Data/Command pin (default: PB4)
  ## - `resetPin` - Reset pin (default: PB15)
  ## - `sclkPin` - SPI clock pin (default: PG11)
  ## - `mosiPin` - SPI MOSI pin (default: PB5)
  ## - `nssPin` - SPI chip select pin (default: PG10)
  ## 
  ## **Returns:** Initialized display instance
  ## 
  ## **Example:**
  ## ```nim
  ## var oled = initSSD1327Spi(128, 128)
  ## oled.setGrayscale(0xF)  # White
  ## oled.fill(false)
  ## oled.update()
  ## ```
  when (width, height) == (128, 128):
    block:
      var result = cppNewSSD1327Spi()
      var config = cppNewSSD1327SpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  else:
    {.error: "SSD1327 only supports 128x128 resolution".}

# Generic procs work on SSD1327 display
proc width*(display: SSD1327Spi128x128): int {.inline.} = 
  ## Get display width in pixels (always 128)
  display.Width().int

proc height*(display: SSD1327Spi128x128): int {.inline.} = 
  ## Get display height in pixels (always 128)
  display.Height().int

proc drawPixel*(display: var SSD1327Spi128x128, x, y: int, on: bool = true) = 
  ## Draw a single pixel with current grayscale level
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Pixel coordinates (0-based)
  ## - `on` - true to draw with current grayscale, false for black
  ## 
  ## **Note:** Use `setGrayscale()` to change the drawing color before calling this.
  display.DrawPixel(x.uint8, y.uint8, on)

proc fill*(display: var SSD1327Spi128x128, on: bool = true) = 
  ## Fill entire display with a color
  ## 
  ## **Parameters:**
  ## - `on` - true for white (0xF), false for black (0x0)
  display.Fill(on)

proc update*(display: var SSD1327Spi128x128) = 
  ## Send framebuffer to display hardware
  ## Call this after drawing to make changes visible
  display.Update()

proc setGrayscale*(display: var SSD1327Spi128x128, level: uint8) =
  ## Set the current grayscale drawing level
  ## 
  ## **Parameters:**
  ## - `level` - Grayscale value 0x0 (black) to 0xF (white)
  ## 
  ## **Example:**
  ## ```nim
  ## display.setGrayscale(0x0)  # Black
  ## display.drawCircle(32, 32, 10, true)
  ## display.setGrayscale(0x8)  # Medium gray
  ## display.drawCircle(64, 64, 10, true)
  ## display.setGrayscale(0xF)  # White
  ## display.drawCircle(96, 96, 10, true)
  ## ```
  display.Set_Color(level and 0x0F)

# Drawing helpers - same algorithms as monochrome displays
proc drawLine*(display: var SSD1327Spi128x128, x0, y0, x1, y1: int, on: bool = true) =
  ## Draw a line using Bresenham's algorithm
  ## 
  ## **Parameters:**
  ## - `x0`, `y0` - Start point
  ## - `x1`, `y1` - End point
  ## - `on` - true to draw with current grayscale, false for black
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

proc drawRect*(display: var SSD1327Spi128x128, x, y, w, h: int, on: bool = true) =
  ## Draw a rectangle outline
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Top-left corner
  ## - `w`, `h` - Width and height
  ## - `on` - true to draw with current grayscale, false for black
  for i in 0..<w:
    display.drawPixel(x + i, y, on)
    display.drawPixel(x + i, y + h - 1, on)
  for i in 0..<h:
    display.drawPixel(x, y + i, on)
    display.drawPixel(x + w - 1, y + i, on)

proc fillRect*(display: var SSD1327Spi128x128, x, y, w, h: int, on: bool = true) =
  ## Draw a filled rectangle
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Top-left corner
  ## - `w`, `h` - Width and height
  ## - `on` - true to draw with current grayscale, false for black
  for j in 0..<h:
    for i in 0..<w:
      display.drawPixel(x + i, y + j, on)

proc drawCircle*(display: var SSD1327Spi128x128, x0, y0, radius: int, on: bool = true) =
  ## Draw a circle outline using midpoint circle algorithm
  ## 
  ## **Parameters:**
  ## - `x0`, `y0` - Center point
  ## - `radius` - Circle radius in pixels
  ## - `on` - true to draw with current grayscale, false for black
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

# Grayscale level constants
const
  GRAYSCALE_BLACK* = 0x0'u8
    ## Black (minimum brightness)
  GRAYSCALE_DARK* = 0x4'u8
    ## Dark gray (25% brightness)
  GRAYSCALE_MEDIUM* = 0x8'u8
    ## Medium gray (50% brightness)
  GRAYSCALE_LIGHT* = 0xC'u8
    ## Light gray (75% brightness)
  GRAYSCALE_WHITE* = 0xF'u8
    ## White (maximum brightness)
