## nimphea_patch_sm
## ==================
##
## Nim wrapper for Electro-Smith Daisy Patch SM (Surface Mount) development board.
##
## The Daisy Patch SM is a compact Eurorack module DSP engine featuring:
## - 8 CV inputs (bipolar, +/-5V Eurorack standard)
## - 4 auxiliary ADC inputs (0-3.3V)
## - 2 CV outputs (12-bit DAC, 0-5V)
## - 2 gate inputs (digital, Eurorack compatible)
## - 2 gate outputs (GPIO, Eurorack compatible)
## - Audio I/O (Eurorack level, 24-bit/48kHz)
## - USB for programming/power
## - SDRAM (64MB)
## - QSPI Flash (8MB)
## - Pin bank system (A/B/C/D headers, 10 pins each)
##
## **Hardware Overview:**
## - Based on Daisy Seed (STM32H750, 480MHz ARM Cortex-M7)
## - Compact Eurorack form factor (8HP)
## - Perfect for CV processors, quantizers, utilities
## - PCM3060 codec for high-quality audio
##
## **Example - Simple CV processor:**
## ```nim
## import boards/daisy_patch_sm
##
## var patchsm: DaisyPatchSM
## patchsm.init()
## patchsm.startAdc()
## patchsm.startDac()
##
## while true:
##   patchsm.processAllControls()
##   
##   # Read CV inputs
##   let cv1 = patchsm.getAdcValue(CV_1)
##   let cv2 = patchsm.getAdcValue(CV_2)
##   
##   # Process and output
##   patchsm.writeCvOut(CV_OUT_1, (cv1 + cv2) * 2.5)
##   patchsm.writeCvOut(CV_OUT_2, cv1 * 5.0)
##   
##   patchsm.delay(1)
## ```
##
## **Example - With audio processing:**
## ```nim
## var patchsm: DaisyPatchSM
## var gain: float32 = 1.0
##
## proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
##   for i in 0..<size:
##     output[0][i] = input[0][i] * gain
##     output[1][i] = input[1][i] * gain
##
## proc main() =
##   patchsm.init()
##   patchsm.startAdc()
##   patchsm.startAudio(audioCallback)
##   
##   while true:
##     patchsm.processAllControls()
##     gain = patchsm.getAdcValue(CV_1) * 2.0  # 0-10V control range
##     patchsm.delay(1)
## ```

import nimphea
import nimphea_macros
import hid/gatein
import per/dac
import dev/codec_pcm3060

useNimpheaModules(patch_sm, codec_pcm3060)

{.push header: "daisy_patch_sm.h".}

