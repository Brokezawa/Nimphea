## Mapped Value Module
## 
## This module provides value mapping and scaling utilities for control parameters.
## Maps normalized 0-1 input to typed ranges (int, float) with quantization and clamping.
## Useful for converting knob/CV inputs to musically meaningful parameter values.
##
## **Key Features:**
## - Map 0-1 input to int or float ranges
## - Step quantization for discrete parameters
## - Bipolar and unipolar range mapping
## - Clamping to min/max bounds
## - Zero heap allocation (pure Nim implementation)
## - Audio-rate safe
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import nimphea_mapped_value
##   
##   # Map knob (0-1) to discrete octave selection (0-4)
##   let knobValue = 0.6
##   let octave = mapValueInt(knobValue, 0, 4)
##   echo "Octave: ", octave  # 2
##   
##   # Map CV input to bipolar range
##   let cvInput = 0.75  # 0-1 from ADC
##   let bipolar = mapValueBipolar(cvInput, -5.0, 5.0)
##   echo "CV: ", bipolar, "V"  # 2.5V
##   
##   # Quantize float to steps
##   let continuous = 0.333
##   let stepped = mapValueFloatQuantized(continuous, 0.0, 1.0, 4)
##   echo "Quantized: ", stepped  # 0.25 (4 steps: 0.0, 0.25, 0.5, 0.75, 1.0)
##
## **Common Use Cases:**
## - Discrete parameter selection (waveform, mode, octave)
## - Quantized control values (semitones, scale degrees)
## - Bipolar CV inputs (-5V to +5V → -1.0 to +1.0)
## - Range clamping and normalization

proc mapValueFloat*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Map normalized 0-1 input to float range.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Linearly mapped float value, clamped to range
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let frequency = mapValueFloat(0.5, 100.0, 1000.0)
  ##   # Result: 550.0
  let clamped = clamp(input, 0.0'f32, 1.0'f32)
  result = min + (clamped * (max - min))

proc mapValueInt*(input: float32, min: int, max: int): int {.inline.} =
  ## Map normalized 0-1 input to integer range.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value (inclusive)
  ## - max: Maximum output value (inclusive)
  ## 
  ## **Returns:**
  ## Linearly mapped integer value
  ## 
  ## **Note:** Useful for discrete parameter selection (modes, octaves, etc.)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let waveform = mapValueInt(0.3, 0, 3)  # 4 waveforms: 0, 1, 2, 3
  ##   # Result: 1 (30% of range)
  let clamped = clamp(input, 0.0'f32, 1.0'f32)
  let range = float32(max - min)
  result = min + int(clamped * range + 0.5)  # Round to nearest
  result = clamp(result, min, max)

proc mapValueFloatQuantized*(input: float32, min: float32, max: float32, 
                             numSteps: int): float32 {.inline.} =
  ## Map 0-1 input to quantized float steps.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## - numSteps: Number of discrete steps (must be > 1)
  ## 
  ## **Returns:**
  ## Float value quantized to nearest step
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   # Quantize to semitones (12 steps per octave)
  ##   let semitone = mapValueFloatQuantized(0.45, 0.0, 12.0, 12)
  ##   # Result: 5.0 (closest semitone)
  ##   
  ##   # Quantize mix to 5% increments (20 steps)
  ##   let mix = mapValueFloatQuantized(0.37, 0.0, 1.0, 20)
  ##   # Result: 0.35
  if numSteps <= 1:
    return min
  
  let clamped = clamp(input, 0.0'f32, 1.0'f32)
  let stepSize = 1.0'f32 / float32(numSteps - 1)
  let stepIndex = int(clamped / stepSize + 0.5)  # Round to nearest step
  let normalizedValue = float32(clamp(stepIndex, 0, numSteps - 1)) / float32(numSteps - 1)
  result = min + (normalizedValue * (max - min))

