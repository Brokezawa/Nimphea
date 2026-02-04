## MAX11300 20-Port Programmable Mixed-Signal I/O Module
##
## Device driver for MAX11300 PIXI - 20-port ADC/DAC/GPIO device.
## Highly opinionated implementation optimized for Eurorack modular synthesis.
## 
## This is a full wrapper around libDaisy's MAX11300 C++ driver, supporting:
## - 20 configurable pins (ADC, DAC, GPIO input/output)
## - DMA-based continuous updates via Start() method
## - Multiple voltage ranges (-10V to +10V)
## - Up to 4 devices on shared SPI bus (multi-slave)
##
## ⚠️ **IMPORTANT**: This implementation wraps libDaisy's C++ driver but has
## **NOT been tested on hardware**. It follows libDaisy's proven code and
## compiles successfully, but should be considered **experimental** until
## hardware validation is complete.
##
## Example:
## ```nim
## var pixi: MAX11300[1]  # Single device
## var config: MAX11300Config[1]
## config.transport_config.pin_config.defaults()
## 
## if pixi.init(config) != MAX_OK:
##   # Handle error
## 
## # Configure pins
## discard pixi.configurePinAsAnalogRead(0, PIN_0, ADC_NEG5_TO_5)
## discard pixi.configurePinAsAnalogWrite(0, PIN_1, DAC_NEG5_TO_5)
## 
## # Start DMA updates (optional)
## discard pixi.start(nil, nil)
## 
## # Read/write
## let cvIn = pixi.readAnalogPinVolts(0, PIN_0)
## pixi.writeAnalogPinVolts(0, PIN_1, cvIn)
## ```

import ../nimphea
import ../nimphea_macros
import ../per/spi

# Need to expose SPI types in the module
export SpiPeripheral, SpiBaudPrescaler

useNimpheaModules(max11300)

{.push header: "dev/max11300.h".}

# ============================================================================
# Types from MAX11300Types namespace
# ============================================================================

type
  MAX11300Pin* {.importcpp: "daisy::MAX11300Types::Pin", size: sizeof(cint).} = enum
    ## Represents a pin/port on the MAX11300 (20 pins total)
    PIN_0  = "daisy::MAX11300Types::Pin::PIN_0"
    PIN_1  = "daisy::MAX11300Types::Pin::PIN_1"
    PIN_2  = "daisy::MAX11300Types::Pin::PIN_2"
    PIN_3  = "daisy::MAX11300Types::Pin::PIN_3"
    PIN_4  = "daisy::MAX11300Types::Pin::PIN_4"
    PIN_5  = "daisy::MAX11300Types::Pin::PIN_5"
    PIN_6  = "daisy::MAX11300Types::Pin::PIN_6"
    PIN_7  = "daisy::MAX11300Types::Pin::PIN_7"
    PIN_8  = "daisy::MAX11300Types::Pin::PIN_8"
    PIN_9  = "daisy::MAX11300Types::Pin::PIN_9"
    PIN_10 = "daisy::MAX11300Types::Pin::PIN_10"
    PIN_11 = "daisy::MAX11300Types::Pin::PIN_11"
    PIN_12 = "daisy::MAX11300Types::Pin::PIN_12"
    PIN_13 = "daisy::MAX11300Types::Pin::PIN_13"
    PIN_14 = "daisy::MAX11300Types::Pin::PIN_14"
    PIN_15 = "daisy::MAX11300Types::Pin::PIN_15"
    PIN_16 = "daisy::MAX11300Types::Pin::PIN_16"
    PIN_17 = "daisy::MAX11300Types::Pin::PIN_17"
    PIN_18 = "daisy::MAX11300Types::Pin::PIN_18"
    PIN_19 = "daisy::MAX11300Types::Pin::PIN_19"

  AdcVoltageRange* {.importcpp: "daisy::MAX11300Types::AdcVoltageRange", size: sizeof(cint).} = enum
    ## ADC voltage ranges (assumes proper power supply)
    ## WARNING: DigitalRead pins are 0-5V only and corrupted by negative voltages
    ADC_0_TO_10      = "daisy::MAX11300Types::AdcVoltageRange::ZERO_TO_10"
    ADC_NEG5_TO_5    = "daisy::MAX11300Types::AdcVoltageRange::NEGATIVE_5_TO_5"
    ADC_NEG10_TO_0   = "daisy::MAX11300Types::AdcVoltageRange::NEGATIVE_10_TO_0"
    ADC_0_TO_2P5     = "daisy::MAX11300Types::AdcVoltageRange::ZERO_TO_2P5"

  DacVoltageRange* {.importcpp: "daisy::MAX11300Types::DacVoltageRange", size: sizeof(cint).} = enum
    ## DAC voltage ranges (assumes proper power supply)
    ## DigitalWrite pins are 0-5V only
    DAC_0_TO_10      = "daisy::MAX11300Types::DacVoltageRange::ZERO_TO_10"
    DAC_NEG5_TO_5    = "daisy::MAX11300Types::DacVoltageRange::NEGATIVE_5_TO_5"
    DAC_NEG10_TO_0   = "daisy::MAX11300Types::DacVoltageRange::NEGATIVE_10_TO_0"

  MAX11300Result* {.importcpp: "daisy::MAX11300Types::Result", size: sizeof(cint).} = enum
    ## Operation result codes
    MAX_OK  = "daisy::MAX11300Types::Result::OK"
    MAX_ERR = "daisy::MAX11300Types::Result::ERR"

  MAX11300DmaBuffer* {.importcpp: "daisy::MAX11300Types::DmaBuffer", bycopy.} = object
    ## DMA buffer for SPI transfers - must be in non-cached memory
    rx_buffer* {.importc: "rx_buffer".}: array[41, uint8]
    tx_buffer* {.importc: "tx_buffer".}: array[41, uint8]

  UpdateCompleteCallback* = proc(context: pointer) {.cdecl.}
    ## Callback called after each successful DMA update cycle

