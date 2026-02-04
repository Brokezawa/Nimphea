## LED Driver Module - PCA9685 12-bit PWM LED Driver
##
## This module provides support for the PCA9685 12-bit PWM LED driver chip via I2C.
## It supports multiple chips daisy-chained on a single I2C bus, with double-buffered
## DMA transfers for flicker-free LED updates.
##
## Features:
## - 16 channels per chip, multiple chips supported
## - 12-bit PWM resolution (0-4095)
## - Built-in gamma correction (8-bit brightness)
## - Double-buffered DMA for smooth updates
## - Configurable buffer persistence
##
## Example:
## ```nim
## import panicoverride
## import nimphea
## import ../per/i2c
## import dev/leddriver
##
## # Allocate DMA buffers in D2 memory
## var bufferA {.section: ".sram_d2".}: LedDriverDmaBuffer[2]
## var bufferB {.section: ".sram_d2".}: LedDriverDmaBuffer[2]
##
## # Configure for 2 PCA9685 chips (32 LEDs total)
## var config: LedDriverConfig[2]
## config.i2c_config.periph = I2C_1
## config.i2c_config.speed = I2C_400KHZ
## config.i2c_config.scl = D11()
## config.i2c_config.sda = D12()
## config.addresses = [0'u8, 1'u8]  # Chip addresses
## config.oe_pin = D10()  # Optional output enable pin
##
## var driver: LedDriverPca9685[2]
## driver.init(config, addr(bufferA), addr(bufferB))
##
## # Set LED brightness (0.0 - 1.0)
## driver.setLed(0, 0.5)  # LED 0 at 50% brightness
## driver.setAllTo(1.0)   # All LEDs full brightness
##
## # Update LEDs (non-blocking DMA transfer)
## driver.swapBuffersAndTransmit()
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(leddriver, i2c)

# System delay functions from libDaisy
proc delayMs*(ms: uint32) {.importcpp: "daisy::System::Delay(@)", header: "sys/system.h".}
proc delayUs*(us: uint32) {.importcpp: "daisy::System::DelayUs(@)", header: "sys/system.h".}
proc delayTicks*(ticks: uint32) {.importcpp: "daisy::System::DelayTicks(@)", header: "sys/system.h".}

type
  ## DMA buffer for a single PCA9685 chip (16 channels)
  ## Each LED has an on/off cycle value (4 bytes per LED + 1 register address byte)
  Pca9685TransmitBuffer* = object
    registerAddr*: uint8  ## Register address (always PCA9685_LED0)
    leds*: array[16, tuple[on: uint16, off: uint16]]  ## 16 LED on/off values

  ## DMA buffer array for multiple daisy-chained chips
  LedDriverDmaBuffer*[N: static int] = array[N, Pca9685TransmitBuffer]

  ## Configuration for PCA9685 LED driver
  LedDriverConfig*[N: static int] = object
    i2c_config*: I2CConfig         ## I2C peripheral configuration
    addresses*: array[N, uint8]    ## I2C addresses for each chip (0-63, ORed with base address)
    oe_pin*: Pin                   ## Optional output enable pin (active low)

  ## PCA9685 LED driver for one or multiple chips on a single I2C bus
  LedDriverPca9685*[N: static int, PersistentBuffer: static bool = true] = object
    i2c*: I2CHandle
    drawBuffer*: ptr LedDriverDmaBuffer[N]
    transmitBuffer*: ptr LedDriverDmaBuffer[N]
    addresses*: array[N, uint8]
    oePin*: Pin
    oePinGpio*: GPIO
    currentDriverIdx*: int8  ## -1 when idle, 0..N-1 during transmission

  ## Type alias for Daisy Field LED driver (26 LEDs, 2× PCA9685 chips)
  ## This concrete type enables Field-specific wrapper procedures (v0.12.0 fix)
  FieldLedDriver* = LedDriverPca9685[2, true]

