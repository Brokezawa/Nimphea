## OLED Fonts
## ===========
##
## Nim wrapper for OLED font data utilities.
##
## Provides various bitmap fonts for use with OLED displays (SSD130x family).
## These fonts are pre-rendered ASCII character sets optimized for small displays.
##
## **Available Fonts:**
## - Font_4x6   - Tiny font (4x6 pixels per character)
## - Font_4x8   - Small font (4x8 pixels)
## - Font_5x8   - Small font (5x8 pixels)
## - Font_6x7   - Medium small font (6x7 pixels)
## - Font_6x8   - Medium font (6x8 pixels)
## - Font_7x10  - Medium font (7x10 pixels)
## - Font_11x18 - Large font (11x18 pixels)
## - Font_16x26 - Extra large font (16x26 pixels)
##
## **Example:**
## ```nim
## import ../src/nimphea
## import ../src/dev/oled
## import ../src/util/oled_fonts
##
## var display: OledDisplay128x64I2c
## # ... initialize display ...
##
## # Use different font sizes
## display.setFont(Font_7x10)
## display.writeString("Medium", Font_7x10, true)
## 
## display.setFont(Font_16x26)
## display.writeString("Large", Font_16x26, true)
## ```
##
## **Note:** These fonts are migrated from the stm32-ssd1306 library by afiskon.

import ../nimphea
import ../nimphea_macros

useNimpheaModules(oled_fonts)

{.push header: "util/oled_fonts.h".}

type
  FontDef* {.importcpp: "FontDef".} = object
    ## Font definition structure
    ## 
    ## Contains font metrics and bitmap data for rendering text on displays.
    FontWidth*: uint8     ## Font width in pixels
    FontHeight*: uint8    ## Font height in pixels
    data*: ptr uint16     ## Pointer to font bitmap data array

{.pop.}

# Font data declarations
var Font_4x6* {.importcpp: "Font_4x6", header: "util/oled_fonts.h".}: FontDef
  ## Tiny 4x6 pixel font
  ## 
  ## Best for: Very dense information display, small screens
  ## Character size: 4 pixels wide x 6 pixels tall

var Font_4x8* {.importcpp: "Font_4x8", header: "util/oled_fonts.h".}: FontDef
  ## Small 4x8 pixel font
  ## 
  ## Best for: Compact display with better readability than 4x6
  ## Character size: 4 pixels wide x 8 pixels tall

var Font_5x8* {.importcpp: "Font_5x8", header: "util/oled_fonts.h".}: FontDef
  ## Small 5x8 pixel font
  ## 
  ## Best for: Default small font with good clarity
  ## Character size: 5 pixels wide x 8 pixels tall

var Font_6x7* {.importcpp: "Font_6x7", header: "util/oled_fonts.h".}: FontDef
  ## Medium-small 6x7 pixel font
  ## 
  ## Best for: Balanced size and readability
  ## Character size: 6 pixels wide x 7 pixels tall

var Font_6x8* {.importcpp: "Font_6x8", header: "util/oled_fonts.h".}: FontDef
  ## Medium 6x8 pixel font
  ## 
  ## Best for: General purpose text display
  ## Character size: 6 pixels wide x 8 pixels tall

var Font_7x10* {.importcpp: "Font_7x10", header: "util/oled_fonts.h".}: FontDef
  ## Medium 7x10 pixel font
  ## 
  ## Best for: Comfortable reading on small displays
  ## Character size: 7 pixels wide x 10 pixels tall

var Font_11x18* {.importcpp: "Font_11x18", header: "util/oled_fonts.h".}: FontDef
  ## Large 11x18 pixel font
  ## 
  ## Best for: Headings, important values
  ## Character size: 11 pixels wide x 18 pixels tall

var Font_16x26* {.importcpp: "Font_16x26", header: "util/oled_fonts.h".}: FontDef
  ## Extra large 16x26 pixel font
  ## 
  ## Best for: Large displays, prominent text
  ## Character size: 16 pixels wide x 26 pixels tall
