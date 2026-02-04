## Daisy Patch Demo - Eurorack Module Showcase
## ============================================
##
## Comprehensive demonstration of the Daisy Patch Eurorack module:
## - 4 CV/knob inputs with configurable ranges
## - 2 gate inputs for triggers and clocks
## - Rotary encoder with button
## - OLED display support
## - Stereo audio I/O
##
## Hardware Requirements:
## - Daisy Patch (Eurorack format)
##
## Demo Modes (select by uncommenting one):
## - MODE_SIMPLE: Basic control reading and LED feedback
## - MODE_EFFECT: Multi-effect audio processor
## - MODE_CV_UTIL: CV processor utilities (quantizer, slew, S&H)
##
## Pin Reference:
## - CTRL_1-4: CV knob inputs
## - GATE_IN_1-2: Gate inputs
## - Audio In/Out: Stereo 3.5mm

import panicoverride
import ../src/nimphea
import ../src/boards/daisy_patch
import ../src/nimphea_macros
import std/math

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_SIMPLE = true
const MODE_EFFECT = false
const MODE_CV_UTIL = false

const
  SAMPLE_RATE = 48000.0
  MAX_DELAY = 24000  # 0.5 seconds at 48kHz

var
  patch: DaisyPatch

# ============================================================================
# DEMO 1: SIMPLE CONTROL TEST
# ============================================================================
## Demonstrates:
## - Reading CV/knob values
## - Gate input detection
## - Encoder interaction
## - LED control
##
## Controls:
## - Knob 1: LED blink rate
## - Encoder: Not used in this mode
## - Gates: Show on LED

when MODE_SIMPLE:
  proc runSimpleDemo() =
    patch.init()
    
    var ledState = false
    var counter = 0
    
    while true:
      patch.processAllControls()
      
      # Blink LED based on knob 1 position
      counter.inc
      let blinkRate = int(patch.getKnobValue(CTRL_1) * 1000.0) + 50
      if counter > blinkRate:
        counter = 0
        ledState = not ledState
        patch.seed.setLed(ledState)
      
      # Override LED if gate is high
      if patch.gateInputTrig(GATE_IN_1):
        patch.seed.setLed(true)
      
      patch.delayMs(1)

# ============================================================================
# DEMO 2: MULTI-EFFECT PROCESSOR
# ============================================================================
## Demonstrates:
## - Stereo audio processing
## - Effect selection with encoder
## - CV modulation of parameters
## - Gate-triggered bypass
##
## Effects: Delay, Feedback, Distortion, Filter
##
## Controls:
## - Knob 1: Effect parameter
## - Knob 2: Wet/dry mix
## - Encoder rotate: Select effect
## - Encoder press: Cycle parameter target
## - Gate 1: Bypass toggle

