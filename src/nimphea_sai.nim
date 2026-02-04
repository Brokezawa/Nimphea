## SAI (Serial Audio Interface) support for Nimphea
##
## This module provides low-level SAI peripheral access for the Daisy Audio Platform.
## SAI is used for I2S audio communication with external codecs.
##
## **Note**: For most applications, you should use the high-level audio API in
## `nimphea.nim` instead of using SAI directly. This module is provided for
## advanced use cases requiring custom audio configurations.
##
## Example - Custom SAI configuration:
## ```nim
## import nimphea, nimphea_sai
## 
## var sai: SaiHandle
## var config = newSaiConfig()
## 
## # Configure SAI1 for 48kHz, 24-bit audio
## config.periph = SAI_1
## config.sr = SAI_48KHZ
## config.bit_depth = SAI_24BIT
## config.a_sync = MASTER
## config.b_sync = SLAVE
## config.a_dir = RECEIVE
## config.b_dir = TRANSMIT
## 
## # Configure pins
## config.pin_config.fs = initPin(PORTE, 4)
## config.pin_config.mclk = initPin(PORTE, 2)
## config.pin_config.sck = initPin(PORTE, 5)
## config.pin_config.sa = initPin(PORTE, 6)
## config.pin_config.sb = initPin(PORTE, 3)
## 
## # Initialize SAI
## let result = sai.init(config)
## if result != SAI_OK:
##   # Handle error
##   discard
## 
## # Define audio callback
## proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
##   # Process audio samples
##   for i in 0..<size:
##     outputBuf[i] = inputBuf[i]  # Pass through
## 
## # Allocate DMA buffers (must be in DMA-capable memory)
## var rxBuffer: array[256, int32]
## var txBuffer: array[256, int32]
## 
## # Start DMA transfer
## discard sai.startDma(rxBuffer[0].addr, txBuffer[0].addr, 256, audioCallback)
## ```

import nimphea
import nimphea_macros

# Use the macro system for this module's compilation unit
useNimpheaModules(sai)

{.push header: "per/sai.h".}

type
  # SaiHandle is defined in libdaisy.nim
  # SaiHandle* {.importcpp: "daisy::SaiHandle", bycopy.} = object
  
  SaiConfig* {.importcpp: "daisy::SaiHandle::Config", bycopy.} = object
    periph* {.importcpp: "periph".}: SaiPeripheral
    pin_config* {.importcpp: "pin_config".}: SaiPinConfig
    sr* {.importcpp: "sr".}: SaiSampleRate
    bit_depth* {.importcpp: "bit_depth".}: SaiBitDepth
    a_sync* {.importcpp: "a_sync".}: SaiSync
    b_sync* {.importcpp: "b_sync".}: SaiSync
    a_dir* {.importcpp: "a_dir".}: SaiDirection
    b_dir* {.importcpp: "b_dir".}: SaiDirection
  
  SaiPinConfig* {.importcpp: "daisy::SaiHandle::Config::pin_config", bycopy.} = object
    mclk* {.importcpp: "mclk".}: Pin
    fs* {.importcpp: "fs".}: Pin
    sck* {.importcpp: "sck".}: Pin
    sa* {.importcpp: "sa".}: Pin
    sb* {.importcpp: "sb".}: Pin
  
  SaiPeripheral* {.importcpp: "daisy::SaiHandle::Config::Peripheral", size: sizeof(cint).} = enum
    SAI_1
    SAI_2
  
  SaiSampleRate* {.importcpp: "daisy::SaiHandle::Config::SampleRate", size: sizeof(cint).} = enum
    SAI_8KHZ
    SAI_16KHZ
    SAI_32KHZ
    SAI_48KHZ
    SAI_96KHZ
  
  SaiBitDepth* {.importcpp: "daisy::SaiHandle::Config::BitDepth", size: sizeof(cint).} = enum
    SAI_16BIT
    SAI_24BIT
    SAI_32BIT
  
  SaiSync* {.importcpp: "daisy::SaiHandle::Config::Sync", size: sizeof(cint).} = enum
    MASTER
    SLAVE
  
  SaiDirection* {.importcpp: "daisy::SaiHandle::Config::Direction", size: sizeof(cint).} = enum
    TRANSMIT
    RECEIVE
  
  SaiResult* {.importcpp: "daisy::SaiHandle::Result", size: sizeof(cint).} = enum
    SAI_OK = 0
    SAI_ERR = 1
  
  # Pin type (from daisy_core.h)
  GPIOPort* {.importcpp: "daisy::GPIOPort", size: sizeof(cint).} = enum
    PORTA = 0
    PORTB = 1
    PORTC = 2
    PORTD = 3
    PORTE = 4
    PORTF = 5
    PORTG = 6
    PORTH = 7
    PORTI = 8
    PORTJ = 9
    PORTK = 10
    PORTX = 255  # Invalid port
  
  Pin* {.importcpp: "daisy::Pin", bycopy.} = object
    port* {.importcpp: "port".}: GPIOPort
    pin* {.importcpp: "pin".}: uint8
  
  # SAI callback type
  SaiCallback* = proc(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.}