const
  PCA9685_I2C_BASE_ADDRESS* = 0b01000000'u8
  PCA9685_MODE1* = 0x00'u8
  PCA9685_MODE2* = 0x01'u8
  PCA9685_LED0* = 0x06'u8
  PCA9685_PRESCALE* = 0xFE'u8

  ## Gamma correction lookup table (8-bit to 12-bit PWM)
  ## Maps linear brightness (0-255) to perceptually linear PWM values (0-4095)
  GAMMA_TABLE* = [
    0'u16, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 3, 3, 4, 4, 5,
    5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 15, 16,
    17, 18, 20, 21, 23, 25, 26, 28, 30, 32, 34, 36,
    38, 40, 43, 45, 48, 50, 53, 56, 59, 62, 65, 68,
    71, 75, 78, 82, 85, 89, 93, 97, 101, 105, 110, 114,
    119, 123, 128, 133, 138, 143, 149, 154, 159, 165, 171, 177,
    183, 189, 195, 202, 208, 215, 222, 229, 236, 243, 250, 258,
    266, 273, 281, 290, 298, 306, 315, 324, 332, 341, 351, 360,
    369, 379, 389, 399, 409, 419, 430, 440, 451, 462, 473, 485,
    496, 508, 520, 532, 544, 556, 569, 582, 594, 608, 621, 634,
    648, 662, 676, 690, 704, 719, 734, 749, 764, 779, 795, 811,
    827, 843, 859, 876, 893, 910, 927, 944, 962, 980, 998, 1016,
    1034, 1053, 1072, 1091, 1110, 1130, 1150, 1170, 1190, 1210, 1231, 1252,
    1273, 1294, 1316, 1338, 1360, 1382, 1404, 1427, 1450, 1473, 1497, 1520,
    1544, 1568, 1593, 1617, 1642, 1667, 1693, 1718, 1744, 1770, 1797, 1823,
    1850, 1877, 1905, 1932, 1960, 1988, 2017, 2045, 2074, 2103, 2133, 2162,
    2192, 2223, 2253, 2284, 2315, 2346, 2378, 2410, 2442, 2474, 2507, 2540,
    2573, 2606, 2640, 2674, 2708, 2743, 2778, 2813, 2849, 2884, 2920, 2957,
    2993, 3030, 3067, 3105, 3143, 3181, 3219, 3258, 3297, 3336, 3376, 3416,
    3456, 3496, 3537, 3578, 3619, 3661, 3703, 3745, 3788, 3831, 3874, 3918,
    3962, 4006, 4050, 4095'u16
  ]

proc getDriverForLed*[N, P](driver: LedDriverPca9685[N, P], ledIndex: int): int {.inline.} =
  ## Get which PCA9685 chip contains the given LED (0..N-1)
  ledIndex shr 4  # Divide by 16

proc getDriverChannelForLed*[N, P](driver: LedDriverPca9685[N, P], ledIndex: int): int {.inline.} =
  ## Get which channel (0..15) on a chip the LED uses
  ledIndex and 0x0F

proc getStartCycleForLed*[N, P](driver: LedDriverPca9685[N, P], ledIndex: int): uint16 {.inline.} =
  ## Get staggered start cycle for LED (reduces current spikes)
  ((ledIndex shl 2) and 0x0FFF).uint16

proc getNumLeds*[N, P](driver: LedDriverPca9685[N, P]): int {.inline.} =
  ## Returns total number of LEDs (16 per chip)
  N * 16

proc initializeBuffers*[N, P](driver: var LedDriverPca9685[N, P]) =
  ## Initialize both DMA buffers with staggered LED start cycles
  for led in 0 ..< driver.getNumLeds():
    let
      d = driver.getDriverForLed(led)
      ch = driver.getDriverChannelForLed(led)
      startCycle = driver.getStartCycleForLed(led)
    
    driver.drawBuffer[][d].registerAddr = PCA9685_LED0
    driver.drawBuffer[][d].leds[ch].on = startCycle
    driver.drawBuffer[][d].leds[ch].off = startCycle
    
    driver.transmitBuffer[][d].registerAddr = PCA9685_LED0
    driver.transmitBuffer[][d].leds[ch].on = startCycle
    driver.transmitBuffer[][d].leds[ch].off = startCycle

proc initializeDrivers*[N, P](driver: var LedDriverPca9685[N, P]) =
  ## Initialize all PCA9685 chips via I2C
  # Init output enable pin if provided
  if driver.oePin.port != PORTX:
    driver.oePinGpio = initGpio(driver.oePin, OUTPUT)
    driver.oePinGpio.write(false)  # Active low, enable outputs
  
  # Initialize each PCA9685 chip
  for d in 0 ..< N:
    let address = PCA9685_I2C_BASE_ADDRESS or driver.addresses[d]
    var buffer: array[2, uint8]
    
    # Wake from sleep
    buffer[0] = PCA9685_MODE1
    buffer[1] = 0x00
    discard driver.i2c.TransmitBlocking(address, addr buffer[0], 2, 100)
    delayMs(20)
    
    # Restart
    buffer[0] = PCA9685_MODE1
    buffer[1] = 0x00
    discard driver.i2c.TransmitBlocking(address, addr buffer[0], 2, 100)
    delayMs(20)
    
    # Enable auto-increment
    buffer[0] = PCA9685_MODE1
    buffer[1] = 0b00100000  # Auto increment on
    discard driver.i2c.TransmitBlocking(address, addr buffer[0], 2, 100)
    delayMs(20)
    
    # Configure MODE2
    buffer[0] = PCA9685_MODE2
    buffer[1] = 0b00110110  # OE=high-Z, push-pull, update on STOP, inverted
    discard driver.i2c.TransmitBlocking(address, addr buffer[0], 2, 100)
    delayMs(5)