# Forward declare namespace enum types
type
  PatchSmCv* {.importcpp: "daisy::patch_sm::CV_1", size: sizeof(cint).} = enum
    ## CV input identifiers (8 bipolar CV + 4 auxiliary ADC)
    ##
    ## **CV Inputs (bipolar, +/-5V):**
    ## - CV_1 through CV_8: Eurorack CV inputs with protection
    ##
    ## **Auxiliary ADC (0-3.3V):**
    ## - ADC_9 through ADC_12: Direct ADC inputs (non-Eurorack)
    CV_1 = 0   ## CV input 1 (bipolar +/-5V)
    CV_2 = 1   ## CV input 2 (bipolar +/-5V)
    CV_3 = 2   ## CV input 3 (bipolar +/-5V)
    CV_4 = 3   ## CV input 4 (bipolar +/-5V)
    CV_5 = 4   ## CV input 5 (bipolar +/-5V)
    CV_6 = 5   ## CV input 6 (bipolar +/-5V)
    CV_7 = 6   ## CV input 7 (bipolar +/-5V)
    CV_8 = 7   ## CV input 8 (bipolar +/-5V)
    ADC_9 = 8  ## Auxiliary ADC input (0-3.3V)
    ADC_10 = 9  ## Auxiliary ADC input (0-3.3V)
    ADC_11 = 10 ## Auxiliary ADC input (0-3.3V)
    ADC_12 = 11 ## Auxiliary ADC input (0-3.3V)
    ADC_LAST = 12 ## Sentinel value
  
  PatchSmCvOut* {.importcpp: "daisy::patch_sm::CV_OUT_BOTH", size: sizeof(cint).} = enum
    ## CV output channel identifiers
    ##
    ## **Channels:**
    ## - CV_OUT_1, CV_OUT_2: Individual outputs (0-5V)
    ## - CV_OUT_BOTH: Write to both outputs simultaneously
    CV_OUT_BOTH = 0 ## Both CV outputs
    CV_OUT_1 = 1    ## CV output 1 (0-5V)
    CV_OUT_2 = 2    ## CV output 2 (0-5V)
  
  PatchSmPinBank* {.importcpp: "daisy::patch_sm::DaisyPatchSM::PinBank", size: sizeof(cint).} = enum
    ## Pin bank identifiers for GetPin function
    ##
    ## Each bank has 10 pins (indices 1-10)
    PIN_BANK_A = 0 ## Bank A (header A)
    PIN_BANK_B = 1 ## Bank B (header B)
    PIN_BANK_C = 2 ## Bank C (header C)
    PIN_BANK_D = 3 ## Bank D (header D)
  
  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: "hid/ctrl.h".} = object
    ## Analog control (knob/CV input) wrapper
  
  DaisyPatchSM* {.importcpp: "daisy::patch_sm::DaisyPatchSM".} = object
    ## Daisy Patch SM board handle
    ##
    ## Contains all hardware peripherals pre-configured for the Patch SM platform.
    ## Access individual components as public members.
    system*: System              ## System utilities
    sdram*: SdramHandle          ## 64MB SDRAM
    qspi*: QSPIHandle            ## 8MB QSPI Flash
    audio*: AudioHandle             ## Audio I/O (PCM3060 codec)
    adc*: nimphea.AdcHandle        ## 12-channel ADC (8 CV + 4 aux)
    usb*: UsbHandle                 ## USB peripheral
    codec*: Pcm3060                 ## PCM3060 audio codec
    dac*: nimphea.DacHandle        ## 2-channel DAC for CV outputs
    user_led*: GPIO                 ## Onboard user LED
    controls*: array[12, AnalogControl] ## Array of 12 analog controls
    gate_in_1*: GateIn           ## Gate input 1
    gate_in_2*: GateIn           ## Gate input 2
    gate_out_1*: GPIO            ## Gate output 1
    gate_out_2*: GPIO            ## Gate output 2

{.pop.}  # header

# ============================================================================
# Initialization and Core Control
# ============================================================================

proc init*(this: var DaisyPatchSM)
  {.importcpp: "#.Init()".} =
  ## Initialize the Daisy Patch SM board
  ##
  ## Configures all hardware peripherals:
  ## - Audio codec (PCM3060, 24-bit/48kHz)
  ## - ADC for CV inputs (8 CV + 4 aux)
  ## - DAC for CV outputs (started automatically)
  ## - Gate inputs (GateIn class)
  ## - SDRAM (64MB)
  ## - QSPI Flash (8MB)
  ##
  ## **Note:** Audio and ADC are started automatically during Init().
  ## DAC for CV outputs is also started with default 48kHz callback.
  discard

proc delay*(this: var DaisyPatchSM, milliseconds: uint32)
  {.importcpp: "#.Delay(#)".} =
  ## Delay execution for specified milliseconds
  ##
  ## **Parameters:**
  ## - `milliseconds` - Delay time in milliseconds
  ##
  ## **Note:** Blocking delay. For audio applications, prefer
  ## timing based on audio callback rate or use timers.
  discard

# ============================================================================
# Audio Control
# ============================================================================

# Global callback storage (one set per board type to avoid conflicts)
var globalPatchSmAudioCallback: AudioCallback = nil
var globalPatchSmInterleavingCallback: InterleavingAudioCallback = nil

# C-compatible wrapper functions
proc patchSmAudioCallbackWrapper(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.exportc: "patchSmAudioCallbackWrapper", cdecl.} =
  if not globalPatchSmAudioCallback.isNil:
    globalPatchSmAudioCallback(cast[AudioBuffer](input),
                              cast[AudioBuffer](output),
                              size.int)

proc patchSmInterleavingCallbackWrapper(input: ptr cfloat, output: ptr cfloat, size: csize_t) {.exportc: "patchSmInterleavingCallbackWrapper", cdecl.} =
  if not globalPatchSmInterleavingCallback.isNil:
    globalPatchSmInterleavingCallback(cast[InterleavedAudioBuffer](input),
                                     cast[InterleavedAudioBuffer](output),
                                     size.int)

