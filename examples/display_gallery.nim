## Display Gallery - Comprehensive Demo of All OLED Drivers
##
## This example demonstrates all the OLED display drivers available in Nimphea,
## showcasing their capabilities and providing a visual comparison.
##
## **Supported Displays:**
## - SSD1306/SSD1309 (128x64 monochrome, I2C/SPI) - existing
## - SH1106 (128x64 monochrome, I2C/SPI) - v0.15.0
## - SSD1327 (128x128 grayscale 16-level, SPI) - v0.15.0
## - SSD1351 (128x128 RGB 65K color, SPI) - v0.15.0
##
## **Features Demonstrated:**
## - Rectangle drawing and manipulation
## - Circle and arc drawing
## - Line drawing with patterns
## - Pixel-level control
## - Color/grayscale support
## - Alignment helpers
## - Animation patterns (expanding circles, grids)
## - Performance comparison
##
## **Hardware Setup:**
## Connect your OLED display to Daisy Seed:
## - I2C: SCL=PB8, SDA=PB9
## - SPI: SCK=PG11, MOSI=PB5, DC=PB4, CS=PB12, RST=PB15
##
## **Usage:**
## Uncomment the display type you want to test below.

import ../src/nimphea
import ../src/nimphea_macros
import ../src/hid/disp/graphics_common

# Import display drivers (uncomment the one you're using)
# import ../src/hid/disp/oled_display  # SSD130x series
# import ../src/dev/oled_sh1106  # SH1106
# import ../src/dev/oled_ssd1327  # SSD1327 grayscale
import ../src/dev/oled_ssd1351  # SSD1351 color

useNimpheaNamespace()
useNimpheaModules(ssd1351)  # Change based on your display

# ============================================================================
# Pattern 1: Geometric shapes test pattern
# ============================================================================
proc drawTestPattern(display: var SSD1351Spi128x128) =
  ## Demonstrates all drawing capabilities with geometric shapes
  
  display.fill(false)
  
  # Section 1: Geometric shapes (top-left quadrant)
  # Draw nested rectangles
  display.setColor(COLOR_RED)
  display.drawRect(2, 2, 60, 60, true)  # Outer border
  
  display.setColor(COLOR_ORANGE)
  display.fillRect(10, 10, 44, 44, true)  # Filled inner
  
  display.setColor(COLOR_YELLOW)
  display.drawRect(20, 20, 24, 24, true)  # Inner border
  
  # Section 2: Circles (top-right quadrant)
  display.setColor(COLOR_GREEN)
  display.drawCircle(96, 32, 28, true)  # Large circle
  
  display.setColor(COLOR_CYAN)
  display.drawCircle(96, 32, 20, true)  # Medium circle
  
  display.setColor(COLOR_BLUE)
  display.drawCircle(96, 32, 12, true)  # Small circle
  
  # Section 3: Lines and patterns (bottom-left quadrant)
  display.setColor(COLOR_PURPLE)
  for i in 0..5:
    display.drawLine(2 + i*10, 66, 2 + i*10, 126, true)
    display.drawLine(2, 66 + i*10, 62, 66 + i*10, true)
  
  # Section 4: Pixel art (bottom-right quadrant)
  display.setColor(COLOR_MAGENTA)
  # Draw a simple smiley face with pixels
  for y in 80..82:
    for x in 82..84:
      display.drawPixel(x, y, true)
    for x in 106..108:
      display.drawPixel(x, y, true)
  
  # Smile (simple arc approximation)
  let smilePoints = [
    (82, 100), (84, 102), (86, 104), (88, 105),
    (90, 106), (92, 106), (94, 106), (96, 106),
    (98, 106), (100, 106), (102, 105), (104, 104),
    (106, 102), (108, 100)
  ]
  
  for point in smilePoints:
    display.drawPixel(point[0], point[1], true)
  
  display.update()

# ============================================================================
# Pattern 2: Concentric circles (adapted from oled_graphics.nim)
# ============================================================================
proc drawConcentricCircles(display: var SSD1351Spi128x128) =
  ## Draws concentric circles from center outward
  
  display.fill(false)
  
  let centerX = 64  # 128/2
  let centerY = 64  # 128/2
  let maxRadius = 60
  
  var colorIdx = 0
  for r in countup(5, maxRadius, 5):
    case colorIdx mod 8
    of 0: display.setColor(COLOR_RED)
    of 1: display.setColor(COLOR_ORANGE)
    of 2: display.setColor(COLOR_YELLOW)
    of 3: display.setColor(COLOR_GREEN)
    of 4: display.setColor(COLOR_CYAN)
    of 5: display.setColor(COLOR_BLUE)
    of 6: display.setColor(COLOR_PURPLE)
    else: display.setColor(COLOR_MAGENTA)
    
    display.drawCircle(centerX, centerY, r, true)
    inc colorIdx
  
  display.update()

