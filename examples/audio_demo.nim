## Audio Demonstration
##
## Comprehensive example showing basic audio capabilities in Nimphea:
## - Audio passthrough (input → output)
## - Sine wave oscillator (basic synthesis)
## - Distortion effect (audio processing)
## - Sample rate and block size configuration
##
## **Hardware Setup**:
## - Daisy Seed with audio codec
## - Audio input: Line in or instrument
## - Audio output: Headphones or speakers
## - Optional: Potentiometer on A0 for parameter control
##
## **Audio Specifications**:
## - Sample rate: 48kHz
## - Block size: 48 samples (~1ms latency)
## - Bit depth: 32-bit float internal, 24-bit codec
## - Channels: Stereo (2 in, 2 out)
##
## **Features Demonstrated**:
## 1. AudioCallback signature and structure
## 2. AudioBuffer access (input[channel][sample])
## 3. startAudio() / stopAudio()
## 4. setSampleRate() / setBlockSize()
## 5. Basic DSP: oscillator, soft clipping
##
## **Modes**: Cycles through passthrough, sine wave, and distortion.
## Press button on D2 to manually advance modes.

import panicoverride
import ../src/nimphea
import ../src/hid/ctrl
import std/math

useNimpheaNamespace()

const
  SAMPLE_RATE = 48000.0
  TWO_PI = 2.0 * PI

type
  AudioMode = enum
    amPassthrough   ## Direct input to output
    amSineWave      ## Sine wave oscillator
    amDistortion    ## Soft clipping distortion

var
  currentMode: AudioMode = amPassthrough
  
  # Oscillator state
  oscPhase: float = 0.0
  oscFrequency: float = 440.0  # A4
  oscVolume: float = 0.3
  
  # Distortion parameters
  drive: float32 = 0.5       # 0.0 - 1.0
  wetMix: float32 = 0.7      # Dry/wet mix

# =============================================================================
# DSP Helper Functions
# =============================================================================

proc softClip(x: float32): float32 {.inline.} =
  ## Soft clipping distortion using cubic waveshaping.
  ## Provides warm overdrive character.
  if x > 1.0'f32:
    1.0'f32
  elif x < -1.0'f32:
    -1.0'f32
  else:
    x - (x * x * x) / 3.0'f32

proc hardClip(x: float32, threshold: float32 = 0.8'f32): float32 {.inline.} =
  ## Hard clipping for more aggressive distortion.
  if x > threshold: threshold
  elif x < -threshold: -threshold
  else: x

# =============================================================================
# Audio Callbacks for Each Mode
# =============================================================================

proc audioPassthrough(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Mode 1: Simple passthrough - copy input to output unchanged.
  ## This is the most basic audio callback possible.
  for i in 0..<size:
    output[0][i] = input[0][i]  # Left channel
    output[1][i] = input[1][i]  # Right channel

proc audioSineWave(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Mode 2: Sine wave oscillator - generates a pure tone.
  ## Demonstrates basic synthesis with phase accumulator.
  let phaseIncrement = oscFrequency * TWO_PI / SAMPLE_RATE
  
  for i in 0..<size:
    # Generate sine sample
    let sample = sin(oscPhase).float32 * oscVolume.float32
    
    # Output to both channels
    output[0][i] = sample
    output[1][i] = sample
    
    # Advance phase with wraparound
    oscPhase += phaseIncrement
    if oscPhase >= TWO_PI:
      oscPhase -= TWO_PI

proc audioDistortion(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Mode 3: Distortion effect - applies soft clipping to input.
  ## Demonstrates real-time audio processing.
  let gain = 1.0'f32 + drive * 10.0'f32  # 1x to 11x gain
  
  for i in 0..<size:
    let inL = input[0][i]
    let inR = input[1][i]
    
    # Apply gain and soft clip
    let distL = softClip(inL * gain)
    let distR = softClip(inR * gain)
    
    # Mix dry and wet signals
    output[0][i] = inL * (1.0'f32 - wetMix) + distL * wetMix
    output[1][i] = inR * (1.0'f32 - wetMix) + distR * wetMix

# Unified callback that switches based on mode
proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  case currentMode
  of amPassthrough:
    audioPassthrough(input, output, size)
  of amSineWave:
    audioSineWave(input, output, size)
  of amDistortion:
    audioDistortion(input, output, size)

# =============================================================================
# Main Program
# =============================================================================

proc main() =
  var daisy = initDaisy()
  var button = initSwitch(D2())
  
  # Configure audio
  daisy.setSampleRate(SAI_48KHZ)
  daisy.setBlockSize(48)  # ~1ms latency at 48kHz
  
  # Start audio processing
  daisy.startAudio(audioCallback)
  
  # LED patterns for each mode
  var ledCounter = 0
  var ledState = false
  
  while true:
    button.update()
    
    # Change mode on button press
    if button.risingEdge():
      case currentMode
      of amPassthrough: currentMode = amSineWave
      of amSineWave: currentMode = amDistortion
      of amDistortion: currentMode = amPassthrough
    
    # LED indication based on mode
    inc ledCounter
    case currentMode
    of amPassthrough:
      # Slow blink (1 Hz)
      if ledCounter >= 500:
        ledState = not ledState
        daisy.setLed(ledState)
        ledCounter = 0
    
    of amSineWave:
      # Fast blink (4 Hz)
      if ledCounter >= 125:
        ledState = not ledState
        daisy.setLed(ledState)
        ledCounter = 0
    
    of amDistortion:
      # Solid on
      daisy.setLed(true)
      ledCounter = 0
    
    daisy.delay(1)

when isMainModule:
  main()
