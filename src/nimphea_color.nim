## Color Utilities
## ===============
##
## Simple color handling for RGB LEDs and displays.
##
## The Color class provides:
## - RGB color representation (0.0 to 1.0 floats)
## - Preset colors (RED, GREEN, BLUE, WHITE, PURPLE, CYAN, GOLD, OFF)
## - 8-bit RGB values (0-255)
## - Color blending and scaling
## - Arithmetic operations (+, *)
##
## **Usage:**
## ```nim
## import nimphea_color
##
## # Create from preset
## var red = Color()
## red.init(COLOR_RED)
##
## # Create from RGB values (0.0 to 1.0)
## var purple = Color()
## purple.init(0.5, 0.0, 0.5)
##
## # Direct construction
## var cyan = createColor(0.0, 1.0, 1.0)
##
## # Get values
## let r = red.red()      # 0.0 to 1.0
## let r8 = red.red8()    # 0 to 255
##
## # Modify
## purple.setRed(0.8)
##
## # Blend two colors
## var blended = colorBlend(red, purple, 0.5)  # 50% mix
##
## # Scale brightness
## var dimRed = red * 0.5  # 50% brightness
##
## # Add colors
## var combined = red + purple
## ```

import nimphea_macros

useNimpheaModules(color)

type
  PresetColor* {.importcpp: "daisy::Color::PresetColor",
                 header: "util/color.h".} = enum
    ## Preset color values
    COLOR_RED = 0     ## Pure red (1.0, 0.0, 0.0)
    COLOR_GREEN       ## Pure green (0.0, 1.0, 0.0)
    COLOR_BLUE        ## Pure blue (0.0, 0.0, 1.0)
    COLOR_WHITE       ## White (1.0, 1.0, 1.0)
    COLOR_PURPLE      ## Purple (0.5, 0.0, 0.5)
    COLOR_CYAN        ## Cyan (0.0, 1.0, 1.0)
    COLOR_GOLD        ## Gold/yellow (1.0, 0.84, 0.0)
    COLOR_OFF         ## Off/black (0.0, 0.0, 0.0)

  Color* {.importcpp: "daisy::Color",
           header: "util/color.h", bycopy.} = object
    ## RGB color representation
    ##
    ## Stores RGB values as floats from 0.0 to 1.0

# Constructors
proc createColor*(): Color {.importcpp: "daisy::Color()".} =
  ## Create a color initialized to black (0, 0, 0)
  discard

proc createColor*(r, g, b: cfloat): Color {.importcpp: "daisy::Color(#, #, #)".} =
  ## Create a color with specific RGB values
  ##
  ## **Parameters:**
  ## - `r` - Red component (0.0 to 1.0)
  ## - `g` - Green component (0.0 to 1.0)
  ## - `b` - Blue component (0.0 to 1.0)
  ##
  ## **Example:**
  ## ```nim
  ## let purple = createColor(0.5, 0.0, 0.5)
  ## let white = createColor(1.0, 1.0, 1.0)
  ## ```
  discard

# Initialization methods
proc init*(this: var Color, preset: PresetColor)
  {.importcpp: "#.Init(#)".} =
  ## Initialize color with a preset value
  ##
  ## **Parameters:**
  ## - `preset` - One of the PresetColor enum values
  ##
  ## **Example:**
  ## ```nim
  ## var color = createColor()
  ## color.init(COLOR_RED)
  ## ```
  discard

proc init*(this: var Color, r, g, b: cfloat)
  {.importcpp: "#.Init(#, #, #)".} =
  ## Initialize color with specific RGB values
  ##
  ## **Parameters:**
  ## - `r` - Red component (0.0 to 1.0)
  ## - `g` - Green component (0.0 to 1.0)
  ## - `b` - Blue component (0.0 to 1.0)
  ##
  ## **Example:**
  ## ```nim
  ## var color = createColor()
  ## color.init(0.8, 0.2, 0.5)
  ## ```
  discard

# Getters - Float (0.0 to 1.0)
proc red*(this: Color): cfloat {.importcpp: "#.Red()".} =
  ## Get red component as float
  ##
  ## **Returns:** Red value (0.0 to 1.0)
  discard

proc green*(this: Color): cfloat {.importcpp: "#.Green()".} =
  ## Get green component as float
  ##
  ## **Returns:** Green value (0.0 to 1.0)
  discard

