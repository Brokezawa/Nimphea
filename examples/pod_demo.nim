## Daisy Pod Demo - Comprehensive Board Showcase
## ==============================================
##
## Demonstrates all features of the Daisy Pod hardware platform:
## - Dual RGB LEDs with color control
## - Two buttons with edge detection
## - Two rotary knobs (potentiometers)
## - Rotary encoder with click
## - Stereo audio I/O with various effects
##
## Hardware Requirements:
## - Daisy Pod
##
## Demo Modes (select by uncommenting one):
## - MODE_SIMPLE: Basic I/O test (LEDs, buttons, knobs)
## - MODE_EFFECT: Multi-effect audio processor
## - MODE_SYNTH: Simple monophonic synthesizer
##
## Controls (vary by mode - see individual sections):
## - Knobs: Parameter control
## - Buttons: Mode selection / bypass
## - Encoder: Navigation / selection
## - LEDs: Visual feedback

import panicoverride
import ../src/nimphea
import ../src/boards/daisy_pod
import ../src/nimphea_macros
import std/math

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_SIMPLE = true
const MODE_EFFECT = false
const MODE_SYNTH = false

const
  SAMPLE_RATE = 48000.0
  TWO_PI = 2.0 * PI
  MAX_DELAY = 24000  # 0.5 seconds at 48kHz

var
  pod: DaisyPod

# ============================================================================
# DEMO 1: SIMPLE I/O TEST
# ============================================================================
## Demonstrates:
## - Reading knob values (0.0 to 1.0)
## - RGB LED color control
## - Button edge detection
## - Seed LED blinking
##
## Controls:
## - Knob 1: LED1 color (red to blue gradient)
## - Knob 2: LED2 color (green to blue gradient)
## - Button 1: Flash LED1 white on press
## - Button 2: LED2 red while held

when MODE_SIMPLE:
  proc runSimpleDemo() =
    pod.init()
    pod.startAdc()  # Enable knob reading
    
    var counter = 0
    
    while true:
      pod.processAllControls()
      
      # Read knobs (0.0 to 1.0)
      let knob1Val = pod.getKnobValue(KNOB_1)
      let knob2Val = pod.getKnobValue(KNOB_2)
      
      # Set LED colors based on knobs
      pod.led1.set(knob1Val, 0.0, 1.0 - knob1Val)  # Red to Blue
      pod.led2.set(0.0, knob2Val, 1.0 - knob2Val)  # Green to Blue
      
      # Button 1: Flash white on rising edge
      if pod.button1.risingEdge():
        pod.led1.set(1.0, 1.0, 1.0)
      
      # Button 2: Solid red while held
      if pod.button2.pressed():
        pod.led2.set(1.0, 0.0, 0.0)
      
      pod.updateLeds()
      
      # Blink seed LED to show activity
      counter.inc
      if counter > 500:
        counter = 0
        pod.seed.setLed(true)
      elif counter > 250:
        pod.seed.setLed(false)
      
      pod.delay(1)

# ============================================================================
# DEMO 2: MULTI-EFFECT PROCESSOR
# ============================================================================
## Demonstrates:
## - Stereo audio processing
## - Effect selection with encoder
## - Wet/dry mix control
## - Bypass functionality
##
## Effects: Delay, Tremolo, Distortion, Bitcrusher
##
## Controls:
## - Encoder: Select effect (rotate)
## - Knob 1: Wet/dry mix
## - Knob 2: Effect parameter
## - Button 1: Bypass toggle
## - LED1: Effect type (R=Delay, G=Tremolo, Orange=Distort, B=Bitcrush)
## - LED2: Mix level indicator