# Low-level C++ interface
proc Init(this: var SaiHandle, config: SaiConfig): SaiResult {.importcpp: "#.Init(@)".}
proc DeInit(this: var SaiHandle): SaiResult {.importcpp: "#.DeInit()".}
proc GetConfig(this: SaiHandle): SaiConfig {.importcpp: "#.GetConfig()".}
proc StartDma(this: var SaiHandle, bufferRx, bufferTx: ptr int32, size: csize_t, callback: SaiCallback): SaiResult {.importcpp: "#.StartDma(@)".}
proc StopDma(this: var SaiHandle): SaiResult {.importcpp: "#.StopDma()".}
proc GetSampleRate(this: SaiHandle): cfloat {.importcpp: "#.GetSampleRate()".}
proc GetBlockSize(this: SaiHandle): csize_t {.importcpp: "#.GetBlockSize()".}
proc GetBlockRate(this: SaiHandle): cfloat {.importcpp: "#.GetBlockRate()".}
proc GetOffset(this: SaiHandle): csize_t {.importcpp: "#.GetOffset()".}
proc IsInitialized(this: SaiHandle): bool {.importcpp: "#.IsInitialized()".}

# Constructors
proc newSaiConfig*(): SaiConfig {.importcpp: "daisy::SaiHandle::Config()", constructor.}
proc initPin*(port: GPIOPort, pin: uint8): Pin {.importcpp: "daisy::Pin(@)", constructor.}

{.pop.} # header

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc init*(sai: var SaiHandle, config: SaiConfig): SaiResult {.inline.} =
  ## Initialize the SAI peripheral with the given configuration.
  ##
  ## Parameters:
  ##   sai: The SAI handle to initialize
  ##   config: Configuration structure
  ##
  ## Returns:
  ##   SAI_OK on success, SAI_ERR on failure
  ##
  ## Example:
  ## ```nim
  ## var sai: SaiHandle
  ## var config = newSaiConfig()
  ## config.periph = SAI_1
  ## config.sr = SAI_48KHZ
  ## config.bit_depth = SAI_24BIT
  ## let result = sai.init(config)
  ## ```
  result = sai.Init(config)

proc deinit*(sai: var SaiHandle): SaiResult {.inline.} =
  ## Deinitialize the SAI peripheral.
  ##
  ## Returns:
  ##   SAI_OK on success, SAI_ERR on failure
  result = sai.DeInit()

proc getConfig*(sai: SaiHandle): SaiConfig {.inline.} =
  ## Get the current configuration of the SAI peripheral.
  ##
  ## Returns:
  ##   The current SAI configuration
  result = sai.GetConfig()

proc startDma*(sai: var SaiHandle, bufferRx, bufferTx: ptr int32, size: int, callback: SaiCallback): SaiResult {.inline.} =
  ## Start DMA-based audio transfer in circular buffer mode.
  ##
  ## The callback will be called when half of the buffer is ready,
  ## processing size/2 samples per callback.
  ##
  ## **Important**: Buffers must be allocated in DMA-capable memory.
  ## Use `DSY_DMA_BUFFER_SECTOR` pragma or ensure proper memory placement.
  ##
  ## Parameters:
  ##   sai: The initialized SAI handle
  ##   bufferRx: Pointer to receive buffer (for input)
  ##   bufferTx: Pointer to transmit buffer (for output)
  ##   size: Total buffer size in samples
  ##   callback: Function to call for audio processing
  ##
  ## Returns:
  ##   SAI_OK on success, SAI_ERR on failure
  ##
  ## Example:
  ## ```nim
  ## proc audioCallback(inputBuf, outputBuf: ptr int32, size: csize_t) {.cdecl.} =
  ##   for i in 0..<size:
  ##     outputBuf[i] = inputBuf[i]
  ## 
  ## var rxBuf: array[256, int32]
  ## var txBuf: array[256, int32]
  ## discard sai.startDma(rxBuf[0].addr, txBuf[0].addr, 256, audioCallback)
  ## ```
  result = sai.StartDma(bufferRx, bufferTx, size.csize_t, callback)

