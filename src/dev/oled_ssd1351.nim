## SSD1351 RGB Color OLED Display driver for libDaisy Nim wrapper
##
## The SSD1351 is a 128x128 full-color OLED controller with 65K colors (RGB565 format).
## Each pixel can display any of 65,536 colors using 16-bit color depth.
##
## **Features:**
## - 128x128 resolution
## - 65K colors (RGB565: 5-bit red, 6-bit green, 5-bit blue)
## - SPI transport only (no I2C variant)
## - Large framebuffer: 2 bytes per pixel (32,768 bytes total)
## - Separate foreground and background colors
## - Compatible drawing API with other OLED drivers
##
## **Hardware Notes:**
## - Premium OLED modules (higher cost than monochrome)
## - RGB565 format: RRRRRGGGGGGBBBBBbit packed into uint16
## - Default colors: white foreground, black background
##
## Example - Basic usage:
## ```nim
## import nimphea
## import dev/oled_ssd1351
##
## var display = initSSD1351Spi(128, 128)
## display.fill(false)  # Clear to black
## display.setColorRGB(31, 0, 0)  # Red (max R, no G/B)
## display.drawCircle(64, 64, 30, true)
## display.setColorRGB(0, 63, 0)  # Green (max G)
## display.drawRect(30, 30, 68, 68, true)
## display.update()
## ```
##
## Example - Using color constants:
## ```nim
## display.setColor(COLOR_RED)
## display.drawLine(0, 0, 127, 127, true)
## display.setColor(COLOR_BLUE)
## display.drawLine(0, 127, 127, 0, true)
## display.update()
## ```

import ../nimphea
import ../per/spi
import ../nimphea_macros

useNimpheaModules(spi, ssd1351)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # SPI transport configuration
  SSD1351SpiPinConfig* {.importcpp: "daisy::SSD13514WireSpiTransport::Config::pin_config", bycopy.} = object
    dc* {.importc: "dc".}: Pin
    reset* {.importc: "reset".}: Pin
  
  SSD13514WireSpiTransportConfig* {.importcpp: "daisy::SSD13514WireSpiTransport::Config", bycopy.} = object
    spi_config* {.importc: "spi_config".}: SpiConfig
    pin_config* {.importc: "pin_config".}: SSD1351SpiPinConfig
  
  # Pre-instantiated SSD1351 Display type from libDaisy
  # Using the short typedef defined in the macro system (SSD1351Spi128x128)
  SSD1351Spi128x128* {.importcpp: "SSD1351Spi128x128".} = object
  
  # Config struct
  SSD1351SpiConfig* {.importcpp: "SSD1351Spi128x128::Config", bycopy.} = object
    transport_config* {.importc: "transport_config".}: SSD13514WireSpiTransportConfig

{.pop.} # importcpp
{.pop.} # header

# Generic C++ member functions
proc Init[T, C](display: var T, config: C) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc Width[T](display: T): csize_t {.importcpp: "#.Width()", header: "daisy_seed.h".}
proc Height[T](display: T): csize_t {.importcpp: "#.Height()", header: "daisy_seed.h".}
proc DrawPixel[T](display: var T, x: uint8, y: uint8, on: bool) {.importcpp: "#.DrawPixel(@)", header: "daisy_seed.h".}
proc Fill[T](display: var T, on: bool) {.importcpp: "#.Fill(@)", header: "daisy_seed.h".}
proc Update[T](display: var T) {.importcpp: "#.Update()", header: "daisy_seed.h".}
proc SetColorFG[T](display: var T, red, green, blue: uint8) {.importcpp: "#.SetColorFG(@)", header: "daisy_seed.h".}
proc SetColorBG[T](display: var T, red, green, blue: uint8) {.importcpp: "#.SetColorBG(@)", header: "daisy_seed.h".}

# Constructors
proc cppNewSSD1351Spi(): SSD1351Spi128x128 {.importcpp: "SSD1351Spi128x128()", constructor, header: "daisy_seed.h".}
proc cppNewSSD1351SpiConfig(): SSD1351SpiConfig {.importcpp: "SSD1351Spi128x128::Config()", constructor, header: "daisy_seed.h".}

