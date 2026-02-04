## I/O Expander Demo - GPIO, Shift Register, and CV Expansion
## ===========================================================
##
## Comprehensive demonstration of I/O expansion hardware:
## - MCP23017: 16-bit I2C GPIO expander (buttons + LEDs)
## - CD4021: 8-bit shift register for button scanning
## - MAX11300: Eurorack CV/Gate I/O (PIXI chip)
##
## Hardware Requirements:
## - Daisy Seed
## - External I/O expansion hardware (specific to each mode)
##
## Demo Modes (select by uncommenting one):
## - MODE_MCP23017: 16-bit GPIO expander (8 buttons + 8 LEDs)
## - MODE_SHIFT_REG: CD4021 shift register for 8 buttons
## - MODE_CV_EXPANDER: MAX11300 for eurorack CV processing
##
## ⚠️ Note: These demos require external hardware and have NOT been
## fully hardware-tested. Consider them experimental until validated.

import ../src/nimphea

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_MCP23017 = true
const MODE_SHIFT_REG = false
const MODE_CV_EXPANDER = false

var hw: DaisySeed

# ============================================================================
# DEMO 1: MCP23017 GPIO EXPANDER
# ============================================================================
## Demonstrates:
## - 16-bit I2C GPIO expander (2x 8-bit ports)
## - Port A: 8 input buttons with pull-ups
## - Port B: 8 output LEDs
## - Mirror button state to LEDs
##
## Connections:
## - MCP23017 SDA → Daisy D12
## - MCP23017 SCL → Daisy D11
## - Port A pins → 8 buttons to GND
## - Port B pins → 8 LEDs (with resistors to GND)

when MODE_MCP23017:
  import ../src/dev/mcp23x17
  
  var mcp: Mcp23017
  
  proc audioCallback(input_buffer, output_buffer: AudioBuffer, size: int) {.cdecl.} =
    for i in 0 ..< size:
      output_buffer[0][i] = 0.0
      output_buffer[1][i] = 0.0
  
  proc runMcp23017Demo() =
    hw.init()
    
    # Configure MCP23017
    var config: Mcp23017Config
    config.defaults()
    mcp.init(config)
    
    # Port A = inputs with pullups (for buttons)
    mcp.portMode(MCP_PORT_A, 0xFF, 0xFF, 0x00)
    
    # Port B = outputs (for LEDs)
    mcp.portMode(MCP_PORT_B, 0x00, 0x00, 0x00)
    
    hw.startAudio(audioCallback)
    
    while true:
      # Read buttons from Port A
      let inputs = mcp.readPort(MCP_PORT_A)
      
      # Mirror to LEDs on Port B (inverted for active-high LEDs)
      mcp.digitalWrite(MCP_PORT_B, not inputs)
      
      hw.delay(10)

# ============================================================================
# DEMO 2: CD4021 SHIFT REGISTER
# ============================================================================
## Demonstrates:
## - CD4021 8-bit parallel-to-serial shift register
## - Button matrix scanning via SPI-like interface
## - Edge detection for press/release events
##
## Connections:
## - CD4021 pin 10 (Clock) → Daisy D0
## - CD4021 pin 9 (Latch) → Daisy D1
## - CD4021 pin 11 (Data) → Daisy D2
## - CD4021 parallel inputs → 8 buttons to GND
## - Pull-up resistors on each input (or internal pull-ups)
##
## Behavior:
## - Slow blink when no buttons pressed
## - Fast blink when any button pressed

when MODE_SHIFT_REG:
  import ../src/nimphea_shift_register
  
  var
    shiftReg: ShiftRegister4021_1
    ledState: bool = false
    lastButtonState: array[8, bool]
  
  proc runShiftRegDemo() =
    hw.init()
    
    # Configure shift register pins
    var srConfig: ShiftRegisterConfig_1
    srConfig.clk = D0()
    srConfig.latch = D1()
    srConfig.data[0] = D2()
    srConfig.delay_ticks = 10
    
    shiftReg.init(srConfig)
    
    # Initialize button tracking
    for i in 0..<8:
      lastButtonState[i] = false
    
    var loopCount: uint32 = 0
    
    while true:
      # Read shift register
      shiftReg.update()
      
      # Check for any button press
      var anyPressed = false
      for i in 0..<8:
        let currentState = shiftReg.pressed(i.cint)
        
        # Detect rising edge (button just pressed)
        if currentState and not lastButtonState[i]:
          anyPressed = true
        
        lastButtonState[i] = currentState
      
      # Blink rate depends on button state
      let blinkRate = if anyPressed: 100'u32 else: 500'u32
      if loopCount mod blinkRate == 0:
        ledState = not ledState
        hw.setLed(ledState)
      
      inc loopCount
      hw.delay(1)