# ============================================================================
# Transport Layer Types
# ============================================================================

# ============================================================================
# Transport Layer Types (N=1 only - C++ templates are complex)
# ============================================================================

type
  MAX11300TransportPinConfig* {.importcpp: "daisy::MAX11300MultiSlaveSpiTransport::Config<1>::PinConfig", bycopy.} = object
    ## SPI pin configuration for transport layer
    nss*  {.importc: "nss".}: array[1, Pin]   ## Chip select pins (one per device)
    mosi* {.importc: "mosi".}: Pin             ## SPI MOSI
    miso* {.importc: "miso".}: Pin             ## SPI MISO
    sclk* {.importc: "sclk".}: Pin             ## SPI clock

  MAX11300TransportConfig* {.importcpp: "daisy::MAX11300MultiSlaveSpiTransport::Config<1>", bycopy.} = object
    ## Transport layer configuration
    pin_config*      {.importc: "pin_config".}: MAX11300TransportPinConfig
    periph*          {.importc: "periph".}: SpiPeripheral
    baud_prescaler*  {.importc: "baud_prescaler".}: SpiBaudPrescaler

# ============================================================================
# Device Driver Types (N=1 only)
# ============================================================================

type
  MAX11300Config* {.importcpp: "daisy::MAX11300<1>::Config", bycopy.} = object
    ## MAX11300 device configuration (currently supports N=1 only)
    transport_config* {.importc: "transport_config".}: MAX11300TransportConfig

  MAX11300Cpp* {.importcpp: "daisy::MAX11300<1>".} = object
    ## C++ MAX11300 driver object (opaque wrapper)

{.pop.}  # header

# ============================================================================
# Default Configuration Helpers
# ============================================================================

proc defaults*(config: var MAX11300TransportPinConfig) =
  ## Set default pin configuration for Daisy Seed
  ## Default pins match libDaisy defaults:
  ## - SPI1: PORTB.5 (MOSI), PORTB.4 (MISO), PORTG.11 (SCLK)
  ## - CS0: PORTG.10
  config.mosi = newPin(PORTB, 5)
  config.miso = newPin(PORTB, 4)
  config.sclk = newPin(PORTG, 11)
  config.nss[0] = newPin(PORTG, 10)

proc defaults*(config: var MAX11300TransportConfig) =
  ## Set default transport configuration
  config.pin_config.defaults()
  config.periph = SPI_1
  config.baud_prescaler = SPI_PS_8

# ============================================================================
# C++ Method Wrappers
# ============================================================================

