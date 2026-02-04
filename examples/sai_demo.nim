## SAI (Serial Audio Interface) Demonstration
##
## Demonstrates low-level SAI peripheral usage for custom audio configurations.
## SAI provides I2S communication with external audio codecs.
##
## **Note**: For most applications, use the high-level audio API in libdaisy.nim.
## This example is for advanced use cases requiring custom SAI configurations.
##
## Hardware:
## - Daisy Seed (or other Daisy board)
## - Audio codec (AK4556, WM8731, PCM3060, etc.)
##
## Features demonstrated:
## - SAI peripheral initialization
## - Custom sample rate and bit depth configuration
## - DMA-based audio transfer
## - Audio callback implementation
## - Standard configuration helpers
##
## Compile-time modes (use -d:mode=<mode>):
## - standard: Standard 48kHz 24-bit passthrough (default)
## - hires: High-resolution 96kHz 32-bit audio
## - lofi: Low-resolution 8kHz 16-bit audio
## - custom: Custom pin configuration example

import nimphea
import nimphea_sai

useNimpheaNamespace()

const MODE = 
  when defined(hires): "hires"
  elif defined(lofi): "lofi"
  elif defined(custom): "custom"
  else: "standard"

# DMA buffer sizes (must be in DMA-capable memory)
const BUFFER_SIZE = 256  # 128 samples per callback (stereo = 256 total)

# Declare buffers in DMA memory section
# In actual hardware, use: var rxBuffer {.codegenDecl: "int32_t DSY_DMA_BUFFER_SECTOR $#[$#]".}: array[BUFFER_SIZE, int32]
var rxBuffer: array[BUFFER_SIZE, int32]
var txBuffer: array[BUFFER_SIZE, int32]

when MODE == "standard":
  # ==========================================================================
  # Mode 1: Standard 48kHz 24-bit Configuration
  # ==========================================================================
  ## Demonstrates the most common SAI configuration using helper functions
  
  proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
    ## Simple audio passthrough
    ## Processes size samples (size/2 per channel for stereo)
    for i in 0..<size.int:
      cast[ptr UncheckedArray[int32]](outputBuf)[i] = cast[ptr UncheckedArray[int32]](inputBuf)[i]
  
  proc main() =
    var daisy = initDaisy()
    var sai: SaiHandle
    var config = newSaiConfig()
    
    # Use helper to configure standard 48kHz 24-bit
    config.configureStandard48k24bit(SAI_1)
    
    # Configure pins using standard layout on PORT E
    config.configurePinsStandard(PORTE)
    
    # Initialize SAI
    let result = sai.init(config)
    if result != SAI_OK:
      # Error: blink LED rapidly
      while true:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
    
    # Start audio processing
    discard sai.startDma(rxBuffer[0].addr, txBuffer[0].addr, BUFFER_SIZE, audioCallback)
    
    # Get and display audio info (would need serial output)
    let sampleRate = sai.getSampleRate()
    let blockSize = sai.getBlockSize()
    let blockRate = sai.getBlockRate()
    
    # Main loop - blink LED to show running
    var counter = 0
    while true:
      if counter mod 1000 == 0:
        daisy.setLed(true)
      elif counter mod 1000 == 100:
        daisy.setLed(false)
      
      inc counter
      daisy.delay(1)

elif MODE == "hires":
  # ==========================================================================
  # Mode 2: High-Resolution 96kHz 32-bit Audio
  # ==========================================================================
  ## Demonstrates high-resolution audio configuration
  
  proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
    ## High-resolution audio passthrough
    for i in 0..<size.int:
      cast[ptr UncheckedArray[int32]](outputBuf)[i] = cast[ptr UncheckedArray[int32]](inputBuf)[i]
  
  proc main() =
    var daisy = initDaisy()
    var sai: SaiHandle
    var config = newSaiConfig()
    
    # High-resolution configuration
    config.periph = SAI_1
    config.sr = SAI_96KHZ       # 96kHz sample rate
    config.bit_depth = SAI_32BIT # 32-bit depth for maximum quality
    config.a_sync = MASTER
    config.b_sync = SLAVE
    config.a_dir = RECEIVE
    config.b_dir = TRANSMIT
    
    # Configure pins
    config.configurePinsStandard(PORTE)
    
    # Initialize and start
    let result = sai.init(config)
    if result != SAI_OK:
      while true:
        daisy.setLed(true)
        daisy.delay(50)
        daisy.setLed(false)
        daisy.delay(50)
    
    discard sai.startDma(rxBuffer[0].addr, txBuffer[0].addr, BUFFER_SIZE, audioCallback)
    
    # Main loop
    while true:
      daisy.delay(10)

