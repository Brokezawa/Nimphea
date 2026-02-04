## Unit tests for MappedValue (Value mapping and scaling utilities)
##
## Tests pure Nim implementation of value mapping, quantization, and interpolation.
## Used for converting control inputs to parameter values.
##
## Run with: nimble test_unit

import unittest2
import std/math
import ../src/nimphea_mapped_value

suite "MappedValue: Float Mapping":
  test "should map 0-1 to float range":
    check abs(mapValueFloat(0.0, 100.0, 200.0) - 100.0) < 0.001
    check abs(mapValueFloat(0.5, 100.0, 200.0) - 150.0) < 0.001
    check abs(mapValueFloat(1.0, 100.0, 200.0) - 200.0) < 0.001
  
  test "should clamp input to 0-1":
    check abs(mapValueFloat(-0.5, 0.0, 100.0) - 0.0) < 0.001  # Below 0
    check abs(mapValueFloat(1.5, 0.0, 100.0) - 100.0) < 0.001  # Above 1
  
  test "should handle inverted ranges":
    check abs(mapValueFloat(0.0, 200.0, 100.0) - 200.0) < 0.001
    check abs(mapValueFloat(1.0, 200.0, 100.0) - 100.0) < 0.001
    check abs(mapValueFloat(0.5, 200.0, 100.0) - 150.0) < 0.001

suite "MappedValue: Integer Mapping":
  test "should map 0-1 to int range":
    check mapValueInt(0.0, 0, 4) == 0
    check mapValueInt(0.25, 0, 4) == 1
    check mapValueInt(0.5, 0, 4) == 2
    check mapValueInt(0.75, 0, 4) == 3
    check mapValueInt(1.0, 0, 4) == 4
  
  test "should round to nearest integer":
    check mapValueInt(0.12, 0, 10) == 1  # Rounds to nearest
    check mapValueInt(0.18, 0, 10) == 2
  
  test "should clamp to range bounds":
    check mapValueInt(-0.5, 0, 10) == 0   # Below 0
    check mapValueInt(1.5, 0, 10) == 10   # Above 1
  
  test "should handle negative ranges":
    check mapValueInt(0.0, -10, 10) == -10
    check mapValueInt(0.5, -10, 10) == 0
    check mapValueInt(1.0, -10, 10) == 10

suite "MappedValue: Float Quantization":
  test "should quantize to discrete steps":
    # 5 steps: 0.0, 0.25, 0.5, 0.75, 1.0
    check abs(mapValueFloatQuantized(0.0, 0.0, 1.0, 5) - 0.0) < 0.001
    check abs(mapValueFloatQuantized(0.1, 0.0, 1.0, 5) - 0.0) < 0.001  # Rounds to 0.0
    check abs(mapValueFloatQuantized(0.3, 0.0, 1.0, 5) - 0.25) < 0.001 # Rounds to 0.25
    check abs(mapValueFloatQuantized(0.5, 0.0, 1.0, 5) - 0.5) < 0.001
    check abs(mapValueFloatQuantized(0.9, 0.0, 1.0, 5) - 1.0) < 0.001  # Rounds to 1.0
  
  test "should quantize semitones (12 steps)":
    # Test musical semitone quantization
    let semitone0 = mapValueFloatQuantized(0.0, 0.0, 12.0, 12)
    let semitone5 = mapValueFloatQuantized(0.42, 0.0, 12.0, 12)  # ~5th semitone
    let semitone12 = mapValueFloatQuantized(1.0, 0.0, 12.0, 12)
    
    check abs(semitone0 - 0.0) < 0.001
    check abs(semitone5 - 5.0) < 0.5  # Within 0.5 semitone tolerance
    check abs(semitone12 - 12.0) < 0.001
  
  test "should handle numSteps = 1":
    check abs(mapValueFloatQuantized(0.5, 0.0, 100.0, 1) - 0.0) < 0.001  # Returns min
  
  test "should handle numSteps = 2":
    check abs(mapValueFloatQuantized(0.0, 0.0, 10.0, 2) - 0.0) < 0.001
    # 2 steps means values at 0.0 and 1.0 → outputs 0.0 or 10.0
    let mid = mapValueFloatQuantized(0.5, 0.0, 10.0, 2)
    check mid in [0.0'f32, 10.0'f32]  # Should be one of the two steps
    check abs(mapValueFloatQuantized(1.0, 0.0, 10.0, 2) - 10.0) < 0.001