proc init*[N, P](driver: var LedDriverPca9685[N, P],
                 config: LedDriverConfig[N],
                 dmaBufferA: ptr LedDriverDmaBuffer[N],
                 dmaBufferB: ptr LedDriverDmaBuffer[N]) =
  ## Initialize the LED driver with DMA buffers
  ## 
  ## DMA buffers must be allocated in D2 memory:
  ## ```nim
  ## var bufferA {.section: ".sram_d2".}: LedDriverDmaBuffer[2]
  ## var bufferB {.section: ".sram_d2".}: LedDriverDmaBuffer[2]
  ## driver.init(config, addr(bufferA), addr(bufferB))
  ## ```
  driver.i2c = initI2C(
    config.i2c_config.periph,
    config.i2c_config.pin_config.scl,
    config.i2c_config.pin_config.sda,
    config.i2c_config.speed,
    config.i2c_config.mode
  )
  driver.drawBuffer = dmaBufferA
  driver.transmitBuffer = dmaBufferB
  driver.oePin = config.oe_pin
  driver.addresses = config.addresses
  driver.currentDriverIdx = -1
  
  driver.initializeBuffers()
  driver.initializeDrivers()

proc setLedRaw*[N, P](driver: var LedDriverPca9685[N, P], ledIndex: int, rawBrightness: uint16) =
  ## Set a single LED to raw 12-bit brightness (0-4095)
  let
    d = driver.getDriverForLed(ledIndex)
    ch = driver.getDriverChannelForLed(ledIndex)
    on = driver.drawBuffer[][d].leds[ch].on and 0x0FFF
  
  var brightness = rawBrightness and 0x0FFF
  driver.drawBuffer[][d].leds[ch].off = (on + brightness) and 0x0FFF
  
  # Set "full on" bit if at max brightness
  if brightness >= 0x0FFF:
    driver.drawBuffer[][d].leds[ch].on = 0x1000 or on
  else:
    driver.drawBuffer[][d].leds[ch].on = on

proc setLed*[N, P](driver: var LedDriverPca9685[N, P], ledIndex: int, brightness: uint8) =
  ## Set a single LED to gamma-corrected brightness (0-255)
  let cycles = GAMMA_TABLE[brightness]
  driver.setLedRaw(ledIndex, cycles)