elif MODE == "lofi":
  # ==========================================================================
  # Mode 3: Lo-Fi 8kHz 16-bit Audio
  # ==========================================================================
  ## Demonstrates low-resolution audio (retro/lo-fi effects)
  
  proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
    ## Lo-fi audio passthrough with bit reduction
    for i in 0..<size.int:
      # In 16-bit mode, only upper 16 bits are used
      # Could add additional lo-fi effects here
      cast[ptr UncheckedArray[int32]](outputBuf)[i] = cast[ptr UncheckedArray[int32]](inputBuf)[i]
  
  proc main() =
    var daisy = initDaisy()
    var sai: SaiHandle
    var config = newSaiConfig()
    
    # Lo-fi configuration
    config.periph = SAI_1
    config.sr = SAI_8KHZ        # 8kHz for lo-fi sound
    config.bit_depth = SAI_16BIT # 16-bit depth
    config.a_sync = MASTER
    config.b_sync = SLAVE
    config.a_dir = RECEIVE
    config.b_dir = TRANSMIT
    
    # Configure pins
    config.configurePinsStandard(PORTE)
    
    # Initialize and start
    let result = sai.init(config)
    if result != SAI_OK:
      while true:
        daisy.setLed(true)
        daisy.delay(25)
        daisy.setLed(false)
        daisy.delay(25)
    
    discard sai.startDma(rxBuffer[0].addr, txBuffer[0].addr, BUFFER_SIZE, audioCallback)
    
    # Main loop - fast blink for lo-fi mode
    var counter = 0
    while true:
      if counter mod 100 == 0:
        daisy.setLed(true)
      elif counter mod 100 == 10:
        daisy.setLed(false)
      
      inc counter
      daisy.delay(1)

elif MODE == "custom":
  # ==========================================================================
  # Mode 4: Custom Pin Configuration
  # ==========================================================================
  ## Demonstrates custom pin mapping for non-standard hardware
  
  proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
    ## Audio processing with custom pins
    for i in 0..<size.int:
      cast[ptr UncheckedArray[int32]](outputBuf)[i] = cast[ptr UncheckedArray[int32]](inputBuf)[i]
  
  proc main() =
    var daisy = initDaisy()
    var sai: SaiHandle
    var config = newSaiConfig()
    
    # Custom configuration
    config.periph = SAI_1
    config.sr = SAI_48KHZ
    config.bit_depth = SAI_24BIT
    config.a_sync = MASTER
    config.b_sync = SLAVE
    config.a_dir = RECEIVE
    config.b_dir = TRANSMIT
    
    # Custom pin configuration (example for non-standard layout)
    # Adjust these pins based on your hardware design
    config.pin_config.mclk = initPin(PORTE, 2)  # Master clock
    config.pin_config.fs = initPin(PORTE, 4)    # Frame sync (LRCK)
    config.pin_config.sck = initPin(PORTE, 5)   # Serial clock (BCK)
    config.pin_config.sa = initPin(PORTE, 6)    # Serial data A (input)
    config.pin_config.sb = initPin(PORTE, 3)    # Serial data B (output)
    
    # Alternative: Use different GPIO port
    # config.pin_config.mclk = initPin(PORTD, 10)
    # config.pin_config.fs = initPin(PORTD, 11)
    # etc.
    
    # Initialize and start
    let result = sai.init(config)
    if result != SAI_OK:
      while true:
        daisy.setLed(true)
        daisy.delay(200)
        daisy.setLed(false)
        daisy.delay(200)
    
    discard sai.startDma(rxBuffer[0].addr, txBuffer[0].addr, BUFFER_SIZE, audioCallback)
    
    # Query SAI configuration
    let currentConfig = sai.getConfig()
    let sampleRate = sai.getSampleRate()
    let blockSize = sai.getBlockSize()
    let isInit = sai.isInitialized()
    
    # Main loop
    while true:
      daisy.delay(10)

when isMainModule:
  main()
