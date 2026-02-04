## DaisyLegio
## ===========
## 
## Wrapper for the Daisy Legio Eurorack module (Virt Iter Legio by Olivia Artz Modular + Noise Engineering).
## 
## **Hardware Overview**:
## - Compact Eurorack utility module
## - Audio I/O: Stereo in/out (24-bit, up to 96kHz)
## - Controls: 1 encoder, 3 CV inputs (pitch + 2 knobs), 1 gate input
## - Switches: 2 three-position switches
## - LEDs: 2 RGB LEDs (PWM controlled)
## 
## **Key Features**:
## - Encoder with button for menu navigation
## - CV inputs for pitch and modulation
## - Gate input for triggering
## - Three-position switches for mode selection
## 
## **Usage Example**:
## ```nim
## import nimphea
## import boards/daisy_legio
## 
## proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
##   for i in 0..<size:
##     let inL = input[0][i]
##     let inR = input[1][i]
##     output[0][i] = inL
##     output[1][i] = inR
## 
## proc main() =
##   var legio: DaisyLegio
##   legio.init()
##   legio.startAudio(audioCallback)
##   
##   while true:
##     legio.processAllControls()
##     
##     # Read encoder
##     let increment = legio.encoder.increment()
##     let pressed = legio.encoder.pressed()
##     
##     # Read CV inputs
##     let pitch = legio.getKnobValue(CONTROL_PITCH.cint)
##     let knobTop = legio.getKnobValue(CONTROL_KNOB_TOP.cint)
##     let knobBottom = legio.getKnobValue(CONTROL_KNOB_BOTTOM.cint)
##     
##     # Update LEDs
##     legio.setLed(LED_LEFT.csize_t, pitch, 0.0, 0.0)
##     legio.setLed(LED_RIGHT.csize_t, 0.0, knobTop, knobBottom)
##     legio.updateLeds()
##     
##     legio.delayMs(10)
## 
## when isMainModule:
##   main()
## ```

import nimphea
import nimphea_macros
import hid/rgb_led
import hid/gatein

useNimpheaModules(legio)

{.push header: "daisy_legio.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  LegioLed* {.importcpp: "daisy::DaisyLegio::LEGIO_LEDS",
              size: sizeof(cint).} = enum
    ## LED identifiers (2 RGB LEDs)
    LED_LEFT = 0
    LED_RIGHT = 1
    LED_LAST = 2

  LegioControl* {.importcpp: "daisy::DaisyLegio::LEGIO_CONTROLS",
                  size: sizeof(cint).} = enum
    ## Control input identifiers (3 CV inputs)
    CONTROL_PITCH = 0
    CONTROL_KNOB_TOP = 1
    CONTROL_KNOB_BOTTOM = 2
    CONTROL_LAST = 3

  LegioSwitch* {.importcpp: "daisy::DaisyLegio::LEGIO_TOGGLE3",
                 size: sizeof(cint).} = enum
    ## Three-position switch identifiers (2 switches)
    SW_LEFT = 0
    SW_RIGHT = 1
    SW_LAST = 2

  # Types that aren't in separate modules - define inline
  Encoder* {.importcpp: "daisy::Encoder",
             header: "hid/encoder.h".} = object
    ## Quadrature encoder with button

  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/CV input) wrapper

  Switch3* {.importcpp: "daisy::Switch3",
            header: "hid/switch3.h".} = object
    ## Three-position switch

  DaisyLegio* {.importcpp: "daisy::DaisyLegio".} = object
    ## Daisy Legio board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Legio platform.
    seed*: DaisySeed                               ## Underlying Seed board
    encoder*: Encoder                              ## Rotary encoder with button
    gate*: GateIn                                  ## Gate input
    leds*: array[2, RgbLed]                        ## 2 RGB LEDs (PWM controlled)
    controls*: array[3, AnalogControl]             ## 3 CV inputs (pitch + 2 knobs)
    sw*: array[2, Switch3]                         ## 2 three-position switches

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyLegio, boost: bool = false)
  {.importcpp: "#.Init(#)".} =
  ## Initialize the Daisy Legio board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (AK4556, 24-bit/48kHz)
  ## - ADC inputs for CV
  ## - Gate input
  ## - Encoder
  ## - RGB LEDs (PWM)
  ## - Three-position switches
  ##
  ## **Parameters:**
  ## - `boost` - Enable CPU boost mode (400MHz, default: false for 480MHz)

