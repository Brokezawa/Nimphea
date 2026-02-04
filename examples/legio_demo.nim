## Daisy Legio Demo - Compact Module Showcase
## ===========================================
##
## Comprehensive demonstration of the Daisy Legio platform:
## - 3 CV inputs (pitch + 2 knobs)
## - Rotary encoder with button
## - 2 RGB LEDs
## - 2 three-position toggle switches
## - Gate input
## - Stereo audio I/O
##
## Hardware Requirements:
## - Daisy Legio (Virt Iter Legio by Olivia Artz Modular + Noise Engineering)
##
## Demo Modes (select by uncommenting one):
## - MODE_LED_CONTROL: LED patterns with CV/encoder control
## - MODE_CV_METER: CV monitoring with audio passthrough
##
## Control Reference:
## - CONTROL_PITCH: CV input (pitch)
## - CONTROL_KNOB_TOP: CV input (knob 1)
## - CONTROL_KNOB_BOTTOM: CV input (knob 2)
## - SW_LEFT, SW_RIGHT: Three-position switches
## - ENCODER: Rotary encoder with button

import ../src/nimphea
import ../src/boards/daisy_legio

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_LED_CONTROL = true
const MODE_CV_METER = false

var legio: DaisyLegio

# ============================================================================
# DEMO 1: LED CONTROL
# ============================================================================
## Demonstrates:
## - Dual RGB LED control
## - Three-position switch reading
## - Encoder rotation and button
## - Gate trigger flash effect
## - CV-controlled colors
##
## Controls:
## - CONTROL_PITCH: Left LED red channel
## - CONTROL_KNOB_TOP: Left LED green channel
## - CONTROL_KNOB_BOTTOM: Right LED blue channel
## - SW_LEFT: Mode (individual/mirrored/alternate)
## - SW_RIGHT: Brightness (dim/normal/bright)
## - ENCODER: Adjust brightness / toggle alternate
## - GATE: Flash trigger

when MODE_LED_CONTROL:
  type LedMode = enum
    MODE_INDIVIDUAL, MODE_MIRRORED, MODE_ALTERNATE
  
  var
    currentMode = MODE_INDIVIDUAL
    brightness: cfloat = 0.5
    encoderPressed = false
    flashActive = false
    flashCounter = 0
  
  const FLASH_DURATION = 30
  
  proc runLedControlDemo() =
    legio.init()
    
    while true:
      legio.processAllControls()
      
      # Mode from SW_LEFT
      let sw0 = legio.sw[0].read()
      currentMode = case sw0
        of 0: MODE_INDIVIDUAL
        of 1: MODE_MIRRORED
        else: MODE_ALTERNATE
      
      # Brightness from SW_RIGHT
      let sw1 = legio.sw[1].read()
      brightness = case sw1
        of 0: 0.3
        of 1: 0.7
        else: 1.0
      
      # Encoder adjustment
      let inc = legio.encoder.increment()
      if inc != 0:
        brightness += inc.cfloat * 0.05
        if brightness < 0.0: brightness = 0.0
        if brightness > 1.0: brightness = 1.0
      
      if legio.encoder.risingEdge():
        encoderPressed = not encoderPressed
      
      # Gate flash
      if legio.gate():
        flashActive = true
        flashCounter = 0
      
      # Read CV values
      let pitch = legio.getKnobValue(CONTROL_PITCH.cint)
      let knobTop = legio.getKnobValue(CONTROL_KNOB_TOP.cint)
      let knobBottom = legio.getKnobValue(CONTROL_KNOB_BOTTOM.cint)
      
      # LED update
      if flashActive:
        let fb = 1.0 - (flashCounter.cfloat / FLASH_DURATION.cfloat)
        legio.setLed(LED_LEFT.csize_t, fb, fb, fb)
        legio.setLed(LED_RIGHT.csize_t, fb, fb, fb)
        inc flashCounter
        if flashCounter >= FLASH_DURATION:
          flashActive = false
      else:
        case currentMode
        of MODE_INDIVIDUAL:
          legio.setLed(LED_LEFT.csize_t,
            pitch * brightness, knobTop * brightness, 0.0)
          legio.setLed(LED_RIGHT.csize_t,
            0.0, 0.0, knobBottom * brightness)
        
        of MODE_MIRRORED:
          let r = pitch * brightness
          let g = knobTop * brightness
          let b = knobBottom * brightness
          legio.setLed(LED_LEFT.csize_t, r, g, b)
          legio.setLed(LED_RIGHT.csize_t, r, g, b)
        
        of MODE_ALTERNATE:
          if encoderPressed:
            legio.setLed(LED_LEFT.csize_t,
              pitch * brightness, knobTop * brightness, knobBottom * brightness)
            legio.setLed(LED_RIGHT.csize_t,
              pitch * 0.1, knobTop * 0.1, knobBottom * 0.1)
          else:
            legio.setLed(LED_LEFT.csize_t,
              pitch * 0.1, knobTop * 0.1, knobBottom * 0.1)
            legio.setLed(LED_RIGHT.csize_t,
              pitch * brightness, knobTop * brightness, knobBottom * brightness)
      
      legio.updateLeds()
      legio.delayMs(10)

