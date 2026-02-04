## VU Meter Example - DotStar Audio Visualizer
##
## Audio-reactive LED VU meter using DotStar RGB LED strip.
## Displays stereo audio levels with color gradient.
##
## **Thread Safety Note:**
## This example demonstrates proper thread-safe communication between
## the audio callback (ISR context) and main loop (normal context).
## - Audio callback writes to peakCallback[] only
## - Main loop reads peakCallback[], writes to peakDisplay[] only
## - Uses atomic bool flag to signal new data availability

import panicoverride
import ../src/nimphea
import ../src/per/spi
import ../src/dev/dotstar

useNimpheaNamespace()

const NUM_LEDS = 16

var
  hw: DaisySeed
  leds: DotStarSpi
  
  # Thread-safe peak detection using double buffering
  # Audio callback writes to peakCallback, main loop reads from peakDisplay
  peakCallback: array[2, float32] = [0.0, 0.0]  # Written by audio callback (ISR context)
  peakDisplay: array[2, float32] = [0.0, 0.0]   # Read by main loop (normal context)
  peakReady: bool = false  # Atomic flag (bool is atomic on ARM)

proc audioCallback(input_buffer, output_buffer: AudioBuffer, size: int) {.cdecl.} =
  ## Audio callback - detect peaks
  ## Thread-safe: Only writes to peakCallback[], never reads peakDisplay[]
  for i in 0..<size:
    let absL = abs(input_buffer[0][i])
    let absR = abs(input_buffer[1][i])
    
    # Update peak levels (audio callback writes only)
    if absL > peakCallback[0]: peakCallback[0] = absL
    if absR > peakCallback[1]: peakCallback[1] = absR
    
    # Pass through audio
    output_buffer[0][i] = input_buffer[0][i]
    output_buffer[1][i] = input_buffer[1][i]
  
  # Signal that new peaks are ready (set after all writes complete)
  peakReady = true

hw.init()

var config: DotStarConfig
config.defaults()
config.num_pixels = NUM_LEDS
config.color_order = GRB

discard leds.init(config)
leds.setAllGlobalBrightness(5)  # Keep brightness low to avoid overheating

hw.startAudio(audioCallback)

while true:
  # Thread-safe peak reading: Copy callback values to display buffer
  # This is atomic on ARM (array copy = 2x 32-bit word copies)
  if peakReady:
    peakDisplay[0] = peakCallback[0]
    peakDisplay[1] = peakCallback[1]
    peakCallback[0] = 0.0  # Reset for next measurement
    peakCallback[1] = 0.0
    peakReady = false
  
  # Apply decay to display values (only touches peakDisplay, never peakCallback)
  peakDisplay[0] *= 0.95
  peakDisplay[1] *= 0.95
  
  # Calculate VU levels (0-8 LEDs per channel)
  let
    levelL = (peakDisplay[0] * 8.0).int.clamp(0, 8)
    levelR = (peakDisplay[1] * 8.0).int.clamp(0, 8)
  
  # Clear all
  leds.clear()
  
  # Left channel (LEDs 0-7) - Green to Red gradient
  for i in 0 ..< levelL:
    let
      green = (255 * (8 - i) div 8).uint8
      red = (255 * i div 8).uint8
    discard leds.setPixelColor(i.uint16, red, green, 0)
  
  # Right channel (LEDs 8-15) - Blue to Red gradient  
  for i in 0 ..< levelR:
    let
      blue = (255 * (8 - i) div 8).uint8
      red = (255 * i div 8).uint8
    discard leds.setPixelColor((i + 8).uint16, red, 0, blue)
  
  discard leds.show()
  hw.delay(20)  # 50 Hz update rate
