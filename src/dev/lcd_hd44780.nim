## HD44780 LCD Driver
## ===================
##
## Nim wrapper for the HD44780 character LCD controller.
##
## The HD44780 is a very common character LCD controller used in 16x2 and 20x4
## displays. This driver uses 4-bit data mode to minimize pin usage.
##
## **Features:**
## - 4-bit data mode (uses 6 GPIO pins total)
## - 16x2 or 20x4 character displays
## - Cursor control (on/off, blink)
## - Text and integer printing
## - Cursor positioning
## - Clear display
##
## **Hardware:**
## - Example product: https://www.adafruit.com/product/181
## - Requires 6 GPIO pins: RS, EN, D4, D5, D6, D7
##
## **Example:**
## ```nim
## import ../src/nimphea
## import ../src/dev/lcd_hd44780
##
## var lcd: LcdHD44780
## var lcdCfg: LcdHD44780Config
##
## lcdCfg.cursor_on = false
## lcdCfg.cursor_blink = false
## lcdCfg.rs = seed.GetPin(1)
## lcdCfg.en = seed.GetPin(2)
## lcdCfg.d4 = seed.GetPin(3)
## lcdCfg.d5 = seed.GetPin(4)
## lcdCfg.d6 = seed.GetPin(5)
## lcdCfg.d7 = seed.GetPin(6)
##
## lcd.init(lcdCfg)
## lcd.clear()
## lcd.print("Hello, World!")
## lcd.setCursor(1, 0)  # Move to second row
## lcd.printInt(42)
## ```

import ../nimphea
import ../nimphea_macros

useNimpheaModules(lcd_hd44780)

{.push header: "dev/lcd_hd44780.h".}

type
  LcdHD44780Config* {.importcpp: "daisy::LcdHD44780::Config".} = object
    ## Configuration struct for HD44780 LCD initialization
    cursor_on*: bool      ## Set true to show cursor
    cursor_blink*: bool   ## Set true to enable cursor blinking
    rs*: Pin              ## Register Select pin
    en*: Pin              ## Enable pin
    d4*: Pin              ## Data pin 4
    d5*: Pin              ## Data pin 5
    d6*: Pin              ## Data pin 6
    d7*: Pin              ## Data pin 7

  LcdHD44780* {.importcpp: "daisy::LcdHD44780".} = object
    ## HD44780 character LCD driver
    ## 
    ## Controls 16x2 or 20x4 character LCDs using the HD44780 controller
    ## in 4-bit data mode.

{.pop.}

proc init*(this: var LcdHD44780, config: LcdHD44780Config) 
  {.importcpp: "#.Init(#)".}
  ## Initialize the LCD display
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct with pin assignments and cursor settings
  ## 
  ## **Example:**
  ## ```nim
  ## var lcd: LcdHD44780
  ## var cfg: LcdHD44780Config
  ## cfg.cursor_on = false
  ## cfg.cursor_blink = false
  ## cfg.rs = seed.GetPin(1)
  ## cfg.en = seed.GetPin(2)
  ## cfg.d4 = seed.GetPin(3)
  ## cfg.d5 = seed.GetPin(4)
  ## cfg.d6 = seed.GetPin(5)
  ## cfg.d7 = seed.GetPin(6)
  ## lcd.init(cfg)
  ## ```

proc print*(this: var LcdHD44780, text: cstring) 
  {.importcpp: "#.Print(#)".}
  ## Print a string to the LCD at the current cursor position
  ## 
  ## **Parameters:**
  ## - `text` - C-style string to print
  ## 
  ## **Example:**
  ## ```nim
  ## lcd.print("Hello!")
  ## ```

proc printInt*(this: var LcdHD44780, number: cint) 
  {.importcpp: "#.PrintInt(#)".}
  ## Print an integer value to the LCD at the current cursor position
  ## 
  ## **Parameters:**
  ## - `number` - Integer to print
  ## 
  ## **Example:**
  ## ```nim
  ## lcd.printInt(42)
  ## ```

proc setCursor*(this: var LcdHD44780, row: uint8, col: uint8) 
  {.importcpp: "#.SetCursor(#, #)".}
  ## Move the cursor to the specified position
  ## 
  ## **Parameters:**
  ## - `row` - Row number (0 or 1 for 16x2, 0-3 for 20x4)
  ## - `col` - Column number (0-15 for 16x2, 0-19 for 20x4)
  ## 
  ## **Example:**
  ## ```nim
  ## lcd.setCursor(1, 0)  # Move to start of second row
  ## lcd.print("Row 2")
  ## ```

proc clear*(this: var LcdHD44780) 
  {.importcpp: "#.Clear()".}
  ## Clear the entire LCD display
  ## 
  ## Clears all characters and resets cursor to home position (0, 0).
  ## 
  ## **Example:**
  ## ```nim
  ## lcd.clear()
  ## lcd.print("Fresh start")
  ## ```
