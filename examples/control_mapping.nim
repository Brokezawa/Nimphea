## Control Mapping Example
## 
## This example demonstrates parameter and value mapping utilities:
## - Parameter mapping with curves (linear, exponential, logarithmic, cubic)
## - MappedValue for range conversion and quantization
## - Practical use cases for synthesizer/audio parameters
##
## Shows how to map control inputs (knobs, CV) to musically useful ranges
## with appropriate scaling curves for natural feel.

import ../src/nimphea
import ../src/hid/parameter
import ../src/nimphea_mapped_value
import ../src/nimphea_fixedstr
import math

useNimpheaNamespace()

var
  daisy: DaisySeed
  ledState: bool = false

proc demonstrateCurveTypes() =
  ## Show different curve types and their effect
  echo "======================================"
  echo "  Parameter Curve Types"
  echo "======================================"
  echo ""
  
  let testValues = [0.0'f32, 0.25'f32, 0.5'f32, 0.75'f32, 1.0'f32]
  
  # Linear mapping (direct proportion)
  echo "Linear Curve (0-100):"
  for val in testValues:
    let mapped = mapParameter(val, 0.0, 100.0, LINEAR)
    echo "  Input ", val, " -> ", mapped
  echo ""
  
  # Exponential curve (good for frequency)
  echo "Exponential Curve (20-20000 Hz):"
  for val in testValues:
    let freq = mapParameter(val, 20.0, 20000.0, EXPONENTIAL)
    echo "  Input ", val, " -> ", int(freq), " Hz"
  echo ""
  
  # Logarithmic curve (good for volume)
  echo "Logarithmic Curve (0-1 volume):"
  for val in testValues:
    let volume = mapParameter(val, 0.0, 1.0, LOGARITHMIC)
    echo "  Input ", val, " -> ", volume
  echo ""
  
  # Cubic curve (smooth S-curve)
  echo "Cubic Curve (0-100):"
  for val in testValues:
    let mapped = mapParameter(val, 0.0, 100.0, CUBE)
    echo "  Input ", val, " -> ", mapped
  echo ""

proc demonstrateSynthParameters() =
  ## Realistic synthesizer parameter mappings
  echo "======================================"
  echo "  Synthesizer Parameter Mapping"
  echo "======================================"
  echo ""
  
  # Simulated knob positions (0.0 to 1.0)
  let cutoffKnob = 0.6'f32
  let resonanceKnob = 0.75'f32
  let attackKnob = 0.3'f32
  let octaveKnob = 0.4'f32
  let waveformKnob = 0.7'f32
  
  # Filter cutoff: 100 Hz to 10 kHz (exponential feels natural)
  let cutoffFreq = mapParameterExp(cutoffKnob, 100.0, 10000.0)
  echo "Cutoff Knob at ", cutoffKnob, " -> ", int(cutoffFreq), " Hz (exponential)"
  
  # Resonance: 0 to 1 (linear is fine for resonance)
  let resonance = mapParameterLin(resonanceKnob, 0.0, 1.0)
  echo "Resonance Knob at ", resonanceKnob, " -> ", resonance, " (linear)"
  
  # Envelope attack: 1ms to 5000ms (exponential for time feels good)
  let attackMs = mapParameterExp(attackKnob, 1.0, 5000.0)
  echo "Attack Knob at ", attackKnob, " -> ", int(attackMs), " ms (exponential)"
  
  # Octave selection: -2 to +2 (quantized to discrete values)
  let octave = mapValueInt(octaveKnob, -2, 2)
  echo "Octave Knob at ", octaveKnob, " -> ", octave, " octaves (quantized)"
  
  # Waveform selection: 0=Sine, 1=Saw, 2=Square, 3=Triangle
  let waveform = mapValueInt(waveformKnob, 0, 3)
  let waveNames = ["Sine", "Saw", "Square", "Triangle"]
  echo "Waveform Knob at ", waveformKnob, " -> ", waveNames[waveform]
  echo ""

proc demonstrateQuantization() =
  ## Show quantization for discrete parameters
  echo "======================================"
  echo "  Value Quantization"
  echo "======================================"
  echo ""
  
  # Quantize frequency to semitones
  echo "Quantizing to semitones (12 steps/octave):"
  let baseFreq = 220.0'f32  # A3
  for knobVal in [0.0'f32, 0.2'f32, 0.5'f32, 0.8'f32, 1.0'f32]:
    let semitone = mapValueFloatQuantized(knobVal, 0.0, 12.0, 12)
    let freq = baseFreq * pow(2.0, semitone / 12.0)
    echo "  Knob ", knobVal, " -> semitone ", int(semitone), " = ", int(freq), " Hz"
  echo ""
  
  # Quantize mix to 10% increments
  echo "Quantizing mix to 10% steps:"
  for knobVal in [0.23'f32, 0.47'f32, 0.68'f32, 0.95'f32]:
    let mixPercent = mapValueFloatQuantized(knobVal, 0.0, 100.0, 10)
    echo "  Knob ", knobVal, " -> ", int(mixPercent), "%"
  echo ""

proc demonstrateBipolarMapping() =
  ## Show bipolar CV/parameter mapping
  echo "======================================"
  echo "  Bipolar Parameter Mapping"
  echo "======================================"
  echo ""
  
  echo "Pan control (center at 0.5):"
  for cvInput in [0.0'f32, 0.25'f32, 0.5'f32, 0.75'f32, 1.0'f32]:
    let pan = mapValueBipolar(cvInput, -1.0, 1.0)
    let position = if pan < -0.1: "Left"
                   elif pan > 0.1: "Right"
                   else: "Center"
    echo "  CV ", cvInput, " -> Pan ", pan, " (", position, ")"
  echo ""
  
  echo "Pitch bend ±2 semitones (center at 0.5):"
  for cvInput in [0.0'f32, 0.5'f32, 1.0'f32]:
    let bendSemitones = mapValueBipolar(cvInput, -2.0, 2.0)
    echo "  CV ", cvInput, " -> ", bendSemitones, " semitones"
  echo ""

proc demonstrateNormalizationRoundtrip() =
  ## Show normalization and denormalization
  echo "======================================"
  echo "  Normalization Round-Trip"
  echo "======================================"
  echo ""
  
  let originalFreq = 440.0'f32
  let minFreq = 20.0'f32
  let maxFreq = 20000.0'f32
  
  # Normalize frequency to 0-1
  let normalized = normalizeValue(originalFreq, minFreq, maxFreq)
  echo "Frequency ", int(originalFreq), " Hz in range ", int(minFreq), "-", int(maxFreq), " Hz"
  echo "  -> Normalized: ", normalized
  
  # Map back to frequency
  let restored = mapValueFloat(normalized, minFreq, maxFreq)
  echo "  -> Restored: ", int(restored), " Hz"
  
  # Integer round-trip
  let originalOctave = 2
  let normOctave = normalizeValueInt(originalOctave, 0, 4)
  let restoredOctave = mapValueInt(normOctave, 0, 4)
  echo ""
  echo "Octave ", originalOctave, " in range 0-4"
  echo "  -> Normalized: ", normOctave
  echo "  -> Restored: ", restoredOctave
  echo ""

proc demonstrateUtilityFunctions() =
  ## Show utility functions (lerp, clamp, etc.)
  echo "======================================"
  echo "  Utility Functions"
  echo "======================================"
  echo ""
  
  # Linear interpolation
  echo "Lerp between 100 and 200:"
  for t in [0.0'f32, 0.25'f32, 0.5'f32, 0.75'f32, 1.0'f32]:
    let value = lerp(100.0, 200.0, t)
    echo "  t=", t, " -> ", value
  echo ""
  
  # Inverse lerp
  echo "Inverse lerp (find t for given value):"
  for value in [100.0'f32, 125.0'f32, 150.0'f32, 175.0'f32, 200.0'f32]:
    let t = inverseLerp(100.0, 200.0, value)
    echo "  value=", value, " -> t=", t
  echo ""
  
  # Clamping
  echo "Clamping values to range 0.0-1.0:"
  for value in [-0.5'f32, 0.0'f32, 0.5'f32, 1.0'f32, 1.5'f32]:
    let clamped = clamp(value, 0.0'f32, 1.0'f32)
    echo "  value=", value, " -> clamped=", clamped
  echo ""
  
  # Quantization
  echo "Quantize to 0.1 steps:"
  for value in [0.23'f32, 0.47'f32, 0.68'f32, 0.95'f32]:
    let quantized = quantizeFloat(value, 0.1)
    echo "  value=", value, " -> quantized=", quantized
  echo ""

proc demonstrateDisplayFormatting() =
  ## Show using FixedStr with parameter values for display
  echo "======================================"
  echo "  Display Formatting"
  echo "======================================"
  echo ""
  
  var displayLine: FixedStr[32]
  
  # Filter display
  displayLine.init()
  discard displayLine.add("Cutoff: ")
  let cutoff = mapParameterExp(0.7, 100.0, 10000.0)
  discard displayLine.add(int(cutoff))
  discard displayLine.add(" Hz")
  echo $displayLine
  
  # Volume display
  displayLine.clear()
  discard displayLine.add("Vol: ")
  let volume = mapParameterLog(0.8, 0.0, 1.0)
  discard displayLine.add(int(volume * 100.0))
  discard displayLine.add("%")
  echo $displayLine
  
  # Waveform display
  displayLine.clear()
  discard displayLine.add("Wave: ")
  let waveIdx = mapValueInt(0.5, 0, 3)
  let waveName = case waveIdx
    of 0: "Sine"
    of 1: "Saw"
    of 2: "Square"
    else: "Triangle"
  discard displayLine.add(waveName)
  echo $displayLine
  
  echo ""

proc main() =
  echo "======================================"
  echo "  Nimphea Control Mapping Demo"
  echo "======================================"
  echo ""
  
  # Initialize hardware
  daisy.init()
  
  # Run all demonstrations
  demonstrateCurveTypes()
  demonstrateSynthParameters()
  demonstrateQuantization()
  demonstrateBipolarMapping()
  demonstrateNormalizationRoundtrip()
  demonstrateUtilityFunctions()
  demonstrateDisplayFormatting()
  
  echo "======================================"
  echo "  Demo Complete - Blinking LED"
  echo "======================================"
  echo ""
  
  # Blink LED to show we're done
  while true:
    ledState = not ledState
    daisy.setLed(ledState)
    daisy.delay(500)

when isMainModule:
  main()
