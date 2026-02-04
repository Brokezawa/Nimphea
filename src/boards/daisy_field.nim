## nimphea_field
## ===============
##
## Nim wrapper for Electro-Smith Daisy Field development board.
##
## The Daisy Field is a large Eurorack-format module featuring:
## - 16-key capacitive touch keyboard (2× 8-key rows)
## - 8 potentiometers with LEDs
## - 4 CV inputs (±5V)
## - 2 CV outputs (0-5V via DAC)
## - 2 gate inputs
## - 1 gate output
## - OLED display (128×64, SPI)
## - 26 RGB LEDs (16 keyboard, 8 knob, 2 switch)
## - 2 tactile switches with LEDs
## - MIDI I/O (TRS jacks)
## - Audio I/O (Eurorack level)
##
## **Hardware Overview:**
## - Based on Daisy Seed (STM32H750, 480MHz ARM Cortex-M7)
## - Eurorack format (42HP wide)
## - Perfect for keyboard synthesizers, sequencers, CV processors
##
## **Example - Keyboard and display:**
## ```nim
## import boards/daisy_field
##
## var field: DaisyField
## field.init()
##
## while true:
##   field.processAllControls()
##   
##   # Check keyboard
##   for key in 0..<16:
##     if field.keyboardRisingEdge(key):
##       # Key was just pressed
##       field.led_driver.setLed(key, 1.0)
##   
##   field.display.fill(false)
##   field.display.setCursor(0, 0)
##   field.display.writeString("Hello Field!", Font_7x10, true)
##   field.display.update()
##   
##   field.seed.delay(10)
## ```
##
## **Example - CV processing:**
## ```nim
## while true:
##   field.processAnalogControls()
##   
##   let cv1 = field.getCvValue(CV_1)  # Read CV input
##   let knob1 = field.getKnobValue(KNOB_1)
##   
##   let processed = cv1 * knob1  # Process CV
##   
##   # Output via DAC (0-4095 = 0-5V)
##   let dacValue = (processed * 4095.0).uint16
##   field.setCvOut1(dacValue)
## ```

import nimphea
import nimphea_macros
import hid/disp/oled_display
import hid/gatein
import hid/switch
import dev/leddriver

export oled_display  # Export OLED types and methods
export leddriver  # Export LED driver methods
export gatein  # Export GateIn methods for gate input access

useNimpheaModules(field)

{.push header: "daisy_field.h".}

