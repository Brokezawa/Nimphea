## Controls and sensors support for libDaisy Nim wrapper
##
## This module provides support for encoders, switches, analog controls, and ADC.
##
## Example - Simple button:
## ```nim
## import nimphea, hid/ctrl
## 
## var daisy = initDaisy()
## var button = initSwitch(D2())
## 
## while true:
##   button.update()
##   if button.pressed:
##     daisy.setLed(true)
##   elif button.released:
##     daisy.setLed(false)
##   daisy.delay(1)
## ```
##
## Example - Rotary encoder:
## ```nim
## var encoder = initEncoder(D0(), D1(), D2())
## var value = 0
## 
## while true:
##   encoder.update()
##   value += encoder.increment
##   daisy.delay(1)
## ```
##
## Example - Analog input (ADC):
## ```nim
## var adc = initAdc(daisy, [A0(), A1()])
## adc.start()
## 
## while true:
##   let knob1 = adc.value(0)  # 0.0 to 1.0
##   let knob2 = adc.value(1)
##   daisy.delay(10)
## ```

# Import Pin type from main module
# Import libdaisy which provides the macro system
import nimphea


# Use the macro system for this module's compilation unit
useNimpheaModules(controls, adc)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # Switch types
  Switch* {.importcpp: "daisy::Switch".} = object
  
  SwitchType* {.importcpp: "daisy::Switch::Type", size: sizeof(cint).} = enum
    TYPE_MOMENTARY = 0
    TYPE_LATCHING
    TYPE_TOGGLE
  
  SwitchPolarity* {.importcpp: "daisy::Switch::Polarity", size: sizeof(cint).} = enum
    POLARITY_NORMAL = 0
    POLARITY_INVERTED
  
  SwitchPull* {.importcpp: "daisy::Switch::Pull", size: sizeof(cint).} = enum
    PULL_UP = 0
    PULL_DOWN
    PULL_NONE

  # Encoder types
  Encoder* {.importcpp: "daisy::Encoder".} = object
  
  # AnalogControl - hardware interface for potentiometers and CV inputs
  AnalogControl* {.importcpp: "daisy::AnalogControl".} = object
  
  # ADC (Analog to Digital Converter) types
  AdcChannelConfig* {.importcpp: "daisy::AdcChannelConfig".} = object
  
  AdcHandle* {.importcpp: "daisy::AdcHandle".} = object
  
  MuxPin* {.importcpp: "daisy::AdcChannelConfig::MuxPin", size: sizeof(cint).} = enum
    MUX_SEL_0 = 0
    MUX_SEL_1
    MUX_SEL_2
    MUX_SEL_LAST
  
  ConversionSpeed* {.importcpp: "daisy::AdcChannelConfig::ConversionSpeed", size: sizeof(cint).} = enum
    SPEED_1CYCLES_5 = 0
    SPEED_2CYCLES_5
    SPEED_8CYCLES_5
    SPEED_16CYCLES_5
    SPEED_32CYCLES_5
    SPEED_64CYCLES_5
    SPEED_387CYCLES_5
    SPEED_810CYCLES_5
  
  OverSampling* {.importcpp: "daisy::AdcHandle::OverSampling", size: sizeof(cint).} = enum
    OVS_NONE = 0
    OVS_4
    OVS_8
    OVS_16
    OVS_32
    OVS_64
    OVS_128
    OVS_256
    OVS_512
    OVS_1024
    OVS_LAST

{.pop.} # importcpp
{.pop.} # header

# Low-level C++ interface (moved outside push blocks for correct code generation)
proc cppInit(this: var Switch, pin: Pin, update_rate: cfloat = 1000.0, 
           typ: SwitchType = TYPE_MOMENTARY, pol: SwitchPolarity = POLARITY_NORMAL,
           pull: SwitchPull = PULL_UP) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc cppDebounce(this: var Switch) {.importcpp: "#.Debounce()", header: "daisy_seed.h".}
proc cppPressed(this: var Switch): bool {.importcpp: "#.Pressed()", header: "daisy_seed.h".}
proc cppReleased(this: var Switch): bool {.importcpp: "#.Released()", header: "daisy_seed.h".}
proc cppFallingEdge(this: var Switch): bool {.importcpp: "#.FallingEdge()", header: "daisy_seed.h".}
proc cppRisingEdge(this: var Switch): bool {.importcpp: "#.RisingEdge()", header: "daisy_seed.h".}
proc cppTimeHeldMs(this: var Switch): cfloat {.importcpp: "#.TimeHeldMs()", header: "daisy_seed.h".}