proc stopDma*(sai: var SaiHandle): SaiResult {.inline.} =
  ## Stop the DMA audio transfer.
  ##
  ## Returns:
  ##   SAI_OK on success, SAI_ERR on failure
  result = sai.StopDma()

proc getSampleRate*(sai: SaiHandle): float {.inline.} =
  ## Get the sample rate based on the current configuration.
  ##
  ## Returns:
  ##   Sample rate in Hz (e.g., 48000.0 for 48kHz)
  result = sai.GetSampleRate().float

proc getBlockSize*(sai: SaiHandle): int {.inline.} =
  ## Get the number of samples per audio block.
  ##
  ## Calculated as: Buffer Size / 2 / number of channels
  ##
  ## Returns:
  ##   Block size in samples
  result = sai.GetBlockSize().int

proc getBlockRate*(sai: SaiHandle): float {.inline.} =
  ## Get the block rate of the current stream.
  ##
  ## Based on buffer size and sample rate.
  ##
  ## Returns:
  ##   Block rate in Hz
  result = sai.GetBlockRate().float

proc getOffset*(sai: SaiHandle): int {.inline.} =
  ## Get the current offset within the SAI buffer.
  ##
  ## Returns:
  ##   Offset (will be either 0 or size/2)
  result = sai.GetOffset().int

proc isInitialized*(sai: SaiHandle): bool {.inline.} =
  ## Check if the SAI peripheral is initialized.
  ##
  ## Returns:
  ##   true if initialized, false otherwise
  result = sai.IsInitialized()

# =============================================================================
# Helper Procedures
# =============================================================================

proc configurePinsStandard*(config: var SaiConfig, port: GPIOPort) =
  ## Configure SAI pins using a standard layout on a single GPIO port.
  ##
  ## This is a convenience function for common pin configurations.
  ##
  ## Standard pin layout (example for PORTE):
  ## - MCLK: port pin 2
  ## - FS:   port pin 4
  ## - SCK:  port pin 5
  ## - SA:   port pin 6
  ## - SB:   port pin 3
  ##
  ## Parameters:
  ##   config: SAI configuration to modify
  ##   port: GPIO port to use for all pins
  ##
  ## Example:
  ## ```nim
  ## var config = newSaiConfig()
  ## config.configurePinsStandard(PORTE)
  ## ```
  config.pin_config.mclk = initPin(port, 2)
  config.pin_config.fs = initPin(port, 4)
  config.pin_config.sck = initPin(port, 5)
  config.pin_config.sa = initPin(port, 6)
  config.pin_config.sb = initPin(port, 3)

proc configureStandard48k24bit*(config: var SaiConfig, peripheral: SaiPeripheral = SAI_1) =
  ## Configure SAI for standard 48kHz, 24-bit stereo audio.
  ##
  ## This sets up common defaults:
  ## - Sample rate: 48kHz
  ## - Bit depth: 24-bit
  ## - Block A: Master, Receive (input)
  ## - Block B: Slave, Transmit (output)
  ##
  ## **Note**: You still need to configure pins separately.
  ##
  ## Parameters:
  ##   config: SAI configuration to modify
  ##   peripheral: SAI peripheral to use (default: SAI_1)
  ##
  ## Example:
  ## ```nim
  ## var config = newSaiConfig()
  ## config.configureStandard48k24bit()
  ## config.configurePinsStandard(PORTE)
  ## ```
  config.periph = peripheral
  config.sr = SAI_48KHZ
  config.bit_depth = SAI_24BIT
  config.a_sync = MASTER
  config.b_sync = SLAVE
  config.a_dir = RECEIVE
  config.b_dir = TRANSMIT

when isMainModule:
  echo "libDaisy SAI wrapper - Serial Audio Interface support"
