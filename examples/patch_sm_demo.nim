## Daisy Patch SM Demo - SOM Module Showcase
## ==========================================
##
## Comprehensive demonstration of the Daisy Patch SM System-on-Module:
## - 8 CV inputs (bipolar ±5V)
## - 2 CV outputs (0-5V)
## - 2 gate inputs with trigger detection
## - Stereo audio I/O
## - User LED
##
## Hardware Requirements:
## - Daisy Patch SM (Eurorack SOM format)
##
## Demo Modes (select by uncommenting one):
## - MODE_CV_MIXER: CV summing/mixing utilities
## - MODE_QUANTIZER: Pitch CV quantizer (chromatic scale)
##
## CV Reference:
## - Inputs are normalized 0.0-1.0 (representing -5V to +5V)
## - Outputs are 0-5V (set directly in volts)

import ../src/boards/daisy_patch_sm
import ../src/nimphea_macros

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_CV_MIXER = true
const MODE_QUANTIZER = false

var patchsm: DaisyPatchSM

# ============================================================================
# DEMO 1: CV MIXER
# ============================================================================
## Demonstrates:
## - Reading all 8 CV inputs
## - Outputting processed CV to DAC outputs
## - Gate input detection
## - LED control
##
## CV Routing:
## - CV 1-4 summed → CV Out 1
## - CV 5-8 summed → CV Out 2
## - Gate inputs trigger LED

when MODE_CV_MIXER:
  proc runCvMixerDemo() =
    patchsm.init()
    patchsm.startAdc()
    patchsm.startDac()
    
    var ledState = false
    var counter = 0
    
    while true:
      patchsm.processAllControls()
      
      # Sum CV inputs 1-4 (average)
      let cv1 = patchsm.getAdcValue(CV_1.cint)
      let cv2 = patchsm.getAdcValue(CV_2.cint)
      let cv3 = patchsm.getAdcValue(CV_3.cint)
      let cv4 = patchsm.getAdcValue(CV_4.cint)
      let sum1234 = (cv1 + cv2 + cv3 + cv4) * 0.25
      
      # Sum CV inputs 5-8 (average)
      let cv5 = patchsm.getAdcValue(CV_5.cint)
      let cv6 = patchsm.getAdcValue(CV_6.cint)
      let cv7 = patchsm.getAdcValue(CV_7.cint)
      let cv8 = patchsm.getAdcValue(CV_8.cint)
      let sum5678 = (cv5 + cv6 + cv7 + cv8) * 0.25
      
      # Output to CV outs (scale to 0-5V)
      patchsm.writeCvOut(CV_OUT_1.cint, sum1234 * 5.0)
      patchsm.writeCvOut(CV_OUT_2.cint, sum5678 * 5.0)
      
      # Gate activity → LED
      let gateActive = patchsm.gate_in_1.state() or patchsm.gate_in_2.state()
      
      if gateActive:
        patchsm.setLed(true)
      else:
        # Blink at 1Hz
        inc counter
        if counter >= 1000:
          counter = 0
          ledState = not ledState
          patchsm.setLed(ledState)
      
      patchsm.delay(1)

# ============================================================================
# DEMO 2: PITCH QUANTIZER
# ============================================================================
## Demonstrates:
## - 1V/octave CV quantization to chromatic scale
## - Sample & Hold with gate trigger
## - Dry/wet mixing
##
## CV Routing:
## - CV 1: Pitch input
## - CV 2: Quantize amount (dry/wet)
## - CV Out 1: Quantized pitch
## - CV Out 2: Raw pitch (bypass)
## - Gate 1: Sample & Hold trigger

when MODE_QUANTIZER:
  proc round(x: cfloat): cfloat {.inline.} =
    if x >= 0.0: (x + 0.5).cfloat.int.cfloat
    else: (x - 0.5).cfloat.int.cfloat
  
  proc quantizeToSemitone(voltage: cfloat): cfloat =
    ## Quantize 1V/oct CV to semitone grid
    let semitones = voltage * 12.0
    let quantized = round(semitones)
    quantized / 12.0
  
  proc runQuantizerDemo() =
    patchsm.init()
    patchsm.startAdc()
    patchsm.startDac()
    
    var heldNote: cfloat = 0.0
    var isHolding = false
    
    while true:
      patchsm.processAllControls()
      
      # CV input to voltage: (normalized - 0.5) * 10.0 = -5V to +5V
      let pitchNorm = patchsm.getAdcValue(CV_1.cint)
      let pitchVolt = (pitchNorm - 0.5) * 10.0
      
      # Quantize amount
      let quantAmount = patchsm.getAdcValue(CV_2.cint)
      
      # Quantize and mix
      let quantized = quantizeToSemitone(pitchVolt)
      let output = pitchVolt * (1.0 - quantAmount) + quantized * quantAmount
      
      # Sample & Hold on gate rising edge
      let gateActive = patchsm.gate_in_1.state()
      if gateActive and not isHolding:
        heldNote = output
        isHolding = true
      elif not gateActive:
        isHolding = false
      
      let finalOutput = if isHolding: heldNote else: output
      
      # Convert to DAC range (0-5V)
      var cvOut1 = (finalOutput + 5.0) / 2.0
      var cvOut2 = (pitchVolt + 5.0) / 2.0
      
      # Clamp
      if cvOut1 < 0.0: cvOut1 = 0.0
      if cvOut1 > 5.0: cvOut1 = 5.0
      if cvOut2 < 0.0: cvOut2 = 0.0
      if cvOut2 > 5.0: cvOut2 = 5.0
      
      patchsm.writeCvOut(CV_OUT_1.cint, cvOut1)
      patchsm.writeCvOut(CV_OUT_2.cint, cvOut2)
      
      patchsm.setLed(gateActive)
      patchsm.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_CV_MIXER:
    runCvMixerDemo()
  elif MODE_QUANTIZER:
    runQuantizerDemo()
  else:
    patchsm.init()
    while true:
      patchsm.setLed(true)
      patchsm.delay(100)
      patchsm.setLed(false)
      patchsm.delay(100)

when isMainModule:
  main()
