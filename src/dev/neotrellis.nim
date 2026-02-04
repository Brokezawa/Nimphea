## NeoTrellis 4x4 RGB Button Pad Module
## ======================================
##
## Nim wrapper for the Adafruit NeoTrellis 4x4 RGB keypad.
##
## The NeoTrellis is a 4x4 grid of elastomer buttons with individually addressable
## RGB NeoPixel LEDs underneath. It combines capacitive touch sensing with vibrant
## RGB lighting, perfect for creating custom controllers and MIDI interfaces.
##
## **Features:**
## - 16 elastomer buttons (4x4 grid) with capacitive touch sensing
## - 16 individually addressable RGB NeoPixels
## - Key event detection (press/release with rising/falling edge)
## - Callback support for key events
## - I2C interface only
## - Based on Seesaw firmware
##
## **Example:**
## ```nim
## import nimphea
## import dev/neotrellis
##
## var trellis: NeoTrellisI2C
## var config: NeoTrellisConfig
## 
## # Configure I2C transport
## config.transport_config.address = NEO_TRELLIS_ADDR
## config.transport_config.periph = I2C_PERIPH_1
## config.transport_config.speed = I2C_400KHZ
## config.transport_config.scl = seed.GetPin(11)  # PB8
## config.transport_config.sda = seed.GetPin(12)  # PB9
##
## if trellis.init(config) == NEOTRELLIS_OK:
##   # Activate all keys to detect rising and falling edges
##   for x in 0..3:
##     for y in 0..3:
##       trellis.activateKey(x, y, RISING, true)
##       trellis.activateKey(x, y, FALLING, true)
##   
##   while true:
##     trellis.process()  # Read events and update state
##     
##     for i in 0..15:
##       if trellis.getRising(i):
##         # Button i was just pressed
##         trellis.pixels.setPixelColor(i, 255, 0, 0)  # Red
##       if trellis.getFalling(i):
##         # Button i was just released
##         trellis.pixels.setPixelColor(i, 0, 0, 0)    # Off
##     
##     trellis.pixels.show()
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(neotrellis)

{.push header: "dev/neotrellis.h".}

# Constants
const
  NEO_TRELLIS_ADDR* = 0x2E'u8         ## Default I2C address
  NEO_TRELLIS_NUM_ROWS* = 4'i32       ## Number of rows
  NEO_TRELLIS_NUM_COLS* = 4'i32       ## Number of columns
  NEO_TRELLIS_NUM_KEYS* = 16'i32      ## Total number of keys (4x4)

# Enums

type
  NeoTrellisKeypadEdge* {.importcpp: "daisy::NeoTrellis<daisy::NeoTrellisI2CTransport>::KeypadEdge", size: sizeof(cint).} = enum
    ## Key event edge types
    NEO_TRELLIS_HIGH = 0    ## Key is currently high
    NEO_TRELLIS_LOW = 1     ## Key is currently low
    NEO_TRELLIS_FALLING = 2 ## Falling edge (key released)
    NEO_TRELLIS_RISING = 3  ## Rising edge (key pressed)

type
  NeoTrellisResult* {.importcpp: "daisy::NeoTrellis<daisy::NeoTrellisI2CTransport>::Result", size: sizeof(cint).} = enum
    ## Operation result
    NEOTRELLIS_OK  = 0  ## Success
    NEOTRELLIS_ERR = 1  ## Error

# I2C Transport Types

type
  NeoTrellisI2CTransportConfig* {.importcpp: "daisy::NeoTrellisI2CTransport::Config", bycopy.} = object
    ## I2C transport configuration
    periph* {.importcpp: "periph".}: I2CPeripheral
    speed* {.importcpp: "speed".}: I2CSpeed
    scl* {.importcpp: "scl".}: Pin
    sda* {.importcpp: "sda".}: Pin
    address* {.importcpp: "address".}: uint8

type
  NeoTrellisI2CTransport* {.importcpp: "daisy::NeoTrellisI2CTransport", bycopy.} = object
    ## I2C transport for NeoTrellis

# Forward declaration for NeoPixelI2C
type
  NeoPixelI2CConfig* {.importcpp: "daisy::NeoPixelI2C::Config", bycopy.} = object
    ## NeoPixel I2C configuration (from dev/neopixel.h)

