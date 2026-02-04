## Daisy Versio Demo - Eurorack Module Showcase
## =============================================
##
## Comprehensive demonstration of the Daisy Versio platform:
## - 7 knobs for parameter control
## - 4 RGB LEDs
## - 2 three-position toggle switches
## - Gate input with trigger detection
## - Stereo audio I/O
##
## Hardware Requirements:
## - Daisy Versio (Noise Engineering Eurorack module)
##
## Demo Modes (select by uncommenting one):
## - MODE_LED_CONTROL: LED patterns with knob/switch control
## - MODE_REVERB: Schroeder reverb effect with VU meter
##
## Control Reference:
## - KNOB_0-6: Rotary potentiometers
## - SW_0, SW_1: Three-position switches
## - GATE_IN: Gate/trigger input

import ../src/nimphea
import ../src/boards/daisy_versio

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_LED_CONTROL = true
const MODE_REVERB = false

var versio: DaisyVersio

# ============================================================================
# DEMO 1: LED CONTROL
# ============================================================================
## Demonstrates:
## - 4 RGB LED control
## - Three-position switch reading
## - Gate trigger flash effect
## - Knob-controlled colors and patterns
##
## Controls:
## - KNOB_0-2: LED 0 RGB
## - KNOB_3-4: LED 1 RG
## - KNOB_5-6: LED 2-3 brightness
## - SW_0: Mode (individual/chase/all)
## - SW_1: Speed (slow/medium/fast)
## - GATE: Flash trigger

when MODE_LED_CONTROL:
  type LedMode = enum
    MODE_INDIVIDUAL, MODE_CHASE, MODE_ALL
  
  var
    currentMode = MODE_INDIVIDUAL
    chasePosition = 0
    frameCounter = 0
    speedMultiplier = 1
    flashActive = false
    flashCounter = 0
  
  const FLASH_DURATION = 50
  
  proc runLedControlDemo() =
    versio.init()
    
    while true:
      # Update mode from SW_0
      let sw0 = versio.sw[0].read()
      currentMode = case sw0
        of 0: MODE_INDIVIDUAL
        of 1: MODE_CHASE
        else: MODE_ALL
      
      # Update speed from SW_1
      let sw1 = versio.sw[1].read()
      speedMultiplier = case sw1
        of 0: 4  # Slow
        of 1: 2  # Medium
        else: 1  # Fast
      
      # Check gate for flash
      if versio.gate.state():
        flashActive = true
        flashCounter = 0
      
      # LED update
      if flashActive:
        let brightness = 1.0 - (flashCounter.cfloat / FLASH_DURATION.cfloat)
        for i in 0..<4:
          versio.setLed(i.csize_t, brightness, brightness, brightness)
        inc flashCounter
        if flashCounter >= FLASH_DURATION:
          flashActive = false
      else:
        case currentMode
        of MODE_INDIVIDUAL:
          versio.setLed(LED_0.csize_t, 
            versio.getKnobValue(KNOB_0.cint),
            versio.getKnobValue(KNOB_1.cint),
            versio.getKnobValue(KNOB_2.cint))
          versio.setLed(LED_1.csize_t,
            versio.getKnobValue(KNOB_3.cint),
            versio.getKnobValue(KNOB_4.cint), 0.0)
          let b2 = versio.getKnobValue(KNOB_5.cint)
          let b3 = versio.getKnobValue(KNOB_6.cint)
          versio.setLed(LED_2.csize_t, b2, 0.0, b2)
          versio.setLed(LED_3.csize_t, 0.0, b3, b3)
        
        of MODE_CHASE:
          for i in 0..<4:
            if i == chasePosition:
              versio.setLed(i.csize_t, 1.0, 1.0, 1.0)
            else:
              versio.setLed(i.csize_t, 0.1, 0.1, 0.1)
        
        of MODE_ALL:
          let r = versio.getKnobValue(KNOB_0.cint)
          let g = versio.getKnobValue(KNOB_1.cint)
          let b = versio.getKnobValue(KNOB_2.cint)
          for i in 0..<4:
            versio.setLed(i.csize_t, r, g, b)
      
      versio.updateLeds()
      
      # Advance chase
      inc frameCounter
      if frameCounter >= (10 * speedMultiplier):
        frameCounter = 0
        chasePosition = (chasePosition + 1) mod 4
      
      versio.delayMs(10)

# ============================================================================
# DEMO 2: REVERB EFFECT
# ============================================================================
## Demonstrates:
## - Schroeder reverb algorithm (4 combs + 2 allpass)
## - VU meter on LEDs
## - Freeze effect via gate
##
## Controls:
## - KNOB_0: Room size
## - KNOB_1: Damping
## - KNOB_2: Dry/wet mix
## - KNOB_3: Pre-delay
## - KNOB_6: Diffusion
## - SW_1: VU mode (input/mix/output)
## - GATE: Freeze reverb tail

