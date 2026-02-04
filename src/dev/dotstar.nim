## DotStar RGB LED Module - APA102/SK9822 Addressable RGB LEDs
##
## This module provides support for DotStar (APA102/SK9822) addressable RGB LED strips via SPI.
## DotStars offer advantages over NeoPixels: higher refresh rates, no timing-critical protocol,
## and per-pixel global brightness control.
##
## Features:
## - Up to 64 pixels per strip (configurable)
## - 24-bit RGB color + 5-bit global brightness per pixel
## - Configurable color channel ordering (RGB, GRB, BRG, etc.)
## - SPI-based communication (no timing constraints)
## - High refresh rate capability
##
## Example:
## ```nim
## import panicoverride
## import nimphea
## import ../per/spi
## import dev/dotstar
##
## var config: DotStarConfig
## config.transport_config.periph = SPI_1
## config.transport_config.baud_prescaler = SPI_PS_4
## config.transport_config.clk_pin = D10()
## config.transport_config.data_pin = D9()
## config.color_order = RGB
## config.num_pixels = 16
##
## var leds: DotStarSpi
## if leds.init(config) == DS_OK:
##   leds.setPixelColor(0, 255, 0, 0)  # Red
##   leds.fill(0, 255, 0)  # Green on all pixels
##   leds.show()  # Update the strip
## ```

import ../nimphea
import ../nimphea_macros
import ../per/spi
import ../nimphea_color

useNimpheaModules(dotstar, spi)

type
  DotStarResult* = enum
    DS_OK = 0
    DS_ERR_INVALID_ARGUMENT
    DS_ERR_TRANSPORT

  ColorOrder* = enum
    ## Pixel color channel ordering
    ## Format encodes R/G/B offsets in 4/2/0 bit positions
    RGB = 0b00_01_10  # R=0, G=1, B=2
    RBG = 0b00_10_01  # R=0, B=1, G=2
    GRB = 0b01_00_10  # G=0, R=1, B=2
    GBR = 0b10_00_01  # G=0, B=1, R=2
    BRG = 0b01_10_00  # B=0, R=1, G=2
    BGR = 0b10_01_00  # B=0, G=1, R=2

  DotStarSpiTransportConfig* = object
    periph*: SpiPeripheral
    baud_prescaler*: SpiBaudPrescaler
    clk_pin*: Pin
    data_pin*: Pin

  DotStarConfig* = object
    transport_config*: DotStarSpiTransportConfig
    color_order*: ColorOrder
    num_pixels*: uint16  ## Number of pixels (max 64)

  DotStarSpi* = object
    spi: SpiHandle
    numPixels: uint16
    pixels: array[64, uint32]  ## 32-bit per pixel (brightness + RGB)
    rOffset, gOffset, bOffset: uint8

const MAX_NUM_PIXELS = 64

proc defaults*(config: var DotStarSpiTransportConfig) =
  config.periph = SPI_1
  config.baud_prescaler = SPI_PS_4
  config.clk_pin = newPin(PORTG, 11)
  config.data_pin = newPin(PORTB, 5)

proc defaults*(config: var DotStarConfig) =
  config.transport_config.defaults()
  config.color_order = RGB
  config.num_pixels = 1

proc init*(dotstar: var DotStarSpi, config: DotStarConfig): DotStarResult =
  ## Initialize DotStar strip
  if config.num_pixels > MAX_NUM_PIXELS:
    return DS_ERR_INVALID_ARGUMENT
  
  # Init SPI transport
  dotstar.spi = initSPI(
    config.transport_config.periph,
    config.transport_config.clk_pin,
    newPin(PORTA, 0),  # MISO not used
    config.transport_config.data_pin,
    newPin(PORTA, 0),  # NSS not used
    config.transport_config.baud_prescaler,
    0  # SPI mode 0
  )
  
  dotstar.numPixels = config.num_pixels
  
  # Decode color order (first color byte is always global brightness)
  dotstar.rOffset = ((config.color_order.uint8 shr 4) and 0b11) + 1
  dotstar.gOffset = ((config.color_order.uint8 shr 2) and 0b11) + 1
  dotstar.bOffset = (config.color_order.uint8 and 0b11) + 1
  
  # Initialize pixels (note: setAllGlobalBrightness and clear should be called after init)
  for i in 0 ..< MAX_NUM_PIXELS:
    dotstar.pixels[i] = 0xE0000001'u32  # Min brightness, black
  
  return DS_OK

