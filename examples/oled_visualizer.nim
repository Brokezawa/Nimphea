## OLED Visualizer Example
## 
## Uses ADC input to create a simple audio-style visualizer on the OLED.
## Connect a potentiometer to A0 for interactive control.

import panicoverride
import ../src/nimphea
import ../src/hid/disp/oled_display
import ../src/per/adc

useNimpheaNamespace()

proc main() =
  var hw = initDaisy()
  
  # Initialize OLED display - generic API
  var display = initOledI2c(128, 64)
  
  # Initialize ADC for input
  var adcChannels: array[1, AdcChannelConfig]
  adcChannels[0].initSingle(A0())
  var adc = initAdcHandle(adcChannels, OVS_32)
  adc.start()
  
  # Buffer for bar heights
  var bars: array[16, int]
  
  while true:
    # Read ADC value
    let input = adc.getFloat(0)
    
    # Update bars (shift left and add new)
    for i in 0..<15:
      bars[i] = bars[i + 1]
    let maxBarHeight = display.height - 10
    bars[15] = int(input * maxBarHeight.float)
    
    # Clear display
    display.fill(false)
    
    # Draw title bar
    display.fillRect(0, 0, display.width, 8, true)
    
    # Draw bars
    for i in 0..<16:
      let x = i * 8
      let barHeight = bars[i]
      if barHeight > 0:
        display.fillRect(x + 1, display.height - barHeight, 6, barHeight, true)
    
    # Draw current value indicator
    let indicatorY = display.height - int(input * (display.height - 10).float) - 10
    display.fillRect(display.width - 8, indicatorY, 6, 4, true)
    
    display.update()
    
    hw.delay(50)

when isMainModule:
  main()