proc startAudio*(patchsm: var DaisyPatchSM, callback: AudioCallback) =
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
  ## patchsm.startAudio(audioCallback)
  ## ```
  globalPatchSmAudioCallback = callback
  {.emit: "`patchsm`.StartAudio(reinterpret_cast<daisy::AudioHandle::AudioCallback>(patchSmAudioCallbackWrapper));".}

proc startAudio*(patchsm: var DaisyPatchSM, callback: InterleavingAudioCallback) =
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
  ## patchsm.startAudio(audioCallback)
  ## ```
  globalPatchSmInterleavingCallback = callback
  {.emit: "`patchsm`.StartAudio(reinterpret_cast<daisy::AudioHandle::InterleavingAudioCallback>(patchSmInterleavingCallbackWrapper));".}

proc changeAudioCallback*(patchsm: var DaisyPatchSM, callback: AudioCallback) =
  ## Change the audio callback while audio is running
  ##
  ## **Note:** May cause clicks if done while audio is processing.
  globalPatchSmAudioCallback = callback

proc changeAudioCallback*(patchsm: var DaisyPatchSM, callback: InterleavingAudioCallback) =
  ## Change the interleaved audio callback while audio is running
  ##
  ## **Note:** May cause clicks if done while audio is processing.
  globalPatchSmInterleavingCallback = callback

proc stopAudio*(patchsm: var DaisyPatchSM) {.importcpp: "#.StopAudio()".} =
  ## Stop audio processing
  ##
  ## Stops the audio callback and codec.
  globalPatchSmAudioCallback = nil
  globalPatchSmInterleavingCallback = nil

proc setAudioBlockSize*(this: var DaisyPatchSM, size: csize_t)
  {.importcpp: "#.SetAudioBlockSize(#)".} =
  ## Sets the number of samples processed in an audio callback
  ##
  ## **Parameters:**
  ## - `size` - Number of samples per channel (default: 48)
  ##
  ## **Note:** This will only take effect on the next invocation of `startAudio()`.
  ##
  ## Smaller blocks = lower latency, higher CPU load.
  ## Larger blocks = higher latency, lower CPU load.
  discard

proc setAudioSampleRate*(this: var DaisyPatchSM, sr: cfloat)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Sets the samplerate for the audio engine
  ##
  ## **Parameters:**
  ## - `sr` - Target sample rate in Hz
  ##
  ## This will set it to the closest valid samplerate. Options being:
  ## 8kHz, 16kHz, 32kHz, 48kHz, and 96kHz
  discard

proc setAudioSampleRate*(this: var DaisyPatchSM, sample_rate: SampleRate)
  {.importcpp: "#.SetAudioSampleRate(#)".} =
  ## Sets the samplerate for the audio engine
  ##
  ## **Parameters:**
  ## - `sample_rate` - Sample rate enum (e.g., SAI_48KHZ, SAI_96KHZ)
  discard

proc audioBlockSize*(this: var DaisyPatchSM): csize_t
  {.importcpp: "#.AudioBlockSize()".} =
  ## Returns the number of samples processed in an audio callback
  ##
  ## **Returns:** Samples per channel per callback
  discard

proc audioSampleRate*(this: var DaisyPatchSM): cfloat
  {.importcpp: "#.AudioSampleRate()".} =
  ## Returns the audio engine's samplerate in Hz
  ##
  ## **Returns:** Sample rate in Hz (e.g., 48000.0)
  discard

proc audioCallbackRate*(this: var DaisyPatchSM): cfloat
  {.importcpp: "#.AudioCallbackRate()".} =
  ## Returns the rate at which the audio callback will be called in Hz
  ##
  ## **Returns:** Callbacks per second (Hz)
  ##
  ## **Formula:** sample_rate / block_size
  ## **Example:** 48000 / 48 = 1000 Hz (1ms per callback)
  discard

# ============================================================================
# Analog/Digital Input Control
# ============================================================================

proc startAdc*(this: var DaisyPatchSM)
  {.importcpp: "#.StartAdc()".} =
  ## Starts the Control ADCs
  ##
  ## **Note:** This is started automatically when Init() is called.
  ##
  ## Uses DMA for continuous background conversion of all 12 channels.
  discard

