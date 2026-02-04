## Daisy Petal Demo - Guitar Pedal Showcase
## =========================================
##
## Comprehensive demonstration of the Daisy Petal guitar pedal platform:
## - 6 knobs for parameter control
## - 8 ring LEDs (RGB addressable)
## - 4 footswitches with LEDs
## - 3 toggle switches
## - Rotary encoder
## - Expression pedal input
## - Stereo audio I/O
##
## Hardware Requirements:
## - Daisy Petal
##
## Demo Modes (select by uncommenting one):
## - MODE_SIMPLE: LED and control test (no audio)
## - MODE_OVERDRIVE: Full guitar overdrive effect with VU meter
##
## Control Reference:
## - KNOB_1 to KNOB_6: Rotary potentiometers
## - SW_1 to SW_4: Footswitches
## - SW_5 to SW_7: Toggle switches

import ../src/boards/daisy_petal
import ../src/nimphea_macros

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_SIMPLE = true
const MODE_OVERDRIVE = false

var petal: DaisyPetal

# ============================================================================
# DEMO 1: SIMPLE LED/CONTROL TEST
# ============================================================================
## Demonstrates:
## - Reading all 6 knobs
## - Expression pedal input
## - Encoder rotation tracking
## - Toggle switch states
## - RGB ring LED control
## - Footswitch LED toggle
##
## Controls:
## - Knobs 1-3: Ring LEDs 1-4 color (RGB)
## - Knobs 4-6: Ring LEDs 5-8 color (RGB)
## - Footswitches: Toggle their LEDs
## - Encoder: Global brightness
## - Expression: Intensity modulation

when MODE_SIMPLE:
  proc runSimpleDemo() =
    petal.init()
    petal.startAdc()
    
    var footswitchStates: array[4, bool]
    var globalBrightness: cfloat = 1.0
    var encoderValue: int32 = 50
    
    petal.clearLeds()
    petal.updateLeds()
    
    while true:
      petal.processAllControls()
      
      # Read knobs for RGB
      let red1 = petal.getKnobValue(KNOB_1.cint)
      let green1 = petal.getKnobValue(KNOB_2.cint)
      let blue1 = petal.getKnobValue(KNOB_3.cint)
      
      let red2 = petal.getKnobValue(KNOB_4.cint)
      let green2 = petal.getKnobValue(KNOB_5.cint)
      let blue2 = petal.getKnobValue(KNOB_6.cint)
      
      # Expression pedal
      let expression = petal.getExpression()
      
      # Encoder for brightness
      encoderValue += petal.encoder.increment()
      if encoderValue < 0: encoderValue = 0
      if encoderValue > 100: encoderValue = 100
      globalBrightness = encoderValue.cfloat / 100.0
      
      # Toggle switch states
      let invertColors = petal.switches[SW_7.int].pressed()
      
      # Set ring LEDs 1-4
      for i in 0..<4:
        var r = red1 * globalBrightness * expression
        var g = green1 * globalBrightness * expression
        var b = blue1 * globalBrightness * expression
        if invertColors:
          r = (1.0 - red1) * globalBrightness
          g = (1.0 - green1) * globalBrightness
          b = (1.0 - blue1) * globalBrightness
        petal.setRingLed(i.cint, r, g, b)
      
      # Set ring LEDs 5-8
      for i in 4..<8:
        var r = red2 * globalBrightness * expression
        var g = green2 * globalBrightness * expression
        var b = blue2 * globalBrightness * expression
        if invertColors:
          r = (1.0 - red2) * globalBrightness
          g = (1.0 - green2) * globalBrightness
          b = (1.0 - blue2) * globalBrightness
        petal.setRingLed(i.cint, r, g, b)
      
      # Footswitch toggles
      for i in 0..<4:
        if petal.switches[i].risingEdge():
          footswitchStates[i] = not footswitchStates[i]
          let brightness = if footswitchStates[i]: 1.0 else: 0.0
          petal.setFootswitchLed(i.cint, brightness)
      
      petal.updateLeds()
      petal.delayMs(1)

# ============================================================================
# DEMO 2: OVERDRIVE EFFECT
# ============================================================================
## Demonstrates:
## - Stereo audio processing
## - Soft-clipping distortion algorithm
## - One-pole low-pass filter
## - VU meter on ring LEDs
## - Bypass/boost/mute controls
##
## Controls:
## - Knob 1: Gain (0-10x)
## - Knob 2: Drive amount
## - Knob 3: Tone (filter cutoff)
## - Knob 4: Output level
## - Knob 5: Dry/wet mix
## - Footswitch 1: Bypass toggle
## - Footswitch 2: Boost (momentary)
## - Footswitch 3: Clip mode toggle
## - Footswitch 4: Mute toggle