type
  FieldSwitch* = enum
    ## Tactile switch identifiers
    SW_1 = 0  ## Left switch
    SW_2 = 1  ## Right switch

  FieldKnob* = enum
    ## Knob (potentiometer) identifiers
    ## Layout: Left to right on panel
    KNOB_1 = 0
    KNOB_2 = 1
    KNOB_3 = 2
    KNOB_4 = 3
    KNOB_5 = 4
    KNOB_6 = 5
    KNOB_7 = 6
    KNOB_8 = 7

  FieldCV* = enum
    ## CV input identifiers
    CV_1 = 0  ## CV input 1 (±5V)
    CV_2 = 1  ## CV input 2 (±5V)
    CV_3 = 2  ## CV input 3 (±5V)
    CV_4 = 3  ## CV input 4 (±5V)

  FieldLed* = enum
    ## LED identifiers (26 total)
    ## 16 keyboard LEDs (Row B then Row A, right to left)
    LED_KEY_B1 = 0
    LED_KEY_B2 = 1
    LED_KEY_B3 = 2
    LED_KEY_B4 = 3
    LED_KEY_B5 = 4
    LED_KEY_B6 = 5
    LED_KEY_B7 = 6
    LED_KEY_B8 = 7
    LED_KEY_A8 = 8
    LED_KEY_A7 = 9
    LED_KEY_A6 = 10
    LED_KEY_A5 = 11
    LED_KEY_A4 = 12
    LED_KEY_A3 = 13
    LED_KEY_A2 = 14
    LED_KEY_A1 = 15
    ## 8 knob LEDs (left to right)
    LED_KNOB_1 = 16
    LED_KNOB_2 = 17
    LED_KNOB_3 = 18
    LED_KNOB_4 = 19
    LED_KNOB_5 = 20
    LED_KNOB_6 = 21
    LED_KNOB_7 = 22
    LED_KNOB_8 = 23
    ## 2 switch LEDs
    LED_SW_1 = 24
    LED_SW_2 = 25

  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/CV input) wrapper

  MidiUartTransport* {.importcpp: "daisy::MidiUartTransport",
                       header: "hid/midi.h".} = object
    ## MIDI UART transport

  MidiUartHandler* {.importcpp: "daisy::MidiHandler<daisy::MidiUartTransport>",
                     header: "hid/midi.h".} = object
    ## MIDI UART handler

  DaisyField* {.importcpp: "daisy::DaisyField".} = object
    ## Daisy Field board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Field platform.
    seed*: DaisySeed                    ## Underlying Seed board
    display*: OledDisplay128x64Spi      ## 128×64 OLED display (SPI)
    gate_out*: GPIO                     ## Gate output pin
    gate_in*: GateIn                    ## Gate input
    led_driver*: FieldLedDriver         ## LED driver (2× PCA9685, daisy-chained) - v0.12.0 fix
    sw*: array[2, Switch]               ## 2 tactile switches
    knob*: array[8, AnalogControl]      ## 8 potentiometers
    cv*: array[4, AnalogControl]        ## 4 CV inputs
    midi*: MidiUartHandler              ## MIDI UART handler

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyField, boost: bool = false)
  {.importcpp: "#.Init(#)".} =
  ## Initialize the Daisy Field board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (AK4556, 24-bit/48kHz)
  ## - ADC for knobs and CV inputs (with multiplexing)
  ## - Keyboard shift registers
  ## - OLED display
  ## - LED drivers (2× PCA9685, 26 LEDs total)
  ## - Gate I/O
  ## - MIDI UART
  ## - DAC for CV outputs
  ##
  ## **Parameters:**
  ## - `boost` - Enable CPU boost mode (480MHz, default is 400MHz)
  ##
  ## **Note:** Audio and ADC must be started separately with
  ## `startAudio()` and `startAdc()`.
  discard

proc delayMs*(this: var DaisyField, del: csize_t)
  {.importcpp: "#.DelayMs(#)".} =
  ## Delay execution for specified milliseconds
  ##
  ## **Parameters:**
  ## - `del` - Delay time in milliseconds
  discard

# ============================================================================
# Audio Control
# ============================================================================

# Global callback storage
var globalFieldAudioCallback: AudioCallback = nil
var globalFieldInterleavingCallback: InterleavingAudioCallback = nil

# C-compatible wrapper functions
proc fieldAudioCallbackWrapper(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.exportc: "fieldAudioCallbackWrapper", cdecl.} =
  if not globalFieldAudioCallback.isNil:
    globalFieldAudioCallback(cast[AudioBuffer](input),
                            cast[AudioBuffer](output),
                            size.int)

proc fieldInterleavingCallbackWrapper(input: ptr cfloat, output: ptr cfloat, size: csize_t) {.exportc: "fieldInterleavingCallbackWrapper", cdecl.} =
  if not globalFieldInterleavingCallback.isNil:
    globalFieldInterleavingCallback(cast[InterleavedAudioBuffer](input),
                                   cast[InterleavedAudioBuffer](output),
                                   size.int)

proc startAudio*(field: var DaisyField, callback: AudioCallback) =
  ## Start audio processing with multi-channel (non-interleaved) callback
  ##
  ## **Example:**
  ## ```nim
  ## proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ##   for i in 0..<size:
  ##     output[0][i] = input[0][i] * 0.5
  ##     output[1][i] = input[1][i] * 0.5
  ## ```
  globalFieldAudioCallback = callback
  {.emit: "`field`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(fieldAudioCallbackWrapper));".}

proc startAudio*(field: var DaisyField, callback: InterleavingAudioCallback) =
  ## Start audio processing with interleaved callback
  ##
  ## **Example:**
  ## ```nim
  ## proc audioCallback(input, output: InterleavedAudioBuffer, size: int) {.cdecl.} =
  ##   for i in 0..<size:
  ##     output[i * 2] = input[i * 2] * 0.5
  ##     output[i * 2 + 1] = input[i * 2 + 1] * 0.5
  ## ```
  globalFieldInterleavingCallback = callback
  {.emit: "`field`.StartAudio(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(fieldInterleavingCallbackWrapper));".}

