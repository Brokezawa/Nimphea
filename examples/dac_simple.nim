## DAC Simple Example
import panicoverride
## 
## Output a sine wave using DAC in polling mode

import ../src/per/dac
import ../src/nimphea
useNimpheaNamespace()

import std/math

proc main() =
  var daisy = initDaisy()
  
  # Initialize DAC in polling mode
  var dac: dac.DacHandle
  var config = DacConfig(
    target_samplerate: 48000,
    chn: DAC_CHN_ONE,
    mode: DAC_MODE_POLLING,
    bitdepth: DAC_BITS_12,
    buff_state: DAC_BUFFER_ENABLED
  )
  
  if dac.init(config) == DAC_OK:
    daisy.setLed(true)
  
  var phase: float32 = 0.0
  let frequency = 1.0  # 1 Hz sine wave
  let phaseIncrement = frequency * 2.0 * PI / 1000.0  # 1ms update rate
  
  while true:
    # Generate sine wave value (0-4095 for 12-bit DAC)
    let sineValue = sin(phase)
    let dacValue = uint16((sineValue + 1.0) * 2047.5)  # Convert -1..1 to 0..4095
    
    discard dac.writeValue(DAC_CHN_ONE, dacValue)
    
    phase += phaseIncrement
    if phase > 2.0 * PI:
      phase -= 2.0 * PI
    
    daisy.delay(1)

when isMainModule:
  main()