type
  NeoPixelI2C* {.importcpp: "daisy::NeoPixelI2C", bycopy.} = object
    ## NeoPixel I2C controller (from dev/neopixel.h)

# Event Types

type
  KeyEvent* {.importcpp: "daisy::NeoTrellis<daisy::NeoTrellisI2CTransport>::keyEvent", bycopy.} = object
    ## Key event structure
    reg* {.importcpp: "reg".}: uint16

type
  TrellisCallback* = proc(evt: KeyEvent) {.cdecl.}
    ## Callback function type for key events

# Device Types

type
  NeoTrellisConfig* {.importcpp: "daisy::NeoTrellisI2C::Config", bycopy.} = object
    ## NeoTrellis device configuration
    transport_config* {.importcpp: "transport_config".}: NeoTrellisI2CTransportConfig
    pixels_conf* {.importcpp: "pixels_conf".}: NeoPixelI2CConfig

type
  NeoTrellisI2C* {.importcpp: "daisy::NeoTrellisI2C", bycopy.} = object
    ## NeoTrellis device with I2C transport
    pixels* {.importcpp: "pixels".}: NeoPixelI2C

{.pop.}

# Constructors

proc initNeoTrellisI2CTransportConfig*(): NeoTrellisI2CTransportConfig {.constructor,
    importcpp: "daisy::NeoTrellisI2CTransport::Config(@)", header: "dev/neotrellis.h".}
  ## Initialize I2C transport config with defaults

proc initNeoTrellisConfig*(): NeoTrellisConfig {.constructor,
    importcpp: "daisy::NeoTrellisI2C::Config(@)", header: "dev/neotrellis.h".}
  ## Initialize device config with defaults

# Methods

proc init*(this: var NeoTrellisI2C, config: NeoTrellisConfig): NeoTrellisResult 
  {.importcpp: "#.Init(#)", header: "dev/neotrellis.h".}
  ## Initialize the NeoTrellis device
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with transport settings
  ## 
  ## **Returns:** NEOTRELLIS_OK on success, NEOTRELLIS_ERR on failure

proc swReset*(this: var NeoTrellisI2C) 
  {.importcpp: "#.SWReset()", header: "dev/neotrellis.h".}
  ## Perform a software reset
  ##
  ## Resets all Seesaw registers to default values.

proc activateKey*(this: var NeoTrellisI2C, x: uint8, y: uint8, edge: uint8, enable: bool) 
  {.importcpp: "#.ActivateKey(#, #, #, #)", header: "dev/neotrellis.h".}
  ## Activate or deactivate a key event
  ##
  ## **Parameters:**
  ## - `x` - Column index (0-3, 0 is leftmost)
  ## - `y` - Row index (0-3, 0 is topmost)
  ## - `edge` - Edge sensitivity (NEO_TRELLIS_RISING, NEO_TRELLIS_FALLING, etc.)
  ## - `enable` - true to enable event, false to disable

proc process*(this: var NeoTrellisI2C, polling: bool = true) 
  {.importcpp: "#.Process(#)", header: "dev/neotrellis.h".}
  ## Read all events from the FIFO and update state
  ##
  ## Call this regularly to process key events and update rising/falling states.
  ##
  ## **Parameters:**
  ## - `polling` - true if not using interrupt pin, false if using interrupt (default: true)

proc getState*(this: var NeoTrellisI2C, idx: uint8): bool 
  {.importcpp: "#.GetState(#)", header: "dev/neotrellis.h".}
  ## Check if a key is currently pressed
  ##
  ## Updated by process() function.
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##
  ## **Returns:** true if pressed, false if released

proc getRising*(this: var NeoTrellisI2C, idx: uint8): bool 
  {.importcpp: "#.GetRising(#)", header: "dev/neotrellis.h".}
  ## Check if a key was just pressed (rising edge)
  ##
  ## Clears the rising flag after reading. Updated by process() function.
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##
  ## **Returns:** true if just pressed

proc getFalling*(this: var NeoTrellisI2C, idx: uint8): bool 
  {.importcpp: "#.GetFalling(#)", header: "dev/neotrellis.h".}
  ## Check if a key was just released (falling edge)
  ##
  ## Clears the falling flag after reading. Updated by process() function.
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##
  ## **Returns:** true if just released

