## nimphea_pod
## =============
##
## Nim wrapper for Electro-Smith Daisy Pod development board.
##
## The Daisy Pod is a desktop synth/effect platform featuring:
## - Rotary encoder with integrated button
## - 2 potentiometers (knobs)
## - 2 tactile buttons
## - 2 RGB LEDs
## - MIDI I/O (5-pin DIN)
## - Audio I/O (line level, 24-bit/48kHz)
## - USB for programming/power
##
## **Hardware Overview:**
## - Based on Daisy Seed (STM32H750, 480MHz ARM Cortex-M7)
## - Compact desktop enclosure with panel-mount controls
## - Perfect for tabletop synthesizers and effect processors
##
## **Example - Simple LED control:**
## ```nim
## import boards/daisy_pod
##
## var pod: DaisyPod
## pod.init()
##
## while true:
##   pod.processAllControls()
##   
##   let knob1 = pod.getKnobValue(KNOB_1)
##   let knob2 = pod.getKnobValue(KNOB_2)
##   
##   pod.led1.setColor(knob1, 0.0, 1.0 - knob1)
##   pod.led2.setColor(0.0, knob2, 1.0 - knob2)
##   pod.updateLeds()
##   
##   pod.seed.delay(10)
## ```
##
## **Example - With audio processing:**
## ```nim
## var pod: DaisyPod
## var gain: float32 = 0.5
##
## proc audioCallback(input, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
##   for i in 0..<size:
##     output[0][i] = input[0][i] * gain
##     output[1][i] = input[1][i] * gain
##
## proc main() =
##   pod.init()
##   pod.startAdc()
##   pod.startAudio(audioCallback)
##   
##   while true:
##     pod.processAllControls()
##     gain = pod.getKnobValue(KNOB_1)
##     pod.seed.delay(1)
## ```

import nimphea
import nimphea_macros
import hid/ctrl
import hid/rgb_led
{.push warning[UnusedImport]: off.}
import hid/midi  # Types used via importcpp (MidiUartTransport, MidiUartHandler)
{.pop.}

export rgb_led  # Export RgbLed methods for user convenience

useNimpheaModules(pod)

{.push header: "daisy_pod.h".}

type
  PodButton* = enum
    ## Button identifiers for DaisyPod
    BUTTON_1 = 0  ## Left button
    BUTTON_2 = 1  ## Right button

  PodKnob* = enum
    ## Knob identifiers for DaisyPod
    KNOB_1 = 0  ## Left knob
    KNOB_2 = 1  ## Right knob

  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/CV input) wrapper

  MidiUartTransport* {.importcpp: "daisy::MidiUartTransport",
                       header: "hid/midi.h".} = object
    ## MIDI UART transport

  MidiUartHandler* {.importcpp: "daisy::MidiHandler<daisy::MidiUartTransport>",
                     header: "hid/midi.h".} = object
    ## MIDI UART handler

  DaisyPod* {.importcpp: "daisy::DaisyPod".} = object
    ## Daisy Pod board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Pod platform.
    ## Access individual components as public members.
    seed*: DaisySeed            ## Underlying Seed board
    encoder*: Encoder           ## Rotary encoder with integrated button
    knob1*: AnalogControl       ## Left knob (pot)
    knob2*: AnalogControl       ## Right knob (pot)
    knobs*: array[2, ptr AnalogControl]   ## Array of pointers to knobs
    button1*: Switch            ## Left tactile button
    button2*: Switch            ## Right tactile button
    buttons*: array[2, ptr Switch]        ## Array of pointers to buttons
    led1*: RgbLed               ## Left RGB LED
    led2*: RgbLed               ## Right RGB LED
    midi*: MidiUartHandler      ## MIDI UART handler (5-pin DIN)

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyPod, boost: bool = false)
  {.importcpp: "#.Init(#)".} =
  ## Initialize the Daisy Pod board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (AK4556, 24-bit/48kHz)
  ## - ADC for knobs
  ## - Encoder with button
  ## - Switches
  ## - RGB LEDs
  ## - MIDI UART
  ##
  ## **Parameters:**
  ## - `boost` - Enable CPU boost mode (480MHz, default is 400MHz)
  ##
  ## **Note:** Audio and ADC must be started separately with
  ## `startAudio()` and `startAdc()`.
  discard

proc delayMs*(this: var DaisyPod, del: csize_t)
  {.importcpp: "#.DelayMs(#)".} =
  ## Delay execution for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Delay time in milliseconds
  ##
  ## **Note:** Blocking delay. For audio applications, prefer
  ## timing based on audio callback rate or use timers.
  discard

# ============================================================================
# Audio Control
# ============================================================================

# Global callback storage (one set per board type to avoid conflicts)
var globalPodAudioCallback: AudioCallback = nil
var globalPodInterleavingCallback: InterleavingAudioCallback = nil

