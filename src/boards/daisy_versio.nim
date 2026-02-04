## nimphea_versio
## ================
##
## Nim wrapper for Electro-Smith Daisy Versio (Noise Engineering) development board.
##
## The Daisy Versio is a compact Eurorack DSP module featuring:
## - 7 knobs/CV inputs (0-5V)
## - 2 three-position switches
## - 1 momentary tap switch
## - 1 gate input
## - 4 RGB LEDs (PWM controlled)
## - Audio I/O (stereo, Eurorack level)
## - USB for programming/power
##
## **Hardware Overview:**
## - Based on Daisy Seed (STM32H750, 480MHz ARM Cortex-M7)
## - Compact Eurorack form factor (10HP)
## - Perfect for effects, delays, reverbs, filters
##
## **Example - Simple LED control:**
## ```nim
## import boards/daisy_versio
##
## var versio: DaisyVersio
## versio.init()
## versio.startAdc()
##
## while true:
##   versio.processAllControls()
##   
##   # Knobs control LED colors
##   let red = versio.getKnobValue(KNOB_0.cint)
##   let green = versio.getKnobValue(KNOB_1.cint)
##   let blue = versio.getKnobValue(KNOB_2.cint)
##   
##   versio.setLed(LED_0.cint, red, green, blue)
##   versio.updateLeds()
##   
##   versio.delayMs(10)
## ```
##
## **Example - Audio processing:**
## ```nim
## proc audioCallback(input: ptr float32, output: ptr float32, size: csize_t) {.cdecl.} =
##   for i in 0..<size:
##     var sample: cfloat
##     {.emit: "`sample` = `input`[`i`];".}
##     
##     # Process audio
##     sample = sample * 0.5
##     
##     {.emit: "`output`[`i`] = `sample`;".}
##
## versio.startAudio(audioCallback)
## ```

import nimphea
import nimphea_macros
import hid/switch
import hid/rgb_led
import hid/gatein

export switch  # Export Switch methods
export gatein  # Export GateIn methods

useNimpheaModules(versio)

{.push header: "daisy_versio.h".}

type
  VersioLed* {.importcpp: "daisy::DaisyVersio::AV_LEDS", size: sizeof(cint).} = enum
    ## RGB LED identifiers
    ##
    ## 4 RGB LEDs arranged on the panel
    LED_0 = 0  ## LED 0 (top-left)
    LED_1 = 1  ## LED 1 (top-right)
    LED_2 = 2  ## LED 2 (bottom-left)
    LED_3 = 3  ## LED 3 (bottom-right)
  
  VersioKnob* {.importcpp: "daisy::DaisyVersio::AV_KNOBS", size: sizeof(cint).} = enum
    ## Knob/CV input identifiers
    ##
    ## 7 knobs with CV inputs (0-5V)
    KNOB_0 = 0  ## Knob 0 (leftmost)
    KNOB_1 = 1  ## Knob 1
    KNOB_2 = 2  ## Knob 2
    KNOB_3 = 3  ## Knob 3
    KNOB_4 = 4  ## Knob 4
    KNOB_5 = 5  ## Knob 5
    KNOB_6 = 6  ## Knob 6 (rightmost)
  
  VersioSwitch* {.importcpp: "daisy::DaisyVersio::AV_TOGGLE3", size: sizeof(cint).} = enum
    ## Three-position switch identifiers
    ##
    ## 2 three-position switches (up/center/down)
    SW_0 = 0  ## Switch 0 (left)
    SW_1 = 1  ## Switch 1 (right)
  
  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/CV input) wrapper
  
  Switch3* {.importcpp: "daisy::Switch3",
             header: "hid/switch3.h".} = object
    ## Three-position switch
  
  DaisyVersio* {.importcpp: "daisy::DaisyVersio".} = object
    ## Daisy Versio board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Versio platform.
    seed*: DaisySeed                               ## Underlying Seed board
    leds*: array[4, RgbLed]                        ## 4 RGB LEDs (PWM controlled)
    knobs*: array[7, AnalogControl]                ## 7 knobs/CV inputs
    tap*: switch.Switch                   ## Momentary tap switch
    gate*: GateIn                                  ## Gate input
    sw*: array[2, Switch3]                         ## 2 three-position switches

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyVersio, boost: bool = false)
  {.importcpp: "#.Init(#)".} =
  ## Initialize the Daisy Versio board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (PCM3060, 24-bit/48kHz)
  ## - ADC for knobs/CV inputs
  ## - Switches (momentary and 3-position)
  ## - Gate input
  ## - RGB LEDs (PWM)
  ##
  ## **Parameters:**
  ## - `boost` - Enable CPU boost mode (480MHz, default is 400MHz)
  ##
  ## **Note:** Audio and ADC must be started separately with
  ## `startAudio()` and `startAdc()`.
  discard