proc blue*(this: Color): cfloat {.importcpp: "#.Blue()".} =
  ## Get blue component as float
  ##
  ## **Returns:** Blue value (0.0 to 1.0)
  discard

# Getters - 8-bit (0 to 255)
proc red8*(this: Color): uint8 {.importcpp: "#.Red8()".} =
  ## Get red component as 8-bit value
  ##
  ## **Returns:** Red value (0 to 255)
  ##
  ## **Example:**
  ## ```nim
  ## let r8 = color.red8()  # For setting LED PWM duty cycle
  ## ```
  discard

proc green8*(this: Color): uint8 {.importcpp: "#.Green8()".} =
  ## Get green component as 8-bit value
  ##
  ## **Returns:** Green value (0 to 255)
  discard

proc blue8*(this: Color): uint8 {.importcpp: "#.Blue8()".} =
  ## Get blue component as 8-bit value
  ##
  ## **Returns:** Blue value (0 to 255)
  discard

# Setters
proc setRed*(this: var Color, amt: cfloat) {.importcpp: "#.SetRed(#)".} =
  ## Set red component
  ##
  ## **Parameters:**
  ## - `amt` - Red value (0.0 to 1.0)
  discard

proc setGreen*(this: var Color, amt: cfloat) {.importcpp: "#.SetGreen(#)".} =
  ## Set green component
  ##
  ## **Parameters:**
  ## - `amt` - Green value (0.0 to 1.0)
  discard

proc setBlue*(this: var Color, amt: cfloat) {.importcpp: "#.SetBlue(#)".} =
  ## Set blue component
  ##
  ## **Parameters:**
  ## - `amt` - Blue value (0.0 to 1.0)
  discard

# Operators
proc `*`*(this: Color, scale: cfloat): Color {.importcpp: "(# * #)".} =
  ## Scale color brightness
  ##
  ## **Parameters:**
  ## - `scale` - Scaling factor (typically 0.0 to 1.0, but can be > 1.0)
  ##
  ## **Returns:** New scaled color
  ##
  ## **Example:**
  ## ```nim
  ## var bright = createColor(1.0, 0.0, 0.0)  # Bright red
  ## var dim = bright * 0.5                    # Dim red (50%)
  ## var veryDim = bright * 0.1                # Very dim (10%)
  ## ```
  discard

proc `+`*(this: Color, rhs: Color): Color {.importcpp: "(# + #)".} =
  ## Add two colors together (saturating at 1.0)
  ##
  ## **Parameters:**
  ## - `rhs` - Color to add
  ##
  ## **Returns:** New combined color (components clamped to 1.0)
  ##
  ## **Example:**
  ## ```nim
  ## var red = createColor(1.0, 0.0, 0.0)
  ## var green = createColor(0.0, 1.0, 0.0)
  ## var yellow = red + green  # (1.0, 1.0, 0.0)
  ## ```
  discard

# Static methods
proc colorBlend*(a, b: Color, amt: cfloat): Color 
  {.importcpp: "daisy::Color::Blend(#, #, #)".} =
  ## Blend between two colors
  ##
  ## **Parameters:**
  ## - `a` - First color
  ## - `b` - Second color
  ## - `amt` - Blend amount (0.0 = all A, 1.0 = all B, 0.5 = 50/50 mix)
  ##
  ## **Returns:** Blended color
  ##
  ## **Example:**
  ## ```nim
  ## var red = createColor(1.0, 0.0, 0.0)
  ## var blue = createColor(0.0, 0.0, 1.0)
  ## 
  ## var purple = colorBlend(red, blue, 0.5)    # 50/50 purple
  ## var reddish = colorBlend(red, blue, 0.25)  # More red
  ## var blueish = colorBlend(red, blue, 0.75)  # More blue
  ## 
  ## # Animate between colors
  ## for i in 0..100:
  ##   let t = i.float / 100.0
  ##   let color = colorBlend(red, blue, t)
  ##   # Set LED to color
  ## ```
  discard

# Helper templates for common operations
template dimColor*(c: Color, brightness: cfloat): Color =
  ## Dim a color by a percentage
  ##
  ## **Parameters:**
  ## - `c` - Color to dim
  ## - `brightness` - Brightness level (0.0 = off, 1.0 = full)
  c * brightness

template mixColors*(c1, c2: Color): Color =
  ## Mix two colors equally (50/50)
  colorBlend(c1, c2, 0.5)
