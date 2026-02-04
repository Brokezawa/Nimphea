## SPI (Serial Peripheral Interface) support for libDaisy Nim wrapper
##
## This module provides SPI communication support for the Daisy Audio Platform.
##
## ⚠️ **IMPORTANT - Blocking vs DMA Functions:**
##
## - **Blocking functions** (`write`, `read`, `transfer`) will stall the CPU while waiting
##   for the SPI transaction to complete. This can cause **audio glitches** if called from
##   the audio callback or main loop during audio processing.
##
## - **DMA functions** (`dmaTransmit`, `dmaReceive`, `dmaTransmitAndReceive`) use Direct
##   Memory Access to transfer data in the background without blocking the CPU. These are
##   **safe to use during audio processing** if your buffers are in the correct memory region.
##
## **DMA Buffer Requirements:**
## - Buffers must be in D2 memory domain (not stack variables!)
## - Use `{.section: ".sram1_bss".}` or allocate on heap
## - Or use `dsy_dma_clear_cache_for_buffer()` before transfer (advanced)
##
## Example - Simple SPI master (blocking):
## ```nim
## import nimphea, per/spi
## 
## var daisy = initDaisy()
## var spi = initSPI(SPI_1, D8(), D9(), D10())
## 
## # Write bytes (BLOCKS - don't use in audio callback!)
## discard spi.write([0x01'u8, 0x02, 0x03, 0x04])
## 
## # Read bytes (BLOCKS)
## var buffer: array[4, uint8]
## discard spi.read(buffer)
## 
## # Full-duplex transfer (BLOCKS)
## let txData = [0xAA'u8, 0xBB, 0xCC]
## var rxData: array[3, uint8]
## discard spi.transfer(txData, rxData)
## ```
##
## Example - SPI with register access (blocking):
## ```nim
## # Write to register (BLOCKS)
## discard spi.writeRegister(0x20, 0xFF)
## 
## # Read from register (BLOCKS)
## let (result, value) = spi.readRegister(0x21)
## ```
##
## Example - Non-blocking DMA transfer:
## ```nim
## import nimphea, per/spi
##
## # DMA buffers MUST be in D2 memory, not on stack!
## var txBuffer {.section: ".sram1_bss".}: array[256, uint8]
## var transferComplete = false
##
## proc onTransferComplete(context: pointer, result: SpiResult) {.cdecl.} =
##   # Called from interrupt - keep this FAST!
##   transferComplete = true
##
## var daisy = initDaisy()
## var spi = initSPI(SPI_1, D8(), D9(), D10())
##
## # Start DMA transfer (non-blocking)
## discard spi.dmaTransmit(txBuffer, nil, onTransferComplete, nil)
##
## # CPU is free to do other work while transfer happens in background
## while not transferComplete:
##   # Do audio processing or other tasks
##   discard
## ```

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(spi)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # SPI Implementation (opaque)
  SpiHandleImpl* {.importcpp: "daisy::SpiHandle::Impl".} = object

  # SPI Configuration enums
  SpiPeripheral* {.importcpp: "daisy::SpiHandle::Config::Peripheral", size: sizeof(cint).} = enum
    SPI_1 = 0
    SPI_2
    SPI_3
    SPI_4
    SPI_5
    SPI_6

  SpiMode* {.importcpp: "daisy::SpiHandle::Config::Mode", size: sizeof(cint).} = enum
    SPI_MASTER = 0
    SPI_SLAVE

  SpiDirection* {.importcpp: "daisy::SpiHandle::Config::Direction", size: sizeof(cint).} = enum
    SPI_TWO_LINES = 0          ## Full duplex
    SPI_TWO_LINES_TX_ONLY      ## Half duplex transmit only
    SPI_TWO_LINES_RX_ONLY      ## Half duplex receive only
    SPI_ONE_LINE               ## Single wire bidirectional

  SpiClockPolarity* {.importcpp: "daisy::SpiHandle::Config::ClockPolarity", size: sizeof(cint).} = enum
    SPI_CLOCK_POL_LOW = 0      ## Clock idle state is low
    SPI_CLOCK_POL_HIGH         ## Clock idle state is high

  SpiClockPhase* {.importcpp: "daisy::SpiHandle::Config::ClockPhase", size: sizeof(cint).} = enum
    SPI_CLOCK_PHASE_1 = 0      ## Data sampled on first edge
    SPI_CLOCK_PHASE_2          ## Data sampled on second edge

  SpiNSS* {.importcpp: "daisy::SpiHandle::Config::NSS", size: sizeof(cint).} = enum
    SPI_NSS_SOFT = 0           ## Software NSS management
    SPI_NSS_HARD_INPUT         ## Hardware NSS input
    SPI_NSS_HARD_OUTPUT        ## Hardware NSS output

  SpiBaudPrescaler* {.importcpp: "daisy::SpiHandle::Config::BaudPrescaler", size: sizeof(cint).} = enum
    SPI_PS_2 = 0               ## Clock / 2
    SPI_PS_4                   ## Clock / 4
    SPI_PS_8                   ## Clock / 8
    SPI_PS_16                  ## Clock / 16
    SPI_PS_32                  ## Clock / 32
    SPI_PS_64                  ## Clock / 64
    SPI_PS_128                 ## Clock / 128
    SPI_PS_256                 ## Clock / 256

  SpiResult* {.importcpp: "daisy::SpiHandle::Result", size: sizeof(cint).} = enum
    SPI_OK = 0
    SPI_ERR

  SpiDmaDirection* {.importcpp: "daisy::SpiHandle::DmaDirection", size: sizeof(cint).} = enum
    SPI_DMA_RX = 0             ## DMA receive only
    SPI_DMA_TX                 ## DMA transmit only
    SPI_DMA_RX_TX              ## DMA receive and transmit

  # Pin configuration structure
  SpiPinConfig* {.importcpp: "daisy::SpiHandle::Config::pin_config", bycopy.} = object
    sclk* {.importc: "sclk".}: Pin
    miso* {.importc: "miso".}: Pin
    mosi* {.importc: "mosi".}: Pin
    nss* {.importc: "nss".}: Pin

  # SPI Configuration structure
  SpiConfig* {.importcpp: "daisy::SpiHandle::Config", bycopy.} = object
    periph* {.importc: "periph".}: SpiPeripheral
    mode* {.importc: "mode".}: SpiMode
    direction* {.importc: "direction".}: SpiDirection
    datasize* {.importc: "datasize".}: culong
    clock_polarity* {.importc: "clock_polarity".}: SpiClockPolarity
    clock_phase* {.importc: "clock_phase".}: SpiClockPhase
    nss* {.importc: "nss".}: SpiNSS
    baud_prescaler* {.importc: "baud_prescaler".}: SpiBaudPrescaler
    pin_config* {.importc: "pin_config".}: SpiPinConfig

  # SPI callback function pointers
  SpiStartCallbackFunctionPtr* = proc(context: pointer) {.cdecl.}
  SpiEndCallbackFunctionPtr* = proc(context: pointer, result: SpiResult) {.cdecl.}

  # Main SPI Handle
  SpiHandle* {.importcpp: "daisy::SpiHandle".} = object
    pimpl {.importc: "pimpl_".}: ptr SpiHandleImpl

