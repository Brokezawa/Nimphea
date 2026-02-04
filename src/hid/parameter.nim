## Parameter Mapping Module
## 
## This module provides parameter mapping with different scaling curves.
## Maps a normalized 0-1 input (e.g., from a knob or CV input) to a custom range
## with various transformation curves (linear, exponential, logarithmic, cubic).
##
## **Key Features:**
## - Map 0-1 input to any min-max range
## - Multiple curve types for natural feel
## - Exponential curves for frequency parameters
## - Logarithmic curves for attenuation/volume
## - Cubic curves for smooth non-linear response
## - Audio-rate safe transformations
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import hid/parameter
##   
##   # Map knob value to frequency range with exponential curve
##   let knobValue = 0.5  # From ADC (0.0 to 1.0)
##   let frequency = mapParameter(knobValue, 20.0, 20000.0, EXPONENTIAL)
##   echo "Frequency: ", frequency, " Hz"
##   
##   # Map different parameter types
##   let cutoff = mapParameter(0.7, 100.0, 10000.0, EXPONENTIAL)
##   let volume = mapParameter(0.8, 0.0, 1.0, LOGARITHMIC)
##   let mix = mapParameter(0.5, 0.0, 1.0, LINEAR)
##
## **Curve Types:**
## - LINEAR: Direct proportional mapping (y = x)
## - EXPONENTIAL: Fast rise at high end (ideal for frequency)
## - LOGARITHMIC: Fast rise at low end (ideal for volume/attenuation)
## - CUBE: Smooth S-curve (cubic transformation)
##
## **Performance Notes:**
## - All transformations use simple math (no table lookups)
## - Safe to call in audio callback
## - No memory allocation

import nimphea_macros

useNimpheaModules(parameter)

type
  Curve* {.importcpp: "daisy::Parameter::Curve", header: "hid/parameter.h", pure.} = enum
    ## Parameter scaling curve types.
    ## 
    ## **Values:**
    ## - LINEAR: Direct proportional mapping (y = x)
    ## - EXPONENTIAL: Exponential curve (fast rise at high end)
    ## - LOGARITHMIC: Logarithmic curve (fast rise at low end)
    ## - CUBE: Cubic curve (smooth S-curve)
    LINEAR = 0
    EXPONENTIAL = 1
    LOGARITHMIC = 2
    CUBE = 3

proc mapParameter*(input: float32, min: float32, max: float32, curve: Curve): float32 =
  ## Map a normalized 0-1 input to a custom range with scaling curve.
  ## 
  ## **Parameters:**
  ## - input: Normalized input value (0.0 to 1.0)
  ## - min: Minimum output value (when input = 0.0)
  ## - max: Maximum output value (when input = 1.0)
  ## - curve: Transformation curve to apply
  ## 
  ## **Returns:**
  ## Mapped value in range [min, max] with curve applied
  ## 
  ## **Note:** Input values outside 0-1 are clamped.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   # Exponential frequency mapping (natural feel for pitch)
  ##   let freq = mapParameter(0.5, 20.0, 20000.0, EXPONENTIAL)
  ##   
  ##   # Logarithmic volume mapping (natural feel for amplitude)
  ##   let vol = mapParameter(0.75, 0.0, 1.0, LOGARITHMIC)
  ##   
  ##   # Linear mix parameter
  ##   let mix = mapParameter(0.5, 0.0, 1.0, LINEAR)
  
  # Clamp input to 0-1 range
  var x = input
  if x < 0.0: x = 0.0
  if x > 1.0: x = 1.0
  
  # Apply curve transformation
  var scaled: float32
  case curve
  of LINEAR:
    scaled = x
  of EXPONENTIAL:
    # Exponential: fast rise at high end
    # Good for frequency parameters (feels natural)
    scaled = x * x
  of LOGARITHMIC:
    # Logarithmic: fast rise at low end
    # Good for volume/attenuation (feels natural)
    if x > 0.0:
      # log curve approximation: 1 - (1-x)^2
      let inverted = 1.0 - x
      scaled = 1.0 - (inverted * inverted)
    else:
      scaled = 0.0
  of CUBE:
    # Cubic: smooth S-curve
    scaled = x * x * x
  
  # Map to output range
  result = min + (scaled * (max - min))

proc mapParameterExp*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Convenience function for exponential parameter mapping.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Exponentially mapped value
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let cutoffFreq = mapParameterExp(knobValue, 100.0, 10000.0)
  result = mapParameter(input, min, max, EXPONENTIAL)

proc mapParameterLog*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Convenience function for logarithmic parameter mapping.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Logarithmically mapped value
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let volume = mapParameterLog(knobValue, 0.0, 1.0)
  result = mapParameter(input, min, max, LOGARITHMIC)

proc mapParameterLin*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Convenience function for linear parameter mapping.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Linearly mapped value
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let mixAmount = mapParameterLin(knobValue, 0.0, 1.0)
  result = mapParameter(input, min, max, LINEAR)

proc mapParameterCube*(input: float32, min: float32, max: float32): float32 {.inline.} =
  ## Convenience function for cubic parameter mapping.
  ## 
  ## **Parameters:**
  ## - input: Normalized input (0.0 to 1.0)
  ## - min: Minimum output value
  ## - max: Maximum output value
  ## 
  ## **Returns:**
  ## Cubic curve mapped value
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let smoothParam = mapParameterCube(knobValue, 0.0, 100.0)
  result = mapParameter(input, min, max, CUBE)
