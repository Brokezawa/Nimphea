## Hardware Timer (TIM)
## ====================
##
## Hardware timer peripheral support for Daisy Seed.
##
## Supports general-purpose TIM peripherals:
## - TIM2, TIM5 (32-bit counters)
## - TIM3, TIM4 (16-bit counters)
##
## **Features:**
## - High-precision timing (up to 200MHz/240MHz)
## - Tick-based or time-based measurements (us/ms)
## - Configurable period and prescaler
## - User callbacks on period elapsed
## - Blocking delays (DelayTick, DelayMs, DelayUs)
##
## **Note:** DaisySeed uses TIM2 internally for timing/delay purposes at maximum frequency.
##
## **Usage:**
## ```nim
## import per/tim
##
## var timer: TimerHandle
## var config = TimerConfig()
## config.periph = TIM_PERIPH_TIM2
## config.dir = TIMER_DIR_UP
## config.period = 0xffffffff  # Max for 32-bit
## config.enable_irq = false
##
## discard timer.init(config)
## discard timer.start()
##
## # Get current tick
## let tick = timer.getTick()
##
## # Delay for 1000us
## timer.delayUs(1000)
## ```
##
## **Callback Usage:**
## ```nim
## proc onTimerPeriod(data: pointer) {.cdecl.} =
##   # Called every period
##   echo "Timer elapsed!"
##
## config.enable_irq = true
## discard timer.init(config)
## timer.setCallback(onTimerPeriod, nil)
## discard timer.start()
## ```

import nimphea_macros

useNimpheaModules(tim)

type
  TimerPeripheral* {.importcpp: "daisy::TimerHandle::Config::Peripheral",
                     header: "per/tim.h".} = enum
    ## Hardware timer peripheral selection
    TIM_PERIPH_TIM2 = 0  ## 32-bit counter (recommended for long periods)
    TIM_PERIPH_TIM3      ## 16-bit counter
    TIM_PERIPH_TIM4      ## 16-bit counter
    TIM_PERIPH_TIM5      ## 32-bit counter

  TimerCounterDir* {.importcpp: "daisy::TimerHandle::Config::CounterDir",
                     header: "per/tim.h".} = enum
    ## Counter direction
    TIMER_DIR_UP = 0     ## Count up from 0 to period
    TIMER_DIR_DOWN       ## Count down from period to 0

  TimerResult* {.importcpp: "daisy::TimerHandle::Result",
                 header: "per/tim.h".} = enum
    ## Return values for timer functions
    TIMER_OK = 0         ## Operation successful
    TIMER_ERR            ## Operation failed

  TimerConfig* {.importcpp: "daisy::TimerHandle::Config",
                 header: "per/tim.h", bycopy.} = object
    ## Timer configuration structure
    periph*: TimerPeripheral    ## Hardware peripheral to use
    dir*: TimerCounterDir       ## Counter direction
    period*: uint32             ## Period in ticks (max: 0xffff for 16-bit, 0xffffffff for 32-bit)
    enable_irq*: bool           ## Enable interrupt for callbacks

  TimerHandle* {.importcpp: "daisy::TimerHandle",
                 header: "per/tim.h".} = object
    ## Hardware timer handle
    ##
    ## Provides access to one of the four general-purpose timers (TIM2-TIM5).

  TimerCallback* = proc(data: pointer) {.cdecl.}
    ## User callback type that fires at the end of each timer period
    ##
    ## **Note:** Requires `enable_irq = true` in config

# Constructor for config with defaults
proc createTimerConfig*(): TimerConfig {.importcpp: "daisy::TimerHandle::Config()".} =
  ## Create a timer configuration with default values
  ##
  ## **Defaults:**
  ## - periph: TIM_PERIPH_TIM2
  ## - dir: TIMER_DIR_UP
  ## - period: 0xffffffff (max for 32-bit)
  ## - enable_irq: false
  discard

# Timer methods
proc init*(this: var TimerHandle, config: TimerConfig): TimerResult 
  {.importcpp: "#.Init(#)".} =
  ## Initialize the timer according to the configuration
  ##
  ## **Parameters:**
  ## - `config` - Timer configuration structure
  ##
  ## **Returns:** TIMER_OK on success, TIMER_ERR on failure
  ##
  ## **Example:**
  ## ```nim
  ## var timer: TimerHandle
  ## var config = createTimerConfig()
  ## config.periph = TIM_PERIPH_TIM5
  ## config.period = 10000  # Wrap every 10000 ticks
  ## 
  ## if timer.init(config) == TIMER_OK:
  ##   echo "Timer initialized"
  ## ```
  discard

proc deInit*(this: var TimerHandle): TimerResult
  {.importcpp: "#.DeInit()".} =
  ## Deinitialize the timer
  ##
  ## **Returns:** TIMER_OK on success, TIMER_ERR on failure
  discard

proc getConfig*(this: TimerHandle): TimerConfig
  {.importcpp: "#.GetConfig()".} =
  ## Returns the current configuration
  ##
  ## **Returns:** Timer configuration structure
  discard