# Low-level C++ interface
proc Init(this: var SpiHandle, config: SpiConfig): SpiResult {.importcpp: "#.Init(@)".}
proc GetConfig(this: SpiHandle): SpiConfig {.importcpp: "#.GetConfig()".}

proc BlockingTransmit*(this: var SpiHandle, buff: ptr uint8, size: csize_t, 
                        timeout: uint32 = 100): SpiResult {.importcpp: "#.BlockingTransmit(@)".}

proc BlockingReceive(this: var SpiHandle, buffer: ptr uint8, size: uint16, 
                       timeout: uint32): SpiResult {.importcpp: "#.BlockingReceive(@)".}

proc BlockingTransmitAndReceive(this: var SpiHandle, tx_buff: ptr uint8, rx_buff: ptr uint8, 
                                  size: csize_t, timeout: uint32 = 100): SpiResult {.importcpp: "#.BlockingTransmitAndReceive(@)".}

proc DmaTransmit(this: var SpiHandle, buff: ptr uint8, size: csize_t, 
                   start_callback: SpiStartCallbackFunctionPtr, 
                   end_callback: SpiEndCallbackFunctionPtr, 
                   callback_context: pointer): SpiResult {.importcpp: "#.DmaTransmit(@)".}

proc DmaReceive(this: var SpiHandle, buff: ptr uint8, size: csize_t, 
                  start_callback: SpiStartCallbackFunctionPtr, 
                  end_callback: SpiEndCallbackFunctionPtr, 
                  callback_context: pointer): SpiResult {.importcpp: "#.DmaReceive(@)".}

