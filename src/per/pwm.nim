## PWM (Pulse Width Modulation) support for libDaisy Nim wrapper
##
## This module provides hardware PWM support using the STM32 timer peripherals.
## PWM is useful for LED control, motor control, servo control, and generating
## analog-like signals.
##
## Example - Simple LED dimming:
## ```nim
## import nimphea, per/pwm
## 
## var hw = initDaisy()
## 
## # Initialize PWM on TIM3, channel 2 (internal LED on Daisy Seed)
## var pwm = initPwm(TIM_3, frequency = 1000.0)  # 1kHz
## pwm.channel2.init()
## 
## # Fade LED in and out
## while true:
##   for brightness in 0..100:
##     pwm.channel2.set(brightness / 100.0)
##     hw.delay(10)
##   for brightness in countdown(100, 0):
##     pwm.channel2.set(brightness / 100.0)
##     hw.delay(10)
## ```
##
## Example - Multiple channels:
## ```nim
## # TIM4 with 4 channels (RGB LED + servo)
## var pwm = initPwm(TIM_4, frequency = 50.0)  # 50Hz for servo
## 
## # Configure channels with specific pins
## pwm.channel1.init(D13())  # Red LED
## pwm.channel2.init(D14())  # Green LED
## pwm.channel3.init(D11())  # Blue LED
## pwm.channel4.init(D12())  # Servo control
## 
## # Set RGB color and servo position
## pwm.channel1.set(1.0)    # Red full
## pwm.channel2.set(0.5)    # Green half
## pwm.channel3.set(0.0)    # Blue off
## pwm.channel4.set(0.075)  # Servo center (1.5ms @ 50Hz)
## ```

import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(pwm)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # Forward declarations
  PwmHandleImpl* {.importcpp: "daisy::PWMHandle::Impl".} = object
  
  # PWM Timer peripheral selection
  PwmPeripheral* {.importcpp: "daisy::PWMHandle::Config::Peripheral", size: sizeof(cint).} = enum
    TIM_3 = 0  ## TIM3 - 16-bit counter
    TIM_4 = 1  ## TIM4 - 16-bit counter  
    TIM_5 = 2  ## TIM5 - 32-bit counter
  
  # PWM Result codes
  PwmResult* {.importcpp: "daisy::PWMHandle::Result", size: sizeof(cint).} = enum
    PWM_OK = 0
    PWM_ERR = 1
  
  # Channel polarity
  PwmPolarity* {.importcpp: "daisy::PWMHandle::Channel::Config::Polarity", size: sizeof(cint).} = enum
    POLARITY_HIGH = 0  ## Output high when active
    POLARITY_LOW       ## Output low when active
  
  # PWM Configuration
  PwmConfig* {.importcpp: "daisy::PWMHandle::Config", bycopy.} = object
    periph* {.importc: "periph".}: PwmPeripheral
    prescaler* {.importc: "prescaler".}: uint32
    period* {.importc: "period".}: uint32
  
  # Channel Configuration  
  PwmChannelConfig* {.importcpp: "daisy::PWMHandle::Channel::Config", bycopy.} = object
    pin* {.importc: "pin".}: Pin
    polarity* {.importc: "polarity".}: PwmPolarity
  
  # PWM Handle - must be declared before Channel since Channel references it
  PwmHandle* {.importcpp: "daisy::PWMHandle".} = object
  
  # PWM Channel - nested class reference
  PwmChannel* {.importcpp: "daisy::PWMHandle::Channel".} = object

{.pop.} # importcpp
{.pop.} # header

# Low-level C++ interface for PwmHandle
proc Init(this: var PwmHandle, config: PwmConfig): PwmResult 
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

proc DeInit(this: var PwmHandle): PwmResult
  {.importcpp: "#.DeInit()", header: "daisy_seed.h".}

proc GetConfig(this: PwmHandle): PwmConfig
  {.importcpp: "#.GetConfig()", header: "daisy_seed.h".}

proc Channel1(this: var PwmHandle): var PwmChannel
  {.importcpp: "#.Channel1()", header: "daisy_seed.h".}

proc Channel2(this: var PwmHandle): var PwmChannel
  {.importcpp: "#.Channel2()", header: "daisy_seed.h".}

proc Channel3(this: var PwmHandle): var PwmChannel
  {.importcpp: "#.Channel3()", header: "daisy_seed.h".}

proc Channel4(this: var PwmHandle): var PwmChannel
  {.importcpp: "#.Channel4()", header: "daisy_seed.h".}

proc SetPrescaler(this: var PwmHandle, prescaler: uint32)
  {.importcpp: "#.SetPrescaler(@)", header: "daisy_seed.h".}

proc SetPeriod(this: var PwmHandle, period: uint32)
  {.importcpp: "#.SetPeriod(@)", header: "daisy_seed.h".}

# Low-level C++ interface for PwmChannel
proc Init(this: var PwmChannel, config: PwmChannelConfig): PwmResult
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

