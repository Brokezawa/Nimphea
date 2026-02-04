## WM8731 Codec
## =============
##
## Nim wrapper for the Cirrus Logic (Wolfson) WM8731 audio codec.
##
## The WM8731 is an I2C-controlled codec used on Daisy Seed 1.1 and provides
## more configuration options than the basic AK4556.
##
## **Features:**
## - 24-bit stereo ADC and DAC
## - I2C control interface
## - Configurable audio format (I2S, LJ, RJ, DSP)
## - Configurable word length (16/20/24/32-bit)
## - Volume control and mute
## - 48kHz sample rate (other rates not yet supported)
##
## **Example:**
## ```nim
## import ../src/nimphea
## import ../src/dev/codec_wm8731
## import ../src/per/i2c
##
## var i2c: I2CHandle
## var codecCfg: Wm8731Config
## var codec: Wm8731
##
## codecCfg.defaults()  # MCU is master, 24-bit, MSB LJ
## let result = codec.init(codecCfg, i2c)
## if result == Wm8731Result.OK:
##   echo "Codec initialized successfully"
## ```

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(codec_wm8731)

{.push header: "dev/codec_wm8731.h".}

type
  Wm8731Result* {.importcpp: "daisy::Wm8731::Result", size: sizeof(cint).} = enum
    ## Return values for WM8731 functions
    OK  ## Operation successful
    ERR ## Operation failed

  Wm8731Format* {.importcpp: "daisy::Wm8731::Config::Format", size: sizeof(cint).} = enum
    ## Communication format options
    MSB_FIRST_RJ = 0x00 ## MSB first, right-justified
    MSB_FIRST_LJ = 0x01 ## MSB first, left-justified (default)
    I2S          = 0x02 ## I2S format
    DSP          = 0x03 ## DSP format

  Wm8731WordLength* {.importcpp: "daisy::Wm8731::Config::WordLength", size: sizeof(cint).} = enum
    ## Sample word length in bits
    ## This is for communication only; the device processes audio at 24-bits
    BITS_16 = (0x00 shl 2) ## 16-bit samples
    BITS_20 = (0x01 shl 2) ## 20-bit samples
    BITS_24 = (0x02 shl 2) ## 24-bit samples (default)
    BITS_32 = (0x03 shl 2) ## 32-bit samples

  Wm8731Config* {.importcpp: "daisy::Wm8731::Config".} = object
    ## Configuration struct for WM8731 initialization
    ## 
    ## For now, only 48kHz is supported. USB Mode is not yet supported.
    mcu_is_master*: bool          ## Set true for MCU master mode
    lr_swap*: bool                ## Set true to swap left/right channels
    csb_pin_state*: bool          ## CSB pin state (determines I2C address)
    fmt*: Wm8731Format            ## Communication format
    wl*: Wm8731WordLength         ## Word length

  Wm8731* {.importcpp: "daisy::Wm8731".} = object
    ## WM8731 codec driver
    ## 
    ## I2C-controlled audio codec with configurable format and word length.
    ## Used on Daisy Seed 1.1 and other platforms requiring advanced codec features.

{.pop.}

proc defaults*(this: var Wm8731Config) {.importcpp: "#.Defaults()".}
  ## Set default configuration values
  ## 
  ## Sets the following:
  ## - MCU is master = true
  ## - L/R swap = false  
  ## - CSB pin state = false
  ## - Format = MSB First LJ
  ## - Word length = 24-bit
  ##
  ## **Example:**
  ## ```nim
  ## var cfg: Wm8731Config
  ## cfg.defaults()
  ## # Optionally override specific settings
  ## cfg.fmt = Wm8731Format.I2S
  ## ```

proc init*(this: var Wm8731, config: Wm8731Config, i2c: I2CHandle): Wm8731Result 
  {.importcpp: "#.Init(#, #)".}
  ## Initialize the WM8731 codec
  ## 
  ## **Parameters:**
  ## - `config` - Configuration struct (use `defaults()` for typical setup)
  ## - `i2c` - Initialized I2C handle for communication
  ## 
  ## **Returns:** `Wm8731Result.OK` on success, `Wm8731Result.ERR` on failure
  ## 
  ## **Example:**
  ## ```nim
  ## var i2c: I2CHandle
  ## var cfg: Wm8731Config
  ## var codec: Wm8731
  ## 
  ## # Initialize I2C first
  ## # ... i2c setup ...
  ## 
  ## cfg.defaults()
  ## let result = codec.init(cfg, i2c)
  ## if result != Wm8731Result.OK:
  ##   echo "Codec init failed"
  ## ```
