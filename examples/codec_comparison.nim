## Codec Comparison Example
## ========================
##
## Demonstrates initialization of all three audio codecs supported by Nimphea.
## The actual codec used depends on the Daisy Seed hardware version:
## - Daisy Seed 1.0: AK4556 (simple reset-based codec)
## - Daisy Seed 1.1: WM8731 (I2C-controlled codec)
## - Daisy Seed 2.0: PCM3060 (high-performance codec)
##
## This example shows how to detect and initialize the appropriate codec
## for your hardware version.

import ../src/nimphea
import ../src/per/i2c as i2c_module
import ../src/dev/codec_ak4556
import ../src/dev/codec_wm8731
import ../src/dev/codec_pcm3060

useNimpheaNamespace()

var seed: DaisySeed
var hwVersion: BoardVersion

# Codec instances
var ak4556Codec: Ak4556
var wm8731Codec: Wm8731
var pcm3060Codec: Pcm3060

# I2C for WM8731 and PCM3060
var i2c: I2CHandle

proc initCodecForHardware() =
  ## Initialize the appropriate codec based on hardware version
  hwVersion = seed.boardVersion()
  
  case hwVersion
  of BOARD_DAISY_SEED:
    # Daisy Seed 1.0 - AK4556 codec (reset pin only)
    echo "Detected Daisy Seed 1.0 - Initializing AK4556 codec"
    ak4556Codec.init(getPin(0))  # Reset pin
    echo "AK4556 codec initialized"
    
  of BOARD_DAISY_SEED_1_1:
    # Daisy Seed 1.1 - WM8731 codec (I2C control)
    echo "Detected Daisy Seed 1.1 - Initializing WM8731 codec"
    
    # Initialize I2C
    i2c = initI2C(I2C_1, getPin(11), getPin(12), I2C_400KHZ)
    
    # Initialize codec with default settings
    var codecCfg: Wm8731Config
    codecCfg.defaults()  # MCU is master, 24-bit, MSB LJ
    
    let result = wm8731Codec.init(codecCfg, i2c)
    if result == Wm8731Result.OK:
      echo "WM8731 codec initialized successfully"
    else:
      echo "WM8731 codec initialization failed!"
      
  of BOARD_DAISY_SEED_2_DFM:
    # Daisy Seed 2.0 - PCM3060 codec (I2C control)
    echo "Detected Daisy Seed 2.0 - Initializing PCM3060 codec"
    
    # Initialize I2C
    i2c = initI2C(I2C_1, getPin(11), getPin(12), I2C_400KHZ)
    
    let result = pcm3060Codec.init(i2c)
    if result == Pcm3060Result.OK:
      echo "PCM3060 codec initialized successfully"
    else:
      echo "PCM3060 codec initialization failed!"

proc main() =
  # Initialize Daisy Seed hardware
  seed.init()
  
  # Initialize appropriate codec for this hardware
  initCodecForHardware()
  
  # Blink LED to indicate successful initialization
  while true:
    seed.setLed(true)
    seed.delay(500)
    seed.setLed(false)
    seed.delay(500)

# Entry point
when isMainModule:
  main()