# ============================================================================
# Pattern 3: Grid pattern (adapted from oled_graphics.nim)
# ============================================================================
proc drawGrid(display: var SSD1351Spi128x128) =
  ## Draws a grid pattern
  
  display.fill(false)
  display.setColor(COLOR_CYAN)
  
  # Vertical lines
  for i in countup(0, 127, 16):
    display.drawLine(i, 0, i, 127, true)
  
  # Horizontal lines
  for i in countup(0, 127, 16):
    display.drawLine(0, i, 127, i, true)
  
  # Highlight center
  display.setColor(COLOR_YELLOW)
  display.drawCircle(64, 64, 5, true)
  
  display.update()

# ============================================================================
# Pattern 4: Diagonal lines (adapted from oled_graphics.nim)
# ============================================================================
proc drawDiagonalLines(display: var SSD1351Spi128x128) =
  ## Draws crossing diagonal lines
  
  display.fill(false)
  
  display.setColor(COLOR_GREEN)
  for i in 0..<8:
    display.drawLine(i * 16, 0, 127, 127 - i * 16, true)
  
  display.setColor(COLOR_PURPLE)
  for i in 0..<8:
    display.drawLine(0, i * 16, 127 - i * 16, 127, true)
  
  display.update()

# ============================================================================
# Pattern 5: Nested rectangles (adapted from oled_graphics.nim)
# ============================================================================
proc drawNestedRectangles(display: var SSD1351Spi128x128) =
  ## Draws nested centered rectangles
  
  display.fill(false)
  
  var colorIdx = 0
  for i in 0..<6:
    case colorIdx mod 6
    of 0: display.setColor(COLOR_RED)
    of 1: display.setColor(COLOR_ORANGE)
    of 2: display.setColor(COLOR_YELLOW)
    of 3: display.setColor(COLOR_GREEN)
    of 4: display.setColor(COLOR_CYAN)
    else: display.setColor(COLOR_BLUE)
    
    let size = 20 + i * 18
    let x = 64 - size div 2
    let y = 64 - size div 2
    display.drawRect(x, y, size, size, true)
    inc colorIdx
  
  display.update()

# ============================================================================
# Pattern 6: Performance test with many primitives
# ============================================================================
proc drawPerformanceTest(display: var SSD1351Spi128x128) =
  ## Tests drawing speed with many primitives
  
  display.fill(false)
  
  # Draw 50 pseudo-random lines
  var seed = 12345u32
  for i in 0..<50:
    seed = (seed * 1103515245u32 + 12345u32)
    let x1 = (seed mod 128).int
    seed = (seed * 1103515245u32 + 12345u32)
    let y1 = (seed mod 128).int
    seed = (seed * 1103515245u32 + 12345u32)
    let x2 = (seed mod 128).int
    seed = (seed * 1103515245u32 + 12345u32)
    let y2 = (seed mod 128).int
    seed = (seed * 1103515245u32 + 12345u32)
    let colorIdx = seed mod 9u32
    
    case colorIdx
    of 0: display.setColor(COLOR_RED)
    of 1: display.setColor(COLOR_ORANGE)
    of 2: display.setColor(COLOR_YELLOW)
    of 3: display.setColor(COLOR_GREEN)
    of 4: display.setColor(COLOR_CYAN)
    of 5: display.setColor(COLOR_BLUE)
    of 6: display.setColor(COLOR_PURPLE)
    of 7: display.setColor(COLOR_MAGENTA)
    else: display.setColor(COLOR_WHITE)
    
    display.drawLine(x1, y1, x2, y2, true)
  
  display.update()

