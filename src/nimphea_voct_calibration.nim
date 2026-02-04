## V/Oct Calibration
## ==================
##
## 1V/octave calibration for musical pitch CV (Control Voltage) inputs.
##
## This module provides accurate conversion from analog CV inputs to MIDI note
## numbers, enabling precise pitch tracking for Eurorack synthesizer applications.
##
## What is V/Oct?
## --------------
##
## **1V/octave** is the standard CV pitch control used in modular synthesizers:
##
## - **1V increase = +12 semitones** (one octave higher)
## - **1V decrease = -12 semitones** (one octave lower)
## - **83.33mV = +1 semitone** (1/12 of a volt)
##
## **Example voltages:**
##
## - 0V = C0 (MIDI note 0)
## - 1V = C1 (MIDI note 12)
## - 2V = C2 (MIDI note 24)
## - 3V = C3 (MIDI note 36)
## - 4V = C4 (MIDI note 48, middle C)
##
## Why Calibration is Needed
## --------------------------
##
## ADC (Analog-to-Digital Converter) readings vary due to:
##
## 1. **Input circuit tolerances** (resistors, op-amps)
## 2. **ADC reference voltage drift**
## 3. **Temperature effects**
## 4. **Component aging**
##
## Without calibration, a 1V input might read as 0.23 or 0.25 instead of exactly
## the expected value, causing pitch errors (out-of-tune notes).
##
## **This module solves the problem** by measuring two known voltages (1V and 3V)
## and calculating a correction formula (scale + offset).
##
## Calibration Procedure
## ---------------------
##
## **Step 1: Create calibration object**
##
## .. code-block:: nim
##    var voct: VoctCalibration
##
## **Step 2: Measure 1V reference**
##
## .. code-block:: nim
##    # User patches 1V CV source to input
##    # (use precision voltage source or calibrated CV module)
##    let reading1V = adc.get(0)  # Read ADC value
##
## **Step 3: Measure 3V reference**
##
## .. code-block:: nim
##    # User patches 3V CV source to input
##    let reading3V = adc.get(0)  # Read ADC value
##
## **Step 4: Record calibration**
##
## .. code-block:: nim
##    if voct.record(reading1V, reading3V):
##      echo "Calibration successful!"
##
## **Step 5: Save calibration (optional but recommended)**
##
## .. code-block:: nim
##    # Save to persistent storage
##    let (scale, offset) = voct.getCalibrationData()
##    settings.voctScale = scale
##    settings.voctOffset = offset
##    storage.save(settings)
##
## **Step 6: Restore calibration on boot**
##
## .. code-block:: nim
##    # Load from persistent storage
##    voct.setData(settings.voctScale, settings.voctOffset)
##
## Using Calibrated Input
## ----------------------
##
## Once calibrated, convert ADC readings to MIDI note numbers:
##
## .. code-block:: nim
##    let cvInput = adc.get(0)         # Raw ADC reading (0.0 - 1.0)
##    let midiNote = voct.processInput(cvInput)
##    
##    echo "CV input: ", cvInput
##    echo "MIDI note: ", midiNote
##    echo "Note name: ", cvToNoteName(midiNote)
##    
##    # Use for pitch control
##    let frequency = midiNoteToFreq(midiNote)
##    oscillator.setFrequency(frequency)
##
## Complete Example
## ----------------
##
## Full calibration workflow with OLED display:
##
## .. code-block:: nim
##    import nimphea_voct_calibration
##    import nimphea_persistent_storage
##    
##    type Settings = object
##      voctScale: float32
##      voctOffset: float32
##    
##    var voct: VoctCalibration
##    var storage: PersistentStorage[Settings]
##    var settings: Settings
##    
##    # On first boot: calibrate
##    if not storage.hasCalibration():
##      oled.setCursor(0, 0)
##      oled.writeString("CALIBRATION", Font_7x10, true)
##      oled.setCursor(0, 12)
##      oled.writeString("Patch 1V", Font_7x10, true)
##      oled.update()
##      
##      # Wait for user to press button
##      waitForButtonPress()
##      let val1V = adc.get(0)
##      
##      oled.fill(false)
##      oled.setCursor(0, 0)
##      oled.writeString("Patch 3V", Font_7x10, true)
##      oled.update()
##      
##      waitForButtonPress()
##      let val3V = adc.get(0)
##      
##      voct.record(val1V, val3V)
##      let (scale, offset) = voct.getCalibrationData()
##      
##      settings.voctScale = scale
##      settings.voctOffset = offset
##      storage.save(settings)
##      
##      oled.fill(false)
##      oled.setCursor(0, 0)
##      oled.writeString("DONE!", Font_7x10, true)
##      oled.update()
##    else:
##      # Restore calibration
##      settings = storage.recall()
##      voct.setData(settings.voctScale, settings.voctOffset)
##    
##    # Main loop: track pitch
##    while true:
##      let cvInput = adc.get(0)
##      let midiNote = voct.processInput(cvInput)
##      let freq = midiNoteToFreq(midiNote)
##      osc.setFrequency(freq)
##
## Buchla Standard (100mV/Semitone)
## ---------------------------------
##
## This module also supports Buchla-style CV calibration:
##
## - **100mV/semitone** instead of 83.33mV/semitone
## - **1.2V/octave** instead of 1V/octave
##
## **Calibration procedure for Buchla:**
##
## .. code-block:: nim
##    # Patch 1.2V (C1) to input
##    let val1V2 = adc.get(0)
##    
##    # Patch 3.6V (C3) to input
##    let val3V6 = adc.get(0)
##    
##    voct.record(val1V2, val3V6)  # Same function works!
##
## Helper Functions
## ----------------
##
## This module provides additional Nim helper functions:
##
## .. code-block:: nim
##    # Convert MIDI note to frequency (Hz)
##    let freq = midiNoteToFreq(60.0)  # 60 = middle C = 261.63 Hz
##    
##    # Convert MIDI note to note name
##    let name = midiNoteToName(60)  # "C4"
##    let name2 = midiNoteToName(61) # "C#4"
##    
##    # Convert CV to note name (combines processInput + midiNoteToName)
##    let name3 = cvToNoteName(voct, cvInput)
##
## See Also
## --------
## - `nimphea_persistent_storage <nimphea_persistent_storage.html>`_ - Save calibration data
## - `examples/voct_tuning.nim` - Complete OLED-guided calibration example
## - `per/adc <adc.html>`_ - Read CV inputs

