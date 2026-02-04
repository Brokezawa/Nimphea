## Display Concepts
## =================
##
## Nim-friendly display abstraction layer providing concepts and generic
## programming patterns for working with displays.
##
## This module provides higher-level abstractions over the low-level
## display drivers (SH1106, SSD1327, SSD1351).

type
  DisplayConcept* = concept d
    ## Generic display concept - any type that implements these methods
    ## can be used with generic display functions
    d.fill(bool)           ## Fill display with color
    d.update()             ## Send buffer to hardware
    d.width() is int       ## Get display width
    d.height() is int      ## Get display height

# Helper templates for working with displays

template withDisplay*(display: var auto, body: untyped) =
  ## Execute drawing operations and automatically update display
  ## 
  ## **Example**:
  ## ```nim
  ## display.withDisplay:
  ##   display.fill(false)
  ##   display.drawRect(10, 10, 50, 20, true)
  ## # display.update() called automatically
  ## ```
  body
  display.update()

template clearAndDraw*(display: var auto, body: untyped) =
  ## Clear display and execute drawing operations
  ## 
  ## **Example**:
  ## ```nim
  ## display.clearAndDraw:
  ##   display.drawCircle(64, 32, 20, true)
  ## ```
  display.fill(false)
  body
  display.update()

# Generic display utilities

proc drawCenteredText*(display: var auto, y: int, text: string) =
  ## Draw text centered horizontally (placeholder - text rendering TBD)
  ## This is a template for future text rendering support
  discard

proc drawProgressBar*(display: var auto, x, y, width, height: int, progress: float) =
  ## Draw a progress bar (0.0 to 1.0)
  let fillWidth = int(float(width) * progress.clamp(0.0, 1.0))
  display.drawRect(x, y, width, height, true)
  if fillWidth > 0:
    display.fillRect(x, y, fillWidth, height, true)

template measureTime*(display: var auto, label: static string, body: untyped) =
  ## Measure execution time and display on screen (debug helper)
  ## Note: Requires text rendering support
  let startTime = getTime()  # Would need actual timer
  body
  let elapsed = getTime() - startTime
  # Display timing info (TBD with text support)
