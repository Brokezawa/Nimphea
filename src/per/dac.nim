## nimphea_dac
## =============
##
## Nim wrapper for libDaisy DAC (Digital to Analog Converter) peripheral.
##
## The DAC provides analog voltage output on dedicated pins:
## - DAC Channel 1: PA4
## - DAC Channel 2: PA5
##
## Supports both polling mode (single value writes) and DMA mode (buffered output).
##
## **Example (Polling Mode):**
## ```nim
## import per/dac
##
## var dac: DacHandle
## var config = DacConfig(
##   target_samplerate: 48000,
##   chn: DAC_CHN_ONE,
##   mode: DAC_MODE_POLLING,
##   bitdepth: DAC_BITS_12,
##   buff_state: DAC_BUFFER_ENABLED
## )
##
## if dac.init(config) == DAC_OK:
##   dac.writeValue(DAC_CHN_ONE, 2048)  # Mid-range voltage
## ```

import nimphea_macros

useNimpheaModules(dac)

type
  DacResult* {.importcpp: "daisy::DacHandle::Result", size: sizeof(cint).} = enum
    ## Return values for DAC operations
    DAC_OK = 0
    DAC_ERR = 1

  DacChannel* {.importcpp: "daisy::DacHandle::Channel", size: sizeof(cint).} = enum
    ## DAC channel selection
    DAC_CHN_ONE = 0   ## Channel 1 (PA4)
    DAC_CHN_TWO = 1   ## Channel 2 (PA5)
    DAC_CHN_BOTH = 2  ## Both channels

  DacMode* {.importcpp: "daisy::DacHandle::Mode", size: sizeof(cint).} = enum
    ## DAC operation mode
    DAC_MODE_POLLING = 0  ## Blocking single-value writes
    DAC_MODE_DMA = 1      ## DMA-driven buffered output

  DacBitDepth* {.importcpp: "daisy::DacHandle::BitDepth", size: sizeof(cint).} = enum
    ## DAC resolution
    DAC_BITS_8 = 0   ## 8-bit resolution
    DAC_BITS_12 = 1  ## 12-bit resolution

  DacBufferState* {.importcpp: "daisy::DacHandle::BufferState", size: sizeof(cint).} = enum
    ## DAC output buffer state
    DAC_BUFFER_ENABLED = 0   ## Output buffer enabled for higher drive
    DAC_BUFFER_DISABLED = 1  ## Output buffer disabled

  DacHandle* {.importcpp: "daisy::DacHandle",
                header: "per/dac.h".} = object
    ## DAC peripheral handle

  DacConfig* {.importcpp: "daisy::DacHandle::Config".} = object
    ## DAC configuration structure
    target_samplerate*: uint32  ## Target sample rate in Hz (DMA mode only, default 48000)
    chn*: DacChannel            ## Channel selection
    mode*: DacMode              ## Operation mode
    bitdepth*: DacBitDepth      ## Bit depth
    buff_state*: DacBufferState ## Buffer state

  DacCallback* = proc(output: ptr ptr uint16, size: csize_t) {.cdecl.}
    ## Callback for DMA mode
    ## Called when buffer needs to be filled
    ## For dual channel: output[0] = channel 1, output[1] = channel 2

proc init*(this: var DacHandle, config: DacConfig): DacResult
  {.importcpp: "#.Init(#)".} =
  ## Initialize the DAC peripheral
  ##
  ## **Parameters:**
  ## - `config` - DAC configuration
  ##
  ## **Returns:** DAC_OK on success, DAC_ERR on failure
  discard

proc getConfig*(this: DacHandle): DacConfig
  {.importcpp: "#.GetConfig()".} =
  ## Get current DAC configuration
  ##
  ## **Returns:** Current configuration
  discard

proc start*(this: var DacHandle, buffer: ptr uint16, size: csize_t,
            cb: DacCallback): DacResult
  {.importcpp: "#.Start(#, #, #)".} =
  ## Start DAC in DMA mode (single channel)
  ##
  ## **Parameters:**
  ## - `buffer` - Output buffer
  ## - `size` - Buffer size in samples
  ## - `cb` - Callback function
  ##
  ## **Returns:** DAC_OK on success, DAC_ERR if using both channels
  discard

proc start*(this: var DacHandle, buffer1: ptr uint16, buffer2: ptr uint16,
            size: csize_t, cb: DacCallback): DacResult
  {.importcpp: "#.Start(#, #, #, #)".} =
  ## Start DAC in DMA mode (dual channel)
  ##
  ## **Parameters:**
  ## - `buffer1` - Output buffer for channel 1
  ## - `buffer2` - Output buffer for channel 2
  ## - `size` - Buffer size in samples
  ## - `cb` - Callback function
  ##
  ## **Returns:** DAC_OK on success
  discard

proc stop*(this: var DacHandle): DacResult
  {.importcpp: "#.Stop()".} =
  ## Stop DAC conversion
  ##
  ## **Returns:** DAC_OK on success
  discard

proc writeValue*(this: var DacHandle, chn: DacChannel, val: uint16): DacResult
  {.importcpp: "#.WriteValue(#, #)".} =
  ## Write value in polling mode
  ##
  ## Has no effect in DMA mode.
  ##
  ## **Parameters:**
  ## - `chn` - Channel to write to
  ## - `val` - Value to write (0-255 for 8-bit, 0-4095 for 12-bit)
  ##
  ## **Returns:** DAC_OK on success
  discard