proc getKeypadCount*(this: var NeoTrellisI2C): uint8 
  {.importcpp: "#.GetKeypadCount()", header: "dev/neotrellis.h".}
  ## Get the number of events in the FIFO
  ##
  ## **Returns:** Number of events waiting to be read

proc setKeypadEvent*(this: var NeoTrellisI2C, key: uint8, edge: uint8, enable: bool) 
  {.importcpp: "#.SetKeypadEvent(#, #, #)", header: "dev/neotrellis.h".}
  ## Activate or deactivate a key event by key number
  ##
  ## **Parameters:**
  ## - `key` - Key number (0-15)
  ## - `edge` - Edge sensitivity
  ## - `enable` - true to enable, false to disable

proc enableKeypadInterrupt*(this: var NeoTrellisI2C) 
  {.importcpp: "#.EnableKeypadInterrupt()", header: "dev/neotrellis.h".}
  ## Enable keypad interrupt
  ##
  ## Enables the interrupt that fires when events are in the FIFO.

proc registerCallback*(this: var NeoTrellisI2C, x: uint8, y: uint8, cb: TrellisCallback) 
  {.importcpp: "#.RegisterCallback(#, #, #)", header: "dev/neotrellis.h".}
  ## Register a callback for a key
  ##
  ## **Parameters:**
  ## - `x` - Column index (0-3)
  ## - `y` - Row index (0-3)
  ## - `cb` - Callback function to call when event detected

proc unregisterCallback*(this: var NeoTrellisI2C, x: uint8, y: uint8) 
  {.importcpp: "#.UnregisterCallback(#, #)", header: "dev/neotrellis.h".}
  ## Unregister a callback for a key
  ##
  ## **Parameters:**
  ## - `x` - Column index (0-3)
  ## - `y` - Row index (0-3)

proc write8*(this: var NeoTrellisI2C, reg_high: uint8, reg_low: uint8, value: uint8) 
  {.importcpp: "#.Write8(#, #, #)", header: "dev/neotrellis.h".}
  ## Write an 8-bit value to a register
  ##
  ## **Parameters:**
  ## - `reg_high` - High byte of register address
  ## - `reg_low` - Low byte of register address
  ## - `value` - Value to write

proc read8*(this: var NeoTrellisI2C, reg_high: uint8, reg_low: uint8, delay: cint): uint8 
  {.importcpp: "#.Read8(#, #, #)", header: "dev/neotrellis.h".}
  ## Read an 8-bit value from a register
  ##
  ## **Parameters:**
  ## - `reg_high` - High byte of register address
  ## - `reg_low` - Low byte of register address
  ## - `delay` - Delay in microseconds before reading
  ##
  ## **Returns:** 8-bit register value

proc getTransportError*(this: var NeoTrellisI2C): NeoTrellisResult 
  {.importcpp: "#.GetTransportError()", header: "dev/neotrellis.h".}
  ## Get and reset the transport error flag
  ##
  ## **Returns:** NEOTRELLIS_ERR if error occurred, NEOTRELLIS_OK otherwise

# NeoPixel I2C methods (accessed via trellis.pixels)
# Note: Full NeoPixel API would be in a separate neopixel.nim wrapper

proc setPixelColor*(this: var NeoPixelI2C, pixel: uint16, r: uint8, g: uint8, b: uint8) 
  {.importcpp: "#.SetPixelColor(#, #, #, #)", header: "dev/neopixel.h".}
  ## Set a pixel's RGB color
  ##
  ## **Parameters:**
  ## - `pixel` - Pixel index (0-15 for NeoTrellis)
  ## - `r` - Red value (0-255)
  ## - `g` - Green value (0-255)
  ## - `b` - Blue value (0-255)

proc show*(this: var NeoPixelI2C) 
  {.importcpp: "#.Show()", header: "dev/neopixel.h".}
  ## Update all pixels with buffered color values
  ##
  ## Must be called after setPixelColor() to actually display the colors.

proc clear*(this: var NeoPixelI2C) 
  {.importcpp: "#.Clear()", header: "dev/neopixel.h".}
  ## Clear all pixels (set to off/black)