when MODE_REVERB:
  const
    COMB_SIZE = 4096
    ALLPASS_SIZE = 2048
    PREDELAY_SIZE = 4800
  
  type
    CombFilter = object
      buffer: array[COMB_SIZE, cfloat]
      readPos, writePos, bufSize: int
      feedback, damping, filterState: cfloat
    
    AllpassFilter = object
      buffer: array[ALLPASS_SIZE, cfloat]
      readPos, writePos, bufSize: int
      feedback: cfloat
  
  var
    combsL, combsR: array[4, CombFilter]
    allpassL, allpassR: array[2, AllpassFilter]
    predelayBufL, predelayBufR: array[PREDELAY_SIZE, cfloat]
    predelayPos, predelayTime: int
    vuInput, vuOutput: cfloat
  
  proc initComb(size: int, fb: cfloat): CombFilter =
    result.bufSize = size
    result.feedback = fb
    result.damping = 0.5
  
  proc processComb(c: var CombFilter, input: cfloat): cfloat =
    result = c.buffer[c.readPos]
    c.filterState = result * (1.0 - c.damping) + c.filterState * c.damping
    c.buffer[c.writePos] = input + c.filterState * c.feedback
    c.readPos = (c.readPos + 1) mod c.bufSize
    c.writePos = (c.writePos + 1) mod c.bufSize
  
  proc initAllpass(size: int): AllpassFilter =
    result.bufSize = size
    result.feedback = 0.5
  
  proc processAllpass(a: var AllpassFilter, input: cfloat): cfloat =
    let bufOut = a.buffer[a.readPos]
    result = -input + bufOut
    a.buffer[a.writePos] = input + bufOut * a.feedback
    a.readPos = (a.readPos + 1) mod a.bufSize
    a.writePos = (a.writePos + 1) mod a.bufSize
  
  proc abs(x: cfloat): cfloat {.inline.} = (if x < 0: -x else: x)
  proc clamp(x, lo, hi: cfloat): cfloat {.inline.} =
    (if x < lo: lo elif x > hi: hi else: x)
  
  const
    combTunings = [1557, 1617, 1491, 1422]
    allpassTunings = [225, 341]
  
  proc initReverb() =
    for i in 0..<4:
      combsL[i] = initComb(combTunings[i], 0.84)
      combsR[i] = initComb(combTunings[i] + 23, 0.84)
    for i in 0..<2:
      allpassL[i] = initAllpass(allpassTunings[i])
      allpassR[i] = initAllpass(allpassTunings[i] + 23)
    predelayTime = 1200
  
  proc processReverbMono(combs: var array[4, CombFilter],
                         allpass: var array[2, AllpassFilter],
                         buf: var array[PREDELAY_SIZE, cfloat],
                         input: cfloat): cfloat =
    let readPos = (predelayPos - predelayTime + PREDELAY_SIZE) mod PREDELAY_SIZE
    var sig = buf[readPos]
    buf[predelayPos] = input
    
    var combSum: cfloat = 0.0
    for i in 0..<4:
      combSum += combs[i].processComb(sig)
    sig = combSum * 0.25
    
    for i in 0..<2:
      sig = allpass[i].processAllpass(sig)
    result = sig
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    let mix = versio.getKnobValue(KNOB_2.cint)
    var maxIn, maxOut: cfloat = 0.0
    
    for i in 0..<size:
      let inL = input[0][i]
      let inR = input[1][i]
      maxIn = max(maxIn, max(abs(inL), abs(inR)))
      
      let wetL = processReverbMono(combsL, allpassL, predelayBufL, inL)
      let wetR = processReverbMono(combsR, allpassR, predelayBufR, inR)
      predelayPos = (predelayPos + 1) mod PREDELAY_SIZE
      
      var outL = clamp(inL * (1.0 - mix) + wetL * mix, -1.0, 1.0)
      var outR = clamp(inR * (1.0 - mix) + wetR * mix, -1.0, 1.0)
      maxOut = max(maxOut, max(abs(outL), abs(outR)))
      
      output[0][i] = outL
      output[1][i] = outR
    
    vuInput = vuInput * 0.95 + maxIn * 0.05
    vuOutput = vuOutput * 0.95 + maxOut * 0.05
  
  proc runReverbDemo() =
    versio.init()
    initReverb()
    versio.startAudio(audioCallback)
    
    while true:
      # Update parameters
      let size = versio.getKnobValue(KNOB_0.cint)
      let feedback = 0.7 + size * 0.28
      let damping = versio.getKnobValue(KNOB_1.cint)
      let diffusion = versio.getKnobValue(KNOB_6.cint) * 0.7
      predelayTime = (versio.getKnobValue(KNOB_3.cint) * (PREDELAY_SIZE - 1).cfloat).int
      
      for i in 0..<4:
        combsL[i].feedback = feedback
        combsR[i].feedback = feedback
        combsL[i].damping = damping
        combsR[i].damping = damping
      for i in 0..<2:
        allpassL[i].feedback = diffusion
        allpassR[i].feedback = diffusion
      
      # Freeze on gate
      if versio.gate.state():
        for i in 0..<4:
          combsL[i].feedback = 0.99
          combsR[i].feedback = 0.99
      
      # VU meter
      let sw1 = versio.sw[1].read()
      let level = case sw1
        of 0: vuInput
        of 1: (vuInput + vuOutput) * 0.5
        else: vuOutput
      let scaled = clamp(level * 4.0, 0.0, 4.0)
      for i in 0..<4:
        if scaled > i.cfloat:
          let b = clamp(scaled - i.cfloat, 0.0, 1.0)
          let r = clamp(b * 2.0 - 1.0, 0.0, 1.0)
          let g = clamp(2.0 - b * 2.0, 0.0, 1.0)
          versio.setLed(i.csize_t, r, g, 0.0)
        else:
          versio.setLed(i.csize_t, 0.0, 0.0, 0.0)
      versio.updateLeds()
      
      versio.delayMs(16)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_LED_CONTROL:
    runLedControlDemo()
  elif MODE_REVERB:
    runReverbDemo()
  else:
    versio.init()
    while true:
      versio.setLed(0.csize_t, 1.0, 0.0, 0.0)
      versio.updateLeds()
      versio.delayMs(500)
      versio.setLed(0.csize_t, 0.0, 0.0, 0.0)
      versio.updateLeds()
      versio.delayMs(500)

when isMainModule:
  main()