proc delayMs*(this: var DaisyVersio, del: csize_t)
  {.importcpp: "#.DelayMs(#)".} =
  ## Delay execution for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Delay time in milliseconds
  discard

# ============================================================================
# Audio Control
# ============================================================================

# Board-specific audio callback globals (to avoid conflicts with other boards)
var globalVersioAudioCallback: AudioCallback = nil
var globalVersioInterleavingCallback: InterleavingAudioCallback = nil

proc versioAudioCallbackWrapper(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.exportc: "versioAudioCallbackWrapper", cdecl.} =
  if not globalVersioAudioCallback.isNil:
    globalVersioAudioCallback(cast[AudioBuffer](input),
                             cast[AudioBuffer](output),
                             size.int)

proc versioInterleavingAudioCallbackWrapper(input: ptr cfloat, output: ptr cfloat, size: csize_t) {.exportc: "versioInterleavingAudioCallbackWrapper", cdecl.} =
  if not globalVersioInterleavingCallback.isNil:
    globalVersioInterleavingCallback(cast[InterleavedAudioBuffer](input),
                                    cast[InterleavedAudioBuffer](output),
                                    size.int)

proc startAudio*(this: var DaisyVersio, callback: AudioCallback) =
  ## Start audio processing with multichannel callback
  ##
  ## **Parameters:**
  ## - `callback` - Function called at audio rate for processing
  ##
  ## **Callback signature:**
  ## ```nim
  ## proc(input: ptr ptr float32, output: ptr ptr float32, size: csize_t)
  ## ```
  ##
  ## **Example:**
  ## ```nim
  ## proc myCallback(input: ptr ptr float32, output: ptr ptr float32, size: csize_t) {.cdecl.} =
  ##   for i in 0..<size:
  ##     var inL, inR, outL, outR: cfloat
  ##     {.emit: "`inL` = `input`[0][`i`];".}
  ##     {.emit: "`inR` = `input`[1][`i`];".}
  ##     
  ##     outL = inL * 0.5
  ##     outR = inR * 0.5
  ##     
  ##     {.emit: "`output`[0][`i`] = `outL`;".}
  ##     {.emit: "`output`[1][`i`] = `outR`;".}
  ## 
  ## versio.startAudio(myCallback)
  ## ```
  globalVersioAudioCallback = callback
  {.emit: "`this`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(versioAudioCallbackWrapper));".}

proc startAudio*(this: var DaisyVersio, callback: InterleavingAudioCallback) =
  ## Start audio processing with interleaved callback
  ##
  ## **Parameters:**
  ## - `callback` - Function called at audio rate for processing
  ##
  ## **Callback signature:**
  ## ```nim
  ## proc(input: ptr float32, output: ptr float32, size: csize_t)
  ## ```
  ##
  ## **Note:** Size is total samples (stereo = size/2 frames)
  globalVersioInterleavingCallback = callback
  {.emit: "`this`.StartAudio(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(versioInterleavingAudioCallbackWrapper));".}

proc changeAudioCallback*(this: var DaisyVersio, callback: AudioCallback) =
  ## Change audio callback function while audio is running
  ##
  ## **Parameters:**
  ## - `callback` - New callback function
  globalVersioAudioCallback = callback
  {.emit: "`this`.ChangeAudioCallback(reinterpret_cast<daisy::AudioHandle::AudioCallback>(versioAudioCallbackWrapper));".}

proc changeAudioCallback*(this: var DaisyVersio, callback: InterleavingAudioCallback) =
  ## Change audio callback function while audio is running (interleaved version)
  ##
  ## **Parameters:**
  ## - `callback` - New interleaved callback function
  globalVersioInterleavingCallback = callback
  {.emit: "`this`.ChangeAudioCallback(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(versioInterleavingAudioCallbackWrapper));".}