when MODE_EFFECT:
  type
    EffectType = enum
      FX_DELAY, FX_TREMOLO, FX_DISTORTION, FX_BITCRUSH
  
  var
    currentEffect = FX_DELAY
    bypass = false
    mix: float32 = 0.5
    param: float32 = 0.5
    
    # Effect state
    delayBuffer: array[MAX_DELAY, float32]
    delayIndex: int = 0
    tremoloPhase: float32 = 0.0
  
  proc processDelay(input: float32, delayTime: float32): float32 =
    ## Simple delay with feedback
    let samples = (delayTime * (MAX_DELAY - 1).float32).int
    let delayed = delayBuffer[(delayIndex - samples + MAX_DELAY) mod MAX_DELAY]
    delayBuffer[delayIndex] = input + delayed * 0.5  # 50% feedback
    delayIndex = (delayIndex + 1) mod MAX_DELAY
    delayed
  
  proc processTremolo(input: float32, depth: float32, rate: float32): float32 =
    ## Amplitude modulation tremolo
    let lfo = sin(tremoloPhase * TWO_PI) * 0.5 + 0.5
    tremoloPhase += rate / SAMPLE_RATE
    if tremoloPhase >= 1.0:
      tremoloPhase -= 1.0
    input * (1.0 - depth + lfo * depth)
  
  proc processDistortion(input: float32, drive: float32): float32 =
    ## Soft clipping distortion
    let boosted = input * (1.0 + drive * 10.0)
    tanh(boosted.float64).float32
  
  proc processBitcrush(input: float32, bits: float32): float32 =
    ## Bit depth reduction
    let levels = pow(2.0, (bits * 12.0 + 4.0).float64)  # 4-16 bits
    (floor(input.float64 * levels) / levels).float32
  
  proc audioCallbackEffect(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      var wet: float32
      let dry = input[0][i]
      
      if bypass:
        wet = dry
      else:
        case currentEffect
        of FX_DELAY:
          wet = processDelay(dry, param)
        of FX_TREMOLO:
          wet = processTremolo(dry, param, mix * 10.0)
        of FX_DISTORTION:
          wet = processDistortion(dry, param)
        of FX_BITCRUSH:
          wet = processBitcrush(dry, param)
      
      let outputSample = dry * (1.0 - mix) + wet * mix
      output[0][i] = outputSample
      output[1][i] = outputSample
  
  proc runEffectDemo() =
    pod.init()
    pod.startAdc()
    pod.startAudio(audioCallbackEffect)
    
    var lastInc: int32 = 0
    
    while true:
      pod.processAllControls()
      
      # Encoder: Effect selection
      let inc = pod.encoder.increment()
      if inc != lastInc:
        if inc > lastInc:
          currentEffect = EffectType((currentEffect.ord + 1) mod 4)
        elif inc < lastInc:
          currentEffect = EffectType((currentEffect.ord + 3) mod 4)
        lastInc = inc
      
      # Button 1: Bypass toggle
      if pod.button1.risingEdge():
        bypass = not bypass
      
      # Knobs
      mix = pod.getKnobValue(KNOB_1)
      param = pod.getKnobValue(KNOB_2)
      
      # LED feedback
      if bypass:
        pod.led1.set(0.2, 0.0, 0.0)  # Dim red = bypassed
      else:
        case currentEffect
        of FX_DELAY:
          pod.led1.set(1.0, 0.0, 0.0)    # Red
        of FX_TREMOLO:
          pod.led1.set(0.0, 1.0, 0.0)    # Green
        of FX_DISTORTION:
          pod.led1.set(1.0, 0.5, 0.0)    # Orange
        of FX_BITCRUSH:
          pod.led1.set(0.0, 0.0, 1.0)    # Blue
      
      pod.led2.set(mix, 0.0, 1.0 - mix)  # Mix indicator
      pod.updateLeds()
      
      pod.delay(1)

# ============================================================================
# DEMO 3: MONOPHONIC SYNTHESIZER
# ============================================================================
## Demonstrates:
## - Oscillator waveform generation
## - Frequency/octave control
## - Simple filter (amplitude)
##
## Waveforms: Sine, Saw, Square, Triangle
##
## Controls:
## - Button 1: Cycle waveform
## - Button 2: Octave shift (-1, 0, +1)
## - Knob 2: Amplitude/filter
## - LED1: Waveform (R=Sine, G=Saw, B=Square, Y=Triangle)
## - LED2: Amplitude indicator

when MODE_SYNTH:
  type
    Waveform = enum
      SINE, SAW, SQUARE, TRIANGLE
  
  var
    phase: float32 = 0.0
    frequency: float32 = 440.0
    waveform = SINE
    octaveShift: int = 0
    amplitude: float32 = 1.0
  
  proc generateSample(wf: Waveform, ph: float32): float32 =
    ## Generate sample for given waveform and phase (0.0 to 1.0)
    case wf
    of SINE:
      sin(ph * TWO_PI).float32
    of SAW:
      (2.0 * ph - 1.0).float32
    of SQUARE:
      if ph < 0.5: 1.0.float32 else: -1.0.float32
    of TRIANGLE:
      if ph < 0.5: (4.0 * ph - 1.0).float32
      else: (3.0 - 4.0 * ph).float32
  
  proc audioCallbackSynth(input, output: AudioBuffer, size: int) {.cdecl.} =
    let phaseInc = frequency / SAMPLE_RATE
    
    for i in 0..<size:
      let sample = generateSample(waveform, phase) * amplitude * 0.3
      output[0][i] = sample
      output[1][i] = sample
      
      phase += phaseInc
      if phase >= 1.0:
        phase -= 1.0
  
  proc runSynthDemo() =
    pod.init()
    pod.startAdc()
    pod.startAudio(audioCallbackSynth)
    
    while true:
      pod.processAllControls()
      
      # Button 1: Cycle waveform
      if pod.button1.risingEdge():
        waveform = Waveform((waveform.ord + 1) mod 4)
      
      # Button 2: Octave shift
      if pod.button2.risingEdge():
        octaveShift = (octaveShift + 1) mod 3 - 1  # Cycles: -1, 0, +1
        frequency = 440.0 * pow(2.0, octaveShift.float)
      
      # Knob 2: Amplitude
      amplitude = pod.getKnobValue(KNOB_2)
      
      # LED feedback for waveform
      case waveform
      of SINE:
        pod.led1.set(1.0, 0.0, 0.0)   # Red
      of SAW:
        pod.led1.set(0.0, 1.0, 0.0)   # Green
      of SQUARE:
        pod.led1.set(0.0, 0.0, 1.0)   # Blue
      of TRIANGLE:
        pod.led1.set(1.0, 1.0, 0.0)   # Yellow
      
      pod.led2.set(amplitude, 0.0, 1.0 - amplitude)
      pod.updateLeds()
      
      pod.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_SIMPLE:
    runSimpleDemo()
  elif MODE_EFFECT:
    runEffectDemo()
  elif MODE_SYNTH:
    runSynthDemo()
  else:
    # No mode selected - blink error
    pod.init()
    while true:
      pod.seed.setLed(true)
      pod.delay(100)
      pod.seed.setLed(false)
      pod.delay(100)

when isMainModule:
  main()