# Transport defaults
proc Defaults*(config: var SSD13514WireSpiTransportConfig) {.importcpp: "#.Defaults()", header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim API
# =============================================================================

template initSSD1351Spi*(width, height: static[int],
                         dcPin: Pin = newPin(PORTB, 4),
                         resetPin: Pin = newPin(PORTB, 15),
                         sclkPin: Pin = newPin(PORTG, 11),
                         mosiPin: Pin = newPin(PORTB, 5),
                         nssPin: Pin = newPin(PORTG, 10)): untyped =
  ## Initialize SSD1351 color OLED via SPI
  ## 
  ## **Parameters:**
  ## - `width`, `height` - Display dimensions (only 128x128 supported)
  ## - `dcPin` - Data/Command pin (default: PB4)
  ## - `resetPin` - Reset pin (default: PB15)
  ## - `sclkPin` - SPI clock pin (default: PG11)
  ## - `mosiPin` - SPI MOSI pin (default: PB5)
  ## - `nssPin` - SPI chip select pin (default: PG10)
  ## 
  ## **Returns:** Initialized display instance with white FG, black BG
  ## 
  ## **Example:**
  ## ```nim
  ## var oled = initSSD1351Spi(128, 128)
  ## oled.setColorRGB(31, 0, 0)  # Red
  ## oled.fill(false)
  ## oled.update()
  ## ```
  when (width, height) == (128, 128):
    block:
      var result = cppNewSSD1351Spi()
      var config = cppNewSSD1351SpiConfig()
      config.transport_config.Defaults()
      config.transport_config.pin_config.dc = dcPin
      config.transport_config.pin_config.reset = resetPin
      config.transport_config.spi_config.pin_config.sclk = sclkPin
      config.transport_config.spi_config.pin_config.mosi = mosiPin
      config.transport_config.spi_config.pin_config.nss = nssPin
      result.Init(config)
      result
  else:
    {.error: "SSD1351 only supports 128x128 resolution".}

# Generic procs work on SSD1351 display
proc width*(display: SSD1351Spi128x128): int {.inline.} = 
  ## Get display width in pixels (always 128)
  display.Width().int

proc height*(display: SSD1351Spi128x128): int {.inline.} = 
  ## Get display height in pixels (always 128)
  display.Height().int

proc drawPixel*(display: var SSD1351Spi128x128, x, y: int, on: bool = true) = 
  ## Draw a single pixel with current foreground/background color
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Pixel coordinates (0-based)
  ## - `on` - true for foreground color, false for background color
  ## 
  ## **Note:** Use `setColorRGB()` or `setColor()` to change colors before calling this.
  display.DrawPixel(x.uint8, y.uint8, on)

proc fill*(display: var SSD1351Spi128x128, on: bool = true) = 
  ## Fill entire display with a color
  ## 
  ## **Parameters:**
  ## - `on` - true for foreground color, false for background color
  display.Fill(on)

proc update*(display: var SSD1351Spi128x128) = 
  ## Send framebuffer to display hardware
  ## Call this after drawing to make changes visible
  ## 
  ## **Note:** Transfers 32KB over SPI, takes ~50ms at default speed
  display.Update()

proc setColorRGB*(display: var SSD1351Spi128x128, red, green, blue: uint8) =
  ## Set the current foreground color using RGB values
  ## 
  ## **Parameters:**
  ## - `red` - Red component (0-31, 5-bit)
  ## - `green` - Green component (0-63, 6-bit)
  ## - `blue` - Blue component (0-31, 5-bit)
  ## 
  ## **Note:** RGB565 format has 6 bits for green (human eye sensitivity)
  ## 
  ## **Example:**
  ## ```nim
  ## display.setColorRGB(31, 0, 0)   # Pure red
  ## display.setColorRGB(0, 63, 0)   # Pure green (note: 63, not 31)
  ## display.setColorRGB(0, 0, 31)   # Pure blue
  ## display.setColorRGB(31, 63, 31) # White
  ## display.setColorRGB(15, 31, 15) # Medium gray
  ## ```
  display.SetColorFG(red and 0x1F, green and 0x3F, blue and 0x1F)

proc setBackgroundRGB*(display: var SSD1351Spi128x128, red, green, blue: uint8) =
  ## Set the current background color using RGB values
  ## 
  ## **Parameters:**
  ## - `red` - Red component (0-31, 5-bit)
  ## - `green` - Green component (0-63, 6-bit)
  ## - `blue` - Blue component (0-31, 5-bit)
  display.SetColorBG(red and 0x1F, green and 0x3F, blue and 0x1F)

proc setColor*(display: var SSD1351Spi128x128, color: uint16) =
  ## Set foreground color using RGB565 value
  ## 
  ## **Parameters:**
  ## - `color` - RGB565 color (use COLOR_* constants)
  ## 
  ## **Example:**
  ## ```nim
  ## display.setColor(COLOR_RED)
  ## display.setColor(COLOR_CYAN)
  ## display.setColor(0xF800)  # Raw RGB565 value
  ## ```
  let r = uint8((color shr 11) and 0x1F)
  let g = uint8((color shr 5) and 0x3F)
  let b = uint8(color and 0x1F)
  display.SetColorFG(r, g, b)

proc setBackground*(display: var SSD1351Spi128x128, color: uint16) =
  ## Set background color using RGB565 value
  let r = uint8((color shr 11) and 0x1F)
  let g = uint8((color shr 5) and 0x3F)
  let b = uint8(color and 0x1F)
  display.SetColorBG(r, g, b)

# Drawing helpers - same algorithms as other displays
proc drawLine*(display: var SSD1351Spi128x128, x0, y0, x1, y1: int, on: bool = true) =
  ## Draw a line using Bresenham's algorithm
  ## 
  ## **Parameters:**
  ## - `x0`, `y0` - Start point
  ## - `x1`, `y1` - End point
  ## - `on` - true for foreground color, false for background color
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

proc drawRect*(display: var SSD1351Spi128x128, x, y, w, h: int, on: bool = true) =
  ## Draw a rectangle outline
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Top-left corner
  ## - `w`, `h` - Width and height
  ## - `on` - true for foreground color, false for background color
  for i in 0..<w:
    display.drawPixel(x + i, y, on)
    display.drawPixel(x + i, y + h - 1, on)
  for i in 0..<h:
    display.drawPixel(x, y + i, on)
    display.drawPixel(x + w - 1, y + i, on)

proc fillRect*(display: var SSD1351Spi128x128, x, y, w, h: int, on: bool = true) =
  ## Draw a filled rectangle
  ## 
  ## **Parameters:**
  ## - `x`, `y` - Top-left corner
  ## - `w`, `h` - Width and height
  ## - `on` - true for foreground color, false for background color
  for j in 0..<h:
    for i in 0..<w:
      display.drawPixel(x + i, y + j, on)

proc drawCircle*(display: var SSD1351Spi128x128, x0, y0, radius: int, on: bool = true) =
  ## Draw a circle outline using midpoint circle algorithm
  ## 
  ## **Parameters:**
  ## - `x0`, `y0` - Center point
  ## - `radius` - Circle radius in pixels
  ## - `on` - true for foreground color, false for background color
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

# RGB565 color helper function
proc rgb565*(red, green, blue: uint8): uint16 {.inline.} =
  ## Convert RGB values to RGB565 format
  ## 
  ## **Parameters:**
  ## - `red` - Red component (0-31, 5-bit)
  ## - `green` - Green component (0-63, 6-bit)
  ## - `blue` - Blue component (0-31, 5-bit)
  ## 
  ## **Returns:** RGB565 packed uint16
  ## 
  ## **Example:**
  ## ```nim
  ## let purple = rgb565(16, 0, 16)  # Medium purple
  ## display.setColor(purple)
  ## ```
  ((red.uint16 and 0x1F) shl 11) or ((green.uint16 and 0x3F) shl 5) or (blue.uint16 and 0x1F)

# Common color constants (RGB565 format)
const
  COLOR_BLACK* = 0x0000'u16
    ## Black (R=0, G=0, B=0)
  COLOR_WHITE* = 0xFFFF'u16
    ## White (R=31, G=63, B=31)
  COLOR_RED* = 0xF800'u16
    ## Pure red (R=31, G=0, B=0)
  COLOR_GREEN* = 0x07E0'u16
    ## Pure green (R=0, G=63, B=0)
  COLOR_BLUE* = 0x001F'u16
    ## Pure blue (R=0, G=0, B=31)
  COLOR_CYAN* = 0x07FF'u16
    ## Cyan (green + blue)
  COLOR_MAGENTA* = 0xF81F'u16
    ## Magenta (red + blue)
  COLOR_YELLOW* = 0xFFE0'u16
    ## Yellow (red + green)
  COLOR_ORANGE* = 0xFC00'u16
    ## Orange (R=31, G=32, B=0)
  COLOR_PURPLE* = 0x8010'u16
    ## Purple (R=16, G=0, B=16)
  COLOR_GRAY* = 0x7BEF'u16
    ## Medium gray (R=15, G=31, B=15)
