## nimphea_petal
## ===============
##
## Nim wrapper for Electro-Smith Daisy Petal development board.
##
## The Daisy Petal is a guitar pedal platform featuring:
## - 6 potentiometers (knobs)
## - 1 expression pedal input
## - 7 switches (4 footswitches + 3 toggles)
## - Rotary encoder with button
## - 8 RGB ring LEDs
## - 4 footswitch LEDs
## - Audio I/O (stereo, instrument level)
## - USB for programming/power
##
## **Hardware Overview:**
## - Based on Daisy Seed (STM32H750, 480MHz ARM Cortex-M7)
## - Guitar pedal form factor (Hammond 1590BB enclosure)
## - Perfect for guitar effects, loopers, synth pedals
##
## **Example - Simple effect:**
## ```nim
## import boards/daisy_petal
##
## var petal: DaisyPetal
## petal.init()
##
## proc audioCallback(input: ptr ptr float32, output: ptr ptr float32, size: csize_t) =
##   let gain = petal.getKnobValue(KNOB_1.cint)
##   
##   for i in 0..<size:
##     output[0][i] = input[0][i] * gain  # Left
##     output[1][i] = input[1][i] * gain  # Right
##
## petal.startAudio(audioCallback)
##
## while true:
##   petal.processAllControls()
##   
##   # Knobs control RGB ring LED brightness
##   let brightness = petal.getKnobValue(KNOB_1.cint)
##   petal.setRingLed(RING_LED_1.cint, brightness, 0.0, 0.0)
##   
##   petal.updateLeds()
##   petal.seed.delay(10)
## ```
##
## **Example - Footswitch control:**
## ```nim
## while true:
##   petal.processDigitalControls()
##   
##   if petal.switches[SW_1.int].risingEdge():
##     # Footswitch 1 pressed
##     petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, 1.0)
##   
##   if petal.switches[SW_1.int].fallingEdge():
##     # Footswitch 1 released
##     petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, 0.0)
##   
##   petal.updateLeds()
## ```

import nimphea
import nimphea_macros
import hid/switch
import hid/led
import hid/rgb_led
import dev/leddriver

export switch  # Export Switch methods
export leddriver  # Export LED driver methods

useNimpheaModules(petal)

{.push header: "daisy_petal.h".}

type
  Encoder* {.importcpp: "daisy::Encoder",
             header: "hid/encoder.h".} = object
    ## Rotary encoder with integrated button

  PetalSwitch* {.importcpp: "daisy::DaisyPetal::Sw", size: sizeof(cint).} = enum
    ## Switch identifiers
    ##
    ## **Footswitches (momentary):**
    ## - SW_1 through SW_4: Four stomp switches
    ##
    ## **Toggle switches:**
    ## - SW_5 through SW_7: Three SPDT toggle switches
    SW_1 = 0  ## Footswitch 1 (bottom-left)
    SW_2 = 1  ## Footswitch 2 (bottom-right)
    SW_3 = 2  ## Footswitch 3 (top-left)
    SW_4 = 3  ## Footswitch 4 (top-right)
    SW_5 = 4  ## Toggle switch 1 (left panel)
    SW_6 = 5  ## Toggle switch 2 (center panel)
    SW_7 = 6  ## Toggle switch 3 (right panel)
  
  PetalKnob* {.importcpp: "daisy::DaisyPetal::Knob", size: sizeof(cint).} = enum
    ## Knob (potentiometer) identifiers
    ##
    ## Layout: Top row left to right, then bottom row left to right
    KNOB_1 = 0  ## Top-left knob
    KNOB_2 = 1  ## Top-center-left knob
    KNOB_3 = 2  ## Top-center-right knob
    KNOB_4 = 3  ## Top-right knob
    KNOB_5 = 4  ## Bottom-left knob
    KNOB_6 = 5  ## Bottom-right knob
  
  PetalRingLed* {.importcpp: "daisy::DaisyPetal::RingLed", size: sizeof(cint).} = enum
    ## RGB ring LED identifiers
    ##
    ## 8 RGB LEDs arranged in a ring around the encoder
    RING_LED_1 = 0  ## Ring LED 1 (12 o'clock position)
    RING_LED_2 = 1  ## Ring LED 2 (1:30 position)
    RING_LED_3 = 2  ## Ring LED 3 (3 o'clock position)
    RING_LED_4 = 3  ## Ring LED 4 (4:30 position)
    RING_LED_5 = 4  ## Ring LED 5 (6 o'clock position)
    RING_LED_6 = 5  ## Ring LED 6 (7:30 position)
    RING_LED_7 = 6  ## Ring LED 7 (9 o'clock position)
    RING_LED_8 = 7  ## Ring LED 8 (10:30 position)
  
  PetalFootswitchLed* {.importcpp: "daisy::DaisyPetal::FootswitchLed", size: sizeof(cint).} = enum
    ## Footswitch LED identifiers
    ##
    ## One LED per footswitch (white LED)
    FOOTSWITCH_LED_1 = 0  ## Footswitch 1 LED
    FOOTSWITCH_LED_2 = 1  ## Footswitch 2 LED
    FOOTSWITCH_LED_3 = 2  ## Footswitch 3 LED
    FOOTSWITCH_LED_4 = 3  ## Footswitch 4 LED
  
  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/expression pedal) wrapper
  
  DaisyPetal* {.importcpp: "daisy::DaisyPetal".} = object
    ## Daisy Petal board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Petal platform.
    seed*: DaisySeed                        ## Underlying Seed board
    encoder*: Encoder                             ## Rotary encoder with button
    knob*: array[6, AnalogControl]                ## 6 potentiometers
    expression*: AnalogControl                    ## Expression pedal input
    switches*: array[7, switch.Switch]   ## 7 switches (4 footswitches + 3 toggles)
    ring_led*: array[8, RgbLed]                   ## 8 RGB ring LEDs
    footswitch_led*: array[4, Led]                ## 4 footswitch LEDs

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyPetal, boost: bool = false)
  {.importcpp: "#.Init(#)".} =
  ## Initialize the Daisy Petal board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (AK4556, 24-bit/48kHz)
  ## - ADC for knobs and expression pedal
  ## - Encoder (rotary with button)
  ## - Switches (footswitches and toggles)
  ## - LED drivers (PCA9685, for ring and footswitch LEDs)
  ##
  ## **Parameters:**
  ## - `boost` - Enable CPU boost mode (480MHz, default is 400MHz)
  ##
  ## **Note:** Audio and ADC must be started separately with
  ## `startAudio()` and `startAdc()`.
  discard