proc stopAdc*(this: var DaisyPatchSM)
  {.importcpp: "#.StopAdc()".} =
  ## Stops the Control ADCs
  ##
  ## Halts DMA conversion and reduces power consumption.
  discard

proc processAnalogControls*(this: var DaisyPatchSM)
  {.importcpp: "#.ProcessAnalogControls()".} =
  ## Reads and filters all of the analog control inputs
  ##
  ## **Call regularly in main loop** (e.g., every 1-10ms) for smooth readings.
  ## Applies filtering to ADC values for stability.
  ##
  ## Updates all 12 channels (8 CV + 4 aux ADC).
  discard

proc processDigitalControls*(this: var DaisyPatchSM)
  {.importcpp: "#.ProcessDigitalControls()".} =
  ## Reads and debounces any of the digital control inputs
  ##
  ## **Note:** This does nothing on Patch SM (no digital controls besides gates).
  ## Provided for API compatibility with other boards.
  discard

proc processAllControls*(this: var DaisyPatchSM)
  {.importcpp: "#.ProcessAllControls()".} =
  ## Does both analog and digital control processing
  ##
  ## **Convenience method.** Equivalent to:
  ## ```nim
  ## patchsm.processAnalogControls()
  ## patchsm.processDigitalControls()
  ## ```
  ##
  ## **Call regularly in main loop** (e.g., every 1ms).
  discard

proc getAdcValue*(this: var DaisyPatchSM, idx: cint): cfloat
  {.importcpp: "#.GetAdcValue(#)".} =
  ## Returns the current value for one of the ADCs
  ##
  ## **Parameters:**
  ## - `idx` - ADC channel index (cast PatchSmCv to cint: CV_1.cint)
  ##
  ## **Returns:** Normalized value from 0.0 to 1.0
  ##
  ## **Voltage Mapping:**
  ## - CV inputs (CV_1 to CV_8): 0.0 = -5V, 0.5 = 0V, 1.0 = +5V (bipolar)
  ## - ADC inputs (ADC_9 to ADC_12): 0.0 = 0V, 1.0 = 3.3V (unipolar)
  ##
  ## **Example:**
  ## ```nim
  ## let cv1Value = patchsm.getAdcValue(CV_1.cint)
  ## ```
  ##
  ## **Note:** Call `processAnalogControls()` regularly for accurate readings.
  discard

# ============================================================================
# DAC / CV Output Control
# ============================================================================

proc startDac*(this: var DaisyPatchSM, callback: DacCallback = nil)
  {.importcpp: "#.StartDac(#)".} =
  ## Starts the DAC for the CV Outputs
  ##
  ## **Parameters:**
  ## - `callback` - Optional custom DAC update callback (default: nil)
  ##
  ## By default this starts by running the internal callback at 48kHz,
  ## which will update the values based on the `writeCvOut()` function.
  ##
  ## **Note:** This is started automatically when Init() is called.
  discard

proc stopDac*(this: var DaisyPatchSM)
  {.importcpp: "#.StopDac()".} =
  ## Stop the DAC from updating
  ##
  ## This will suspend the CV Outputs from changing.
  discard

proc writeCvOut*(this: var DaisyPatchSM, channel: cint, voltage: cfloat)
  {.importcpp: "#.WriteCvOut(#, #)".} =
  ## Sets specified DAC channel to the target voltage
  ##
  ## **Parameters:**
  ## - `channel` - Desired channel (cast PatchSmCvOut to cint: CV_OUT_1.cint)
  ## - `voltage` - Value in Volts (valid range is 0-5V)
  ##
  ## **Note:** This may not be 100% accurate without calibration.
  ##
  ## **Examples:**
  ## ```nim
  ## # Set CV Out 1 to 2.5V (middle of range)
  ## patchsm.writeCvOut(CV_OUT_1.cint, 2.5)
  ##
  ## # Set both outputs to 0V
  ## patchsm.writeCvOut(CV_OUT_BOTH.cint, 0.0)
  ## ```
  discard

# ============================================================================
# Pin Access
# ============================================================================