proc cppInit(this: var Encoder, a: Pin, b: Pin, click: Pin, update_rate: cfloat = 1000.0) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc cppDebounce(this: var Encoder) {.importcpp: "#.Debounce()", header: "daisy_seed.h".}
proc cppIncrement(this: var Encoder): int32 {.importcpp: "#.Increment()", header: "daisy_seed.h".}
proc cppPressed(this: var Encoder): bool {.importcpp: "#.Pressed()", header: "daisy_seed.h".}
proc cppRisingEdge(this: var Encoder): bool {.importcpp: "#.RisingEdge()", header: "daisy_seed.h".}
proc cppFallingEdge(this: var Encoder): bool {.importcpp: "#.FallingEdge()", header: "daisy_seed.h".}
proc cppTimeHeldMs(this: var Encoder): cfloat {.importcpp: "#.TimeHeldMs()", header: "daisy_seed.h".}

# AnalogControl low-level C++ interface
proc cppInitAnalog(this: var AnalogControl, adcptr: ptr uint16, sr: cfloat, flip: bool = false, 
                   invert: bool = false, slew_seconds: cfloat = 0.002) {.importcpp: "#.Init(@)", header: "hid/ctrl.h".}
proc cppInitBipolarCv(this: var AnalogControl, adcptr: ptr uint16, sr: cfloat) {.importcpp: "#.InitBipolarCv(@)", header: "hid/ctrl.h".}
proc cppProcessAnalog(this: var AnalogControl): cfloat {.importcpp: "#.Process()", header: "hid/ctrl.h".}
proc cppValueAnalog(this: AnalogControl): cfloat {.importcpp: "#.Value()", header: "hid/ctrl.h".}
proc cppSetCoeff(this: var AnalogControl, val: cfloat) {.importcpp: "#.SetCoeff(@)", header: "hid/ctrl.h".}
proc cppSetScale(this: var AnalogControl, scale: cfloat) {.importcpp: "#.SetScale(@)", header: "hid/ctrl.h".}
proc cppSetOffset(this: var AnalogControl, offset: cfloat) {.importcpp: "#.SetOffset(@)", header: "hid/ctrl.h".}
proc cppGetRawValue(this: var AnalogControl): uint16 {.importcpp: "#.GetRawValue()", header: "hid/ctrl.h".}
proc cppGetRawFloat(this: var AnalogControl): cfloat {.importcpp: "#.GetRawFloat()", header: "hid/ctrl.h".}
proc cppSetSampleRate(this: var AnalogControl, sample_rate: cfloat) {.importcpp: "#.SetSampleRate(@)", header: "hid/ctrl.h".}

proc cppInitSingle(this: var AdcChannelConfig, pin: Pin, speed: ConversionSpeed = SPEED_8CYCLES_5) {.importcpp: "#.InitSingle(@)", header: "daisy_seed.h".}
proc cppInitMux(this: var AdcChannelConfig, adc_pin: Pin, mux_channels: csize_t, 
              mux_0: Pin, mux_1: Pin = Pin(), mux_2: Pin = Pin(), 
              speed: ConversionSpeed = SPEED_8CYCLES_5) {.importcpp: "#.InitMux(@)", header: "daisy_seed.h".}

proc cppInit(this: var AdcHandle, cfg: ptr AdcChannelConfig, num_channels: csize_t, 
           ovs: OverSampling = OVS_32) {.importcpp: "#.Init(@)", header: "daisy_seed.h".}
proc cppStart(this: var AdcHandle) {.importcpp: "#.Start()", header: "daisy_seed.h".}
proc cppStop(this: var AdcHandle) {.importcpp: "#.Stop()", header: "daisy_seed.h".}
proc cppGet(this: AdcHandle, chn: uint8): uint16 {.importcpp: "#.Get(@)", header: "daisy_seed.h".}
proc cppGetPtr(this: AdcHandle, chn: uint8): ptr uint16 {.importcpp: "#.GetPtr(@)", header: "daisy_seed.h".}
proc cppGetFloat(this: AdcHandle, chn: uint8): cfloat {.importcpp: "#.GetFloat(@)", header: "daisy_seed.h".}
proc cppGetMux(this: AdcHandle, chn: uint8, idx: uint8): uint16 {.importcpp: "#.GetMux(@)", header: "daisy_seed.h".}
proc cppGetMuxPtr(this: AdcHandle, chn: uint8, idx: uint8): ptr uint16 {.importcpp: "#.GetMuxPtr(@)", header: "daisy_seed.h".}
proc cppGetMuxFloat(this: AdcHandle, chn: uint8, idx: uint8): cfloat {.importcpp: "#.GetMuxFloat(@)", header: "daisy_seed.h".}

