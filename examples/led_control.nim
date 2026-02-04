## LED Control Example
import panicoverride
import ../src/nimphea
import ../src/per/uart
import ../src/hid/rgb_led
import ../src/nimphea_color
useNimpheaNamespace()

proc main() =
  var daisy = initDaisy()
  
  # Initialize RGB LED on pins D10 (R), D11 (G), D12 (B)
  var rgb: RgbLed
  rgb.init(D10(), D11(), D12(), false)  # Not inverted
  
  startLog()
  printLine("LED Control Example")
  printLine("RGB LED + Color")
  printLine("Pins: R=D10, G=D11, B=D12")
  printLine()
  
  # Create some predefined colors
  var red = createColor()
  red.init(COLOR_RED)
  
  var green = createColor()
  green.init(COLOR_GREEN)
  
  var blue = createColor()
  blue.init(COLOR_BLUE)
  
  var white = createColor()
  white.init(COLOR_WHITE)
  
  var purple = createColor()
  purple.init(COLOR_PURPLE)
  
  var cyan = createColor()
  cyan.init(COLOR_CYAN)
  
  var off = createColor()
  off.init(COLOR_OFF)
  
  # Custom color (orange)
  var orange = createColor(1.0f, 0.5f, 0.0f)
  
  printLine("Phase 1: Primary Colors")
  
  # Cycle through primary colors
  rgb.setColor(red)
  rgb.update()
  print("Red")
  daisy.delay(1000)
  
  rgb.setColor(green)
  rgb.update()
  printLine(" -> Green")
  daisy.delay(1000)
  
  rgb.setColor(blue)
  rgb.update()
  printLine(" -> Blue")
  daisy.delay(1000)
  
  printLine()
  printLine("Phase 2: Mixed Colors")
  
  rgb.setColor(purple)
  rgb.update()
  print("Purple")
  daisy.delay(1000)
  
  rgb.setColor(cyan)
  rgb.update()
  printLine(" -> Cyan")
  daisy.delay(1000)
  
  rgb.setColor(orange)
  rgb.update()
  printLine(" -> Orange")
  daisy.delay(1000)
  
  rgb.setColor(white)
  rgb.update()
  printLine(" -> White")
  daisy.delay(1000)
  
  printLine()
  printLine("Phase 3: Color Blending (Red <-> Blue)")
  
  # Blend between red and blue
  for i in 0..10:
    let blend_amt = float(i) / 10.0f
    var blended = colorBlend(red, blue, blend_amt)
    rgb.setColor(blended)
    rgb.update()
    
    print("Blend ")
    print(int(blend_amt * 100.0f))
    printLine("%")
    daisy.delay(200)
  
  printLine()
  printLine("Phase 4: Rainbow Cycle")
  
  # Simple rainbow effect using HSV-like color generation
  var cycleCount = 0
  while cycleCount < 3:  # 3 full cycles
    for hue in 0..359:
      # Convert hue (0-359) to RGB
      let h = float(hue) / 60.0f
      let sector = int(h)
      let f = h - float(sector)
      
      var r, g, b: cfloat
      
      case sector
      of 0:  # Red to Yellow
        r = 1.0f
        g = f
        b = 0.0f
      of 1:  # Yellow to Green
        r = 1.0f - f
        g = 1.0f
        b = 0.0f
      of 2:  # Green to Cyan
        r = 0.0f
        g = 1.0f
        b = f
      of 3:  # Cyan to Blue
        r = 0.0f
        g = 1.0f - f
        b = 1.0f
      of 4:  # Blue to Magenta
        r = f
        g = 0.0f
        b = 1.0f
      else:  # Magenta to Red
        r = 1.0f
        g = 0.0f
        b = 1.0f - f
      
      var color = createColor(r, g, b)
      rgb.setColor(color)
      rgb.update()
      
      # Print every 60 degrees
      if hue mod 60 == 0:
        print("Hue: ")
        print(hue)
        printLine("°")
      
      daisy.delay(10)  # 10ms per step = 3.6s per cycle
    
    cycleCount.inc
  
  printLine()
  printLine("Done! Turning off LED.")
  rgb.setColor(off)
  rgb.update()
  
  # Loop forever
  while true:
    daisy.delay(1000)

when isMainModule:
  main()