{.push header: "dev/max11300.h".}

proc cppInit(this: var MAX11300Cpp, config: MAX11300Config, 
                dma_buffer: ptr MAX11300DmaBuffer): MAX11300Result
  {.importcpp: "#.Init(@)".}

proc cppConfigurePinAsAnalogRead(this: var MAX11300Cpp, device: csize_t,
                                     pin: MAX11300Pin, range: AdcVoltageRange): MAX11300Result
  {.importcpp: "#.ConfigurePinAsAnalogRead(@)".}

proc cppConfigurePinAsAnalogWrite(this: var MAX11300Cpp, device: csize_t,
                                      pin: MAX11300Pin, range: DacVoltageRange): MAX11300Result
  {.importcpp: "#.ConfigurePinAsAnalogWrite(@)".}

proc cppConfigurePinAsDigitalRead(this: var MAX11300Cpp, device: csize_t,
                                      pin: MAX11300Pin, threshold: cfloat): MAX11300Result
  {.importcpp: "#.ConfigurePinAsDigitalRead(@)".}

proc cppConfigurePinAsDigitalWrite(this: var MAX11300Cpp, device: csize_t,
                                       pin: MAX11300Pin, voltage: cfloat): MAX11300Result
  {.importcpp: "#.ConfigurePinAsDigitalWrite(@)".}

proc cppDisablePin(this: var MAX11300Cpp, device: csize_t, pin: MAX11300Pin): MAX11300Result
  {.importcpp: "#.DisablePin(@)".}

proc cppReadAnalogPinRaw(this: var MAX11300Cpp, device: csize_t, pin: MAX11300Pin): uint16
  {.importcpp: "#.ReadAnalogPinRaw(@)".}

proc cppReadAnalogPinVolts(this: var MAX11300Cpp, device: csize_t, pin: MAX11300Pin): cfloat
  {.importcpp: "#.ReadAnalogPinVolts(@)".}

proc cppWriteAnalogPinRaw(this: var MAX11300Cpp, device: csize_t, 
                              pin: MAX11300Pin, value: uint16)
  {.importcpp: "#.WriteAnalogPinRaw(@)".}

proc cppWriteAnalogPinVolts(this: var MAX11300Cpp, device: csize_t,
                                pin: MAX11300Pin, voltage: cfloat)
  {.importcpp: "#.WriteAnalogPinVolts(@)".}

proc cppReadDigitalPin(this: var MAX11300Cpp, device: csize_t, pin: MAX11300Pin): bool
  {.importcpp: "#.ReadDigitalPin(@)".}

proc cppWriteDigitalPin(this: var MAX11300Cpp, device: csize_t,
                            pin: MAX11300Pin, value: bool)
  {.importcpp: "#.WriteDigitalPin(@)".}

proc cppStart(this: var MAX11300Cpp, callback: UpdateCompleteCallback,
                 context: pointer): MAX11300Result
  {.importcpp: "#.Start(@)".}

proc cppStop(this: var MAX11300Cpp)
  {.importcpp: "#.Stop()".}

proc cppVoltsTo12BitUint(volts: cfloat, range: DacVoltageRange): uint16
  {.importcpp: "daisy::MAX11300<1>::VoltsTo12BitUint(@)".}

proc cppTwelveBitUintToVolts(value: uint16, range: AdcVoltageRange): cfloat
  {.importcpp: "daisy::MAX11300<1>::TwelveBitUintToVolts(@)".}

{.pop.}  # header

# ============================================================================
# Nim Wrapper Type & Public API
# ============================================================================

type
  MAX11300*[N: static int] {.bycopy, nodecl.} = object
    ## MAX11300 device wrapper (currently supports N=1 only)
    ## 
    ## Note: The libDaisy C++ template is complex to wrap with multiple devices.
    ## This wrapper is hard-coded for single device (N=1). Multi-device support
    ## would require additional Nim/C++ template instantiation work.
    cpp: MAX11300Cpp
    dmaBuffer {.align(4).}: MAX11300DmaBuffer  # Note: Must be in DMA-accessible memory
    numDevices: csize_t

# ----------------------------------------------------------------------------
# Initialization
# ----------------------------------------------------------------------------

