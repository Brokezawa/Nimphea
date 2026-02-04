## ADC (Analog to Digital Converter) support for libDaisy Nim wrapper
##
## This module provides comprehensive ADC functionality for the Daisy Audio Platform,
## including single-channel inputs, multiplexed inputs, and various conversion speeds.
##
## Example - Simple single-channel ADC:
## ```nim
## import nimphea, per/adc
## 
## var hw = initDaisy()
## 
## # Configure ADC channels
## var channels: array[2, AdcChannelConfig]
## channels[0].initSingle(A0())
## channels[1].initSingle(A1())
## 
## # Initialize ADC
## var adc = initAdcHandle(channels, OVS_32)
## adc.start()
## 
## while true:
##   let value1 = adc.getFloat(0)  # 0.0 to 1.0
##   let value2 = adc.getFloat(1)
##   hw.delay(10)
## ```
##
## Example - Multiplexed ADC (up to 8 inputs on one pin):
## ```nim
## # Configure mux: one ADC pin with 4 multiplexed inputs
## var channels: array[1, AdcChannelConfig]
## channels[0].initMux(
##   adcPin = A0(),
##   muxChannels = 4,  # Using a 4052 mux (2 select lines)
##   mux0 = D0(),      # First select line
##   mux1 = D1()       # Second select line
## )
## 
## var adc = initAdcHandle(channels, OVS_32)
## adc.start()
## 
## while true:
##   for i in 0..<4:
##     let value = adc.getMuxFloat(0, i)  # Channel 0, mux index i
##   hw.delay(10)
## ```

import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(adc)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # ADC Channel Configuration enums
  MuxPin* {.importcpp: "daisy::AdcChannelConfig::MuxPin", size: sizeof(cint).} = enum
    MUX_SEL_0 = 0  ## First multiplexer select pin
    MUX_SEL_1      ## Second multiplexer select pin
    MUX_SEL_2      ## Third multiplexer select pin
    MUX_SEL_LAST   ## Internal marker

  ConversionSpeed* {.importcpp: "daisy::AdcChannelConfig::ConversionSpeed", size: sizeof(cint).} = enum
    SPEED_1CYCLES_5 = 0    ## 1.5 cycles conversion time (fastest)
    SPEED_2CYCLES_5        ## 2.5 cycles conversion time
    SPEED_8CYCLES_5        ## 8.5 cycles conversion time (default)
    SPEED_16CYCLES_5       ## 16.5 cycles conversion time
    SPEED_32CYCLES_5       ## 32.5 cycles conversion time
    SPEED_64CYCLES_5       ## 64.5 cycles conversion time
    SPEED_387CYCLES_5      ## 387.5 cycles conversion time
    SPEED_810CYCLES_5      ## 810.5 cycles conversion time (slowest, most accurate)

  # ADC oversampling options
  OverSampling* {.importcpp: "daisy::AdcHandle::OverSampling", size: sizeof(cint).} = enum
    OVS_NONE = 0   ## No oversampling
    OVS_4          ## 4x oversampling
    OVS_8          ## 8x oversampling
    OVS_16         ## 16x oversampling
    OVS_32         ## 32x oversampling (default, good balance)
    OVS_64         ## 64x oversampling
    OVS_128        ## 128x oversampling
    OVS_256        ## 256x oversampling
    OVS_512        ## 512x oversampling
    OVS_1024       ## 1024x oversampling (slowest, most accurate)
    OVS_LAST       ## Internal marker

  # ADC Channel Configuration
  AdcChannelConfig* {.importcpp: "daisy::AdcChannelConfig", bycopy.} = object

  # ADC Handle - main ADC controller
  AdcHandle* {.importcpp: "daisy::AdcHandle".} = object

{.pop.} # importcpp
{.pop.} # header

# Low-level C++ interface for AdcChannelConfig
proc InitSingle(this: var AdcChannelConfig, pin: Pin, speed: ConversionSpeed = SPEED_8CYCLES_5) 
  {.importcpp: "#.InitSingle(@)", header: "daisy_seed.h".}

proc InitMux(this: var AdcChannelConfig, adc_pin: Pin, mux_channels: csize_t, 
             mux_0: Pin, mux_1: Pin = Pin(), mux_2: Pin = Pin(), 
             speed: ConversionSpeed = SPEED_8CYCLES_5) 
  {.importcpp: "#.InitMux(@)", header: "daisy_seed.h".}