proc Init(this: var PwmChannel): PwmResult
  {.importcpp: "#.Init()", header: "daisy_seed.h".}

proc DeInit(this: var PwmChannel): PwmResult
  {.importcpp: "#.DeInit()", header: "daisy_seed.h".}

proc SetRaw(this: var PwmChannel, raw: uint32)
  {.importcpp: "#.SetRaw(@)", header: "daisy_seed.h".}

proc Set(this: var PwmChannel, val: cfloat)
  {.importcpp: "#.Set(@)", header: "daisy_seed.h".}

proc GetConfig(this: PwmChannel): PwmChannelConfig
  {.importcpp: "#.GetConfig()", header: "daisy_seed.h".}

# C++ constructors
proc cppNewPwmHandle(): PwmHandle 
  {.importcpp: "daisy::PWMHandle()", constructor, header: "daisy_seed.h".}

proc cppNewPwmConfig(): PwmConfig
  {.importcpp: "daisy::PWMHandle::Config()", constructor, header: "daisy_seed.h".}

proc cppNewPwmConfig(periph: PwmPeripheral, prescaler: uint32, period: uint32): PwmConfig
  {.importcpp: "daisy::PWMHandle::Config(@)", constructor, header: "daisy_seed.h".}

proc cppNewPwmChannelConfig(): PwmChannelConfig
  {.importcpp: "daisy::PWMHandle::Channel::Config()", constructor, header: "daisy_seed.h".}

