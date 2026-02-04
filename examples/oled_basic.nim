## OLED Basic Example
## 
## Demonstrates basic OLED display usage with pixel drawing.
## Draws a simple pattern and animation.

import panicoverride
import ../src/nimphea
import ../src/hid/disp/oled_display

useNimpheaNamespace()

proc main() =
  var hw = initDaisy()
  
  # Initialize 128x64 OLED display via I2C
  # Default pins: PB8 (SCL), PB9 (SDA)
  var display = initOledI2c(128, 64)
  
  # Clear screen
  display.fill(false)
  
  # Draw border
  display.drawRect(0, 0, display.width, display.height, true)
  
  # Draw some patterns
  for i in 0..<10:
    display.drawLine(0, i * 6, 127, 63 - i * 6, true)
  
  # Draw circles
  display.drawCircle(32, 32, 15, true)
  display.drawCircle(96, 32, 15, true)
  
  # Update display to show everything
  display.update()
  
  # Animate a bouncing pixel
  var x = display.width div 2
  var y = display.height div 2
  var dx = 1
  var dy = 1
  
  while true:
    # Clear old pixel
    display.drawPixel(x, y, false)
    
    # Update position
    x += dx
    y += dy
    
    # Bounce off walls
    if x <= 1 or x >= display.width - 2:
      dx = -dx
    if y <= 1 or y >= display.height - 2:
      dy = -dy
    
    # Draw new pixel
    display.drawPixel(x, y, true)
    display.update()
    
    hw.delay(20)

when isMainModule:
  main()