suite "MappedValue: Bipolar Mapping":
  test "should map with center at 0.5":
    check abs(mapValueBipolar(0.0, -5.0, 5.0) - (-5.0)) < 0.001
    check abs(mapValueBipolar(0.5, -5.0, 5.0) - 0.0) < 0.001  # Center
    check abs(mapValueBipolar(1.0, -5.0, 5.0) - 5.0) < 0.001
  
  test "should work for pan control":
    check abs(mapValueBipolar(0.0, -1.0, 1.0) - (-1.0)) < 0.001  # Full left
    check abs(mapValueBipolar(0.5, -1.0, 1.0) - 0.0) < 0.001     # Center
    check abs(mapValueBipolar(1.0, -1.0, 1.0) - 1.0) < 0.001     # Full right
  
  test "should handle quarter positions":
    check abs(mapValueBipolar(0.25, -10.0, 10.0) - (-5.0)) < 0.001
    check abs(mapValueBipolar(0.75, -10.0, 10.0) - 5.0) < 0.001

suite "MappedValue: Unipolar Mapping":
  test "should map 0-1 to 0-max":
    check abs(mapValueUnipolar(0.0, 100.0) - 0.0) < 0.001
    check abs(mapValueUnipolar(0.5, 100.0) - 50.0) < 0.001
    check abs(mapValueUnipolar(1.0, 100.0) - 100.0) < 0.001
  
  test "should work for amplitude scaling":
    check abs(mapValueUnipolar(0.0, 1.0) - 0.0) < 0.001
    check abs(mapValueUnipolar(0.8, 1.0) - 0.8) < 0.001
    check abs(mapValueUnipolar(1.0, 1.0) - 1.0) < 0.001

suite "MappedValue: Normalization":
  test "should normalize float values to 0-1":
    check abs(normalizeValue(100.0, 0.0, 200.0) - 0.5) < 0.001
    check abs(normalizeValue(0.0, 0.0, 100.0) - 0.0) < 0.001
    check abs(normalizeValue(100.0, 0.0, 100.0) - 1.0) < 0.001
  
  test "should normalize frequency range":
    # Normalize 440 Hz in 20-20000 Hz range
    let normalized = normalizeValue(440.0, 20.0, 20000.0)
    check normalized > 0.02
    check normalized < 0.03
  
  test "should clamp out-of-range values":
    check abs(normalizeValue(-50.0, 0.0, 100.0) - 0.0) < 0.001  # Below min
    check abs(normalizeValue(150.0, 0.0, 100.0) - 1.0) < 0.001  # Above max
  
  test "should handle min = max":
    check abs(normalizeValue(50.0, 50.0, 50.0) - 0.0) < 0.001  # Returns 0
  
  test "should be inverse of mapValueFloat":
    let original = 0.6'f32
    let mapped = mapValueFloat(original, 100.0, 500.0)
    let normalized = normalizeValue(mapped, 100.0, 500.0)
    check abs(normalized - original) < 0.001

suite "MappedValue: Integer Normalization":
  test "should normalize int values to 0-1":
    check abs(normalizeValueInt(2, 0, 4) - 0.5) < 0.001
    check abs(normalizeValueInt(0, 0, 10) - 0.0) < 0.001
    check abs(normalizeValueInt(10, 0, 10) - 1.0) < 0.001
  
  test "should handle negative ranges":
    check abs(normalizeValueInt(0, -10, 10) - 0.5) < 0.001
    check abs(normalizeValueInt(-10, -10, 10) - 0.0) < 0.001
    check abs(normalizeValueInt(10, -10, 10) - 1.0) < 0.001
  
  test "should clamp out-of-range values":
    check abs(normalizeValueInt(-5, 0, 10) - 0.0) < 0.001  # Below min
    check abs(normalizeValueInt(15, 0, 10) - 1.0) < 0.001  # Above max

suite "MappedValue: Float Quantization":
  test "should quantize to step size":
    check abs(quantizeFloat(3.7, 0.5) - 3.5) < 0.001
    check abs(quantizeFloat(3.8, 0.5) - 4.0) < 0.001
    check abs(quantizeFloat(3.2, 0.5) - 3.0) < 0.001
  
  test "should quantize frequency to 10 Hz steps":
    check abs(quantizeFloat(447.3, 10.0) - 450.0) < 0.001
    check abs(quantizeFloat(443.0, 10.0) - 440.0) < 0.001
  
  test "should handle stepSize <= 0":
    check abs(quantizeFloat(3.7, 0.0) - 3.7) < 0.001  # Returns original
    check abs(quantizeFloat(3.7, -1.0) - 3.7) < 0.001  # Returns original
  
  test "should quantize to integer steps":
    check abs(quantizeFloat(2.3, 1.0) - 2.0) < 0.001
    check abs(quantizeFloat(2.7, 1.0) - 3.0) < 0.001