# ============================================================================
# DEMO 3: MAX11300 CV EXPANDER
# ============================================================================
## Demonstrates:
## - MAX11300 (PIXI) 20-channel mixed-signal I/O
## - 4x CV inputs (-5V to +5V bipolar)
## - 4x CV outputs (-5V to +5V bipolar)
## - DMA-based continuous updates
##
## Processing Examples:
## - CH 0: Quantize to semitones (1V/oct)
## - CH 1: Invert signal
## - CH 2: Attenuate 50%
## - CH 3: Pass through
##
## Pin Assignment:
## - Pins 0-3: CV inputs (ADC)
## - Pins 4-7: CV outputs (DAC)
##
## LED Indicators:
## - Fast blink: Init error
## - Medium blink: Config error
## - Slow blink (normal): Active operation

when MODE_CV_EXPANDER:
  import ../src/dev/max11300
  import std/math
  
  const
    NUM_CV_IN = 4
    NUM_CV_OUT = 4
  
  var
    pixi: MAX11300[1]
    cvInputs: array[NUM_CV_IN, float32]
    cvOutputs: array[NUM_CV_OUT, float32]
    updateCount: uint32 = 0
  
  proc updateComplete(context: pointer) {.cdecl.} =
    updateCount += 1
  
  proc processCV() =
    # Read all inputs
    for i in 0..<NUM_CV_IN:
      cvInputs[i] = pixi.readAnalogPinVolts(0, i.MAX11300Pin)
    
    # Process each channel differently
    # CH 0: Quantize to semitones (1V/oct, 12 semitones = 1V)
    cvOutputs[0] = (cvInputs[0] * 12.0).round() / 12.0
    
    # CH 1: Invert (-1x gain)
    cvOutputs[1] = -cvInputs[1]
    
    # CH 2: Attenuate (0.5x gain)
    cvOutputs[2] = cvInputs[2] * 0.5
    
    # CH 3: Pass through
    cvOutputs[3] = cvInputs[3]
    
    # Write outputs
    for i in 0..<NUM_CV_OUT:
      pixi.writeAnalogPinVolts(0, (i + NUM_CV_IN).MAX11300Pin, cvOutputs[i])
  
  proc audioCallback(input_buffer, output_buffer: AudioBuffer, size: int) {.cdecl.} =
    for i in 0 ..< size:
      output_buffer[0][i] = input_buffer[0][i]
      output_buffer[1][i] = input_buffer[1][i]
  
  proc errorBlink(delayMs: int) =
    while true:
      hw.setLed(true)
      hw.delay(delayMs)
      hw.setLed(false)
      hw.delay(delayMs)
  
  proc runCvExpanderDemo() =
    hw.init()
    hw.setLed(false)
    
    # Initialize MAX11300
    var config: MAX11300Config
    config.transport_config.defaults()
    
    if pixi.init(config) != MAX_OK:
      errorBlink(100)  # Fast blink on init error
    
    # Configure CV inputs (pins 0-3)
    for i in 0..<NUM_CV_IN:
      if pixi.configurePinAsAnalogRead(0, i.MAX11300Pin, ADC_NEG5_TO_5) != MAX_OK:
        errorBlink(200)  # Medium blink on config error
    
    # Configure CV outputs (pins 4-7)
    for i in 0..<NUM_CV_OUT:
      let pinNum = (i + NUM_CV_IN).MAX11300Pin
      if pixi.configurePinAsAnalogWrite(0, pinNum, DAC_NEG5_TO_5) != MAX_OK:
        errorBlink(300)  # Slow blink on config error
    
    # Start DMA updates
    discard pixi.start(updateComplete, nil)
    
    hw.startAudio(audioCallback)
    
    # Main loop
    while true:
      processCV()
      
      # Activity LED (toggle every 1024 DMA updates)
      if (updateCount and 0x3FF) == 0:
        hw.setLed(true)
      elif (updateCount and 0x3FF) == 0x200:
        hw.setLed(false)
      
      hw.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_MCP23017:
    runMcp23017Demo()
  elif MODE_SHIFT_REG:
    runShiftRegDemo()
  elif MODE_CV_EXPANDER:
    runCvExpanderDemo()
  else:
    hw.init()
    while true:
      hw.setLed(true)
      hw.delay(100)
      hw.setLed(false)
      hw.delay(100)

when isMainModule:
  main()