proc setPeriod*(this: var TimerHandle, ticks: uint32): TimerResult
  {.importcpp: "#.SetPeriod(#)".} =
  ## Set the period of the timer
  ##
  ## This is the number of ticks before it wraps around.
  ## Can be changed on-the-fly while timer is running.
  ##
  ## **Parameters:**
  ## - `ticks` - Period in ticks (max 0xffff for 16-bit, 0xffffffff for 32-bit)
  ##
  ## **Returns:** TIMER_OK on success
  ##
  ## **Example:**
  ## ```nim
  ## # Set to wrap every second at 200MHz
  ## discard timer.setPeriod(200_000_000)
  ## ```
  discard

proc setPrescaler*(this: var TimerHandle, val: uint32): TimerResult
  {.importcpp: "#.SetPrescaler(#)".} =
  ## Set the prescaler applied to the TIM peripheral
  ##
  ## Adjusts the rate of ticks: APBx_Freq / prescaler per tick
  ## Can be changed on-the-fly while timer is running.
  ##
  ## **Parameters:**
  ## - `val` - Prescaler value (0 to 0xffff)
  ##
  ## **Returns:** TIMER_OK on success
  ##
  ## **Example:**
  ## ```nim
  ## # Divide by 200 to get 1MHz ticks from 200MHz clock
  ## discard timer.setPrescaler(200)
  ## ```
  discard

proc start*(this: var TimerHandle): TimerResult
  {.importcpp: "#.Start()".} =
  ## Start the timer peripheral
  ##
  ## **Returns:** TIMER_OK on success
  discard

proc stop*(this: var TimerHandle): TimerResult
  {.importcpp: "#.Stop()".} =
  ## Stop the timer peripheral
  ##
  ## **Returns:** TIMER_OK on success
  discard

proc getFreq*(this: var TimerHandle): uint32
  {.importcpp: "#.GetFreq()".} =
  ## Returns the frequency of each tick in Hz
  ##
  ## **Returns:** Tick frequency in Hz
  ##
  ## **Example:**
  ## ```nim
  ## let freq = timer.getFreq()
  ## echo "Timer ticks at ", freq, " Hz"
  ## # Typically 200MHz or 240MHz (boost mode)
  ## ```
  discard

proc getTick*(this: var TimerHandle): uint32
  {.importcpp: "#.GetTick()".} =
  ## Returns the current counter position
  ##
  ## Increments according to CounterDir and wraps at period.
  ##
  ## **Returns:** Current tick count
  ##
  ## **Example:**
  ## ```nim
  ## let start = timer.getTick()
  ## # ... do work ...
  ## let elapsed = timer.getTick() - start
  ## ```
  discard

proc getMs*(this: var TimerHandle): uint32
  {.importcpp: "#.GetMs()".} =
  ## Returns ticks scaled as milliseconds
  ##
  ## **Warning:** Ensure period can handle max measurement to avoid wrapping!
  ##
  ## **Returns:** Current time in milliseconds
  discard

proc getUs*(this: var TimerHandle): uint32
  {.importcpp: "#.GetUs()".} =
  ## Returns ticks scaled as microseconds
  ##
  ## **Warning:** Ensure period can handle max measurement to avoid wrapping!
  ##
  ## **Returns:** Current time in microseconds
  discard

proc delayTick*(this: var TimerHandle, del: uint32)
  {.importcpp: "#.DelayTick(#)".} =
  ## Blocking delay for specified ticks
  ##
  ## **Parameters:**
  ## - `del` - Number of ticks to delay
  ##
  ## **Example:**
  ## ```nim
  ## timer.delayTick(1000)  # Wait 1000 ticks
  ## ```
  discard

proc delayMs*(this: var TimerHandle, del: uint32)
  {.importcpp: "#.DelayMs(#)".} =
  ## Blocking delay for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Number of milliseconds to delay
  ##
  ## **Example:**
  ## ```nim
  ## timer.delayMs(100)  # Wait 100ms
  ## ```
  discard

proc delayUs*(this: var TimerHandle, del: uint32)
  {.importcpp: "#.DelayUs(#)".} =
  ## Blocking delay for specified microseconds
  ##
  ## **Parameters:**
  ## - `del` - Number of microseconds to delay
  ##
  ## **Example:**
  ## ```nim
  ## timer.delayUs(500)  # Wait 500us (0.5ms)
  ## ```
  discard

proc setCallback*(this: var TimerHandle, cb: TimerCallback, data: pointer = nil)
  {.importcpp: "#.SetCallback(#, #)".} =
  ## Set callback that fires when timer reaches end of period
  ##
  ## **Note:** Requires `enable_irq = true` in config
  ##
  ## **Parameters:**
  ## - `cb` - User callback function
  ## - `data` - Optional pointer to user data (defaults to nil)
  ##
  ## **Example:**
  ## ```nim
  ## proc onPeriod(data: pointer) {.cdecl.} =
  ##   # Called every period
  ##   hw.setLed(true)
  ##
  ## timer.setCallback(onPeriod, nil)
  ## ```
  discard