proc delayMs*(this: var DaisyLegio, del: csize_t)
  {.importcpp: "#.DelayMs(#)".} =
  ## Delay for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Delay time in milliseconds

# ============================================================================
# Audio Control
# ============================================================================

# Global audio callback (board-specific to avoid conflicts)
var globalLegioAudioCallback: AudioCallback = nil

proc legioAudioCallbackWrapper(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.exportc: "legioAudioCallbackWrapper", cdecl.} =
  ## C-compatible wrapper for Nim audio callback
  if not globalLegioAudioCallback.isNil:
    globalLegioAudioCallback(cast[AudioBuffer](input),
                            cast[AudioBuffer](output),
                            size.int)

proc startAudio*(this: var DaisyLegio, callback: AudioCallback) =
  ## Start audio processing with callback
  ##
  ## **Parameters:**
  ## - `callback` - Audio callback function (non-interleaved stereo: `proc(input, output: AudioBuffer, size: int)`)
  ##
  ## **Example:**
  ## ```nim
  ## proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ##   for i in 0..<size:
  ##     let inL = input[0][i]
  ##     let inR = input[1][i]
  ##     output[0][i] = inL
  ##     output[1][i] = inR
  ## 
  ## legio.startAudio(audioCallback)
  ## ```
  globalLegioAudioCallback = callback
  {.emit: "`this`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(legioAudioCallbackWrapper));".}