proc stopAudio*(this: var DaisyVersio)
  {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  ##
  ## Stops the audio callback from being called.
  discard

proc setAudioBlockSize*(this: var DaisyVersio, size: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Set audio block size (samples per channel per callback)
  ##
  ## **Parameters:**
  ## - `size` - Block size in samples (default: 48)
  ##
  ## **Note:** Audio must be stopped before changing block size.
  discard

proc audioBlockSize*(this: var DaisyVersio): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Get current audio block size
  ##
  ## **Returns:** Samples per channel per callback
  discard

proc setAudioSampleRate*(this: var DaisyVersio, samplerate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Set audio sample rate
  ##
  ## **Parameters:**
  ## - `samplerate` - Desired sample rate (e.g., SAI_48KHZ, SAI_96KHZ)
  ##
  ## **Note:** Audio must be stopped before changing sample rate.
  discard

proc audioSampleRate*(this: var DaisyVersio): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Get current audio sample rate in Hz
  ##
  ## **Returns:** Sample rate as floating point (e.g., 48000.0)
  discard

proc audioCallbackRate*(this: var DaisyVersio): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Get audio callback rate in Hz
  ##
  ## **Returns:** Callback frequency (sampleRate / blockSize)
  discard

# ============================================================================
# ADC Control
# ============================================================================

proc startAdc*(this: var DaisyVersio)
  {.importcpp: "#.StartAdc()".} =
  ## Start analog-to-digital conversion for knobs/CV inputs
  ##
  ## **Note:** Must be called before reading knob values.
  discard

proc stopAdc*(this: var DaisyVersio)
  {.importcpp: "#.StopAdc()".} =
  ## Stop analog-to-digital conversion
  discard

proc processAnalogControls*(this: var DaisyVersio)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Process analog control inputs (knobs/CV)
  ##
  ## Updates internal state of all knobs.
  ## **Call regularly in main loop** (e.g., every 1ms) for stable readings.
  ##
  ## **Example:**
  ## ```nim
  ## while true:
  ##   versio.processAnalogControls()
  ##   let knob0 = versio.getKnobValue(KNOB_0.cint)
  ##   versio.delayMs(1)
  ## ```
  discard

proc processAllControls*(this: var DaisyVersio)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Process all control inputs (analog controls only for Versio)
  ##
  ## **Convenience method.** Equivalent to:
  ## ```nim
  ## versio.processAnalogControls()
  ## ```
  ##
  ## **Note:** Digital controls (switches, gate) are updated automatically.
  discard

proc getKnobValue*(this: var DaisyVersio, idx: cint): cfloat
  {.importcpp: "#.GetKnobValue(#)".} =
  ## Get knob value as normalized float
  ##
  ## **Parameters:**
  ## - `idx` - Knob index (cast VersioKnob to cint: KNOB_0.cint)
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Example:**
  ## ```nim
  ## let freq = versio.getKnobValue(KNOB_0.cint) * 1000.0  # 0-1000 Hz
  ## ```
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  discard

# ============================================================================
# Digital Input Control
# ============================================================================

proc switchPressed*(this: var DaisyVersio): bool
  {.importcpp: "#.SwitchPressed()".} =
  ## Check if momentary tap switch is pressed
  ##
  ## **Returns:** True if tap switch is pressed
  ##
  ## **Example:**
  ## ```nim
  ## if versio.switchPressed():
  ##   # Tap switch is pressed
  ##   discard
  ## ```
  discard

proc gate*(this: var DaisyVersio): bool
  {.importcpp: "#.Gate()".} =
  ## Check if gate input is high
  ##
  ## **Returns:** True if gate input is HIGH
  ##
  ## **Example:**
  ## ```nim
  ## if versio.gate():
  ##   # Gate is active
  ##   discard
  ## ```
  discard

# ============================================================================
# LED Control
# ============================================================================

proc setLed*(this: var DaisyVersio, idx: csize_t, red: cfloat, green: cfloat, blue: cfloat)
  {.importcpp: "#.SetLed(#, #, #, #)".} =
  ## Set RGB LED color
  ##
  ## **Parameters:**
  ## - `idx` - LED index (cast VersioLed to csize_t: LED_0.csize_t)
  ## - `red` - Red component (0.0 to 1.0)
  ## - `green` - Green component (0.0 to 1.0)
  ## - `blue` - Blue component (0.0 to 1.0)
  ##
  ## **Note:** Must call `updateLeds()` to apply changes.
  ##
  ## **Example:**
  ## ```nim
  ## # Set LED 0 to purple
  ## versio.setLed(LED_0.csize_t, 1.0, 0.0, 1.0)
  ## 
  ## # Set LED 1 to white at 50% brightness
  ## versio.setLed(LED_1.csize_t, 0.5, 0.5, 0.5)
  ## 
  ## versio.updateLeds()  # Apply changes
  ## ```
  discard

proc updateLeds*(this: var DaisyVersio)
  {.importcpp: "#.UpdateLeds()".} =
  ## Update LED hardware to reflect current LED states
  ##
  ## **Must be called** after `setLed()` to actually change the physical LEDs.
  ##
  ## **Example:**
  ## ```nim
  ## versio.setLed(LED_0.csize_t, 1.0, 0.0, 0.0)  # Set to red
  ## versio.updateLeds()  # Apply the change
  ## ```
  discard

# ============================================================================
# Switch3 (Three-position switch) Control
# ============================================================================

proc read*(sw: var Switch3): cint
  {.importcpp: "#.Read()", header: "hid/switch3.h".} =
  ## Read three-position switch state
  ##
  ## **Returns:** 
  ## - 0 = Down position
  ## - 1 = Center position
  ## - 2 = Up position
  ##
  ## **Example:**
  ## ```nim
  ## let sw0State = versio.sw[SW_0.int].read()
  ## if sw0State == 2:
  ##   echo "Switch 0 is in UP position"
  ## ```
  discard