import nimphea
import nimphea_macros
import std/math  # For pow() in frequency conversion

useNimpheaModules(voct)

{.push header: "util/VoctCalibration.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  VoctCalibration* {.importcpp: "daisy::VoctCalibration".} = object
    ## V/Oct calibration helper for musical pitch CV.
    ##
    ## Converts ADC readings to MIDI note numbers using a two-point
    ## calibration (1V and 3V references).
    ##
    ## **Internal state:**
    ## - Scale factor (semitones per ADC unit)
    ## - Offset (MIDI note number at 0V)
    ## - Calibration valid flag
    ##
    ## **Usage pattern:**
    ## 1. Create object: `var voct: VoctCalibration`
    ## 2. Record calibration: `voct.record(val1V, val3V)`
    ## 3. Process inputs: `let note = voct.processInput(cvReading)`

{.pop.} # header

# ============================================================================
# C++ Method Wrappers
# ============================================================================

proc record*(this: var VoctCalibration, val1V, val3V: cfloat): bool {.
  importcpp: "#.Record(@)".}
  ## Record calibration data from 1V and 3V measurements.
  ##
  ## Calculates scale and offset for converting ADC readings to MIDI notes.
  ##
  ## **Formula:**
  ## - delta = val3V - val1V
  ## - scale = 24 / delta (24 semitones in 2 octaves)
  ## - offset = 12 - scale * val1V (MIDI note 12 = C1 = 1V)
  ##
  ## **Parameters:**
  ## - `val1V` - ADC reading when 1V is applied (0.0 - 1.0 range)
  ## - `val3V` - ADC reading when 3V is applied (0.0 - 1.0 range)
  ##
  ## **Returns:** Always true (calibration always succeeds)
  ##
  ## **Example:**
  ## ```nim
  ## var voct: VoctCalibration
  ## 
  ## # User patches 1V CV source
  ## let reading1V = adc.get(0)  # e.g., 0.2345
  ## 
  ## # User patches 3V CV source
  ## let reading3V = adc.get(0)  # e.g., 0.7012
  ## 
  ## if voct.record(reading1V, reading3V):
  ##   echo "Calibration complete!"
  ## ```
  ##
  ## **Note:** This function does not validate the input range.
  ## Ensure val3V > val1V to avoid division issues.

proc getData*(this: var VoctCalibration, scale, offset: var cfloat): bool {.
  importcpp: "#.GetData(@)".}
  ## Get calibration scale and offset values (C++ style, pass-by-reference).
  ##
  ## **Parameters:**
  ## - `scale` - Output: scale factor (semitones per ADC unit)
  ## - `offset` - Output: offset (MIDI note at 0V)
  ##
  ## **Returns:** True if calibration has been recorded, false otherwise
  ##
  ## **Example:**
  ## ```nim
  ## var scale, offset: cfloat
  ## if voct.getData(scale, offset):
  ##   echo "Scale: ", scale
  ##   echo "Offset: ", offset
  ## else:
  ##   echo "Not calibrated yet"
  ## ```
  ##
  ## **Note:** Prefer the Nim-style `getCalibrationData()` which returns a tuple.

proc setData*(this: var VoctCalibration, scale, offset: cfloat) {.
  importcpp: "#.SetData(@)".}
  ## Manually set calibration data (e.g., loaded from persistent storage).
  ##
  ## Use this to restore calibration after power cycle without redoing
  ## the calibration procedure.
  ##
  ## **Parameters:**
  ## - `scale` - Scale factor from previous calibration
  ## - `offset` - Offset from previous calibration
  ##
  ## **Example:**
  ## ```nim
  ## # Load from persistent storage
  ## let savedSettings = storage.recall()
  ## voct.setData(savedSettings.voctScale, savedSettings.voctOffset)
  ## echo "Calibration restored from storage"
  ## ```

proc processInput*(this: var VoctCalibration, inval: cfloat): cfloat {.
  importcpp: "#.ProcessInput(@)".}
  ## Convert ADC reading to MIDI note number using calibration.
  ##
  ## **Formula:** `midiNote = offset + (scale * inval)`
  ##
  ## **Parameters:**
  ## - `inval` - ADC reading (0.0 - 1.0 range)
  ##
  ## **Returns:** MIDI note number (float, can be fractional for pitch bend)
  ##
  ## **Example:**
  ## ```nim
  ## let cvInput = adc.get(0)  # e.g., 0.4567
  ## let midiNote = voct.processInput(cvInput)
  ## echo "MIDI note: ", midiNote  # e.g., 48.23 (slightly above middle C)
  ## 
  ## # Use for pitch control
  ## let freq = midiNoteToFreq(midiNote)
  ## oscillator.setFrequency(freq)
  ## ```
  ##
  ## **Note:** Returns fractional MIDI note numbers for sub-semitone accuracy.
  ## Round if you need integer note values.

# ============================================================================
# Nim Helper Functions
# ============================================================================

proc getCalibrationData*(this: var VoctCalibration): tuple[scale, offset: float32, valid: bool] =
  ## Get calibration data as a Nim tuple (more idiomatic than getData).
  ##
  ## **Returns:** Tuple with:
  ## - `scale` - Scale factor (semitones per ADC unit)
  ## - `offset` - Offset (MIDI note at 0V)
  ## - `valid` - True if calibration has been performed
  ##
  ## **Example:**
  ## ```nim
  ## let (scale, offset, valid) = voct.getCalibrationData()
  ## if valid:
  ##   echo "Scale: ", scale
  ##   echo "Offset: ", offset
  ##   # Save to persistent storage
  ##   settings.voctScale = scale
  ##   settings.voctOffset = offset
  ##   storage.save(settings)
  ## else:
  ##   echo "Not calibrated - run calibration procedure"
  ## ```
  var scale, offset: cfloat
  let valid = this.getData(scale, offset)
  result = (scale: float32(scale), offset: float32(offset), valid: valid)

proc isCalibrated*(this: var VoctCalibration): bool =
  ## Check if calibration has been performed.
  ##
  ## **Returns:** True if `record()` or `setData()` has been called
  ##
  ## **Example:**
  ## ```nim
  ## if not voct.isCalibrated():
  ##   echo "WARNING: Calibration required!"
  ##   runCalibrationWizard()
  ## ```
  var dummyScale, dummyOffset: cfloat
  result = this.getData(dummyScale, dummyOffset)

proc midiNoteToFreq*(midiNote: float32): float32 =
  ## Convert MIDI note number to frequency in Hz.
  ##
  ## Uses standard formula: `freq = 440 * 2^((note - 69) / 12)`
  ##
  ## **Parameters:**
  ## - `midiNote` - MIDI note number (can be fractional)
  ##
  ## **Returns:** Frequency in Hz
  ##
  ## **Examples:**
  ## ```nim
  ## echo midiNoteToFreq(69.0)  # A4 = 440.0 Hz
  ## echo midiNoteToFreq(60.0)  # C4 = 261.63 Hz (middle C)
  ## echo midiNoteToFreq(48.0)  # C3 = 130.81 Hz
  ## echo midiNoteToFreq(72.0)  # C5 = 523.25 Hz
  ## echo midiNoteToFreq(60.5)  # C4 + 50 cents = ~269.4 Hz
  ## ```
  ##
  ## **Note:** A4 (MIDI note 69) = 440 Hz by definition.
  result = 440.0'f32 * pow(2.0'f32, (midiNote - 69.0'f32) / 12.0'f32)

proc midiNoteToName*(midiNote: int): string =
  ## Convert integer MIDI note number to note name (e.g., "C4", "A#5").
  ##
  ## **Parameters:**
  ## - `midiNote` - Integer MIDI note number (0-127)
  ##
  ## **Returns:** Note name as string (e.g., "C4", "F#3", "Bb5")
  ##
  ## **Examples:**
  ## ```nim
  ## echo midiNoteToName(60)  # "C4" (middle C)
  ## echo midiNoteToName(69)  # "A4" (440 Hz)
  ## echo midiNoteToName(61)  # "C#4"
  ## echo midiNoteToName(70)  # "Bb4"
  ## echo midiNoteToName(0)   # "C0"
  ## echo midiNoteToName(127) # "G9"
  ## ```
  ##
  ## **Note naming:**
  ## - Uses sharps (#) for black keys (C#, D#, F#, G#, A#)
  ## - Octave numbering: C0 = MIDI 0, C4 = MIDI 60 (middle C)
  const noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  let octave = midiNote div 12
  let semitone = midiNote mod 12
  result = noteNames[semitone] & $octave

proc cvToNoteName*(this: var VoctCalibration, cvInput: float32): string =
  ## Convert CV input to note name (combines processInput + midiNoteToName).
  ##
  ## **Parameters:**
  ## - `cvInput` - ADC reading (0.0 - 1.0)
  ##
  ## **Returns:** Note name as string
  ##
  ## **Example:**
  ## ```nim
  ## let cvReading = adc.get(0)
  ## let noteName = voct.cvToNoteName(cvReading)
  ## 
  ## oled.setCursor(0, 0)
  ## oled.writeString("Note: " & noteName, Font_7x10, true)
  ## oled.update()
  ## ```
  ##
  ## **Note:** Rounds to nearest semitone (fractional notes are truncated).
  let midiNote = this.processInput(cfloat(cvInput))
  result = midiNoteToName(int(midiNote + 0.5))  # Round to nearest

proc cvToMidiNote*(this: var VoctCalibration, cvInput: float32): float32 =
  ## Convert CV input to MIDI note number (wrapper for processInput).
  ##
  ## Identical to `processInput()` but with more descriptive name.
  ##
  ## **Parameters:**
  ## - `cvInput` - ADC reading (0.0 - 1.0)
  ##
  ## **Returns:** MIDI note number (float32, can be fractional)
  ##
  ## **Example:**
  ## ```nim
  ## let note = voct.cvToMidiNote(adc.get(0))
  ## let freq = midiNoteToFreq(note)
  ## oscillator.setFrequency(freq)
  ## ```
  result = float32(this.processInput(cfloat(cvInput)))

# ============================================================================
# Usage Examples
# ============================================================================

when isMainModule:
  ## Compile-time examples (not executable without hardware)
  
  # Example 1: Basic calibration
  block:
    var voct: VoctCalibration
    
    # Simulate ADC readings (real code would use actual ADC)
    let reading1V = 0.2345'f32  # ADC value when 1V applied
    let reading3V = 0.7012'f32  # ADC value when 3V applied
    
    if voct.record(reading1V, reading3V):
      echo "Calibration successful"
      let (scale, offset, valid) = voct.getCalibrationData()
      echo "Scale: ", scale, ", Offset: ", offset
  
  # Example 2: Save and restore calibration
  block:
    var voct: VoctCalibration
    
    # Initial calibration
    discard voct.record(0.234, 0.701)
    let (scale, offset, _) = voct.getCalibrationData()
    
    # Simulate power cycle
    var voct2: VoctCalibration
    voct2.setData(scale, offset)
    
    echo "Calibration restored"
  
  # Example 3: Process CV inputs
  block:
    var voct: VoctCalibration
    discard voct.record(0.234, 0.701)
    
    let cvInput = 0.468'f32  # Simulate ADC reading
    let midiNote = voct.cvToMidiNote(cvInput)
    let noteName = midiNoteToName(int(midiNote))
    let freq = midiNoteToFreq(midiNote)
    
    echo "CV: ", cvInput
    echo "MIDI: ", midiNote
    echo "Note: ", noteName
    echo "Freq: ", freq, " Hz"
  
  # Example 4: Frequency conversion
  block:
    echo "A4: ", midiNoteToFreq(69.0), " Hz"  # 440.0
    echo "C4: ", midiNoteToFreq(60.0), " Hz"  # 261.63
    echo "C3: ", midiNoteToFreq(48.0), " Hz"  # 130.81
  
  # Example 5: Note names
  block:
    for note in 60..72:
      echo "MIDI ", note, " = ", midiNoteToName(note)