when MODE_EFFECT:
  type
    EffectType = enum
      FX_DELAY, FX_FEEDBACK, FX_DISTORTION, FX_FILTER
  
  var
    currentEffect = FX_DELAY
    paramValue: float32 = 0.5
    mixValue: float32 = 0.5
    bypass = false
    
    # Effect state
    delayBuffer: array[MAX_DELAY, float32]
    delayIndex = 0
    filterState: float32 = 0.0
  
  proc processDelay(input: float32, time: float32): float32 =
    let samples = int(time * float32(MAX_DELAY - 1))
    let delayed = delayBuffer[(delayIndex - samples + MAX_DELAY) mod MAX_DELAY]
    delayBuffer[delayIndex] = input + delayed * 0.4
    delayIndex = (delayIndex + 1) mod MAX_DELAY
    delayed
  
  proc processFeedback(input: float32, amount: float32): float32 =
    let idx = (delayIndex - 1000 + MAX_DELAY) mod MAX_DELAY
    let feedback = delayBuffer[idx]
    delayBuffer[delayIndex] = input + feedback * amount
    delayIndex = (delayIndex + 1) mod MAX_DELAY
    input + feedback * 0.5
  
  proc processDistortion(input: float32, drive: float32): float32 =
    let driven = input * (1.0 + drive * 10.0)
    tanh(driven.float64).float32
  
  proc processFilter(input: float32, cutoff: float32): float32 =
    let coeff = cutoff
    filterState = filterState * (1.0 - coeff) + input * coeff
    filterState
  
  proc audioCallbackEffect(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      var wet: float32
      let dry = input[0][i]
      
      if bypass:
        wet = dry
      else:
        case currentEffect
        of FX_DELAY:
          wet = processDelay(dry, paramValue)
        of FX_FEEDBACK:
          wet = processFeedback(dry, paramValue)
        of FX_DISTORTION:
          wet = processDistortion(dry, paramValue)
        of FX_FILTER:
          wet = processFilter(dry, paramValue)
      
      let outputSample = dry * (1.0 - mixValue) + wet * mixValue
      output[0][i] = outputSample
      output[1][i] = outputSample
  
  proc runEffectDemo() =
    patch.init()
    patch.startAdc()
    patch.startAudio(audioCallbackEffect)
    
    var lastInc: int32 = 0
    var paramSelect = 0
    
    while true:
      patch.processAllControls()
      
      # Encoder: Change effect type
      let inc = patch.encoder.increment()
      if inc != lastInc:
        if paramSelect == 0:
          if inc > lastInc:
            currentEffect = EffectType((currentEffect.ord + 1) mod 4)
          else:
            currentEffect = EffectType((currentEffect.ord + 3) mod 4)
        lastInc = inc
      
      # Encoder button: Toggle parameter select
      if patch.encoderPressed():
        paramSelect = (paramSelect + 1) mod 3
      
      # CV controls
      paramValue = patch.getKnobValue(CTRL_1)
      mixValue = patch.getKnobValue(CTRL_2)
      
      # Gate 1: Bypass toggle
      if patch.gateInputTrig(GATE_IN_1):
        bypass = not bypass
      
      patch.seed.setLed(not bypass)
      patch.delay(1)

# ============================================================================
# DEMO 3: CV PROCESSOR UTILITIES
# ============================================================================
## Demonstrates:
## - CV quantization (chromatic scale)
## - Slew limiting (smoothing)
## - Sample & Hold
## - Gate generation from CV
##
## Controls:
## - Knob 1: Quantizer input
## - Knob 2: Slew rate control
## - Knob 3: S&H input level
## - Knob 4: Gate threshold
## - Gate 1: S&H trigger
## - Gate 2: Reset all processors
## - Encoder: Change display mode
## - Encoder press: Change quantizer scale

when MODE_CV_UTIL:
  const
    SEMITONES = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0]
  
  var
    quantizerScale = 0  # 0=chromatic, 1=major, 2=minor
    slewCurrent: float32 = 0.0
    sampleHoldValue: float32 = 0.0
    lastSampleHoldTrig = false
    gateThreshold: float32 = 0.5
    gateState = false
  
  proc quantizeCv(input: float32, scale: int): float32 =
    ## Quantize CV to semitone steps
    let voltsPerOctave = 1.0
    let semitone = input / voltsPerOctave * 12.0
    let quantized = round(semitone).int mod 12
    (SEMITONES[quantized] / 12.0) * voltsPerOctave
  
  proc slewLimit(input: float32, rate: float32): float32 =
    ## Apply exponential smoothing
    let alpha = clamp(rate, 0.001, 1.0)
    slewCurrent = slewCurrent * (1.0 - alpha) + input * alpha
    slewCurrent
  
  proc audioCallbackCv(input, output: AudioBuffer, size: int) {.cdecl.} =
    ## Pass-through audio
    for i in 0..<size:
      output[0][i] = input[0][i]
      output[1][i] = input[1][i]
  
  proc runCvUtilDemo() =
    patch.init()
    patch.startAdc()
    patch.startAudio(audioCallbackCv)
    
    var lastInc: int32 = 0
    var displayMode = 0
    
    while true:
      patch.processAllControls()
      
      # Read CV inputs
      let cv1 = patch.getKnobValue(CTRL_1)
      let cv2 = patch.getKnobValue(CTRL_2)
      let cv3 = patch.getKnobValue(CTRL_3)
      let cv4 = patch.getKnobValue(CTRL_4)
      
      # Process CV1: Quantizer
      let quantized = quantizeCv(cv1, quantizerScale)
      
      # Process CV2: Slew limiter
      let slewed = slewLimit(cv2, cv2)
      
      # Process CV3: Sample & Hold
      let sampleHoldTrig = patch.gateInputTrig(GATE_IN_1)
      if sampleHoldTrig and not lastSampleHoldTrig:
        sampleHoldValue = cv3
      lastSampleHoldTrig = sampleHoldTrig
      
      # Process CV4: Gate generator
      gateThreshold = cv4
      let newGateState = cv4 > 0.5
      if newGateState != gateState:
        gateState = newGateState
        patch.writeGateOutput(gateState)
      
      # Gate 2: Reset
      if patch.gateInputTrig(GATE_IN_2):
        slewCurrent = 0.0
        sampleHoldValue = 0.0
        quantizerScale = 0
      
      # Encoder: Change display mode
      let inc = patch.encoder.increment()
      if inc != lastInc:
        displayMode = (displayMode + 1) mod 3
        lastInc = inc
      
      # Encoder button: Change quantizer scale
      if patch.encoderRisingEdge():
        quantizerScale = (quantizerScale + 1) mod 3
      
      patch.seed.setLed(gateState)
      patch.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_SIMPLE:
    runSimpleDemo()
  elif MODE_EFFECT:
    runEffectDemo()
  elif MODE_CV_UTIL:
    runCvUtilDemo()
  else:
    patch.init()
    while true:
      patch.seed.setLed(true)
      patch.delay(100)
      patch.seed.setLed(false)
      patch.delay(100)

when isMainModule:
  main()