proc setPixelGlobalBrightness*(dotstar: var DotStarSpi, idx: uint16, brightness: uint16): DotStarResult =
  ## Set global brightness for a single pixel (0-31)
  ## WARNING: Keep brightness low (<=10) especially for SK9822-EC20 to avoid overheating
  if idx >= dotstar.numPixels:
    return DS_ERR_INVALID_ARGUMENT
  
  var pixel = cast[ptr array[4, uint8]](addr dotstar.pixels[idx])
  pixel[0] = 0xE0'u8 or min(brightness, 31'u16).uint8
  return DS_OK

proc setAllGlobalBrightness*(dotstar: var DotStarSpi, brightness: uint16) =
  ## Set global brightness for all pixels (0-31)
  for i in 0'u16 ..< dotstar.numPixels:
    discard dotstar.setPixelGlobalBrightness(i, brightness)

proc getPixelColor*(dotstar: DotStarSpi, idx: uint16): uint32 =
  ## Get color of a pixel as 24-bit RGB value
  if idx >= dotstar.numPixels:
    return 0
  
  let pixel = cast[ptr array[4, uint8]](unsafeAddr dotstar.pixels[idx])
  result = (pixel[dotstar.rOffset].uint32 shl 16) or
           (pixel[dotstar.gOffset].uint32 shl 8) or
            pixel[dotstar.bOffset].uint32

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, r, g, b: uint8): DotStarResult =
  ## Set pixel color with 8-bit RGB values
  if idx >= dotstar.numPixels:
    return DS_ERR_INVALID_ARGUMENT
  
  var pixel = cast[ptr array[4, uint8]](addr dotstar.pixels[idx])
  pixel[dotstar.rOffset] = r
  pixel[dotstar.gOffset] = g
  pixel[dotstar.bOffset] = b
  return DS_OK

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, color: uint32): DotStarResult =
  ## Set pixel color with 32-bit RGB value (MSB ignored)
  let
    r = ((color shr 16) and 0xFF).uint8
    g = ((color shr 8) and 0xFF).uint8
    b = (color and 0xFF).uint8
  return dotstar.setPixelColor(idx, r, g, b)

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, color: Color): DotStarResult =
  ## Set pixel color with Color object
  return dotstar.setPixelColor(idx, color.red8(), color.green8(), color.blue8())

proc fill*(dotstar: var DotStarSpi, r, g, b: uint8) =
  ## Fill all pixels with RGB color
  for i in 0'u16 ..< dotstar.numPixels:
    discard dotstar.setPixelColor(i, r, g, b)

proc fill*(dotstar: var DotStarSpi, color: uint32) =
  ## Fill all pixels with 32-bit color
  for i in 0'u16 ..< dotstar.numPixels:
    discard dotstar.setPixelColor(i, color)

proc fill*(dotstar: var DotStarSpi, color: Color) =
  ## Fill all pixels with Color object
  for i in 0'u16 ..< dotstar.numPixels:
    discard dotstar.setPixelColor(i, color)

proc clear*(dotstar: var DotStarSpi) =
  ## Clear all pixels (set to black)
  ## Does not reset global brightness
  for i in 0'u16 ..< dotstar.numPixels:
    discard dotstar.setPixelColor(i, 0'u32)

proc show*(dotstar: var DotStarSpi): DotStarResult =
  ## Write pixel data to LED strip
  var 
    startFrame: array[4, uint8] = [0'u8, 0, 0, 0]
    endFrame: array[4, uint8] = [0xFF'u8, 0xFF, 0xFF, 0xFF]
  
  # Send start frame
  if dotstar.spi.BlockingTransmit(addr startFrame[0], 4) != SPI_OK:
    return DS_ERR_TRANSPORT
  
  # Send pixel data
  for i in 0'u16 ..< dotstar.numPixels:
    if dotstar.spi.BlockingTransmit(cast[ptr uint8](addr dotstar.pixels[i]), 4) != SPI_OK:
      return DS_ERR_TRANSPORT
  
  # Send end frame
  if dotstar.spi.BlockingTransmit(addr endFrame[0], 4) != SPI_OK:
    return DS_ERR_TRANSPORT
  
  return DS_OK
