## ADC Demonstration
##
## Comprehensive example showing all ADC capabilities in Nimphea:
## - Single channel reading (simple analog input)
## - Multi-channel reading (up to 8 inputs)
## - Multiplexed inputs (8+ inputs via CD4051)
## - Configuration options (conversion speed, oversampling)
##
## **Hardware Setup (Basic)**:
## - Daisy Seed
## - Potentiometer(s) connected to A0, A1, etc.
## - Potentiometer wiper to ADC pin, other legs to 3.3V and GND
##
## **Hardware Setup (Multiplexed - Optional)**:
## - CD4051 8-channel analog multiplexer
## - Mux output (Y) → A0
## - Select pins: S0 → D0, S1 → D1, S2 → D2
## - INH → GND, VDD → 3.3V, VEE/VSS → GND
## - Up to 8 analog inputs on Y0-Y7
##
## **Features Demonstrated**:
## 1. initAdc() / initAdcHandle() - Simple vs. advanced initialization
## 2. getFloat() / value() - Normalized reading (0.0 to 1.0)
## 3. get() - Raw 12-bit ADC value (0-4095)
## 4. getMuxFloat() - Multiplexed input reading
## 5. Oversampling options (OVS_NONE to OVS_1024)
## 6. Conversion speed options (SPEED_1CYCLES_5 to SPEED_810CYCLES_5)
##
## **Modes**: The example cycles through different modes to demonstrate each feature.
## Press the button (if connected to D7) or wait 10 seconds to advance modes.

import panicoverride
import ../src/nimphea
import ../src/per/adc
import ../src/hid/ctrl  # For initAdc() helper
import ../src/per/uart

useNimpheaNamespace()

# =============================================================================
# Mode 1: Single Channel (Simplest Usage)
# =============================================================================
proc demoSingleChannel(hw: var DaisySeed) =
  ## Demonstrates the simplest way to read an analog input.
  ## Uses the high-level initAdc() helper function.
  
  printLine("=== Mode 1: Single Channel ADC ===")
  printLine("Reading A0 with default settings")
  printLine()
  
  # Simple initialization - one line!
  var adc = initAdc(hw, [A0()])
  adc.start()
  
  for i in 0..<50:  # Run for ~5 seconds
    let value = adc.value(0)          # 0.0 to 1.0 normalized
    let voltage = value * 3.3         # Convert to voltage
    
    # Print with simple bar graph
    print("A0: ")
    print(value)
    print(" (")
    print(voltage)
    print("V) ")
    
    # Visual bar graph
    let bars = int(value * 20)
    print("[")
    for j in 0..<20:
      if j < bars: print("#")
      else: print(" ")
    print("]")
    printLine()
    
    hw.delay(100)
  
  adc.stop()
  printLine()

# =============================================================================
# Mode 2: Multi-Channel (4 Inputs)
# =============================================================================
proc demoMultiChannel(hw: var DaisySeed) =
  ## Demonstrates reading multiple independent analog inputs.
  ## Uses the lower-level AdcChannelConfig for more control.
  
  printLine("=== Mode 2: Multi-Channel ADC ===")
  printLine("Reading A0-A3 simultaneously")
  printLine()
  
  # Configure 4 channels using AdcChannelConfig
  var channels: array[4, adc.AdcChannelConfig]
  channels[0].initSingle(A0())
  channels[1].initSingle(A1())
  channels[2].initSingle(A2())
  channels[3].initSingle(A3())
  
  # Initialize with 32x oversampling for noise reduction
  var adc = initAdcHandle(channels, OVS_32)
  adc.start()
  
  for i in 0..<50:  # Run for ~5 seconds
    # Read all 4 channels
    let ch0 = adc.getFloat(0)
    let ch1 = adc.getFloat(1)
    let ch2 = adc.getFloat(2)
    let ch3 = adc.getFloat(3)
    
    # Display in columns
    print("A0: ")
    print(ch0)
    print(" | A1: ")
    print(ch1)
    print(" | A2: ")
    print(ch2)
    print(" | A3: ")
    print(ch3)
    printLine()
    
    # LED brightness based on A0
    hw.setLed(ch0 > 0.5)
    
    hw.delay(100)
  
  adc.stop()
  printLine()