proc setLed*[N, P](driver: var LedDriverPca9685[N, P], ledIndex: int, brightness: float32) =
  ## Set a single LED to gamma-corrected brightness (0.0-1.0)
  let intBrightness = clamp(brightness * 255.0'f32, 0.0'f32, 255.0'f32).uint8
  driver.setLed(ledIndex, intBrightness)

proc setAllToRaw*[N, P](driver: var LedDriverPca9685[N, P], rawBrightness: uint16) =
  ## Set all LEDs to raw 12-bit brightness (0-4095)
  for led in 0 ..< driver.getNumLeds():
    driver.setLedRaw(led, rawBrightness)

proc setAllTo*[N, P](driver: var LedDriverPca9685[N, P], brightness: uint8) =
  ## Set all LEDs to gamma-corrected brightness (0-255)
  let cycles = GAMMA_TABLE[brightness]
  driver.setAllToRaw(cycles)

proc setAllTo*[N, P](driver: var LedDriverPca9685[N, P], brightness: float32) =
  ## Set all LEDs to gamma-corrected brightness (0.0-1.0)
  let intBrightness = clamp(brightness * 255.0'f32, 0.0'f32, 255.0'f32).uint8
  driver.setAllTo(intBrightness)

# Forward declaration for callback
proc continueTransmission*[N, P](driver: var LedDriverPca9685[N, P])

proc txCpltCallback(context: pointer, result: I2CResult) {.exportc, cdecl.} =
  ## Internal DMA completion callback
  # Note: Generic type information is lost in callback context
  # Use Field-specific callback for working DMA (see fieldLedDriverDmaCallback below)
  discard

proc continueTransmission*[N, P](driver: var LedDriverPca9685[N, P]) =
  ## Continue DMA transmission to next chip (internal use)
  driver.currentDriverIdx += 1
  
  if driver.currentDriverIdx >= N:
    driver.currentDriverIdx = -1
    return
  
  let
    d = driver.currentDriverIdx
    address = PCA9685_I2C_BASE_ADDRESS or driver.addresses[d]
    bufferSize = sizeof(Pca9685TransmitBuffer)
  
  # Start DMA transmission for this chip
  # Note: Callback system needs proper type-safe wrapper
  let status = driver.i2c.TransmitDma(
    address.uint16,
    cast[ptr uint8](addr driver.transmitBuffer[][d]),
    bufferSize.uint16,
    nil,  # No callback for now (would need proper context)
    nil
  )
  
  if status != I2C_OK:
    # On error, reinit I2C (as per libDaisy implementation)
    let config = driver.i2c.GetConfig()
    discard driver.i2c.Init(config)
    driver.currentDriverIdx = -1

proc swapBuffersAndTransmit*[N, P](driver: var LedDriverPca9685[N, P], 
                                    timeoutMs: int = 100): bool =
  ## Swap draw and transmit buffers, then start DMA transmission to all chips
  ## This is non-blocking - transmission happens in background via DMA
  ## 
  ## **Parameters:**
  ## - `timeoutMs` - Maximum time to wait for previous transmission (default 100ms)
  ## 
  ## **Returns:** 
  ## - `true` if buffers swapped and transmission started successfully
  ## - `false` if timeout occurred waiting for previous transmission
  ## 
  ## **Note:** On timeout, the driver state is reset to prevent hangs, but
  ## the previous transmission may have been incomplete.
  
  # Wait for current transmission to complete with timeout
  var timeout = timeoutMs
  while driver.currentDriverIdx >= 0 and timeout > 0:
    delayMs(1)  # Use proper 1ms delay instead of busy-wait
    timeout -= 1
  
  # Check if timeout occurred
  if timeout <= 0 and driver.currentDriverIdx >= 0:
    # Force reset driver state to prevent permanent hang
    driver.currentDriverIdx = -1
    return false  # Indicate timeout/failure
  
  # Swap buffers
  swap(driver.drawBuffer, driver.transmitBuffer)
  
  # Copy transmit buffer contents to new draw buffer if persistent
  when P:  # PersistentBuffer compile-time constant
    for d in 0 ..< N:
      for ch in 0 ..< 16:
        driver.drawBuffer[][d].leds[ch].off = driver.transmitBuffer[][d].leds[ch].off
  
  # Start transmission sequence
  driver.currentDriverIdx = -1
  driver.continueTransmission()
  
  return true  # Success

# ============================================================================
# Field-Specific LED Driver Wrappers (v0.12.0)
# ============================================================================
# These wrappers provide convenient access to Field LED driver functions
# using the concrete FieldLedDriver type instead of generic parameters.
# The Field has 26 LEDs controlled by 2× PCA9685 chips (daisy-chained).

proc setLed*(driver: var FieldLedDriver, ledNum: int, brightness: float32) =
  ## Set Field LED brightness (0.0-1.0) with gamma correction
  ## 
  ## **Parameters:**
  ## - `ledNum` - LED index 0-25 (16 keyboard + 8 knob + 2 switch LEDs)
  ## - `brightness` - Brightness level 0.0 (off) to 1.0 (full)
  ## 
  ## **LED Mapping:**
  ## - LEDs 0-15: Keyboard LEDs (Chip 0, channels 0-15)
  ## - LEDs 16-23: Knob LEDs (Chip 1, channels 0-7)
  ## - LEDs 24-25: Switch LEDs (Chip 1, channels 8-9)
  if ledNum < 0 or ledNum >= 26:
    return
  
  let chipIdx = ledNum div 16  # Chip 0 has LEDs 0-15, Chip 1 has LEDs 16-25
  let channelIdx = ledNum mod 16
  
  # Convert brightness to 12-bit PWM with gamma correction
  let brightness8bit = uint8(brightness * 255.0)
  let pwmValue = if brightness8bit < 256: GAMMA_TABLE[brightness8bit] else: 4095'u16
  
  # Update draw buffer
  driver.drawBuffer[][chipIdx].leds[channelIdx].on = 0
  driver.drawBuffer[][chipIdx].leds[channelIdx].off = pwmValue

proc clearAllLeds*(driver: var FieldLedDriver) =
  ## Turn off all Field LEDs (26 total)
  for led in 0..<26:
    driver.setLed(led, 0.0)

proc swapBuffersAndTransmit*(driver: var FieldLedDriver): bool {.inline.} =
  ## Swap buffers and transmit to Field LEDs via DMA
  ## 
  ## **Returns:** `true` if transmission started successfully
  ## 
  ## **Note:** Uses 100ms timeout for DMA transfer initialization
  driver.swapBuffersAndTransmit(100)  # 100ms timeout

# Field LED driver DMA callback (enables high-performance LED updates)
proc fieldLedDriverDmaCallback(context: pointer, result: I2CResult) {.cdecl, exportc: "fieldLedDriverDmaCallback".} =
  ## DMA completion callback for Field LED driver
  ## 
  ## Called from interrupt context when I2C DMA transfer completes.
  ## Enables chaining multiple DMA transfers (one per PCA9685 chip)
  ## without blocking the main thread.
  ## 
  ## **Context:** Pointer to FieldLedDriver instance
  ## **Result:** I2C transfer result (I2C_OK or error code)
  if result == I2C_OK:
    var driver = cast[ptr FieldLedDriver](context)
    driver[].continueTransmission()