proc getPin*(this: var DaisyPatchSM, bank: PatchSmPinBank, idx: cint): Pin
  {.importcpp: "#.GetPin(#, #)".} =
  ## Returns the STM32 port/pin combo for the desired pin
  ##
  ## **Parameters:**
  ## - `bank` - Pin bank (PIN_BANK_A, PIN_BANK_B, PIN_BANK_C, or PIN_BANK_D)
  ## - `idx` - Pin number between 1 and 10 for each bank
  ##
  ## **Returns:** Pin object (or invalid pin for hardware-only pins)
  ##
  ## **Note:** Some pins are hardware-only (power, audio, etc.) and will
  ## return invalid Pin objects.
  ##
  ## **Deprecated:** Please use the Pin definitions in daisy::patch_sm namespace instead.
  discard

# ============================================================================
# Memory Validation
# ============================================================================

proc validateSDRAM*(this: var DaisyPatchSM): bool
  {.importcpp: "#.ValidateSDRAM()".} =
  ## Tests entirety of SDRAM for validity
  ##
  ## **WARNING:** This will wipe contents of SDRAM when testing.
  ##
  ## **Note:** If using the SDRAM for the default bss, or heap,
  ## and using constructors as initializers do not call this function.
  ## Otherwise, it could overwrite changes performed by constructors.
  ##
  ## **Returns:** true if SDRAM is okay, otherwise false
  discard

proc validateQSPI*(this: var DaisyPatchSM, quick: bool = true): bool
  {.importcpp: "#.ValidateQSPI(#)".} =
  ## Tests the QSPI for validity
  ##
  ## **WARNING:** This will wipe contents of QSPI when testing.
  ##
  ## **Parameters:**
  ## - `quick` - If true, only test 16kB starting at offset 0x400000.
  ##             If false, test entire 8MB (takes over a minute).
  ##
  ## **Note:** The "quick" test starts 4MB into the memory and tests 16kB of data.
  ##
  ## **Returns:** true if QSPI is okay, otherwise false
  discard

# ============================================================================
# LED Control
# ============================================================================

proc setLed*(this: var DaisyPatchSM, state: bool)
  {.importcpp: "#.SetLed(#)".} =
  ## Set onboard user LED state
  ##
  ## **Parameters:**
  ## - `state` - true = LED on, false = LED off
  ##
  ## **Example:**
  ## ```nim
  ## patchsm.setLed(true)   # Turn LED on
  ## patchsm.delay(500)
  ## patchsm.setLed(false)  # Turn LED off
  ## ```
  discard

# ============================================================================
# Utility Methods
# ============================================================================

proc getRandomValue*(this: var DaisyPatchSM): uint32
  {.importcpp: "#.GetRandomValue()".} =
  ## Gets a random 32-bit value
  ##
  ## **Returns:** Random uint32 value
  ##
  ## Uses STM32 hardware RNG for true random numbers.
  discard

proc getRandomFloat*(this: var DaisyPatchSM, min: cfloat = 0.0, max: cfloat = 1.0): cfloat
  {.importcpp: "#.GetRandomFloat(#, #)".} =
  ## Gets a random floating point value between the specified minimum and maximum
  ##
  ## **Parameters:**
  ## - `min` - Minimum value (default: 0.0)
  ## - `max` - Maximum value (default: 1.0)
  ##
  ## **Returns:** Random float in range [min, max]
  ##
  ## **Example:**
  ## ```nim
  ## let noise = patchsm.getRandomFloat(-0.1, 0.1)  # ±0.1 noise
  ## let cv = patchsm.getRandomFloat(0.0, 5.0)      # 0-5V random CV
  ## ```
  discard

# ============================================================================
# GateIn Helper Methods (forward to C++ methods)
# ============================================================================

proc state*(gate: var GateIn): bool {.importcpp: "#.State()", header: "hid/gatein.h".} =
  ## Check if gate input is currently HIGH
  ##
  ## **Returns:** true if gate is HIGH, false if LOW
  discard

proc trig*(gate: var GateIn): bool {.importcpp: "#.Trig()", header: "hid/gatein.h".} =
  ## Check if gate input has a rising edge (trigger)
  ##
  ## **Returns:** true on rising edge, false otherwise
  ##
  ## **Note:** Only returns true once per rising edge. Call `processAllControls()`
  ## regularly for accurate trigger detection.
  discard
