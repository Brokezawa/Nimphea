## Display Common Graphics Primitives
## ===================================
##
## This module wraps libDaisy's common display graphics primitives and abstractions.
## It provides the base interfaces and types used by all display drivers.
##
## **Features:**
## - `Rectangle` - Geometric rectangle with rich manipulation API
## - `Alignment` - Text and graphics alignment options
## - `OneBitGraphicsDisplay` - Base interface for monochrome displays
##
## **Wrapped Headers:**
## - `hid/disp/graphics_common.h` - Rectangle and Alignment
## - `hid/disp/display.h` - OneBitGraphicsDisplay interface
##
## Example - Using Rectangle:
## ```nim
## import hid/disp/graphics_common
## 
## var rect = initRectangle(10, 20, 100, 50)  # x=10, y=20, w=100, h=50
## echo rect.getCenterX()  # 60
## echo rect.getCenterY()  # 45
## 
## # Fluent API for transformations
## var centered = rect.withCenter(64, 32)
## var reduced = rect.reduced(5)  # Shrink by 5px on all sides
## ```
##
## Example - Alignment enum:
## ```nim
## import hid/disp/graphics_common
## 
## var align = Alignment.topLeft
## # Use for text rendering, UI layouts, etc.
## ```

import nimphea
import nimphea_macros

useNimpheaModules(oled)  # Display common types are part of OLED module
useNimpheaModules(oled_fonts)  # For Font type

{.push header: "hid/disp/graphics_common.h".}

## Alignment/Justification options for text and graphics
type
  Alignment* {.importcpp: "daisy::Alignment", size: sizeof(cint).} = enum
    ## Centered in both X and Y
    centered
    ## Top-left corner
    topLeft
    ## Top edge, centered horizontally
    topCentered
    ## Top-right corner
    topRight
    ## Bottom-left corner
    bottomLeft
    ## Bottom edge, centered horizontally
    bottomCentered
    ## Bottom-right corner
    bottomRight
    ## Left edge, centered vertically
    centeredLeft
    ## Right edge, centered vertically
    centeredRight

## Geometric rectangle with rich manipulation API
type
  Rectangle* {.importcpp: "daisy::Rectangle", header: "hid/disp/graphics_common.h".} = object
    ## A rectangle defined by x, y, width, and height.
    ## Provides immutable transformations (methods return new Rectangle instances).

{.pop.}

# Constructors
proc initRectangle*(): Rectangle {.importcpp: "daisy::Rectangle()".}
  ## Create empty rectangle at (0, 0) with size (0, 0)

proc initRectangle*(width, height: int16): Rectangle 
  {.importcpp: "daisy::Rectangle(@)".}
  ## Create rectangle at (0, 0) with given size

proc initRectangle*(x, y, width, height: int16): Rectangle 
  {.importcpp: "daisy::Rectangle(@)".}
  ## Create rectangle at (x, y) with given size

# Getters
proc getX*(this: Rectangle): int16 {.importcpp: "#.GetX()".}
  ## Get X coordinate

proc getY*(this: Rectangle): int16 {.importcpp: "#.GetY()".}
  ## Get Y coordinate

proc getWidth*(this: Rectangle): int16 {.importcpp: "#.GetWidth()".}
  ## Get width

proc getHeight*(this: Rectangle): int16 {.importcpp: "#.GetHeight()".}
  ## Get height

proc getRight*(this: Rectangle): int16 {.importcpp: "#.GetRight()".}
  ## Get right edge (x + width)

proc getBottom*(this: Rectangle): int16 {.importcpp: "#.GetBottom()".}
  ## Get bottom edge (y + height)

proc getCenterX*(this: Rectangle): int16 {.importcpp: "#.GetCenterX()".}
  ## Get center X coordinate

proc getCenterY*(this: Rectangle): int16 {.importcpp: "#.GetCenterY()".}
  ## Get center Y coordinate

proc isEmpty*(this: Rectangle): bool {.importcpp: "#.IsEmpty()".}
  ## Returns true if width or height is <= 0

# Immutable transformations (return new Rectangle)
proc withX*(this: Rectangle, x: int16): Rectangle {.importcpp: "#.WithX(#)".}
  ## Return new rectangle with different X coordinate

proc withY*(this: Rectangle, y: int16): Rectangle {.importcpp: "#.WithY(#)".}
  ## Return new rectangle with different Y coordinate