# C++ constructors
proc cppNewSwitch(): Switch {.importcpp: "daisy::Switch()", constructor, header: "daisy_seed.h".}
proc cppNewEncoder(): Encoder {.importcpp: "daisy::Encoder()", constructor, header: "daisy_seed.h".}
proc cppNewAnalogControl(): AnalogControl {.importcpp: "daisy::AnalogControl()", constructor, header: "hid/ctrl.h".}
proc cppNewAdcChannelConfig(): AdcChannelConfig {.importcpp: "daisy::AdcChannelConfig()", constructor, header: "daisy_seed.h".}
proc cppNewAdcHandle(): AdcHandle {.importcpp: "daisy::AdcHandle()", constructor, header: "daisy_seed.h".}

# ADC methods through DaisySeed
proc cppInitAdc(hw: var DaisySeed, cfg: ptr AdcChannelConfig, num_channels: csize_t, 
              ovs: OverSampling = OVS_32) {.importcpp: "#.adc.Init(@)", header: "daisy_seed.h".}
proc cppStartAdc(hw: var DaisySeed) {.importcpp: "#.adc.Start()", header: "daisy_seed.h".}
proc cppStopAdc(hw: var DaisySeed) {.importcpp: "#.adc.Stop()", header: "daisy_seed.h".}
proc cppGetAdc(hw: var DaisySeed, chn: uint8): uint16 {.importcpp: "#.adc.Get(@)", header: "daisy_seed.h".}
proc cppGetAdcFloat(hw: var DaisySeed, chn: uint8): cfloat {.importcpp: "#.adc.GetFloat(@)", header: "daisy_seed.h".}
proc cppGetAdcMux(hw: var DaisySeed, chn: uint8, idx: uint8): uint16 {.importcpp: "#.adc.GetMux(@)", header: "daisy_seed.h".}
proc cppGetAdcMuxFloat(hw: var DaisySeed, chn: uint8, idx: uint8): cfloat {.importcpp: "#.adc.GetMuxFloat(@)", header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc initSwitch*(pin: Pin, updateRate: float = 1000.0,
                switchType: SwitchType = TYPE_MOMENTARY,
                polarity: SwitchPolarity = POLARITY_NORMAL,
                pull: SwitchPull = PULL_UP): Switch =
  ## Initialize a switch/button
  ## 
  ## Parameters:
  ##   pin: The GPIO pin the switch is connected to
  ##   updateRate: How often to check the switch (Hz)
  ##   switchType: TYPE_MOMENTARY, TYPE_LATCHING, or TYPE_TOGGLE
  ##   polarity: POLARITY_NORMAL or POLARITY_INVERTED
  ##   pull: PULL_UP, PULL_DOWN, or PULL_NONE
  ## 
  ## Example:
  ## ```nim
  ## var button = initSwitch(D2())  # Simple momentary button
  ## ```
  result = cppNewSwitch()
  result.cppInit(pin, updateRate.cfloat, switchType, polarity, pull)

proc update*(switch: var Switch) =
  ## Update switch state (call this regularly, typically in main loop)
  switch.cppDebounce()

proc pressed*(switch: var Switch): bool =
  ## Check if switch is currently pressed
  switch.cppPressed()

proc released*(switch: var Switch): bool =
  ## Check if switch is currently released
  switch.cppReleased()

proc risingEdge*(switch: var Switch): bool =
  ## Check if switch just transitioned to pressed (trigger once)
  switch.cppRisingEdge()

proc fallingEdge*(switch: var Switch): bool =
  ## Check if switch just transitioned to released (trigger once)
  switch.cppFallingEdge()

proc timeHeld*(switch: var Switch): float =
  ## Get how long the switch has been held in milliseconds
  switch.cppTimeHeldMs()

proc initEncoder*(pinA, pinB: Pin, clickPin: Pin = Pin(), updateRate: float = 1000.0): Encoder =
  ## Initialize a rotary encoder
  ## 
  ## Parameters:
  ##   pinA, pinB: Encoder signal pins
  ##   clickPin: Optional click button pin (use Pin() to skip)
  ##   updateRate: How often to check the encoder (Hz)
  ## 
  ## Example:
  ## ```nim
  ## var encoder = initEncoder(D0(), D1(), D2())  # With click
  ## var encoderNoClick = initEncoder(D3(), D4())  # Without click
  ## ```
  result = cppNewEncoder()
  result.cppInit(pinA, pinB, clickPin, updateRate.cfloat)

proc update*(encoder: var Encoder) =
  ## Update encoder state (call this regularly)
  encoder.cppDebounce()

proc increment*(encoder: var Encoder): int =
  ## Get encoder position change since last call (-N to +N)
  encoder.cppIncrement().int

proc pressed*(encoder: var Encoder): bool =
  ## Check if encoder button is pressed
  encoder.cppPressed()

proc risingEdge*(encoder: var Encoder): bool =
  ## Check if encoder button was just pressed
  encoder.cppRisingEdge()

proc fallingEdge*(encoder: var Encoder): bool =
  ## Check if encoder button was just released
  encoder.cppFallingEdge()

proc timeHeld*(encoder: var Encoder): float =
  ## Get how long encoder button has been held in milliseconds
  encoder.cppTimeHeldMs()

# =============================================================================
# AnalogControl API - For potentiometers and CV inputs with filtering
# =============================================================================

proc initAnalogControl*(adcPtr: ptr uint16, sampleRate: float, flip: bool = false,
                       invert: bool = false, slewSeconds: float = 0.002): AnalogControl =
  ## Initialize an AnalogControl for a potentiometer or CV input.
  ## 
  ## This provides filtered, smoothed analog input with slew limiting.
  ## 
  ## Parameters:
  ##   adcPtr: Pointer to raw ADC value (from AdcHandle.getPtr())
  ##   sampleRate: Rate at which process() will be called (Hz)
  ##   flip: If true, flip the input (1.0 - input)
  ##   invert: If true, invert the input (-1.0 * input)
  ##   slewSeconds: Slew time in seconds for value changes (smoothing)
  ## 
  ## Example:
  ##   ```nim
  ##   # Setup ADC for analog input
  ##   var adc = initAdc(daisy, [A0()])
  ##   adc.start()
  ##   
  ##   # Create AnalogControl connected to ADC channel 0
  ##   var knob = initAnalogControl(daisy.adc.getPtr(0), 1000.0)
  ##   
  ##   while true:
  ##     let value = knob.process()  # Returns 0.0 to 1.0
  ##     daisy.delay(1)
  ##   ```
  result = cppNewAnalogControl()
  result.cppInitAnalog(adcPtr, sampleRate.cfloat, flip, invert, slewSeconds.cfloat)

proc initBipolarCv*(adcPtr: ptr uint16, sampleRate: float): AnalogControl =
  ## Initialize an AnalogControl for bipolar CV input (-5V to +5V).
  ## 
  ## This is a specialized initialization for CV inputs that range from -5V to +5V.
  ## The output will be in the range -1.0 to +1.0.
  ## 
  ## Parameters:
  ##   adcPtr: Pointer to raw ADC value (from AdcHandle.getPtr())
  ##   sampleRate: Rate at which process() will be called (Hz)
  ## 
  ## Example:
  ##   ```nim
  ##   var adc = initAdc(daisy, [A0()])
  ##   adc.start()
  ##   
  ##   var cvInput = initBipolarCv(daisy.adc.getPtr(0), 1000.0)
  ##   
  ##   while true:
  ##     let cv = cvInput.process()  # Returns -1.0 to +1.0
  ##     daisy.delay(1)
  ##   ```
  result = cppNewAnalogControl()
  result.cppInitBipolarCv(adcPtr, sampleRate.cfloat)

proc process*(control: var AnalogControl): float =
  ## Process the analog input and return the filtered value.
  ## 
  ## Call this at the rate specified during initialization.
  ## 
  ## Returns:
  ##   Filtered value (0.0 to 1.0 for normal, -1.0 to 1.0 for bipolar CV)
  control.cppProcessAnalog()

proc value*(control: AnalogControl): float =
  ## Get the current stored value without reprocessing.
  ## 
  ## Returns the last value computed by process().
  control.cppValueAnalog()

proc setCoeff*(control: var AnalogControl, coefficient: float) =
  ## Set the coefficient of the one-pole smoothing filter.
  ## 
  ## Parameters:
  ##   coefficient: Filter coefficient (0.0 to 1.0)
  ##                Higher values = less smoothing (faster response)
  ##                Lower values = more smoothing (slower response)
  control.cppSetCoeff(coefficient.cfloat)

proc setScale*(control: var AnalogControl, scale: float) =
  ## Set the scaling factor used by the process function.
  ## 
  ## Normally set during initialization, but can be adjusted for calibration.
  ## 
  ## Parameters:
  ##   scale: Scaling factor to apply to the processed value
  control.cppSetScale(scale.cfloat)

proc setOffset*(control: var AnalogControl, offset: float) =
  ## Set the offset used by the process function.
  ## 
  ## Normally set during initialization, but can be adjusted for calibration.
  ## 
  ## Parameters:
  ##   offset: Offset to add to the processed value
  control.cppSetOffset(offset.cfloat)

proc getRawValue*(control: var AnalogControl): uint16 =
  ## Get the raw unsigned 16-bit ADC value.
  ## 
  ## Returns:
  ##   Raw ADC value (0 to 65535)
  control.cppGetRawValue()

proc getRawFloat*(control: var AnalogControl): float =
  ## Get a normalized float representing the raw ADC value.
  ## 
  ## Returns:
  ##   Normalized raw value (0.0 to 1.0)
  control.cppGetRawFloat()

proc setSampleRate*(control: var AnalogControl, sampleRate: float) =
  ## Set a new sample rate after initialization.
  ## 
  ## Parameters:
  ##   sampleRate: New update rate in Hz
  control.cppSetSampleRate(sampleRate.cfloat)

# ADC wrapper type for cleaner API - using fixed-size array instead of seq
const MAX_ADC_CHANNELS = 16

type
  AdcReader* = object
    configs: array[MAX_ADC_CHANNELS, AdcChannelConfig]
    daisy: ptr DaisySeed
    numChannels: int

proc initAdc*(daisy: var DaisySeed, pins: openArray[Pin], 
              oversampling: int = 4): AdcReader =
  ## Initialize ADC for reading analog inputs
  ## 
  ## Parameters:
  ##   daisy: The DaisySeed instance
  ##   pins: Array of analog pins to read (e.g., [A0(), A1(), A2()])
  ##   oversampling: Oversampling rate (0=NONE, 1=4x, 2=8x, 3=16x, 4=32x (default), 5=64x, etc.)
  ## 
  ## Example:
  ## ```nim
  ## var adc = initAdc(daisy, [A0(), A1(), A6()])
  ## adc.start()
  ## let knob1Value = adc.value(0)  # Read first channel
  ## ```
  result.daisy = addr daisy
  result.numChannels = pins.len
  
  if pins.len > MAX_ADC_CHANNELS:
    # In embedded systems, we can't really handle this error gracefully
    # Just limit to max channels
    result.numChannels = MAX_ADC_CHANNELS
  
  for i in 0..<result.numChannels:
    result.configs[i] = cppNewAdcChannelConfig()
    result.configs[i].cppInitSingle(pins[i])
  
  if result.numChannels > 0:
    daisy.cppInitAdc(addr result.configs[0], result.numChannels.csize_t, cast[OverSampling](oversampling))

proc start*(adc: var AdcReader) =
  ## Start ADC conversions
  adc.daisy[].cppStartAdc()

proc stop*(adc: var AdcReader) =
  ## Stop ADC conversions
  adc.daisy[].cppStopAdc()

proc rawValue*(adc: var AdcReader, channel: int): uint16 =
  ## Get raw ADC value (0-65535) for a channel
  adc.daisy[].cppGetAdc(channel.uint8)

proc value*(adc: var AdcReader, channel: int): float =
  ## Get normalized ADC value (0.0-1.0) for a channel
  adc.daisy[].cppGetAdcFloat(channel.uint8)

when isMainModule:
  echo "libDaisy Controls wrapper - Clean API"