# C-compatible wrapper functions
proc podAudioCallbackWrapper(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.exportc: "podAudioCallbackWrapper", cdecl.} =
  if not globalPodAudioCallback.isNil:
    globalPodAudioCallback(cast[AudioBuffer](input),
                          cast[AudioBuffer](output),
                          size.int)

proc podInterleavingCallbackWrapper(input: ptr cfloat, output: ptr cfloat, size: csize_t) {.exportc: "podInterleavingCallbackWrapper", cdecl.} =
  if not globalPodInterleavingCallback.isNil:
    globalPodInterleavingCallback(cast[InterleavedAudioBuffer](input),
                                 cast[InterleavedAudioBuffer](output),
                                 size.int)

proc startAudio*(pod: var DaisyPod, callback: AudioCallback) =
  ## Start audio processing with multi-channel (non-interleaved) callback
  ##
  ## The callback receives separate channels as arrays of float samples.
  ##
  ## **Example:**
  ## ```nim
  ## proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ##   for i in 0..<size:
  ##     output[0][i] = input[0][i] * 0.5  # Left channel
  ##     output[1][i] = input[1][i] * 0.5  # Right channel
  ##
  ## pod.startAudio(audioCallback)
  ## ```
  globalPodAudioCallback = callback
  {.emit: "`pod`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(podAudioCallbackWrapper));".}

proc startAudio*(pod: var DaisyPod, callback: InterleavingAudioCallback) =
  ## Start audio processing with interleaved callback
  ##
  ## The callback receives interleaved samples (L, R, L, R, ...)
  ##
  ## **Example:**
  ## ```nim
  ## proc audioCallback(input, output: InterleavedAudioBuffer, size: int) {.cdecl.} =
  ##   for i in 0..<size:
  ##     output[i * 2] = input[i * 2] * 0.5      # Left
  ##     output[i * 2 + 1] = input[i * 2 + 1] * 0.5  # Right
  ##
  ## pod.startAudio(audioCallback)
  ## ```
  globalPodInterleavingCallback = callback
  {.emit: "`pod`.StartAudio(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(podInterleavingCallbackWrapper));".}

proc changeAudioCallback*(pod: var DaisyPod, callback: AudioCallback) =
  ## Change the audio callback while audio is running
  globalPodAudioCallback = callback

proc changeAudioCallback*(pod: var DaisyPod, callback: InterleavingAudioCallback) =
  ## Change the interleaved audio callback while audio is running
  globalPodInterleavingCallback = callback