proc delayMs*(this: var DaisyPetal, del: csize_t)
  {.importcpp: "#.DelayMs(#)".} =
  ## Delay execution for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Delay time in milliseconds
  discard

# ============================================================================
# Audio Control
# ============================================================================

# Audio callback type aliases (from nimphea)
type
  AudioCallback* = proc(input: ptr ptr float32, output: ptr ptr float32, size: csize_t) {.cdecl.}
  InterleavingAudioCallback* = proc(input: ptr float32, output: ptr float32, size: csize_t) {.cdecl.}

# Board-specific audio callback globals (to avoid conflicts with other boards)
var globalPetalAudioCallback: AudioCallback = nil
var globalPetalInterleavingCallback: InterleavingAudioCallback = nil

proc petalAudioCallbackWrapper(input: ptr ptr float32, output: ptr ptr float32, size: csize_t) {.exportc: "petalAudioCallbackWrapper", cdecl.} =
  if not globalPetalAudioCallback.isNil:
    globalPetalAudioCallback(input, output, size)

proc petalInterleavingAudioCallbackWrapper(input: ptr float32, output: ptr float32, size: csize_t) {.exportc: "petalInterleavingAudioCallbackWrapper", cdecl.} =
  if not globalPetalInterleavingCallback.isNil:
    globalPetalInterleavingCallback(input, output, size)

proc startAudio*(this: var DaisyPetal, callback: AudioCallback) =
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
  ## proc myCallback(input: ptr ptr float32, output: ptr ptr float32, size: csize_t) =
  ##   for i in 0..<size:
  ##     output[0][i] = input[0][i] * 0.5  # Left channel
  ##     output[1][i] = input[1][i] * 0.5  # Right channel
  ## 
  ## petal.startAudio(myCallback)
  ## ```
  globalPetalAudioCallback = callback
  {.emit: "`this`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(petalAudioCallbackWrapper));".}

proc startAudio*(this: var DaisyPetal, callback: InterleavingAudioCallback) =
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
  globalPetalInterleavingCallback = callback
  {.emit: "`this`.StartAudio(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(petalInterleavingAudioCallbackWrapper));".}

proc changeAudioCallback*(this: var DaisyPetal, callback: AudioCallback) =
  ## Change audio callback function while audio is running
  ##
  ## **Parameters:**
  ## - `callback` - New callback function
  globalPetalAudioCallback = callback
  {.emit: "`this`.ChangeAudioCallback(reinterpret_cast<daisy::AudioHandle::AudioCallback>(petalAudioCallbackWrapper));".}