proc mapValueBipolar*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Map bipolar 0-1 input to range (center at 0.5).
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0, where 0.5 = center)
  ## - min: Output value at input = 0.0 (typically negative)
  ## - max: Output value at input = 1.0 (typically positive)
  ## 
  ## **Returns:**
  ## Linearly mapped bipolar value
  ## 
  ## **Note:** Useful for CV inputs where 0.5 represents 0V
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   # Map CV input to ±5V range
  ##   let cv = mapValueBipolar(0.75, -5.0, 5.0)
  ##   # Result: 2.5V (halfway between center and max)
  ##   
  ##   # Map pan control (0.5 = center)
  ##   let pan = mapValueBipolar(0.5, -1.0, 1.0)
  ##   # Result: 0.0 (center)
  result = mapValueFloat(input, min, max)

proc mapValueUnipolar*(input: float32, max: float32): float32 {.inline.} =
  ## Map unipolar 0-1 input to 0-max range.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Linearly scaled value from 0 to max
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let amplitude = mapValueUnipolar(0.8, 1.0)
  ##   # Result: 0.8
  result = mapValueFloat(input, 0.0, max)

proc normalizeValue*(value: float32, min: float32, max: float32): float32 {.inline.} =
  ## Normalize a value from range to 0-1.
  ## 
  ## **Parameters:**
  ## - value: Input value in range [min, max]
  ## - min: Minimum of input range
  ## - max: Maximum of input range
  ## 
  ## **Returns:**
  ## Normalized value in range [0.0, 1.0]
  ## 
  ## **Note:** Inverse operation of mapValueFloat
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let normalized = normalizeValue(440.0, 20.0, 20000.0)
  ##   # Result: ~0.021 (440 Hz in 20-20000 Hz range)
  if max == min:
    return 0.0
  let clamped = clamp(value, min, max)
  result = (clamped - min) / (max - min)

proc normalizeValueInt*(value: int, min: int, max: int): float32 {.inline.} =
  ## Normalize an integer value from range to 0-1.
  ## 
  ## **Parameters:**
  ## - value: Input value in range [min, max]
  ## - min: Minimum of input range
  ## - max: Maximum of input range
  ## 
  ## **Returns:**
  ## Normalized value in range [0.0, 1.0]
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let normalized = normalizeValueInt(2, 0, 4)
  ##   # Result: 0.5 (middle of 0-4 range)
  if max == min:
    return 0.0
  let clamped = clamp(value, min, max)
  result = float32(clamped - min) / float32(max - min)

proc quantizeFloat*(value: float32, stepSize: float32): float32 {.inline.} =
  ## Quantize a float value to nearest step.
  ## 
  ## **Parameters:**
  ## - value: Input value
  ## - stepSize: Size of quantization steps
  ## 
  ## **Returns:**
  ## Value rounded to nearest multiple of stepSize
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let quantized = quantizeFloat(3.7, 0.5)
  ##   # Result: 3.5 (nearest 0.5 step)
  ##   
  ##   # Quantize frequency to 10 Hz steps
  ##   let freq = quantizeFloat(447.3, 10.0)
  ##   # Result: 450.0
  if stepSize <= 0.0:
    return value
  result = float32(int(value / stepSize + 0.5)) * stepSize

proc lerp*(a: float32, b: float32, t: float32): float32 {.inline.} =
  ## Linear interpolation between two values.
  ## 
  ## **Parameters:**
  ## - a: Start value (at t = 0.0)
  ## - b: End value (at t = 1.0)
  ## - t: Interpolation factor (0.0 to 1.0)
  ## 
  ## **Returns:**
  ## Interpolated value
  ## 
  ## **Note:** t is not clamped - extrapolation allowed
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let mid = lerp(100.0, 200.0, 0.5)
  ##   # Result: 150.0
  result = a + (t * (b - a))

proc inverseLerp*(a: float32, b: float32, value: float32): float32 {.inline.} =
  ## Inverse linear interpolation - find t for a given value.
  ## 
  ## **Parameters:**
  ## - a: Start value
  ## - b: End value
  ## - value: Target value
  ## 
  ## **Returns:**
  ## Interpolation factor t where lerp(a, b, t) = value
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let t = inverseLerp(100.0, 200.0, 150.0)
  ##   # Result: 0.5
  if b == a:
    return 0.0
  result = (value - a) / (b - a)