when MODE_OVERDRIVE:
  proc softClip(x, threshold: cfloat): cfloat {.inline.} =
    let scaled = x / threshold
    if scaled > 3.0: threshold
    elif scaled < -3.0: -threshold
    else:
      let absScaled = if scaled < 0.0: -scaled else: scaled
      (scaled / (1.0 + absScaled)) * threshold
  
  type LowPassFilter = object
    lastOutput, coefficient: cfloat
  
  proc initLowPass(cutoff, sampleRate: cfloat): LowPassFilter =
    let rc = 1.0 / (cutoff * 6.28318)
    let dt = 1.0 / sampleRate
    result.coefficient = dt / (rc + dt)
    result.lastOutput = 0.0
  
  proc process(f: var LowPassFilter, input: cfloat): cfloat =
    f.lastOutput = f.lastOutput + f.coefficient * (input - f.lastOutput)
    f.lastOutput
  
  var
    bypassed = true
    boostActive = false
    muted = false
    filterL, filterR: LowPassFilter
    peakLevel: cfloat = 0.0
    gainParam, driveParam, levelParam, mixParam: cfloat
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      let inL = input[0][i]
      let inR = input[1][i]
      var outL, outR: cfloat
      
      if muted:
        outL = 0.0
        outR = 0.0
      elif bypassed:
        outL = inL
        outR = inR
      else:
        var pL = inL * gainParam
        var pR = inR * gainParam
        
        let threshold = 1.0 / (1.0 + driveParam * 10.0)
        pL = softClip(pL, threshold)
        pR = softClip(pR, threshold)
        
        pL = filterL.process(pL)
        pR = filterR.process(pR)
        
        pL = pL * levelParam
        pR = pR * levelParam
        
        outL = inL * (1.0 - mixParam) + pL * mixParam
        outR = inR * (1.0 - mixParam) + pR * mixParam
        
        if boostActive:
          outL = outL * 2.0
          outR = outR * 2.0
      
      output[0][i] = outL
      output[1][i] = outR
      
      let absL = if outL < 0.0: -outL else: outL
      let absR = if outR < 0.0: -outR else: outR
      let peak = if absL > absR: absL else: absR
      if peak > peakLevel: peakLevel = peak
  
  proc updateVuMeter(level: cfloat) =
    let numLeds = (level * 8.0).int
    for i in 0..<8:
      if i < numLeds:
        if i < 3: petal.setRingLed(i.cint, 0.0, 1.0, 0.0)      # Green
        elif i < 6: petal.setRingLed(i.cint, 1.0, 1.0, 0.0)    # Yellow
        else: petal.setRingLed(i.cint, 1.0, 0.0, 0.0)          # Red
      else:
        petal.setRingLed(i.cint, 0.0, 0.0, 0.0)
  
  proc runOverdriveDemo() =
    petal.init()
    petal.startAdc()
    
    filterL = initLowPass(5000.0, 48000.0)
    filterR = initLowPass(5000.0, 48000.0)
    
    petal.startAudio(audioCallback)
    
    petal.clearLeds()
    petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, 1.0)
    petal.updateLeds()
    
    var frameCount = 0
    
    while true:
      petal.processAllControls()
      
      # Read parameters
      gainParam = petal.getKnobValue(KNOB_1.cint) * 10.0 + 0.1
      driveParam = petal.getKnobValue(KNOB_2.cint)
      let tone = petal.getKnobValue(KNOB_3.cint) * 10000.0 + 200.0
      levelParam = petal.getKnobValue(KNOB_4.cint)
      mixParam = petal.getKnobValue(KNOB_5.cint)
      
      filterL = initLowPass(tone, 48000.0)
      filterR = initLowPass(tone, 48000.0)
      
      # Footswitch 1: Bypass
      if petal.switches[SW_1.int].risingEdge():
        bypassed = not bypassed
        petal.setFootswitchLed(FOOTSWITCH_LED_1.cint, if bypassed: 1.0 else: 0.0)
      
      # Footswitch 2: Boost (momentary)
      boostActive = petal.switches[SW_2.int].pressed()
      petal.setFootswitchLed(FOOTSWITCH_LED_2.cint, if boostActive: 1.0 else: 0.0)
      
      # Footswitch 4: Mute
      if petal.switches[SW_4.int].risingEdge():
        muted = not muted
        petal.setFootswitchLed(FOOTSWITCH_LED_4.cint, if muted: 1.0 else: 0.0)
      
      # VU meter update
      frameCount += 1
      if frameCount >= 10:
        frameCount = 0
        updateVuMeter(peakLevel)
        peakLevel = peakLevel * 0.9
      
      petal.updateLeds()
      petal.delayMs(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_SIMPLE:
    runSimpleDemo()
  elif MODE_OVERDRIVE:
    runOverdriveDemo()
  else:
    petal.init()
    while true:
      petal.seed.setLed(true)
      petal.delayMs(100)
      petal.seed.setLed(false)
      petal.delayMs(100)

when isMainModule:
  main()