# =============================================================================
# Mode 3: Multiplexed Inputs (8 via CD4051)
# =============================================================================
proc demoMultiplexed(hw: var DaisySeed) =
  ## Demonstrates reading 8 inputs through a CD4051 multiplexer.
  ## Uses only 1 ADC pin + 3 digital pins for 8 analog inputs.
  
  printLine("=== Mode 3: Multiplexed ADC ===")
  printLine("Reading 8 inputs via CD4051 on A0")
  printLine("Select pins: D0, D1, D2")
  printLine()
  
  # Configure 1 ADC channel with 8-way multiplexer
  var channels: array[1, adc.AdcChannelConfig]
  channels[0].initMux(
    adcPin = A0(),      # Mux output
    muxChannels = 8,    # 8 inputs (CD4051)
    mux0 = D0(),        # S0 select line
    mux1 = D1(),        # S1 select line
    mux2 = D2()         # S2 select line
  )
  
  var adc = initAdcHandle(channels, OVS_32)
  adc.start()
  
  for i in 0..<50:  # Run for ~5 seconds
    # Read all 8 multiplexed inputs
    print("Mux: ")
    for j in 0..<8:
      let value = adc.getMuxFloat(0, j)
      print(value)
      if j < 7: print(" ")
    printLine()
    
    # Bar graph for first mux input
    let input0 = adc.getMuxFloat(0, 0)
    let bars = int(input0 * 30)
    print("[")
    for j in 0..<30:
      if j < bars: print("=")
      else: print(" ")
    print("] ")
    print(input0)
    printLine()
    printLine()
    
    hw.delay(100)
  
  adc.stop()
  printLine()

# =============================================================================
# Mode 4: Configuration Options
# =============================================================================
proc demoConfiguration(hw: var DaisySeed) =
  ## Demonstrates different ADC configuration options.
  ## Shows how conversion speed and oversampling affect readings.
  
  printLine("=== Mode 4: ADC Configuration ===")
  printLine("Comparing fast vs slow conversion")
  printLine()
  
  # Configure 2 channels with different conversion speeds
  var channels: array[2, adc.AdcChannelConfig]
  
  # Channel 0: Fast conversion (for rapidly changing signals)
  channels[0].initSingle(A0(), SPEED_1CYCLES_5)
  
  # Channel 1: Slow conversion (higher accuracy, more filtering)
  channels[1].initSingle(A1(), SPEED_810CYCLES_5)
  
  # 64x oversampling for noise reduction
  var adc = initAdcHandle(channels, OVS_64)
  adc.start()
  
  var sum0, sum1: float = 0.0
  var sampleCount = 0
  
  printLine("Ch0: Fast (1.5 cycles) | Ch1: Slow (810.5 cycles)")
  printLine("Oversampling: 64x")
  printLine()
  
  for i in 0..<100:  # Run for ~5 seconds
    let fast = adc.getFloat(0)
    let slow = adc.getFloat(1)
    
    sum0 += fast
    sum1 += slow
    inc sampleCount
    
    # Every 10 samples, show statistics
    if sampleCount >= 10:
      let avg0 = sum0 / 10.0
      let avg1 = sum1 / 10.0
      
      print("Fast: ")
      print(fast)
      print(" (avg=")
      print(avg0)
      print(") | Slow: ")
      print(slow)
      print(" (avg=")
      print(avg1)
      printLine(")")
      
      # Also show raw 12-bit values
      let raw0 = adc.get(0)
      let raw1 = adc.get(1)
      print("Raw: ")
      print(raw0.int)
      print(" | ")
      print(raw1.int)
      printLine()
      printLine()
      
      sum0 = 0.0
      sum1 = 0.0
      sampleCount = 0
    
    hw.delay(50)
  
  adc.stop()
  printLine()

# =============================================================================
# Main Program
# =============================================================================
proc main() =
  var hw = initDaisy()
  
  startLog()
  printLine("========================================")
  printLine("     ADC Demonstration Example")
  printLine("========================================")
  printLine()
  printLine("This example cycles through 4 ADC modes:")
  printLine("  1. Single Channel (simplest)")
  printLine("  2. Multi-Channel (4 inputs)")
  printLine("  3. Multiplexed (8 via CD4051)")
  printLine("  4. Configuration Options")
  printLine()
  printLine("Each mode runs for ~5 seconds.")
  printLine()
  
  while true:
    # Mode 1: Single channel
    demoSingleChannel(hw)
    hw.delay(1000)
    
    # Mode 2: Multi-channel
    demoMultiChannel(hw)
    hw.delay(1000)
    
    # Mode 3: Multiplexed
    demoMultiplexed(hw)
    hw.delay(1000)
    
    # Mode 4: Configuration
    demoConfiguration(hw)
    hw.delay(1000)
    
    printLine("========================================")
    printLine("       Restarting demonstration")
    printLine("========================================")
    printLine()

when isMainModule:
  main()