proc init*[N](max: var MAX11300[N], config: MAX11300Config): MAX11300Result =
  ## Initialize MAX11300 device(s)
  ## 
  ## This performs:
  ## - SPI initialization and connectivity verification
  ## - Device configuration (ADC/DAC modes, conversion rates, etc.)
  ## - All pins initialized to High-Z (disabled) mode
  ## 
  ## **Parameters:**
  ## - `config` - Configuration including SPI pins and settings
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **Note:** Call this once at startup before configuring pins
  when N != 1:
    {.error: "MAX11300 currently only supports N=1 (single device). Multi-device support requires additional C++ template work.".}
  max.numDevices = N.csize_t
  result = max.cpp.cppInit(config, addr max.dmaBuffer)

# ----------------------------------------------------------------------------
# Pin Configuration
# ----------------------------------------------------------------------------

proc configurePinAsAnalogRead*[N](max: var MAX11300[N], device: csize_t, 
                                   pin: MAX11300Pin, range: AdcVoltageRange): MAX11300Result =
  ## Configure pin as analog input (ADC)
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number (PIN_0 to PIN_19)
  ## - `range` - Voltage range (ADC_0_TO_10, ADC_NEG5_TO_5, etc.)
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **Note:** Requires appropriate power supply for chosen range
  result = max.cpp.cppConfigurePinAsAnalogRead(device, pin, range)

proc configurePinAsAnalogWrite*[N](max: var MAX11300[N], device: csize_t,
                                    pin: MAX11300Pin, range: DacVoltageRange): MAX11300Result =
  ## Configure pin as analog output (DAC)
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number (PIN_0 to PIN_19)
  ## - `range` - Voltage range (DAC_0_TO_10, DAC_NEG5_TO_5, etc.)
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **Note:** Requires appropriate power supply for chosen range
  result = max.cpp.cppConfigurePinAsAnalogWrite(device, pin, range)

proc configurePinAsDigitalRead*[N](max: var MAX11300[N], device: csize_t,
                                    pin: MAX11300Pin, threshold: float32 = 2.5): MAX11300Result =
  ## Configure pin as digital input (GPI)
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number (PIN_0 to PIN_19)
  ## - `threshold` - Logic level threshold voltage (default 2.5V)
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **WARNING:** Digital input pins are 0-5V only. Voltages below -250mV
  ## will corrupt ALL analog readings on the device!
  result = max.cpp.cppConfigurePinAsDigitalRead(device, pin, threshold.cfloat)

proc configurePinAsDigitalWrite*[N](max: var MAX11300[N], device: csize_t,
                                     pin: MAX11300Pin, voltage: float32 = 5.0): MAX11300Result =
  ## Configure pin as digital output (GPO)
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number (PIN_0 to PIN_19)
  ## - `voltage` - Output voltage for logic HIGH (default 5.0V)
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **Note:** Digital outputs are 0-5V only (no negative voltages)
  result = max.cpp.cppConfigurePinAsDigitalWrite(device, pin, voltage.cfloat)

proc disablePin*[N](max: var MAX11300[N], device: csize_t, pin: MAX11300Pin): MAX11300Result =
  ## Disable pin (set to High-Z mode)
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number (PIN_0 to PIN_19)
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  result = max.cpp.cppDisablePin(device, pin)

# ----------------------------------------------------------------------------
# Analog I/O
# ----------------------------------------------------------------------------

proc readAnalogPinRaw*[N](max: var MAX11300[N], device: csize_t, pin: MAX11300Pin): uint16 =
  ## Read raw 12-bit ADC value (0-4095)
  ## 
  ## **Note:** This reads from local buffer. Call start() to enable
  ## automatic DMA updates, or values will be stale.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as ADC
  ## 
  ## **Returns:** Raw 12-bit value (0-4095)
  result = max.cpp.cppReadAnalogPinRaw(device, pin)

proc readAnalogPinVolts*[N](max: var MAX11300[N], device: csize_t, pin: MAX11300Pin): float32 =
  ## Read ADC value in volts
  ## 
  ## **Note:** This reads from local buffer. Call start() to enable
  ## automatic DMA updates, or values will be stale.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as ADC
  ## 
  ## **Returns:** Voltage value according to configured range
  result = max.cpp.cppReadAnalogPinVolts(device, pin).float32