proc DmaTransmitAndReceive(this: var SpiHandle, tx_buff: ptr uint8, rx_buff: ptr uint8, size: csize_t, 
                             start_callback: SpiStartCallbackFunctionPtr, 
                             end_callback: SpiEndCallbackFunctionPtr, 
                             callback_context: pointer): SpiResult {.importcpp: "#.DmaTransmitAndReceive(@)".}

proc CheckError(this: var SpiHandle): cint {.importcpp: "#.CheckError()".}

{.pop.} # importcpp
{.pop.} # header

# Nim-friendly constructors and helpers
proc cppNewSpiHandle(): SpiHandle {.importcpp: "daisy::SpiHandle()", constructor, header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc initSPI*(peripheral: SpiPeripheral, sclkPin, misoPin, mosiPin: Pin,
              nssPin: Pin = Pin(), speed: SpiBaudPrescaler = SPI_PS_8,
              mode: int = 0): SpiHandle =
  ## Initialize SPI interface
  ## 
  ## Parameters:
  ##   peripheral: SPI_1, SPI_2, SPI_3, SPI_4, SPI_5, or SPI_6
  ##   sclkPin: Clock pin (e.g., D8())
  ##   misoPin: Master In Slave Out pin
  ##   mosiPin: Master Out Slave In pin
  ##   nssPin: Chip select pin (optional, use Pin() for software CS)
  ##   speed: Clock prescaler (SPI_PS_2 to SPI_PS_256)
  ##   mode: SPI mode 0-3 (sets clock polarity and phase)
  ## 
  ## Example:
  ## ```nim
  ## var spi = initSPI(SPI_1, D8(), D9(), D10())
  ## ```
  result = cppNewSpiHandle()
  var config: SpiConfig
  config.periph = peripheral
  config.mode = SPI_MASTER
  config.direction = SPI_TWO_LINES
  config.datasize = 8
  config.nss = if nssPin.port == PORTX: SPI_NSS_SOFT else: SPI_NSS_HARD_OUTPUT
  config.baud_prescaler = speed
  config.pin_config.sclk = sclkPin
  config.pin_config.miso = misoPin
  config.pin_config.mosi = mosiPin
  config.pin_config.nss = nssPin
  
  # Set SPI mode
  case mode
  of 0:
    config.clock_polarity = SPI_CLOCK_POL_LOW
    config.clock_phase = SPI_CLOCK_PHASE_1
  of 1:
    config.clock_polarity = SPI_CLOCK_POL_LOW
    config.clock_phase = SPI_CLOCK_PHASE_2
  of 2:
    config.clock_polarity = SPI_CLOCK_POL_HIGH
    config.clock_phase = SPI_CLOCK_PHASE_1
  of 3:
    config.clock_polarity = SPI_CLOCK_POL_HIGH
    config.clock_phase = SPI_CLOCK_PHASE_2
  else: discard
  
  discard result.Init(config)

proc transfer*(spi: var SpiHandle, txData: openArray[uint8], 
               rxBuffer: var openArray[uint8], timeout: uint32 = 100): SpiResult {.inline.} =
  ## Full-duplex transfer (transmit and receive simultaneously)
  ## txData and rxBuffer must be same length
  if txData.len != rxBuffer.len:
    return SPI_ERR
  if txData.len > 0:
    result = spi.BlockingTransmitAndReceive(addr txData[0], addr rxBuffer[0], csize_t(txData.len), timeout)
  else:
    result = SPI_OK

proc write*(spi: var SpiHandle, data: openArray[uint8], timeout: uint32 = 100): SpiResult {.inline.} =
  ## Write data via SPI
  if data.len > 0:
    result = spi.BlockingTransmit(addr data[0], csize_t(data.len), timeout)
  else:
    result = SPI_OK

proc read*(spi: var SpiHandle, buffer: var openArray[uint8], timeout: uint32 = 100): SpiResult {.inline.} =
  ## Read data via SPI into provided buffer
  if buffer.len > 0:
    result = spi.BlockingReceive(addr buffer[0], uint16(buffer.len), timeout)
  else:
    result = SPI_OK

proc writeByte*(spi: var SpiHandle, data: uint8, timeout: uint32 = 100): SpiResult {.inline.} =
  ## Write a single byte
  var b = data
  result = spi.BlockingTransmit(addr b, 1, timeout)

proc readByte*(spi: var SpiHandle, timeout: uint32 = 100): tuple[result: SpiResult, data: uint8] {.inline.} =
  ## Read a single byte
  result.data = 0
  result.result = spi.BlockingReceive(addr result.data, 1, timeout)

proc transferByte*(spi: var SpiHandle, txByte: uint8, timeout: uint32 = 100): tuple[result: SpiResult, rxByte: uint8] {.inline.} =
  ## Transfer a single byte (full duplex)
  var tx = txByte
  result.rxByte = 0
  result.result = spi.BlockingTransmitAndReceive(addr tx, addr result.rxByte, 1, timeout)

proc writeRegister*(spi: var SpiHandle, regAddr: uint8, value: uint8, 
                    timeout: uint32 = 100): SpiResult =
  ## Write to a register (common SPI device pattern)
  var data: array[2, uint8] = [regAddr, value]
  result = spi.BlockingTransmit(addr data[0], 2, timeout)

proc readRegister*(spi: var SpiHandle, regAddr: uint8, 
                   timeout: uint32 = 100): tuple[result: SpiResult, value: uint8] =
  ## Read from a register
  var txData: array[2, uint8] = [regAddr, 0x00]
  var rxData: array[2, uint8]
  result.result = spi.BlockingTransmitAndReceive(addr txData[0], addr rxData[0], 2, timeout)
  result.value = rxData[1]

proc readRegisters*(spi: var SpiHandle, regAddr: uint8, buffer: var openArray[uint8],
                    timeout: uint32 = 100): SpiResult =
  ## Read multiple bytes from consecutive registers into provided buffer
  let count = buffer.len
  if count == 0:
    return SPI_OK
  
  var txData: array[256, uint8]  # Max SPI transfer size
  if count >= 256:
    return SPI_ERR
  
  txData[0] = regAddr
  var rxData: array[256, uint8]
  
  result = spi.BlockingTransmitAndReceive(
    addr txData[0], 
    addr rxData[0], 
    csize_t(count + 1), 
    timeout
  )
  
  if result == SPI_OK:
    for i in 0..<count:
      buffer[i] = rxData[i + 1]

# =============================================================================
# DMA (Non-Blocking) API
# =============================================================================

proc dmaTransmit*(spi: var SpiHandle, 
                  buffer: var openArray[uint8],
                  startCallback: SpiStartCallbackFunctionPtr = nil,
                  endCallback: SpiEndCallbackFunctionPtr = nil,
                  context: pointer = nil): SpiResult =
  ## Non-blocking DMA transmit
  ##
  ## ⚠️ **CRITICAL:** Buffer MUST be in D2 memory domain:
  ## - Use `{.section: ".sram1_bss".}` pragma on buffer declaration
  ## - Or allocate on heap with alloc/create
  ## - **DO NOT use stack variables** (will cause DMA errors)
  ##
  ## Parameters:
  ##   buffer: Data to transmit (must be in D2 memory!)
  ##   startCallback: Called when transfer starts (from interrupt, keep fast!)
  ##   endCallback: Called when transfer completes (from interrupt, keep fast!)
  ##   context: User data pointer passed to callbacks
  ##
  ## Returns:
  ##   SPI_OK if transfer queued successfully, SPI_ERR on error
  ##
  ## Example:
  ## ```nim
  ## var txBuf {.section: ".sram1_bss".}: array[256, uint8]
  ## 
  ## proc onComplete(ctx: pointer, res: SpiResult) {.cdecl.} =
  ##   echo "Transfer done!"
  ##
  ## discard spi.dmaTransmit(txBuf, nil, onComplete, nil)
  ## ```
  if buffer.len > 0:
    result = spi.DmaTransmit(addr buffer[0], csize_t(buffer.len), 
                             startCallback, endCallback, context)
  else:
    result = SPI_OK

proc dmaReceive*(spi: var SpiHandle,
                 buffer: var openArray[uint8],
                 startCallback: SpiStartCallbackFunctionPtr = nil,
                 endCallback: SpiEndCallbackFunctionPtr = nil,
                 context: pointer = nil): SpiResult =
  ## Non-blocking DMA receive
  ##
  ## ⚠️ **CRITICAL:** Buffer MUST be in D2 memory domain:
  ## - Use `{.section: ".sram1_bss".}` pragma on buffer declaration
  ## - Or allocate on heap with alloc/create
  ## - **DO NOT use stack variables** (will cause DMA errors)
  ##
  ## Parameters:
  ##   buffer: Buffer to receive data into (must be in D2 memory!)
  ##   startCallback: Called when transfer starts (from interrupt, keep fast!)
  ##   endCallback: Called when transfer completes (from interrupt, keep fast!)
  ##   context: User data pointer passed to callbacks
  ##
  ## Returns:
  ##   SPI_OK if transfer queued successfully, SPI_ERR on error
  ##
  ## Example:
  ## ```nim
  ## var rxBuf {.section: ".sram1_bss".}: array[256, uint8]
  ##
  ## proc onComplete(ctx: pointer, res: SpiResult) {.cdecl.} =
  ##   # Process received data
  ##   discard
  ##
  ## discard spi.dmaReceive(rxBuf, nil, onComplete, nil)
  ## ```
  if buffer.len > 0:
    result = spi.DmaReceive(addr buffer[0], csize_t(buffer.len),
                            startCallback, endCallback, context)
  else:
    result = SPI_OK

proc dmaTransmitAndReceive*(spi: var SpiHandle,
                            txBuffer: var openArray[uint8],
                            rxBuffer: var openArray[uint8],
                            startCallback: SpiStartCallbackFunctionPtr = nil,
                            endCallback: SpiEndCallbackFunctionPtr = nil,
                            context: pointer = nil): SpiResult =
  ## Non-blocking DMA full-duplex transfer (transmit and receive simultaneously)
  ##
  ## ⚠️ **CRITICAL:** Both buffers MUST be in D2 memory domain:
  ## - Use `{.section: ".sram1_bss".}` pragma on buffer declarations
  ## - Or allocate on heap with alloc/create
  ## - **DO NOT use stack variables** (will cause DMA errors)
  ##
  ## Parameters:
  ##   txBuffer: Data to transmit (must be in D2 memory!)
  ##   rxBuffer: Buffer to receive data into (must be in D2 memory!)
  ##   startCallback: Called when transfer starts (from interrupt, keep fast!)
  ##   endCallback: Called when transfer completes (from interrupt, keep fast!)
  ##   context: User data pointer passed to callbacks
  ##
  ## Returns:
  ##   SPI_OK if transfer queued successfully, SPI_ERR on error
  ##
  ## Note: txBuffer and rxBuffer must be the same length
  ##
  ## Example:
  ## ```nim
  ## var txBuf {.section: ".sram1_bss".}: array[256, uint8]
  ## var rxBuf {.section: ".sram1_bss".}: array[256, uint8]
  ##
  ## proc onComplete(ctx: pointer, res: SpiResult) {.cdecl.} =
  ##   # Transfer complete, process rxBuf
  ##   discard
  ##
  ## discard spi.dmaTransmitAndReceive(txBuf, rxBuf, nil, onComplete, nil)
  ## ```
  if txBuffer.len != rxBuffer.len:
    return SPI_ERR
  if txBuffer.len > 0:
    result = spi.DmaTransmitAndReceive(addr txBuffer[0], addr rxBuffer[0], 
                                       csize_t(txBuffer.len),
                                       startCallback, endCallback, context)
  else:
    result = SPI_OK

# Common SPI modes
const
  SPI_MODE_0* = (SPI_CLOCK_POL_LOW, SPI_CLOCK_PHASE_1)   ## CPOL=0, CPHA=0
  SPI_MODE_1* = (SPI_CLOCK_POL_LOW, SPI_CLOCK_PHASE_2)   ## CPOL=0, CPHA=1
  SPI_MODE_2* = (SPI_CLOCK_POL_HIGH, SPI_CLOCK_PHASE_1)  ## CPOL=1, CPHA=0
  SPI_MODE_3* = (SPI_CLOCK_POL_HIGH, SPI_CLOCK_PHASE_2)  ## CPOL=1, CPHA=1

when isMainModule:
  echo "libDaisy SPI wrapper - Clean API"