suite "MappedValue: Linear Interpolation":
  test "should interpolate between values":
    check abs(lerp(100.0, 200.0, 0.0) - 100.0) < 0.001
    check abs(lerp(100.0, 200.0, 0.5) - 150.0) < 0.001
    check abs(lerp(100.0, 200.0, 1.0) - 200.0) < 0.001
  
  test "should allow extrapolation":
    check abs(lerp(100.0, 200.0, 1.5) - 250.0) < 0.001  # Beyond b
    check abs(lerp(100.0, 200.0, -0.5) - 50.0) < 0.001  # Before a
  
  test "should handle negative values":
    check abs(lerp(-10.0, 10.0, 0.5) - 0.0) < 0.001
    check abs(lerp(-100.0, -50.0, 0.5) - (-75.0)) < 0.001

suite "MappedValue: Inverse Lerp":
  test "should find interpolation factor":
    check abs(inverseLerp(100.0, 200.0, 150.0) - 0.5) < 0.001
    check abs(inverseLerp(100.0, 200.0, 100.0) - 0.0) < 0.001
    check abs(inverseLerp(100.0, 200.0, 200.0) - 1.0) < 0.001
  
  test "should handle values outside range":
    check abs(inverseLerp(100.0, 200.0, 250.0) - 1.5) < 0.001  # Beyond b
    check abs(inverseLerp(100.0, 200.0, 50.0) - (-0.5)) < 0.001  # Before a
  
  test "should be inverse of lerp":
    let t = 0.6'f32
    let value = lerp(100.0, 500.0, t)
    let recovered = inverseLerp(100.0, 500.0, value)
    check abs(recovered - t) < 0.001
  
  test "should handle a = b":
    check abs(inverseLerp(50.0, 50.0, 50.0) - 0.0) < 0.001  # Returns 0

suite "MappedValue: Practical Usage":
  test "should map knob to octave selection":
    # Knob value 0-1 → Octave 0-4
    check mapValueInt(0.0, 0, 4) == 0
    check mapValueInt(0.3, 0, 4) in [1, 2]  # Around octave 1-2
    check mapValueInt(0.6, 0, 4) in [2, 3]  # Around octave 2-3
    check mapValueInt(1.0, 0, 4) == 4
  
  test "should map CV to bipolar voltage":
    # ADC 0-1 → -5V to +5V
    let cv0 = mapValueBipolar(0.0, -5.0, 5.0)
    let cv_center = mapValueBipolar(0.5, -5.0, 5.0)
    let cv_max = mapValueBipolar(1.0, -5.0, 5.0)
    
    check abs(cv0 - (-5.0)) < 0.001
    check abs(cv_center - 0.0) < 0.001
    check abs(cv_max - 5.0) < 0.001
  
  test "should quantize frequency to musical steps":
    # Quantize 447 Hz to nearest 10 Hz
    let freq = quantizeFloat(447.0, 10.0)
    check abs(freq - 450.0) < 0.001
  
  test "should blend between parameter values":
    # Crossfade between two filter cutoffs
    let cutoff_a = 200.0'f32
    let cutoff_b = 2000.0'f32
    
    let blend_0 = lerp(cutoff_a, cutoff_b, 0.0)
    let blend_50 = lerp(cutoff_a, cutoff_b, 0.5)
    let blend_100 = lerp(cutoff_a, cutoff_b, 1.0)
    
    check abs(blend_0 - 200.0) < 0.001
    check abs(blend_50 - 1100.0) < 0.001
    check abs(blend_100 - 2000.0) < 0.001
  
  test "should normalize and remap values":
    # Convert MIDI note (0-127) to frequency range
    let midiNote = 60'f32  # Middle C
    let normalized = normalizeValue(midiNote, 0.0, 127.0)
    let frequency = mapValueFloat(normalized, 20.0, 20000.0)
    
    check normalized > 0.45
    check normalized < 0.50
    check frequency > 9000.0
    check frequency < 10000.0