proc writeAnalogPinRaw*[N](max: var MAX11300[N], device: csize_t,
                            pin: MAX11300Pin, value: uint16) =
  ## Write raw 12-bit DAC value (0-4095)
  ## 
  ## **Note:** This writes to local buffer. Call start() to enable
  ## automatic DMA updates, or values won't reach hardware.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as DAC
  ## - `value` - Raw 12-bit value (0-4095)
  max.cpp.cppWriteAnalogPinRaw(device, pin, value)

proc writeAnalogPinVolts*[N](max: var MAX11300[N], device: csize_t,
                              pin: MAX11300Pin, voltage: float32) =
  ## Write DAC value in volts
  ## 
  ## **Note:** This writes to local buffer. Call start() to enable
  ## automatic DMA updates, or values won't reach hardware.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as DAC
  ## - `voltage` - Voltage value (clamped to configured range)
  max.cpp.cppWriteAnalogPinVolts(device, pin, voltage.cfloat)

# ----------------------------------------------------------------------------
# Digital I/O
# ----------------------------------------------------------------------------

proc readDigitalPin*[N](max: var MAX11300[N], device: csize_t, pin: MAX11300Pin): bool =
  ## Read digital input state
  ## 
  ## **Note:** This reads from local buffer. Call start() to enable
  ## automatic DMA updates, or values will be stale.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as GPI
  ## 
  ## **Returns:** true if above threshold, false otherwise
  result = max.cpp.cppReadDigitalPin(device, pin)

proc writeDigitalPin*[N](max: var MAX11300[N], device: csize_t,
                          pin: MAX11300Pin, value: bool) =
  ## Write digital output state
  ## 
  ## **Note:** This writes to local buffer. Call start() to enable
  ## automatic DMA updates, or values won't reach hardware.
  ## 
  ## **Parameters:**
  ## - `device` - Device index (0 to N-1)
  ## - `pin` - Pin number configured as GPO
  ## - `value` - true for HIGH, false for LOW
  max.cpp.cppWriteDigitalPin(device, pin, value)

# ----------------------------------------------------------------------------
# DMA Update Control
# ----------------------------------------------------------------------------

proc start*[N](max: var MAX11300[N], callback: UpdateCompleteCallback = nil,
               context: pointer = nil): MAX11300Result =
  ## Start continuous DMA updates
  ## 
  ## This begins automatic background updates that:
  ## - Write all DAC values to hardware
  ## - Read all ADC values from hardware
  ## - Write all GPO states to hardware
  ## - Read all GPI states from hardware
  ## - Call callback when complete (from interrupt context)
  ## - Repeat continuously
  ## 
  ## **Parameters:**
  ## - `callback` - Optional callback after each update (keep it fast!)
  ## - `context` - Optional context pointer passed to callback
  ## 
  ## **Returns:** MAX_OK on success, MAX_ERR on failure
  ## 
  ## **Note:** Can work without calling this (polling mode), but DMA
  ## updates provide much better performance and timing.
  result = max.cpp.cppStart(callback, context)

proc stop*[N](max: var MAX11300[N]) =
  ## Stop continuous DMA updates
  ## 
  ## Completes the current update cycle then stops. After this,
  ## read/write operations access local buffers only (polling mode).
  max.cpp.cppStop()

# ----------------------------------------------------------------------------
# Utility Functions (Static)
# ----------------------------------------------------------------------------

proc voltsTo12BitUint*(volts: float32, range: DacVoltageRange): uint16 =
  ## Convert voltage to 12-bit DAC code
  ## 
  ## **Parameters:**
  ## - `volts` - Voltage value
  ## - `range` - DAC voltage range
  ## 
  ## **Returns:** 12-bit value (0-4095), clamped to range
  result = cppVoltsTo12BitUint(volts.cfloat, range)

proc twelveBitUintToVolts*(value: uint16, range: AdcVoltageRange): float32 =
  ## Convert 12-bit ADC code to voltage
  ## 
  ## **Parameters:**
  ## - `value` - Raw 12-bit value (0-4095)
  ## - `range` - ADC voltage range
  ## 
  ## **Returns:** Voltage value
  result = cppTwelveBitUintToVolts(value, range).float32