proc stopAudio*(this: var DaisyLegio)
  {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing

proc setAudioBlockSize*(this: var DaisyLegio, size: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Set audio callback block size (samples per channel)
  ##
  ## **Parameters:**
  ## - `size` - Number of samples per channel (default: 48)

proc audioBlockSize*(this: var DaisyLegio): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Get current audio callback block size
  ##
  ## **Returns:** Samples per channel

proc setAudioSampleRate*(this: var DaisyLegio, samplerate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Set audio sample rate (audio must be stopped first)
  ##
  ## **Parameters:**
  ## - `samplerate` - Sample rate (SAI_48KHZ, SAI_96KHZ, etc.)

proc audioSampleRate*(this: var DaisyLegio): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Get current audio sample rate in Hz
  ##
  ## **Returns:** Sample rate as float (e.g., 48000.0)

proc audioCallbackRate*(this: var DaisyLegio): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Get audio callback rate in Hz
  ##
  ## **Returns:** Callback rate (samplerate / blocksize)

# ============================================================================
# ADC Control
# ============================================================================

proc startAdc*(this: var DaisyLegio)
  {.importcpp: "#.StartAdc()".} =
  ## Start analog-to-digital conversion for CV inputs
  ##
  ## Must be called to enable CV input reading.

proc stopAdc*(this: var DaisyLegio)
  {.importcpp: "#.StopAdc()".} =
  ## Stop analog-to-digital conversion

# ============================================================================
# Control Input Processing
# ============================================================================

proc processDigitalControls*(this: var DaisyLegio)
  {.importcpp: "#.ProcessDigitalControls()".} =
  ## Update encoder and switch states
  ##
  ## Call once per main loop iteration.

proc processAnalogControls*(this: var DaisyLegio)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Normalize CV inputs to range (0.0, 1.0)
  ##
  ## Call once per main loop iteration.

proc processAllControls*(this: var DaisyLegio)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Update all controls (digital + analog)
  ##
  ## Convenience function that calls both:
  ## - `processDigitalControls()`
  ## - `processAnalogControls()`

# ============================================================================
# Gate Input
# ============================================================================

proc gate*(this: var DaisyLegio): bool
  {.importcpp: "#.Gate()".} =
  ## Read gate input state
  ##
  ## **Returns:** `true` if gate is HIGH, `false` if LOW

# ============================================================================
# LED Control
# ============================================================================

proc setLed*(this: var DaisyLegio, idx: csize_t, red: cfloat, green: cfloat, blue: cfloat)
  {.importcpp: "#.SetLed(#, #, #, #)".} =
  ## Set RGB LED color
  ##
  ## **Parameters:**
  ## - `idx` - LED index (LED_LEFT, LED_RIGHT)
  ## - `red` - Red brightness (0.0 to 1.0)
  ## - `green` - Green brightness (0.0 to 1.0)
  ## - `blue` - Blue brightness (0.0 to 1.0)
  ##
  ## **Example:**
  ## ```nim
  ## legio.setLed(LED_LEFT.csize_t, 1.0, 0.0, 0.0)  # Bright red
  ## ```

proc updateLeds*(this: var DaisyLegio)
  {.importcpp: "#.UpdateLeds()".} =
  ## Update LED PWM state
  ##
  ## Must be called after `setLed()` to apply changes.
  ## Call once per main loop iteration.

# ============================================================================
# Analog Control Reading
# ============================================================================

proc getKnobValue*(this: var DaisyLegio, idx: cint): cfloat
  {.importcpp: "#.GetKnobValue(#)".} =
  ## Read normalized CV input value
  ##
  ## **Parameters:**
  ## - `idx` - Control index (CONTROL_PITCH, CONTROL_KNOB_TOP, CONTROL_KNOB_BOTTOM)
  ##
  ## **Returns:** Normalized value (0.0 to 1.0)
  ##
  ## **Note:** Call `processAnalogControls()` first to update values.
  ##
  ## **Example:**
  ## ```nim
  ## let pitch = legio.getKnobValue(CONTROL_PITCH.cint)
  ## let knobTop = legio.getKnobValue(CONTROL_KNOB_TOP.cint)
  ## ```

# ============================================================================
# Encoder Methods (Direct Access)
# ============================================================================

proc increment*(this: var Encoder): cint
  {.importcpp: "#.Increment()".} =
  ## Read encoder rotation since last call
  ##
  ## **Returns:** Number of clicks (positive = clockwise, negative = counter-clockwise)
  ##
  ## **Example:**
  ## ```nim
  ## let delta = legio.encoder.increment()
  ## if delta > 0:
  ##   echo "Rotated clockwise"
  ## elif delta < 0:
  ##   echo "Rotated counter-clockwise"
  ## ```

proc pressed*(this: var Encoder): bool
  {.importcpp: "#.Pressed()".} =
  ## Check if encoder button is currently pressed
  ##
  ## **Returns:** `true` if button is pressed, `false` otherwise

proc risingEdge*(this: var Encoder): bool
  {.importcpp: "#.RisingEdge()".} =
  ## Check if encoder button was just pressed (rising edge)
  ##
  ## **Returns:** `true` on the first frame of button press, `false` otherwise

proc fallingEdge*(this: var Encoder): bool
  {.importcpp: "#.FallingEdge()".} =
  ## Check if encoder button was just released (falling edge)
  ##
  ## **Returns:** `true` on the first frame of button release, `false` otherwise

# ============================================================================
# Switch3 Methods (Direct Access)
# ============================================================================

proc read*(this: var Switch3): cint
  {.importcpp: "#.Read()".} =
  ## Read three-position switch state
  ##
  ## **Returns:**
  ## - `0` - Down position
  ## - `1` - Center position  
  ## - `2` - Up position
  ##
  ## **Example:**
  ## ```nim
  ## let swPos = legio.sw[0].read()
  ## case swPos
  ## of 0: echo "Down"
  ## of 1: echo "Center"
  ## of 2: echo "Up"
  ## else: discard
  ## ```

# ============================================================================
# Hardware Test Function
# ============================================================================

proc updateExample*(this: var DaisyLegio)
  {.importcpp: "#.UpdateExample()".} =
  ## Hardware test function
  ##
  ## Tests all inputs and outputs:
  ## - Each input (gate, encoder, switches, CV) changes LED colors
  ##
  ## Call once per main loop for hardware verification.