# ============================================================================
# DEMO 2: CV METER WITH AUDIO PASSTHROUGH
# ============================================================================
## Demonstrates:
## - CV input visualization
## - Audio passthrough with gain control
## - VU meter on LEDs
## - Hold mode via gate
##
## Controls:
## - ENCODER: Adjust gain / toggle CV/audio meter
## - SW_LEFT: Routing (stereo/mono L/mono R)
## - SW_RIGHT: Gain range (0.5x/1x/2x)
## - GATE: Hold CV readings

when MODE_CV_METER:
  type MeterMode = enum
    METER_CV, METER_AUDIO
  
  var
    gain: cfloat = 1.0
    meterMode = METER_CV
    holdActive = false
    heldPitch, heldKnobTop, heldKnobBottom: cfloat
    audioLevelL, audioLevelR: cfloat
  
  proc abs(x: cfloat): cfloat {.inline.} = (if x < 0: -x else: x)
  proc clamp(x, lo, hi: cfloat): cfloat {.inline.} =
    (if x < lo: lo elif x > hi: hi else: x)
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    let sw0 = legio.sw[0].read()
    var maxL, maxR: cfloat = 0.0
    
    for i in 0..<size:
      let inL = input[0][i]
      let inR = input[1][i]
      
      var outL, outR: cfloat
      case sw0
      of 0:  # Stereo
        outL = inL * gain
        outR = inR * gain
      of 1:  # Mono L
        outL = inL * gain
        outR = inL * gain
      else:  # Mono R
        outL = inR * gain
        outR = inR * gain
      
      outL = clamp(outL, -1.0, 1.0)
      outR = clamp(outR, -1.0, 1.0)
      
      maxL = max(maxL, abs(outL))
      maxR = max(maxR, abs(outR))
      
      output[0][i] = outL
      output[1][i] = outR
    
    audioLevelL = audioLevelL * 0.9 + maxL * 0.1
    audioLevelR = audioLevelR * 0.9 + maxR * 0.1
  
  proc runCvMeterDemo() =
    legio.init()
    legio.startAudio(audioCallback)
    
    while true:
      legio.processAllControls()
      
      # Encoder
      let inc = legio.encoder.increment()
      if inc != 0:
        gain += inc.cfloat * 0.05
        gain = clamp(gain, 0.0, 4.0)
      
      if legio.encoder.risingEdge():
        meterMode = if meterMode == METER_CV: METER_AUDIO else: METER_CV
      
      # Gain range from SW_RIGHT
      let sw1 = legio.sw[1].read()
      let baseGain: cfloat = case sw1
        of 0: 0.5
        of 1: 1.0
        else: 2.0
      
      # Hold mode
      holdActive = legio.gate()
      if holdActive:
        heldPitch = legio.getKnobValue(CONTROL_PITCH.cint)
        heldKnobTop = legio.getKnobValue(CONTROL_KNOB_TOP.cint)
        heldKnobBottom = legio.getKnobValue(CONTROL_KNOB_BOTTOM.cint)
      
      # LED update
      case meterMode
      of METER_CV:
        let pitch = if holdActive: heldPitch else: legio.getKnobValue(CONTROL_PITCH.cint)
        let knobTop = if holdActive: heldKnobTop else: legio.getKnobValue(CONTROL_KNOB_TOP.cint)
        let knobBottom = if holdActive: heldKnobBottom else: legio.getKnobValue(CONTROL_KNOB_BOTTOM.cint)
        legio.setLed(LED_LEFT.csize_t, pitch, knobTop, 0.0)
        legio.setLed(LED_RIGHT.csize_t, 0.0, 0.0, knobBottom)
      
      of METER_AUDIO:
        legio.setLed(LED_LEFT.csize_t, audioLevelL, 0.0, 0.0)
        legio.setLed(LED_RIGHT.csize_t, 0.0, 0.0, audioLevelR)
      
      legio.updateLeds()
      legio.delayMs(16)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_LED_CONTROL:
    runLedControlDemo()
  elif MODE_CV_METER:
    runCvMeterDemo()
  else:
    legio.init()
    while true:
      legio.setLed(LED_LEFT.csize_t, 1.0, 0.0, 0.0)
      legio.updateLeds()
      legio.delayMs(500)
      legio.setLed(LED_LEFT.csize_t, 0.0, 0.0, 0.0)
      legio.updateLeds()
      legio.delayMs(500)

when isMainModule:
  main()