proc changeAudioCallback*(field: var DaisyField, callback: AudioCallback) =
  ## Change the audio callback while audio is running
  globalFieldAudioCallback = callback

proc changeAudioCallback*(field: var DaisyField, callback: InterleavingAudioCallback) =
  ## Change the interleaved audio callback while audio is running
  globalFieldInterleavingCallback = callback

proc stopAudio*(field: var DaisyField) {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  globalFieldAudioCallback = nil
  globalFieldInterleavingCallback = nil

proc setAudioSampleRate*(this: var DaisyField, samplerate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Set audio sample rate (must be called before startAudio)
  discard

proc audioSampleRate*(this: var DaisyField): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Get current audio sample rate in Hz
  discard

proc setAudioBlockSize*(this: var DaisyField, size: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Set audio block size (must be called before startAudio)
  discard

proc audioBlockSize*(this: var DaisyField): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Get current audio block size
  discard

proc audioCallbackRate*(this: var DaisyField): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Get audio callback rate in Hz
  discard

# ============================================================================
# Analog/Digital Input Control
# ============================================================================

proc startAdc*(this: var DaisyField)
  {.importcpp: "#.StartAdc()".} =
  ## Start ADC for analog controls (knobs and CV inputs)
  ##
  ## Uses CD4051 multiplexer for 8 knobs + 4 CV inputs.
  ## Must be called before reading knob/CV values.
  discard

proc stopAdc*(this: var DaisyField)
  {.importcpp: "#.StopAdc()".} =
  ## Stop ADC conversion
  discard

proc processAnalogControls*(this: var DaisyField)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Update analog control values (knobs and CV inputs)
  ##
  ## **Call regularly in main loop** (e.g., every 1-10ms).
  ## Handles multiplexer switching and ADC filtering.
  discard

proc processDigitalControls*(this: var DaisyField)
  {.importcpp: "#.ProcessDigitalControls()".} =
  ## Update digital control states (keyboard, switches, gate inputs)
  ##
  ## **Call regularly in main loop** (e.g., every 1ms).
  ## Reads shift registers for keyboard scanning.
  discard

proc processAllControls*(this: var DaisyField)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Update all control inputs (analog + digital)
  ##
  ## **Convenience method.** Equivalent to:
  ## ```nim
  ## field.processAnalogControls()
  ## field.processDigitalControls()
  ## ```
  discard

# ============================================================================
# CV and DAC Output
# ============================================================================

proc setCvOut1*(this: var DaisyField, val: uint16)
  {.importcpp: "#.SetCvOut1(#)".} =
  ## Set CV output 1 value
  ##
  ## **Parameters:**
  ## - `val` - 12-bit value (0-4095) corresponding to 0-5V
  ##
  ## **Voltage mapping:** `voltage = val * 5.0 / 4095.0`
  ##
  ## **Example:**
  ## ```nim
  ## field.setCvOut1(2048)  # Output 2.5V
  ## field.setCvOut1(4095)  # Output 5.0V
  ## ```
  discard

proc setCvOut2*(this: var DaisyField, val: uint16)
  {.importcpp: "#.SetCvOut2(#)".} =
  ## Set CV output 2 value
  ##
  ## **Parameters:**
  ## - `val` - 12-bit value (0-4095) corresponding to 0-5V
  discard

# ============================================================================
# Keyboard Control
# ============================================================================

proc keyboardState*(this: DaisyField, idx: csize_t): bool
  {.importcpp: "#.KeyboardState(#)".} =
  ## Get current state of keyboard key
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##   - 0-7: Row B (bottom row, left to right)
  ##   - 8-15: Row A (top row, left to right)
  ##
  ## **Returns:** `true` if key is currently pressed
  ##
  ## **Note:** Call `processDigitalControls()` first to update state.
  discard

proc keyboardRisingEdge*(this: DaisyField, idx: csize_t): bool
  {.importcpp: "#.KeyboardRisingEdge(#)".} =
  ## Detect key press (rising edge)
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##
  ## **Returns:** `true` if key was just pressed (since last call)
  ##
  ## **Use case:** Trigger note-on, start sequences, etc.
  ##
  ## **Example:**
  ## ```nim
  ## for key in 0..<16:
  ##   if field.keyboardRisingEdge(key):
  ##     # Key just pressed - play note
  ## ```
  discard

proc keyboardFallingEdge*(this: DaisyField, idx: csize_t): bool
  {.importcpp: "#.KeyboardFallingEdge(#)".} =
  ## Detect key release (falling edge)
  ##
  ## **Parameters:**
  ## - `idx` - Key index (0-15)
  ##
  ## **Returns:** `true` if key was just released (since last call)
  ##
  ## **Use case:** Trigger note-off, stop sequences, etc.
  discard

# ============================================================================
# Knob and CV Reading
# ============================================================================

proc getKnobValue*(this: DaisyField, idx: csize_t): cfloat
  {.importcpp: "#.GetKnobValue(#)".} =
  ## Read knob value
  ##
  ## **Parameters:**
  ## - `idx` - Knob index (0-7, or use FieldKnob enum)
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  ##
  ## **Example:**
  ## ```nim
  ## let cutoff = field.getKnobValue(KNOB_1.csize_t)
  ## let resonance = field.getKnobValue(KNOB_2.csize_t)
  ## ```
  discard

proc getCvValue*(this: DaisyField, idx: csize_t): cfloat
  {.importcpp: "#.GetCvValue(#)".} =
  ## Read CV input value
  ##
  ## **Parameters:**
  ## - `idx` - CV input index (0-3, or use FieldCV enum)
  ##
  ## **Returns:** Voltage value (±5V range, scaled to 0.0-1.0)
  ##
  ## **Voltage mapping:**
  ## - 0.0 → -5V
  ## - 0.5 → 0V
  ## - 1.0 → +5V
  ##
  ## **Example:**
  ## ```nim
  ## let cv1Raw = field.getCvValue(CV_1.csize_t)
  ## let cv1Volts = (cv1Raw - 0.5) * 10.0  # Convert to ±5V
  ## ```
  discard

# ============================================================================
# Component Access Helpers
# ============================================================================

proc getSwitch*(this: var DaisyField, idx: csize_t): ptr Switch
  {.importcpp: "#.GetSwitch(#)".} =
  ## Get pointer to switch object
  ##
  ## **Parameters:**
  ## - `idx` - Switch index (0-1)
  ##
  ## **Returns:** Pointer to Switch object for direct access
  ##
  ## **Use case:** Access switch methods like `pressed()`, `timeHeldMs()`, etc.
  discard

proc getKnob*(this: var DaisyField, idx: csize_t): ptr AnalogControl
  {.importcpp: "#.GetKnob(#)".} =
  ## Get pointer to knob (AnalogControl) object
  ##
  ## **Parameters:**
  ## - `idx` - Knob index (0-7)
  ##
  ## **Returns:** Pointer to AnalogControl object
  discard

proc getCv*(this: var DaisyField, idx: csize_t): ptr AnalogControl
  {.importcpp: "#.GetCv(#)".} =
  ## Get pointer to CV input (AnalogControl) object
  ##
  ## **Parameters:**
  ## - `idx` - CV input index (0-3)
  ##
  ## **Returns:** Pointer to AnalogControl object
  discard

# ============================================================================
# Special Functions
# ============================================================================

proc vegasMode*(this: var DaisyField)
  {.importcpp: "#.VegasMode()".} =
  ## LED test pattern / light show
  ##
  ## Cycles through all 26 LEDs and updates OLED display.
  ## **Blocking function** - runs until interrupted.
  ##
  ## **Use case:** Hardware testing, visual demo
  discard

# ============================================================================
# Convenience Helpers
# ============================================================================

proc delay*(this: var DaisyField, milliseconds: int) {.inline.} =
  ## Delay execution (convenience wrapper)
  this.delayMs(milliseconds.csize_t)