# Low-level C++ interface for AdcHandle
proc Init(this: var AdcHandle, cfg: ptr AdcChannelConfig, num_channels: csize_t, 
          ovs: OverSampling = OVS_32) 
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

proc Start(this: var AdcHandle) 
  {.importcpp: "#.Start()", header: "daisy_seed.h".}

proc Stop(this: var AdcHandle) 
  {.importcpp: "#.Stop()", header: "daisy_seed.h".}

proc Get(this: AdcHandle, chn: uint8): uint16 
  {.importcpp: "#.Get(@)", header: "daisy_seed.h".}

proc GetPtr(this: AdcHandle, chn: uint8): ptr uint16 
  {.importcpp: "#.GetPtr(@)", header: "daisy_seed.h".}

proc GetFloat(this: AdcHandle, chn: uint8): cfloat 
  {.importcpp: "#.GetFloat(@)", header: "daisy_seed.h".}

proc GetMux(this: AdcHandle, chn: uint8, idx: uint8): uint16 
  {.importcpp: "#.GetMux(@)", header: "daisy_seed.h".}

proc GetMuxPtr(this: AdcHandle, chn: uint8, idx: uint8): ptr uint16 
  {.importcpp: "#.GetMuxPtr(@)", header: "daisy_seed.h".}

proc GetMuxFloat(this: AdcHandle, chn: uint8, idx: uint8): cfloat 
  {.importcpp: "#.GetMuxFloat(@)", header: "daisy_seed.h".}

# C++ constructors
proc cppNewAdcChannelConfig(): AdcChannelConfig 
  {.importcpp: "daisy::AdcChannelConfig()", constructor, header: "daisy_seed.h".}