proc cppNewPwmChannelConfig(pin: Pin, polarity: PwmPolarity): PwmChannelConfig
  {.importcpp: "daisy::PWMHandle::Channel::Config(@)", constructor, header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc calculatePwmParams(frequency: float, prescaler: var uint32, period: var uint32) =
  ## Calculate prescaler and period for a given frequency
  ## System clock is 480MHz for STM32H750
  const SYSCLK = 480_000_000.0
  
  # PWM frequency = SYSCLK / (2 * (period + 1) * (prescaler + 1))
  # We want to maximize period for best resolution
  
  if frequency <= 0.0:
    # Default to 1kHz
    prescaler = 0
    period = 0xFFFF
    return
  
  # Try prescaler = 0 first (no division)
  let targetTicks = SYSCLK / (2.0 * frequency)
  
  if targetTicks <= 0xFFFF.float:
    # Fits in 16-bit period (TIM3/TIM4)
    prescaler = 0
    period = uint32(targetTicks) - 1
  elif targetTicks <= 0xFFFFFFFF.float:
    # Need prescaler or use 32-bit timer (TIM5)
    prescaler = 0
    period = uint32(targetTicks) - 1
  else:
    # Need prescaler
    prescaler = uint32((targetTicks / 0xFFFF.float)) - 1
    let adjustedTicks = SYSCLK / (2.0 * frequency * (prescaler.float + 1.0))
    period = uint32(adjustedTicks) - 1

proc cppInit*(pwm: var PwmHandle, peripheral: PwmPeripheral, frequency: float = 1000.0) =
  ## Initialize PWM peripheral in-place with a target frequency
  ## 
  ## This function initializes an existing PwmHandle variable.
  ## Use this to avoid copy constructor issues.
  ## 
  ## Parameters:
  ##   pwm: The PwmHandle variable to initialize
  ##   peripheral: TIM_3, TIM_4, or TIM_5
  ##   frequency: Target frequency in Hz (default 1000Hz / 1kHz)
  ## 
  ## Example:
  ## ```nim
  ## var pwm {.noinit.}: PwmHandle
  ## pwm.cppInit(TIM_3, 1000.0)  # 1kHz
  ## pwm.channel1.init()
  ## ```
  var prescaler, period: uint32
  calculatePwmParams(frequency, prescaler, period)
  
  # For 16-bit timers (TIM3, TIM4), clamp period to 16-bit max
  if peripheral != TIM_5 and period > 0xFFFF:
    period = 0xFFFF
  
  var config = cppNewPwmConfig(peripheral, prescaler, period)
  discard pwm.Init(config)

proc initPwm*(peripheral: PwmPeripheral, frequency: float = 1000.0): PwmHandle =
  ## Initialize PWM peripheral with a target frequency
  ## 
  ## Note: Due to C++ copy constructor restrictions, you may need to use
  ## cppInit() instead if you get compiler errors.
  ## 
  ## Parameters:
  ##   peripheral: TIM_3, TIM_4, or TIM_5
  ##   frequency: Target frequency in Hz (default 1000Hz / 1kHz)
  ## 
  ## Returns: Initialized PWM handle (channels must be initialized separately)
  ## 
  ## Example:
  ## ```nim
  ## var pwm {.noinit.}: PwmHandle
  ## pwm.cppInit(TIM_3, 1000.0)  # Recommended
  ## ```
  result = cppNewPwmHandle()
  result.cppInit(peripheral, frequency)

proc initPwmCustom*(peripheral: PwmPeripheral, prescaler: uint32, 
                    period: uint32): PwmHandle =
  ## Initialize PWM with explicit prescaler and period values
  ## 
  ## For advanced users who want exact control over timing.
  ## Frequency = SYSCLK / (2 * (period + 1) * (prescaler + 1))
  ## 
  ## Parameters:
  ##   peripheral: TIM_3, TIM_4, or TIM_5
  ##   prescaler: Clock prescaler (0 = no division)
  ##   period: Counter period before reset
  ## 
  ## Example:
  ## ```nim
  ## # 100Hz PWM with maximum resolution
  ## var pwm = initPwmCustom(TIM_5, 0, 2_400_000)
  ## ```
  result = cppNewPwmHandle()
  var config = cppNewPwmConfig(peripheral, prescaler, period)
  discard result.Init(config)

proc deinit*(pwm: var PwmHandle) =
  ## Deinitialize PWM peripheral
  discard pwm.DeInit()

proc channel1*(pwm: var PwmHandle): var PwmChannel {.inline.} =
  ## Get reference to channel 1
  pwm.Channel1()

proc channel2*(pwm: var PwmHandle): var PwmChannel {.inline.} =
  ## Get reference to channel 2
  pwm.Channel2()

proc channel3*(pwm: var PwmHandle): var PwmChannel {.inline.} =
  ## Get reference to channel 3
  pwm.Channel3()

proc channel4*(pwm: var PwmHandle): var PwmChannel {.inline.} =
  ## Get reference to channel 4
  pwm.Channel4()

proc setPrescaler*(pwm: var PwmHandle, prescaler: uint32) =
  ## Change the prescaler after initialization
  pwm.SetPrescaler(prescaler)

proc setPeriod*(pwm: var PwmHandle, period: uint32) =
  ## Change the period after initialization
  ## This affects frequency and resolution
  pwm.SetPeriod(period)

# Channel methods

proc init*(channel: var PwmChannel, pin: Pin = Pin(), 
           polarity: PwmPolarity = POLARITY_HIGH): PwmResult =
  ## Initialize a PWM channel
  ## 
  ## Parameters:
  ##   pin: GPIO pin for output (use Pin() for default)
  ##   polarity: POLARITY_HIGH (normal) or POLARITY_LOW (inverted)
  ## 
  ## Example:
  ## ```nim
  ## pwm.channel1.init(D13())
  ## pwm.channel2.init()  # Use default pin
  ## ```
  if pin.port == PORTX:
    # Use default pin
    result = channel.Init()
  else:
    var config = cppNewPwmChannelConfig(pin, polarity)
    result = channel.Init(config)

proc deinit*(channel: var PwmChannel): PwmResult =
  ## Deinitialize a PWM channel
  channel.DeInit()

proc set*(channel: var PwmChannel, dutyCycle: float) =
  ## Set PWM duty cycle as a float (0.0 to 1.0)
  ## 
  ## Parameters:
  ##   dutyCycle: Duty cycle from 0.0 (0%) to 1.0 (100%)
  ## 
  ## Example:
  ## ```nim
  ## channel.set(0.5)   # 50% duty cycle
  ## channel.set(0.25)  # 25% duty cycle
  ## channel.set(1.0)   # 100% duty cycle (fully on)
  ## ```
  channel.Set(dutyCycle.cfloat)

proc setRaw*(channel: var PwmChannel, value: uint32) =
  ## Set PWM duty cycle as raw counter value
  ## 
  ## Value must be <= timer's period
  ## 
  ## Parameters:
  ##   value: Raw counter value
  ## 
  ## Example:
  ## ```nim
  ## # If period is 1000, this sets 75% duty cycle
  ## channel.setRaw(750)
  ## ```
  channel.SetRaw(value)

# Constants and pin mappings
const
  # Pin mapping reference (Daisy Seed)
  
  # TIM3 default pins
  TIM3_CH1_DEFAULT* = "D19"  ## PA6
  TIM3_CH2_DEFAULT* = "LED"  ## PC7 (internal LED)
  TIM3_CH3_DEFAULT* = "D4"   ## PC8
  TIM3_CH4_DEFAULT* = "D17"  ## PB1
  
  # TIM4 pins (fixed)
  TIM4_CH1_PIN* = "D13"  ## PB6
  TIM4_CH2_PIN* = "D14"  ## PB7
  TIM4_CH3_PIN* = "D11"  ## PB8
  TIM4_CH4_PIN* = "D12"  ## PB9
  
  # TIM5 pins (fixed)
  TIM5_CH1_PIN* = "D25"  ## PA0
  TIM5_CH2_PIN* = "D24"  ## PA1
  TIM5_CH3_PIN* = "D28"  ## PA2
  TIM5_CH4_PIN* = "D16"  ## PA3

when isMainModule:
  echo "libDaisy PWM wrapper - Clean API"
