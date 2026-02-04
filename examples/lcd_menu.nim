## LCD Menu Example
## =================
##
## Demonstrates using the HD44780 character LCD for a simple menu system.
## Shows parameter display, editing, and navigation on a 16x2 LCD.
##
## **Hardware:**
## - Daisy Seed
## - 16x2 Character LCD (HD44780 compatible)
## - 6 GPIO connections for LCD
## - Encoder for navigation (optional - using buttons in this example)

import ../src/nimphea
import ../src/hid/ctrl
import ../src/dev/lcd_hd44780

useNimpheaNamespace()

var seed: DaisySeed
var lcd: LcdHD44780
var encoder: Encoder

# Menu parameters
var volume: int = 50        # 0-100
var frequency: int = 440    # Hz
var waveform: int = 0       # 0=sine, 1=square, 2=saw, 3=triangle
var currentMenu: int = 0    # Which parameter we're editing

const waveformNames = ["Sine", "Square", "Saw", "Triangle"]

proc updateDisplay() =
  ## Refresh the LCD display with current values
  lcd.clear()
  
  case currentMenu
  of 0:  # Volume
    lcd.setCursor(0, 0)
    lcd.print(">Volume:")
    lcd.setCursor(1, 0)
    lcd.print(" ")
    lcd.printInt(volume.cint)
    lcd.print("%")
    
  of 1:  # Frequency
    lcd.setCursor(0, 0)
    lcd.print(">Frequency:")
    lcd.setCursor(1, 0)
    lcd.print(" ")
    lcd.printInt(frequency.cint)
    lcd.print("Hz")
    
  of 2:  # Waveform
    lcd.setCursor(0, 0)
    lcd.print(">Waveform:")
    lcd.setCursor(1, 0)
    lcd.print(" ")
    lcd.print(waveformNames[waveform])
    
  else:
    discard

proc handleEncoder() =
  ## Handle encoder input for menu navigation and editing
  let increment = encoder.increment()
  
  # Encoder turn - adjust current parameter
  if increment != 0:
    case currentMenu
    of 0:  # Volume
      volume += increment
      if volume < 0: volume = 0
      if volume > 100: volume = 100
      
    of 1:  # Frequency
      frequency += increment * 10
      if frequency < 20: frequency = 20
      if frequency > 20000: frequency = 20000
      
    of 2:  # Waveform
      waveform += increment
      if waveform < 0: waveform = 3
      if waveform > 3: waveform = 0
      
    else:
      discard
    
    updateDisplay()
  
  # Encoder press - move to next menu item
  if encoder.fallingEdge():
    currentMenu = (currentMenu + 1) mod 3
    updateDisplay()

proc main() =
  # Initialize Daisy Seed
  seed.init()
  
  # Initialize LCD
  var lcdCfg: LcdHD44780Config
  lcdCfg.cursor_on = false
  lcdCfg.cursor_blink = false
  lcdCfg.rs = getPin(1)   # Register Select
  lcdCfg.en = getPin(2)   # Enable
  lcdCfg.d4 = getPin(3)   # Data 4
  lcdCfg.d5 = getPin(4)   # Data 5
  lcdCfg.d6 = getPin(5)   # Data 6
  lcdCfg.d7 = getPin(6)   # Data 7
  lcd.init(lcdCfg)
  
  # Initialize encoder
  encoder = initEncoder(getPin(7), getPin(8), getPin(9))
  
  # Initial display
  lcd.clear()
  lcd.print("LCD Menu Demo")
  lcd.setCursor(1, 0)
  lcd.print("Starting...")
  seed.delay(1000)
  
  updateDisplay()
  
  # Main loop
  while true:
    # Process encoder input
    handleEncoder()
    
    # Small delay to debounce
    seed.delay(10)

# Entry point
when isMainModule:
  main()