proc withWidth*(this: Rectangle, width: int16): Rectangle {.importcpp: "#.WithWidth(#)".}
  ## Return new rectangle with different width

proc withHeight*(this: Rectangle, height: int16): Rectangle {.importcpp: "#.WithHeight(#)".}
  ## Return new rectangle with different height

proc withSize*(this: Rectangle, width, height: int16): Rectangle 
  {.importcpp: "#.WithSize(#, #)".}
  ## Return new rectangle with different size

proc withCenter*(this: Rectangle, centerX, centerY: int16): Rectangle 
  {.importcpp: "#.WithCenter(#, #)".}
  ## Return new rectangle centered at given point

proc withCenterX*(this: Rectangle, centerX: int16): Rectangle 
  {.importcpp: "#.WithCenterX(#)".}
  ## Return new rectangle with different center X

proc withCenterY*(this: Rectangle, centerY: int16): Rectangle 
  {.importcpp: "#.WithCenterY(#)".}
  ## Return new rectangle with different center Y

proc reduced*(this: Rectangle, sizeToReduce: int16): Rectangle 
  {.importcpp: "#.Reduced(#)".}
  ## Return new rectangle reduced by given amount on all sides

proc reduced*(this: Rectangle, xToReduce, yToReduce: int16): Rectangle 
  {.importcpp: "#.Reduced(#, #)".}
  ## Return new rectangle reduced by different amounts in X and Y

proc translated*(this: Rectangle, x, y: int16): Rectangle 
  {.importcpp: "#.Translated(#, #)".}
  ## Return new rectangle moved by given offset

proc withLeft*(this: Rectangle, left: int16): Rectangle 
  {.importcpp: "#.WithLeft(#)".}
  ## Return new rectangle with different left edge

proc withRight*(this: Rectangle, right: int16): Rectangle 
  {.importcpp: "#.WithRight(#)".}
  ## Return new rectangle with different right edge

proc withTop*(this: Rectangle, top: int16): Rectangle 
  {.importcpp: "#.WithTop(#)".}
  ## Return new rectangle with different top edge

proc withBottom*(this: Rectangle, bottom: int16): Rectangle 
  {.importcpp: "#.WithBottom(#)".}
  ## Return new rectangle with different bottom edge

proc withTrimmedLeft*(this: Rectangle, pxToTrim: int16): Rectangle 
  {.importcpp: "#.WithTrimmedLeft(#)".}
  ## Return new rectangle with left edge moved inward

proc withTrimmedRight*(this: Rectangle, pxToTrim: int16): Rectangle 
  {.importcpp: "#.WithTrimmedRight(#)".}
  ## Return new rectangle with right edge moved inward

proc withTrimmedTop*(this: Rectangle, pxToTrim: int16): Rectangle 
  {.importcpp: "#.WithTrimmedTop(#)".}
  ## Return new rectangle with top edge moved downward

proc withTrimmedBottom*(this: Rectangle, pxToTrim: int16): Rectangle 
  {.importcpp: "#.WithTrimmedBottom(#)".}
  ## Return new rectangle with bottom edge moved upward

proc withWidthKeepingCenter*(this: Rectangle, width: int16): Rectangle 
  {.importcpp: "#.WithWidthKeepingCenter(#)".}
  ## Return new rectangle with different width, keeping center position

proc withHeightKeepingCenter*(this: Rectangle, height: int16): Rectangle 
  {.importcpp: "#.WithHeightKeepingCenter(#)".}
  ## Return new rectangle with different height, keeping center position

proc withSizeKeepingCenter*(this: Rectangle, width, height: int16): Rectangle 
  {.importcpp: "#.WithSizeKeepingCenter(#, #)".}
  ## Return new rectangle with different size, keeping center position

# Mutable removal operations (modify this rectangle and return removed part)
proc removeFromLeft*(this: var Rectangle, pxToRemove: int16): Rectangle 
  {.importcpp: "#.RemoveFromLeft(#)".}
  ## Remove pixels from left side, return removed Rectangle

proc removeFromRight*(this: var Rectangle, pxToRemove: int16): Rectangle 
  {.importcpp: "#.RemoveFromRight(#)".}
  ## Remove pixels from right side, return removed Rectangle

proc removeFromTop*(this: var Rectangle, pxToRemove: int16): Rectangle 
  {.importcpp: "#.RemoveFromTop(#)".}
  ## Remove pixels from top side, return removed Rectangle

