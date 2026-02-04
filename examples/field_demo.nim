## Daisy Field Demo - Desktop Controller Showcase
## ===============================================
##
## Comprehensive demonstration of the Daisy Field platform:
## - 8 knobs for parameter control
## - 16-key capacitive touch keyboard (2 rows × 8)
## - 4 CV inputs with ±5V range
## - 2 CV outputs (12-bit DAC)
## - Gate output
## - LED array and OLED display
##
## Hardware Requirements:
## - Daisy Field
##
## Demo Modes (select by uncommenting one):
## - MODE_KEYBOARD: 16-key synth with waveform selection
## - MODE_CV_SEQUENCER: 8-step knob-programmable sequencer
##
## Keyboard Layout:
## - Row 1 (0-7): C4-G4 chromatic
## - Row 2 (8-15): G#4-D#5 chromatic

import panicoverride
import ../src/nimphea
import ../src/boards/daisy_field
import ../src/nimphea_macros
import std/math

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_KEYBOARD = true
const MODE_CV_SEQUENCER = false

const
  SAMPLE_RATE = 48000.0
  TWO_PI = 2.0 * PI
  NOTE_FREQS: array[16, float32] = [
    261.63, 277.18, 293.66, 311.13,  # C4-D#4
    329.63, 349.23, 369.99, 392.00,  # E4-G4
    415.30, 440.00, 466.16, 493.88,  # G#4-B4
    523.25, 554.37, 587.33, 622.25   # C5-D#5
  ]

var field: DaisyField

# ============================================================================
# DEMO 1: KEYBOARD SYNTH
# ============================================================================
## Demonstrates:
## - 16-key capacitive keyboard scanning
## - Monophonic synth with 6 waveforms
## - Envelope with simple attack/release
## - Knob-controlled waveform selection
##
## Controls:
## - Keys 0-15: Play chromatic notes
## - Knob 1: Waveform select (sine/saw/square/triangle/pulse/noise)

when MODE_KEYBOARD:
  type Waveform = enum
    SINE, SAW, SQUARE, TRIANGLE, PULSE, NOISE
  
  var
    phase: float32 = 0.0
    frequency: float32 = 440.0
    amplitude: float32 = 0.0
    waveform = SINE
    activeKey: int = -1
    noiseState: uint32 = 12345
  
  proc generateNoise(): float32 =
    noiseState = noiseState * 1103515245 + 12345
    ((noiseState shr 16) and 0x7FFF).float32 / 16384.0 - 1.0
  
  proc generateSample(wf: Waveform, ph: float32): float32 =
    case wf
    of SINE: sin(ph * TWO_PI).float32
    of SAW: (2.0 * ph - 1.0).float32
    of SQUARE: (if ph < 0.5: 1.0 else: -1.0).float32
    of TRIANGLE: (if ph < 0.5: 4.0 * ph - 1.0 else: 3.0 - 4.0 * ph).float32
    of PULSE: (if ph < 0.25: 1.0 else: -1.0).float32
    of NOISE: generateNoise()
  
  proc audioCallbackKeyboard(input, output: AudioBuffer, size: int) {.cdecl.} =
    let phaseInc = frequency / SAMPLE_RATE
    for i in 0..<size:
      let sample = generateSample(waveform, phase) * amplitude * 0.3
      output[0][i] = sample
      output[1][i] = sample
      phase += phaseInc
      if phase >= 1.0: phase -= 1.0
      if amplitude > 0.001: amplitude *= 0.9995
  
  proc runKeyboardDemo() =
    field.init()
    field.startAdc()
    field.startAudio(audioCallbackKeyboard)
    
    while true:
      field.processAllControls()
      
      # Scan keyboard
      for key in 0..<16:
        if field.keyboardRisingEdge(key.csize_t):
          activeKey = key
          frequency = NOTE_FREQS[key]
          amplitude = 0.8
        if field.keyboardFallingEdge(key.csize_t):
          if activeKey == key:
            activeKey = -1
            amplitude = 0.0
      
      # Waveform selection via knob 1
      let knob1 = field.getKnobValue(KNOB_1.csize_t)
      waveform = Waveform((knob1 * 5.99).int)
      
      field.seed.delay(1)

# ============================================================================
# DEMO 2: CV SEQUENCER
# ============================================================================
## Demonstrates:
## - 8-step sequencer with knob values
## - CV output from DAC
## - Gate output with pattern
## - Keyboard as step selector
## - Auto-advance with adjustable tempo
##
## Controls:
## - Knobs 1-8: Step values
## - Keys 0-7: Jump to step
## - Keys 8-15: Advance sequencer

when MODE_CV_SEQUENCER:
  const NUM_STEPS = 8
  
  var
    stepValues: array[NUM_STEPS, float32]
    currentStep = 0
    gateState = false
    cvInputs: array[4, float32]
  
  proc audioCallbackSeq(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      output[0][i] = input[0][i] * cvInputs[0]
      output[1][i] = input[1][i] * cvInputs[0]
  
  proc advanceStep() =
    currentStep = (currentStep + 1) mod NUM_STEPS
    gateState = (currentStep mod 2) == 0
    field.gate_out.write(gateState)
    field.setCvOut1((stepValues[currentStep] * 4095.0).uint16)
    field.setCvOut2(((1.0 - stepValues[currentStep]) * 4095.0).uint16)
  
  proc runSequencerDemo() =
    field.init()
    field.startAdc()
    field.startAudio(audioCallbackSeq)
    
    for i in 0..<NUM_STEPS:
      stepValues[i] = i.float32 / (NUM_STEPS - 1).float32
    
    var counter = 0
    
    while true:
      field.processAllControls()
      
      # Read CV inputs
      for i in 0..<4:
        let raw = field.getCvValue((FieldCV.CV_1.ord + i).csize_t)
        cvInputs[i] = clamp((raw - 0.5) * 2.0, 0.0, 1.0)
      
      # Keyboard control
      for key in 0..<16:
        if field.keyboardRisingEdge(key.csize_t):
          if key < NUM_STEPS:
            currentStep = key
            advanceStep()
          else:
            advanceStep()
      
      # Read knobs as step values
      for i in 0..<NUM_STEPS:
        stepValues[i] = field.getKnobValue((FieldKnob.KNOB_1.ord + i).csize_t)
      
      # Auto-advance
      counter.inc
      if counter > 500:
        counter = 0
        advanceStep()
      
      field.seed.setLed(currentStep mod 2 == 0)
      field.seed.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_KEYBOARD:
    runKeyboardDemo()
  elif MODE_CV_SEQUENCER:
    runSequencerDemo()
  else:
    field.init()
    while true:
      field.seed.setLed(true)
      field.seed.delay(100)
      field.seed.setLed(false)
      field.seed.delay(100)

when isMainModule:
  main()