proc cppNewAdcHandle(): AdcHandle 
  {.importcpp: "daisy::AdcHandle()", constructor, header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc initSingle*(config: var AdcChannelConfig, pin: Pin, 
                 speed: ConversionSpeed = SPEED_8CYCLES_5) =
  ## Initialize an ADC channel configuration for a single analog input
  ## 
  ## Parameters:
  ##   config: The channel configuration object to initialize
  ##   pin: The analog input pin (e.g., A0(), A1(), etc.)
  ##   speed: Conversion speed - faster = less accurate but quicker reads
  ## 
  ## Example:
  ## ```nim
  ## var channels: array[2, AdcChannelConfig]
  ## channels[0].initSingle(A0())
  ## channels[1].initSingle(A1(), SPEED_16CYCLES_5)
  ## ```
  config.InitSingle(pin, speed)

proc initMux*(config: var AdcChannelConfig, adcPin: Pin, muxChannels: int,
              mux0: Pin, mux1: Pin = Pin(), mux2: Pin = Pin(),
              speed: ConversionSpeed = SPEED_8CYCLES_5) =
  ## Initialize an ADC channel configuration for a multiplexed input
  ## 
  ## Supports CD405X series multiplexers (4051, 4052, 4053) to read
  ## multiple analog inputs through a single ADC channel.
  ## 
  ## Parameters:
  ##   config: The channel configuration object to initialize
  ##   adcPin: The ADC input pin connected to the mux output
  ##   muxChannels: Number of mux inputs (1-8)
  ##   mux0: First select line (required for all muxes)
  ##   mux1: Second select line (required for 4+ channels)
  ##   mux2: Third select line (required for 8 channels)
  ##   speed: Conversion speed
  ## 
  ## Example - 4-channel mux (4052):
  ## ```nim
  ## var channels: array[1, AdcChannelConfig]
  ## channels[0].initMux(A0(), 4, D0(), D1())
  ## ```
  ## 
  ## Example - 8-channel mux (4051):
  ## ```nim
  ## var channels: array[1, AdcChannelConfig]
  ## channels[0].initMux(A0(), 8, D0(), D1(), D2())
  ## ```
  config.InitMux(adcPin, muxChannels.csize_t, mux0, mux1, mux2, speed)

proc newAdcChannelConfig*(): AdcChannelConfig =
  ## Create a new ADC channel configuration
  ## 
  ## Example:
  ## ```nim
  ## var cfg = newAdcChannelConfig()
  ## cfg.initSingle(A0())
  ## ```
  result = cppNewAdcChannelConfig()

proc initAdcHandle*(configs: var openArray[AdcChannelConfig], 
                    oversampling: OverSampling = OVS_32): AdcHandle =
  ## Initialize an ADC handle with the given channel configurations
  ## 
  ## Parameters:
  ##   configs: Array of channel configurations (up to 16 channels)
  ##   oversampling: Oversampling rate for noise reduction
  ##                 Higher = slower but more accurate
  ##                 OVS_32 is a good default balance
  ## 
  ## Example:
  ## ```nim
  ## var channels: array[3, AdcChannelConfig]
  ## channels[0].initSingle(A0())
  ## channels[1].initSingle(A1())
  ## channels[2].initSingle(A2())
  ## 
  ## var adc = initAdcHandle(channels, OVS_32)
  ## adc.start()
  ## ```
  result = cppNewAdcHandle()
  if configs.len > 0:
    result.Init(addr configs[0], configs.len.csize_t, oversampling)

proc start*(adc: var AdcHandle) =
  ## Start ADC conversions
  ## 
  ## Must be called before reading values.
  adc.Start()

proc stop*(adc: var AdcHandle) =
  ## Stop ADC conversions
  adc.Stop()

proc get*(adc: AdcHandle, channel: int): uint16 =
  ## Get raw 16-bit ADC value from a channel
  ## 
  ## Parameters:
  ##   channel: Channel index (0-based)
  ## 
  ## Returns: Raw ADC value (0-65535)
  ## 
  ## Example:
  ## ```nim
  ## let rawValue = adc.get(0)
  ## ```
  adc.Get(channel.uint8)

proc getPtr*(adc: AdcHandle, channel: int): ptr uint16 =
  ## Get pointer to raw ADC value for zero-copy access
  ## 
  ## Useful for performance-critical code that needs direct memory access.
  ## 
  ## Parameters:
  ##   channel: Channel index (0-based)
  ## 
  ## Returns: Pointer to raw ADC value
  adc.GetPtr(channel.uint8)

proc getFloat*(adc: AdcHandle, channel: int): float {.inline.} =
  ## Get normalized floating-point ADC value from a channel
  ## 
  ## Parameters:
  ##   channel: Channel index (0-based)
  ## 
  ## Returns: Normalized value (0.0 to 1.0)
  ## 
  ## Example:
  ## ```nim
  ## let knobPosition = adc.getFloat(0)
  ## let voltage = knobPosition * 3.3  # Convert to voltage
  ## ```
  adc.GetFloat(channel.uint8)

proc getMux*(adc: AdcHandle, channel: int, muxIndex: int): uint16 {.inline.} =
  ## Get raw 16-bit value from a multiplexed input
  ## 
  ## Parameters:
  ##   channel: ADC channel index (0-based)
  ##   muxIndex: Multiplexer input index (0-7)
  ## 
  ## Returns: Raw ADC value (0-65535)
  ## 
  ## Example:
  ## ```nim
  ## # Read all 4 inputs from a mux on channel 0
  ## for i in 0..<4:
  ##   let value = adc.getMux(0, i)
  ## ```
  adc.GetMux(channel.uint8, muxIndex.uint8)

proc getMuxPtr*(adc: AdcHandle, channel: int, muxIndex: int): ptr uint16 {.inline.} =
  ## Get pointer to raw multiplexed ADC value
  ## 
  ## Parameters:
  ##   channel: ADC channel index (0-based)
  ##   muxIndex: Multiplexer input index (0-7)
  ## 
  ## Returns: Pointer to raw ADC value
  adc.GetMuxPtr(channel.uint8, muxIndex.uint8)

proc getMuxFloat*(adc: AdcHandle, channel: int, muxIndex: int): float {.inline.} =
  ## Get normalized floating-point value from a multiplexed input
  ## 
  ## Parameters:
  ##   channel: ADC channel index (0-based)
  ##   muxIndex: Multiplexer input index (0-7)
  ## 
  ## Returns: Normalized value (0.0 to 1.0)
  ## 
  ## Example:
  ## ```nim
  ## # Read all 8 inputs from a mux on channel 0
  ## for i in 0..<8:
  ##   let value = adc.getMuxFloat(0, i)
  ##   echo "Input ", i, ": ", value
  ## ```
  adc.GetMuxFloat(channel.uint8, muxIndex.uint8)

# Constants for common configurations
const
  DSY_ADC_MAX_CHANNELS* = 16  ## Maximum number of ADC channels

when isMainModule:
  echo "libDaisy ADC wrapper - Clean API"