proc changeAudioCallback*(this: var DaisyPetal, callback: InterleavingAudioCallback) =
  ## Change audio callback function while audio is running (interleaved version)
  ##
  ## **Parameters:**
  ## - `callback` - New interleaved callback function
  globalPetalInterleavingCallback = callback
  {.emit: "`this`.ChangeAudioCallback(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(petalInterleavingAudioCallbackWrapper));".}

proc stopAudio*(this: var DaisyPetal)
  {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  ##
  ## Stops the audio callback from being called.
  discard

proc setAudioSampleRate*(this: var DaisyPetal, samplerate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Set audio sample rate
  ##
  ## **Parameters:**
  ## - `samplerate` - Desired sample rate (e.g., SAI_48KHZ, SAI_96KHZ)
  ##
  ## **Note:** Audio must be stopped before changing sample rate.
  discard

proc audioSampleRate*(this: var DaisyPetal): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Get current audio sample rate in Hz
  ##
  ## **Returns:** Sample rate as floating point (e.g., 48000.0)
  discard

proc setAudioBlockSize*(this: var DaisyPetal, size: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Set audio block size (samples per channel per callback)
  ##
  ## **Parameters:**
  ## - `size` - Block size in samples (default: 48)
  ##
  ## **Note:** Audio must be stopped before changing block size.
  discard

proc audioBlockSize*(this: var DaisyPetal): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Get current audio block size
  ##
  ## **Returns:** Samples per channel per callback
  discard

proc audioCallbackRate*(this: var DaisyPetal): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Get audio callback rate in Hz
  ##
  ## **Returns:** Callback frequency (sampleRate / blockSize)
  discard

# ============================================================================
# ADC Control
# ============================================================================

proc startAdc*(this: var DaisyPetal)
  {.importcpp: "#.StartAdc()".} =
  ## Start analog-to-digital conversion for knobs and expression pedal
  ##
  ## **Note:** Must be called before reading knob/expression values.
  discard

proc stopAdc*(this: var DaisyPetal)
  {.importcpp: "#.StopAdc()".} =
  ## Stop analog-to-digital conversion
  discard

proc processAnalogControls*(this: var DaisyPetal)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Process analog control inputs (knobs and expression pedal)
  ##
  ## Updates internal state of all knobs and expression pedal.
  ## **Call regularly in main loop** (e.g., every 1ms) for stable readings.
  ##
  ## **Example:**
  ## ```nim
  ## while true:
  ##   petal.processAnalogControls()
  ##   let knob1 = petal.getKnobValue(KNOB_1.cint)
  ##   petal.delayMs(1)
  ## ```
  discard

proc processDigitalControls*(this: var DaisyPetal)
  {.importcpp: "#.ProcessDigitalControls()".} =
  ## Process digital control inputs (switches and encoder)
  ##
  ## Updates internal state of all switches and encoder.
  ## **Call regularly in main loop** for edge detection.
  ##
  ## **Example:**
  ## ```nim
  ## while true:
  ##   petal.processDigitalControls()
  ##   
  ##   if petal.switches[SW_1.int].risingEdge():
  ##     echo "Footswitch 1 pressed!"
  ##   
  ##   petal.delayMs(1)
  ## ```
  discard

proc processAllControls*(this: var DaisyPetal)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Process all control inputs (analog and digital)
  ##
  ## **Convenience method.** Equivalent to:
  ## ```nim
  ## petal.processAnalogControls()
  ## petal.processDigitalControls()
  ## ```
  ##
  ## **Call regularly in main loop** (e.g., every 1ms).
  discard

proc getKnobValue*(this: var DaisyPetal, k: cint): cfloat
  {.importcpp: "#.GetKnobValue(#)".} =
  ## Get knob value as normalized float
  ##
  ## **Parameters:**
  ## - `k` - Knob index (cast PetalKnob to cint: KNOB_1.cint)
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Example:**
  ## ```nim
  ## let gain = petal.getKnobValue(KNOB_1.cint)
  ## let freq = petal.getKnobValue(KNOB_2.cint) * 1000.0  # 0-1000 Hz
  ## ```
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  discard

proc getExpression*(this: var DaisyPetal): cfloat
  {.importcpp: "#.GetExpression()".} =
  ## Get expression pedal value as normalized float
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Example:**
  ## ```nim
  ## let volume = petal.getExpression()
  ## output = input * volume  # Expression pedal controls volume
  ## ```
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  discard

# ============================================================================
# LED Control
# ============================================================================

proc clearLeds*(this: var DaisyPetal)
  {.importcpp: "#.ClearLeds()".} =
  ## Turn all LEDs off (ring LEDs and footswitch LEDs)
  ##
  ## **Note:** Must call `updateLeds()` to apply changes.
  ##
  ## **Example:**
  ## ```nim
  ## petal.clearLeds()
  ## petal.updateLeds()  # Apply the changes
  ## ```
  discard

proc updateLeds*(this: var DaisyPetal)
  {.importcpp: "#.UpdateLeds()".} =
  ## Update LED hardware to reflect current LED states
  ##
  ## **Must be called** after `setRingLed()` or `setFootswitchLed()` to
  ## actually change the physical LEDs.
  ##
  ## **Example:**
  ## ```nim
  ## petal.setRingLed(RING_LED_1.cint, 1.0, 0.0, 0.0)  # Set to red
  ## petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, 1.0)  # Turn on
  ## petal.updateLeds()  # Apply all changes at once
  ## ```
  discard

proc setRingLed*(this: var DaisyPetal, idx: cint, r: cfloat, g: cfloat, b: cfloat)
  {.importcpp: "#.SetRingLed(#, #, #, #)".} =
  ## Set RGB ring LED color
  ##
  ## **Parameters:**
  ## - `idx` - LED index (cast PetalRingLed to cint: RING_LED_1.cint)
  ## - `r` - Red component (0.0 to 1.0)
  ## - `g` - Green component (0.0 to 1.0)
  ## - `b` - Blue component (0.0 to 1.0)
  ##
  ## **Note:** Must call `updateLeds()` to apply changes.
  ##
  ## **Example:**
  ## ```nim
  ## # Set ring LED 1 to purple
  ## petal.setRingLed(RING_LED_1.cint, 1.0, 0.0, 1.0)
  ## 
  ## # Set ring LED 2 to white at 50% brightness
  ## petal.setRingLed(RING_LED_2.cint, 0.5, 0.5, 0.5)
  ## 
  ## petal.updateLeds()  # Apply changes
  ## ```
  discard

proc setFootswitchLed*(this: var DaisyPetal, idx: cint, bright: cfloat)
  {.importcpp: "#.SetFootswitchLed(#, #)".} =
  ## Set footswitch LED brightness
  ##
  ## **Parameters:**
  ## - `idx` - LED index (cast PetalFootswitchLed to cint: FOOTSWITCH_LED_1.cint)
  ## - `bright` - Brightness (0.0 = off, 1.0 = full brightness)
  ##
  ## **Note:** Must call `updateLeds()` to apply changes.
  ##
  ## **Example:**
  ## ```nim
  ## # Turn on footswitch LED 1 at full brightness
  ## petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, 1.0)
  ## 
  ## # Set footswitch LED 2 to 25% brightness
  ## petal.setFootswitchLed(FOOTSWITCH_LED_2.cint, 0.25)
  ## 
  ## petal.updateLeds()  # Apply changes
  ## ```
  discard

# ============================================================================
# Encoder Control
# ============================================================================

proc increment*(enc: var Encoder): int32
  {.importcpp: "#.Increment()", header: "hid/encoder.h".} =
  ## Get encoder increment since last call
  ##
  ## **Returns:** Number of clicks (positive = clockwise, negative = counter-clockwise)
  ##
  ## **Example:**
  ## ```nim
  ## let delta = petal.encoder.increment()
  ## value += delta  # Update value based on encoder rotation
  ## ```
  discard

proc pressed*(enc: var Encoder): bool
  {.importcpp: "#.Pressed()", header: "hid/encoder.h".} =
  ## Check if encoder button is currently pressed
  ##
  ## **Returns:** True if button is pressed, false otherwise
  discard

proc risingEdge*(enc: var Encoder): bool
  {.importcpp: "#.RisingEdge()", header: "hid/encoder.h".} =
  ## Check if encoder button has rising edge (just pressed)
  ##
  ## **Returns:** True on the first call after button press
  ##
  ## **Example:**
  ## ```nim
  ## if petal.encoder.risingEdge():
  ##   echo "Encoder button pressed!"
  ## ```
  discard

proc fallingEdge*(enc: var Encoder): bool
  {.importcpp: "#.FallingEdge()", header: "hid/encoder.h".} =
  ## Check if encoder button has falling edge (just released)
  ##
  ## **Returns:** True on the first call after button release
  discard