proc removeFromBottom*(this: var Rectangle, pxToRemove: int16): Rectangle 
  {.importcpp: "#.RemoveFromBottom(#)".}
  ## Remove pixels from bottom side, return removed Rectangle

# OneBitGraphicsDisplay interface (base class for monochrome displays)
{.push header: "hid/disp/display.h".}

# Font type (from util/oled_fonts.h)
type
  FontDef* {.importcpp: "FontDef", header: "util/oled_fonts.h".} = object
    ## Font definition structure
    fontData*: ptr uint8
    fontWidth*: uint8
    fontHeight*: uint8
    
type Font* = ptr FontDef  ## Alias for font pointer

type
  OneBitGraphicsDisplay* {.importcpp: "daisy::OneBitGraphicsDisplay".} = object
    ## Base interface for 1-bit-per-pixel graphics displays (monochrome).
    ## All monochrome OLED drivers inherit from this.

{.pop.}

# Virtual methods - these are abstract in C++, must be implemented by subclasses
proc height*(this: OneBitGraphicsDisplay): uint16 
  {.importcpp: "#.Height()".}
  ## Get display height in pixels

proc width*(this: OneBitGraphicsDisplay): uint16 
  {.importcpp: "#.Width()".}
  ## Get display width in pixels

proc getBounds*(this: OneBitGraphicsDisplay): Rectangle 
  {.importcpp: "#.GetBounds()".}
  ## Get display bounds as Rectangle

proc currentX*(this: var OneBitGraphicsDisplay): csize_t 
  {.importcpp: "#.CurrentX()".}
  ## Get current cursor X position

proc currentY*(this: var OneBitGraphicsDisplay): csize_t 
  {.importcpp: "#.CurrentY()".}
  ## Get current cursor Y position

proc fill*(this: var OneBitGraphicsDisplay, on: bool) 
  {.importcpp: "#.Fill(#)".}
  ## Fill entire display with on (true) or off (false)

proc drawPixel*(this: var OneBitGraphicsDisplay, x, y: uint8, on: bool) 
  {.importcpp: "#.DrawPixel(#, #, #)".}
  ## Draw single pixel at (x, y)

proc drawLine*(this: var OneBitGraphicsDisplay, x1, y1, x2, y2: uint8, on: bool) 
  {.importcpp: "#.DrawLine(#, #, #, #, #)".}
  ## Draw line from (x1, y1) to (x2, y2)

proc drawRect*(this: var OneBitGraphicsDisplay, x1, y1, x2, y2: uint8, on: bool, fill = false) 
  {.importcpp: "#.DrawRect(#, #, #, #, #, #)".}
  ## Draw rectangle from (x1, y1) to (x2, y2), optionally filled

proc drawCircle*(this: var OneBitGraphicsDisplay, x, y, r: uint8, on: bool) 
  {.importcpp: "#.DrawCircle(#, #, #, #)".}
  ## Draw circle centered at (x, y) with radius r

proc drawArc*(this: var OneBitGraphicsDisplay, x, y, radius: uint8, 
              startAngle, sweep: int16, on: bool) 
  {.importcpp: "#.DrawArc(#, #, #, #, #, #)".}
  ## Draw arc centered at (x, y) from startAngle through sweep degrees

proc writeChar*(this: var OneBitGraphicsDisplay, ch: char, font: Font, on: bool): uint16 
  {.importcpp: "#.WriteChar(#, #, #)".}
  ## Write single character at cursor position, advance cursor

proc writeString*(this: var OneBitGraphicsDisplay, str: cstring, font: Font, on: bool): uint16 
  {.importcpp: "#.WriteString(#, #, #)".}
  ## Write string at cursor position, advance cursor

proc writeStringAligned*(this: var OneBitGraphicsDisplay, str: cstring, font: Font, 
                        bounds: Rectangle, alignment: Alignment, on: bool): uint16 
  {.importcpp: "#.WriteStringAligned(#, #, #, #, #)".}
  ## Write string aligned within bounds rectangle

proc setCursor*(this: var OneBitGraphicsDisplay, x, y: uint8) 
  {.importcpp: "#.SetCursor(#, #)".}
  ## Set text cursor position

proc update*(this: var OneBitGraphicsDisplay) 
  {.importcpp: "#.Update()".}
  ## Update display (flush framebuffer to hardware)