# ============================================================================
# Pattern 7: Rectangle API demonstration
# ============================================================================
proc demonstrateRectangleAPI(display: var SSD1351Spi128x128) =
  ## Shows Rectangle manipulation capabilities
  
  display.fill(false)
  
  # Create a rectangle and demonstrate transformations
  let baseRect = initRectangle(20, 20, 88, 88)
  
  # Show original
  display.setColor(COLOR_BLUE)
  display.drawRect(baseRect.getX().int, baseRect.getY().int,
                   baseRect.getWidth().int, baseRect.getHeight().int,
                   true)
  
  # Show reduced (shrunk by 10px on all sides)
  let reduced = baseRect.reduced(10)
  display.setColor(COLOR_GREEN)
  display.drawRect(reduced.getX().int, reduced.getY().int,
                   reduced.getWidth().int, reduced.getHeight().int,
                   true)
  
  # Show centered smaller version
  let centered = initRectangle(40, 40).withCenter(64, 64)
  display.setColor(COLOR_RED)
  display.fillRect(centered.getX().int, centered.getY().int,
                   centered.getWidth().int, centered.getHeight().int,
                   true)
  
  # Mark center points
  display.setColor(COLOR_WHITE)
  display.drawPixel(baseRect.getCenterX().int, baseRect.getCenterY().int, true)
  display.drawPixel(reduced.getCenterX().int, reduced.getCenterY().int, true)
  display.drawPixel(centered.getCenterX().int, centered.getCenterY().int, true)
  
  display.update()

# ============================================================================
# Pattern 8: RGB color gradient (SSD1351 only)
# ============================================================================
proc drawColorGradient(display: var SSD1351Spi128x128) =
  ## Shows RGB565 color capabilities
  
  display.fill(false)
  
  # Red gradient (top third)
  for y in 0..<42:
    let redLevel = (y * 31) div 42
    display.setColorRGB(redLevel.uint8, 0, 0)
    display.drawLine(0, y, 127, y, true)
  
  # Green gradient (middle third)
  for y in 42..<84:
    let greenLevel = ((y - 42) * 63) div 42
    display.setColorRGB(0, greenLevel.uint8, 0)
    display.drawLine(0, y, 127, y, true)
  
  # Blue gradient (bottom third)
  for y in 84..<128:
    let blueLevel = ((y - 84) * 31) div 44
    display.setColorRGB(0, 0, blueLevel.uint8)
    display.drawLine(0, y, 127, y, true)
  
  display.update()

# ============================================================================
# Pattern 9: Animated expanding circle (from oled_spi.nim)
# ============================================================================
proc animateExpandingCircle(display: var SSD1351Spi128x128, daisy: var DaisySeed) =
  ## Animated expanding/contracting circle
  
  var radius = 5
  var growing = true
  let centerX = 64
  let centerY = 64
  let maxRadius = 58
  
  for frame in 0..<120:  # Run for ~4 seconds at 30fps
    display.fill(false)
    
    # Draw border
    display.setColor(COLOR_WHITE)
    display.drawRect(0, 0, 128, 128, true)
    
    # Draw expanding/contracting circle
    display.setColor(COLOR_CYAN)
    display.drawCircle(centerX, centerY, radius, true)
    
    # Draw decorative corners
    display.setColor(COLOR_YELLOW)
    display.fillRect(0, 0, 5, 5, true)
    display.fillRect(123, 0, 5, 5, true)
    display.fillRect(0, 123, 5, 5, true)
    display.fillRect(123, 123, 5, 5, true)
    
    display.update()
    
    # Update radius
    if growing:
      inc radius
      if radius >= maxRadius:
        growing = false
    else:
      dec radius
      if radius <= 5:
        growing = true
    
    daisy.delay(33)  # ~30 FPS

# ============================================================================
# Main program
# ============================================================================
proc main() =
  var daisy = initDaisy()
  
  # Initialize display (change based on your hardware)
  var display = initSSD1351Spi(128, 128)
  
  # Run through all demonstration modes
  # Each static mode runs for 2 seconds, animation runs ~4 seconds
  
  while true:
    # Pattern 1: Test pattern
    drawTestPattern(display)
    daisy.delay(2000)
    
    # Pattern 2: Concentric circles
    drawConcentricCircles(display)
    daisy.delay(2000)
    
    # Pattern 3: Grid
    drawGrid(display)
    daisy.delay(2000)
    
    # Pattern 4: Diagonal lines
    drawDiagonalLines(display)
    daisy.delay(2000)
    
    # Pattern 5: Nested rectangles
    drawNestedRectangles(display)
    daisy.delay(2000)
    
    # Pattern 6: Performance test
    drawPerformanceTest(display)
    daisy.delay(2000)
    
    # Pattern 7: Rectangle API demo
    demonstrateRectangleAPI(display)
    daisy.delay(2000)
    
    # Pattern 8: Color gradient (SSD1351 specific)
    drawColorGradient(display)
    daisy.delay(2000)
    
    # Pattern 9: Animated expanding circle
    animateExpandingCircle(display, daisy)

when isMainModule:
  main()