proc stopAudio*(pod: var DaisyPod) {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  globalPodAudioCallback = nil
  globalPodInterleavingCallback = nil

proc startAudio*(this: var DaisyPod, cb: AudioCallbackC)
  {.importcpp: "#.StartAudio(#)".} =
  ## Start audio processing with multi-channel callback
  ##
  ## **Parameters:**
  ## - `cb` - Audio callback function with separate channels
  ##
  ## **Callback signature:**
  ## ```nim
  ## proc audioCallback(input, output: ptr ptr cfloat, size: csize_t) {.cdecl.}
  ## ```
  ##
  ## **Audio format:** input[0] = left, input[1] = right
  discard

proc changeAudioCallback*(this: var DaisyPod, cb: InterleavingAudioCallbackC)
  {.importcpp: "#.ChangeAudioCallback(#)".} =
  ## Switch to a different interleaved audio callback
  ##
  ## Can be called while audio is running.
  ##
  ## **Parameters:**
  ## - `cb` - New audio callback function
  discard

proc changeAudioCallback*(this: var DaisyPod, cb: AudioCallbackC)
  {.importcpp: "#.ChangeAudioCallback(#)".} =
  ## Switch to a different multi-channel audio callback
  ##
  ## Can be called while audio is running.
  ##
  ## **Parameters:**
  ## - `cb` - New audio callback function
  discard

proc stopAudio*(this: var DaisyPod)
  {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  ##
  ## Stops the audio callback and codec.
  discard

proc setAudioSampleRate*(this: var DaisyPod, samplerate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Set audio sample rate
  ##
  ## **Must be called before startAudio().**
  ##
  ## **Parameters:**
  ## - `samplerate` - Target sample rate (e.g., SAI_48KHZ, SAI_96KHZ)
  ##
  ## Supported rates: 8kHz, 16kHz, 32kHz, 48kHz, 96kHz
  discard

proc audioSampleRate*(this: var DaisyPod): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Get current audio sample rate
  ##
  ## **Returns:** Sample rate in Hz (e.g., 48000.0)
  discard

proc setAudioBlockSize*(this: var DaisyPod, blocksize: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Set audio block size (samples per callback)
  ##
  ## **Must be called before startAudio().**
  ##
  ## **Parameters:**
  ## - `blocksize` - Number of samples per channel (default: 48)
  ##
  ## Smaller blocks = lower latency, higher CPU load.
  ## Larger blocks = higher latency, lower CPU load.
  discard

proc audioBlockSize*(this: var DaisyPod): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Get current audio block size
  ##
  ## **Returns:** Samples per channel per callback
  discard

proc audioCallbackRate*(this: var DaisyPod): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Get audio callback rate
  ##
  ## **Returns:** Callbacks per second (Hz)
  ##
  ## **Formula:** sample_rate / block_size
  ## **Example:** 48000 / 48 = 1000 Hz (1ms per callback)
  discard

# ============================================================================
# Analog/Digital Input Control
# ============================================================================

proc startAdc*(this: var DaisyPod)
  {.importcpp: "#.StartAdc()".} =
  ## Start ADC for analog controls (knobs)
  ##
  ## Must be called before reading knob values.
  ## Uses DMA for continuous background conversion.
  discard

proc stopAdc*(this: var DaisyPod)
  {.importcpp: "#.StopAdc()".} =
  ## Stop ADC conversion
  discard

proc processAnalogControls*(this: var DaisyPod)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Update analog control values (knobs)
  ##
  ## **Call regularly in main loop** (e.g., every 1-10ms) for smooth readings.
  ## Applies filtering to ADC values for stability.
  discard

proc processDigitalControls*(this: var DaisyPod)
  {.importcpp: "#.ProcessDigitalControls()".} =
  ## Update digital control states (encoder, buttons)
  ##
  ## **Call regularly in main loop** (e.g., every 1ms) for responsive input.
  ## Handles debouncing and edge detection.
  discard

proc processAllControls*(this: var DaisyPod)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Update all control inputs (analog + digital)
  ##
  ## **Convenience method.** Equivalent to:
  ## ```nim
  ## pod.processAnalogControls()
  ## pod.processDigitalControls()
  ## ```
  ##
  ## **Call regularly in main loop** (e.g., every 1ms).
  discard

proc getKnobValue*(this: var DaisyPod, k: PodKnob): cfloat
  {.importcpp: "#.GetKnobValue(#)".} =
  ## Read knob value
  ##
  ## **Parameters:**
  ## - `k` - Knob identifier (KNOB_1 or KNOB_2)
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  discard

# ============================================================================
# LED Control
# ============================================================================

proc clearLeds*(this: var DaisyPod)
  {.importcpp: "#.ClearLeds()".} =
  ## Turn off all LEDs
  ##
  ## Sets both RGB LEDs to off (black).
  ## Call `updateLeds()` to apply changes.
  discard

proc updateLeds*(this: var DaisyPod)
  {.importcpp: "#.UpdateLeds()".} =
  ## Apply LED color changes to hardware
  ##
  ## **Must be called after** setting LED colors with:
  ## - `pod.led1.setColor(r, g, b)`
  ## - `pod.led2.setColor(r, g, b)`
  ##
  ## **Example:**
  ## ```nim
  ## pod.led1.setColor(1.0, 0.0, 0.0)  # Red
  ## pod.led2.setColor(0.0, 1.0, 0.0)  # Green
  ## pod.updateLeds()  # Apply to hardware
  ## ```
  discard

# ============================================================================
# Convenience Helpers
# ============================================================================

proc delay*(this: var DaisyPod, milliseconds: int) {.inline.} =
  ## Delay execution (convenience wrapper)
  ##
  ## **Parameters:**
  ## - `milliseconds` - Delay time in milliseconds
  this.delayMs(milliseconds.csize_t)

# ============================================================================
# Switch Helper Methods (forward to C++ methods)
# ============================================================================

proc risingEdge*(sw: var Switch): bool {.importcpp: "#.RisingEdge()", header: "hid/switch.h".} =
  ## Check if switch has a rising edge (just pressed)
  discard

proc fallingEdge*(sw: var Switch): bool {.importcpp: "#.FallingEdge()", header: "hid/switch.h".} =
  ## Check if switch has a falling edge (just released)
  discard

proc pressed*(sw: var Switch): bool {.importcpp: "#.Pressed()", header: "hid/switch.h".} =
  ## Check if switch is currently pressed
  discard

proc timeHeldMs*(sw: var Switch): cfloat {.importcpp: "#.TimeHeldMs()", header: "hid/switch.h".} =
  ## Get time switch has been held in milliseconds
  discard

# ============================================================================
# Encoder Helper Methods (forward to C++ methods)
# ============================================================================

proc increment*(enc: var Encoder): int32 {.importcpp: "#.Increment()", header: "hid/encoder.h".} =
  ## Get encoder increment since last call
  discard

proc pressed*(enc: var Encoder): bool {.importcpp: "#.Pressed()", header: "hid/encoder.h".} =
  ## Check if encoder button is pressed
  discard

proc risingEdge*(enc: var Encoder): bool {.importcpp: "#.RisingEdge()", header: "hid/encoder.h".} =
  ## Check if encoder button has rising edge
  discard

proc fallingEdge*(enc: var Encoder): bool {.importcpp: "#.FallingEdge()", header: "hid/encoder.h".} =
  ## Check if encoder button has falling edge
  discard

proc timeHeldMs*(enc: var Encoder): cfloat {.importcpp: "#.TimeHeldMs()", header: "hid/encoder.h".} =
  ## Get time encoder button has been held
  discard
