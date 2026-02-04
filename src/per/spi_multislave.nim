## Multi-Slave SPI Module for libDaisy
## ====================================
##
## This module provides support for sharing a single SPI bus between multiple
## slave devices (up to 4). Each device has its own chip select (NSS) pin,
## while SCLK, MISO, and MOSI are shared.
##
## **Features:**
## - Support for up to 4 SPI slave devices on one bus
## - Software-controlled chip select per device
## - Blocking and DMA-based transfers
## - Compatible with standard SPI peripherals (SPI1-SPI6)
## - Individual device selection
##
## **Common Use Cases:**
## - Multiple sensor ICs on one bus (e.g., accelerometer + gyro + magnetometer)
## - Flash memory + display sharing SPI bus
## - Multiple DAC/ADC chips
## - Modular synth with multiple peripheral boards
##
## **Hardware Setup:**
## ```
## MCU              Device 1         Device 2         Device 3
## ----             --------         --------         --------
## SCLK  --------+--SCLK             SCLK             SCLK
##               |
## MOSI  --------+--MOSI             MOSI             MOSI
##               |
## MISO  --------+--MISO             MISO             MISO
##               
## NSS0  -----------CS
## NSS1  --------------------------CS
## NSS2  -----------------------------------------CS
## ```
##
## **Usage Example (Blocking):**
## ```nim
## import nimphea
## import per/spi_multislave
##
## var daisy = initDaisy()
##
## # Configure for 3 devices on SPI1
## var config = MultiSlaveSpiConfig(
##   periph: SPI_1,
##   direction: SPI_TWO_LINES,
##   datasize: 8,
##   clock_polarity: SPI_CLOCK_POL_LOW,
##   clock_phase: SPI_CLOCK_PHASE_1,
##   baud_prescaler: SPI_PS_8,
##   num_devices: 3
## )
##
## # Configure pins
## config.pin_config.sclk = D7()
## config.pin_config.miso = D8()
## config.pin_config.mosi = D9()
## config.pin_config.nss[0] = D10()  # Device 0 CS
## config.pin_config.nss[1] = D11()  # Device 1 CS
## config.pin_config.nss[2] = D12()  # Device 2 CS
##
## # Initialize
## var spi = MultiSlaveSpiHandle()
## if spi.init(config) != SPI_OK:
##   echo "SPI init failed"
##
## # Communicate with device 0
## var txData = [0x01'u8, 0x02, 0x03]
## if spi.blockingTransmit(0, txData) == SPI_OK:
##   echo "Sent to device 0"
##
## # Communicate with device 1
## var rxData: array[4, uint8]
## if spi.blockingReceive(1, rxData) == SPI_OK:
##   echo "Received from device 1"
##
## # Full-duplex with device 2
## if spi.blockingTransmitAndReceive(2, txData, rxData, 3) == SPI_OK:
##   echo "Transfer with device 2 complete"
## ```
##
## **Usage Example (DMA):**
## ```nim
## # DMA buffers MUST be in D2 memory!
## var txBuffer {.section: ".sram1_bss".}: array[256, uint8]
## var rxBuffer {.section: ".sram1_bss".}: array[256, uint8]
## var transferDone = false
##
## proc onTransferComplete(context: pointer, result: SpiResult) {.cdecl.} =
##   transferDone = true
##
## # Start non-blocking DMA transfer to device 0
## discard spi.dmaTransmitAndReceive(
##   device_index = 0,
##   tx_buff = addr txBuffer[0],
##   rx_buff = addr rxBuffer[0],
##   size = 256,
##   start_callback = nil,
##   end_callback = onTransferComplete,
##   callback_context = nil
## )
##
## # CPU is free while transfer happens
## while not transferDone:
##   # Do other work...
##   discard
## ```
##
## **Important Notes:**
## - Maximum 4 devices per bus
## - Each device can have different timing requirements, but all share
##   the same SPI configuration (clock polarity, phase, baud rate)
## - For devices with different timing needs, use separate SPI peripherals
## - DMA buffers MUST be in D2 memory domain (not stack variables)
## - Device indices are 0-based (0, 1, 2, 3)

import ../nimphea  # For Pin type
import spi
import ../nimphea_macros

useNimpheaModules(spi, spi_multislave)

{.push header: "per/spiMultislave.h".}

const
  MAX_SPI_DEVICES* = 4  ## Maximum number of devices on one multi-slave SPI bus

type
  MultiSlaveSpiPinConfig* {.importcpp: "daisy::MultiSlaveSpiHandle::Config::pin_config",
                            bycopy.} = object
    ## Pin configuration for multi-slave SPI
    sclk* {.importc: "sclk".}: Pin
    miso* {.importc: "miso".}: Pin
    mosi* {.importc: "mosi".}: Pin
    nss* {.importc: "nss".}: array[MAX_SPI_DEVICES, Pin]  ## Chip select pins

  MultiSlaveSpiConfig* {.importcpp: "daisy::MultiSlaveSpiHandle::Config",
                         bycopy.} = object
    ## Configuration for multi-slave SPI bus
    pin_config* {.importc: "pin_config".}: MultiSlaveSpiPinConfig
    periph* {.importc: "periph".}: SpiPeripheral
    direction* {.importc: "direction".}: SpiDirection
    datasize* {.importc: "datasize".}: culong
    clock_polarity* {.importc: "clock_polarity".}: SpiClockPolarity
    clock_phase* {.importc: "clock_phase".}: SpiClockPhase
    baud_prescaler* {.importc: "baud_prescaler".}: SpiBaudPrescaler
    num_devices* {.importc: "num_devices".}: csize_t  ## Number of devices (1-4)

  MultiSlaveSpiHandle* {.importcpp: "daisy::MultiSlaveSpiHandle",
                         byref.} = object
    ## Multi-slave SPI bus handler
    ## 
    ## Manages a single SPI bus shared between multiple slave devices

{.pop.}

# ============================================================================
# Constructor
# ============================================================================

proc initMultiSlaveSpi*(): MultiSlaveSpiHandle {.
  importcpp: "daisy::MultiSlaveSpiHandle()",
  constructor.}
  ## Create a new MultiSlaveSpiHandle instance
  ## 
  ## **Example:**
  ## ```nim
  ## var spi = initMultiSlaveSpi()
  ## ```

# ============================================================================
# Core Methods
# ============================================================================

proc init*(this: var MultiSlaveSpiHandle, 
           config: MultiSlaveSpiConfig): SpiResult {.
  importcpp: "#.Init(@)".}
  ## Initialize the multi-slave SPI bus
  ## 
  ## **Parameters:**
  ## - config: Configuration including pins, timing, and number of devices
  ## 
  ## **Returns:**
  ## - SPI_OK on success
  ## - SPI_ERR on failure
  ## 
  ## **Example:**
  ## ```nim
  ## var config = MultiSlaveSpiConfig(
  ##   periph: SPI_1,
  ##   num_devices: 2,
  ##   baud_prescaler: SPI_PS_16
  ## )
  ## if spi.init(config) != SPI_OK:
  ##   echo "Init failed"
  ## ```

proc getConfig*(this: MultiSlaveSpiHandle): MultiSlaveSpiConfig {.
  importcpp: "#.GetConfig()".}
  ## Get the current SPI configuration
  ## 
  ## **Returns:** Current MultiSlaveSpiConfig

# ============================================================================
# Blocking Transfer Methods
# ============================================================================

proc blockingTransmit*(this: var MultiSlaveSpiHandle,
                       device_index: csize_t,
                       buff: ptr uint8,
                       size: csize_t,
                       timeout: uint32 = 100): SpiResult {.
  importcpp: "#.BlockingTransmit(@)".}
  ## Blocking transmit to a specific device
  ## 
  ## This will:
  ## 1. Assert the chip select for the specified device
  ## 2. Transmit data over SPI
  ## 3. Deassert the chip select
  ## 4. Block CPU until complete or timeout
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - buff: Pointer to transmit buffer
  ## - size: Number of bytes to send
  ## - timeout: Timeout in milliseconds (default: 100)
  ## 
  ## **Returns:**
  ## - SPI_OK on success
  ## - SPI_ERR on failure or timeout
  ## 
  ## **Warning:** Blocks CPU! Do not call from audio callback.
  ## 
  ## **Example:**
  ## ```nim
  ## var data = [0x01'u8, 0x02, 0x03, 0x04]
  ## if spi.blockingTransmit(0, addr data[0], 4) != SPI_OK:
  ##   echo "Transmit failed"
  ## ```

proc blockingReceive*(this: var MultiSlaveSpiHandle,
                      device_index: csize_t,
                      buff: ptr uint8,
                      size: uint16,
                      timeout: uint32 = 100): SpiResult {.
  importcpp: "#.BlockingReceive(@)".}
  ## Blocking receive from a specific device
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - buff: Pointer to receive buffer
  ## - size: Number of bytes to receive
  ## - timeout: Timeout in milliseconds (default: 100)
  ## 
  ## **Returns:**
  ## - SPI_OK on success
  ## - SPI_ERR on failure or timeout
  ## 
  ## **Warning:** Blocks CPU! Do not call from audio callback.
  ## 
  ## **Example:**
  ## ```nim
  ## var data: array[8, uint8]
  ## if spi.blockingReceive(1, addr data[0], 8) == SPI_OK:
  ##   echo "Received: ", data
  ## ```

proc blockingTransmitAndReceive*(this: var MultiSlaveSpiHandle,
                                  device_index: csize_t,
                                  tx_buff: ptr uint8,
                                  rx_buff: ptr uint8,
                                  size: csize_t,
                                  timeout: uint32 = 100): SpiResult {.
  importcpp: "#.BlockingTransmitAndReceive(@)".}
  ## Blocking full-duplex transfer with a specific device
  ## 
  ## Simultaneously sends and receives data (standard SPI operation).
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - tx_buff: Pointer to transmit buffer
  ## - rx_buff: Pointer to receive buffer
  ## - size: Number of bytes to transfer
  ## - timeout: Timeout in milliseconds (default: 100)
  ## 
  ## **Returns:**
  ## - SPI_OK on success
  ## - SPI_ERR on failure or timeout
  ## 
  ## **Warning:** Blocks CPU! Do not call from audio callback.
  ## 
  ## **Example:**
  ## ```nim
  ## var txData = [0x80'u8, 0x00]  # Read register 0x00
  ## var rxData: array[2, uint8]
  ## if spi.blockingTransmitAndReceive(0, addr txData[0], addr rxData[0], 2) == SPI_OK:
  ##   echo "Register value: ", rxData[1]
  ## ```

# ============================================================================
# DMA Transfer Methods
# ============================================================================

proc dmaTransmit*(this: var MultiSlaveSpiHandle,
                  device_index: csize_t,
                  buff: ptr uint8,
                  size: csize_t,
                  start_callback: SpiStartCallbackFunctionPtr,
                  end_callback: SpiEndCallbackFunctionPtr,
                  callback_context: pointer): SpiResult {.
  importcpp: "#.DmaTransmit(@)".}
  ## Non-blocking DMA transmit to a specific device
  ## 
  ## **Important:**
  ## - Buffer MUST be in D2 memory domain
  ## - Use `{.section: ".sram1_bss".}` for static buffers
  ## - Callbacks execute from interrupt context (keep them fast!)
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - buff: Pointer to transmit buffer (must be in D2 memory)
  ## - size: Number of bytes to send
  ## - start_callback: Called when transfer starts (or nil)
  ## - end_callback: Called when transfer completes (or nil)
  ## - callback_context: User data passed to callbacks (or nil)
  ## 
  ## **Returns:**
  ## - SPI_OK: Transfer started successfully
  ## - SPI_ERR: Failed to start transfer
  ## 
  ## **Example:**
  ## ```nim
  ## var txBuf {.section: ".sram1_bss".}: array[256, uint8]
  ## 
  ## proc onDone(ctx: pointer, result: SpiResult) {.cdecl.} =
  ##   if result == SPI_OK:
  ##     echo "Transfer complete"
  ## 
  ## discard spi.dmaTransmit(0, addr txBuf[0], 256, nil, onDone, nil)
  ## ```

proc dmaReceive*(this: var MultiSlaveSpiHandle,
                 device_index: csize_t,
                 buff: ptr uint8,
                 size: csize_t,
                 start_callback: SpiStartCallbackFunctionPtr,
                 end_callback: SpiEndCallbackFunctionPtr,
                 callback_context: pointer): SpiResult {.
  importcpp: "#.DmaReceive(@)".}
  ## Non-blocking DMA receive from a specific device
  ## 
  ## **Important:**
  ## - Buffer MUST be in D2 memory domain
  ## - Callbacks execute from interrupt context
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - buff: Pointer to receive buffer (must be in D2 memory)
  ## - size: Number of bytes to receive
  ## - start_callback: Called when transfer starts (or nil)
  ## - end_callback: Called when transfer completes (or nil)
  ## - callback_context: User data passed to callbacks (or nil)
  ## 
  ## **Returns:**
  ## - SPI_OK: Transfer started successfully
  ## - SPI_ERR: Failed to start transfer

proc dmaTransmitAndReceive*(this: var MultiSlaveSpiHandle,
                             device_index: csize_t,
                             tx_buff: ptr uint8,
                             rx_buff: ptr uint8,
                             size: csize_t,
                             start_callback: SpiStartCallbackFunctionPtr,
                             end_callback: SpiEndCallbackFunctionPtr,
                             callback_context: pointer): SpiResult {.
  importcpp: "#.DmaTransmitAndReceive(@)".}
  ## Non-blocking DMA full-duplex transfer with a specific device
  ## 
  ## **Important:**
  ## - Both buffers MUST be in D2 memory domain
  ## - Callbacks execute from interrupt context
  ## 
  ## **Parameters:**
  ## - device_index: Which device to communicate with (0-3)
  ## - tx_buff: Pointer to transmit buffer (must be in D2 memory)
  ## - rx_buff: Pointer to receive buffer (must be in D2 memory)
  ## - size: Number of bytes to transfer
  ## - start_callback: Called when transfer starts (or nil)
  ## - end_callback: Called when transfer completes (or nil)
  ## - callback_context: User data passed to callbacks (or nil)
  ## 
  ## **Returns:**
  ## - SPI_OK: Transfer started successfully
  ## - SPI_ERR: Failed to start transfer
  ## 
  ## **Example:**
  ## ```nim
  ## var txBuf {.section: ".sram1_bss".}: array[128, uint8]
  ## var rxBuf {.section: ".sram1_bss".}: array[128, uint8]
  ## var done = false
  ## 
  ## proc onComplete(ctx: pointer, res: SpiResult) {.cdecl.} =
  ##   done = true
  ## 
  ## discard spi.dmaTransmitAndReceive(
  ##   device_index = 2,
  ##   tx_buff = addr txBuf[0],
  ##   rx_buff = addr rxBuf[0],
  ##   size = 128,
  ##   start_callback = nil,
  ##   end_callback = onComplete,
  ##   callback_context = nil
  ## )
  ## 
  ## while not done:
  ##   # Do other work while transfer happens
  ##   discard
  ## ```

# ============================================================================
# Error Handling
# ============================================================================

proc checkError*(this: var MultiSlaveSpiHandle): cint {.
  importcpp: "#.CheckError()".}
  ## Check for SPI errors
  ## 
  ## Returns the result of HAL_SPI_GetError().
  ## 
  ## **Returns:** Error code (0 = no error)
  ## 
  ## **Example:**
  ## ```nim
  ## if spi.blockingTransmit(0, data, size) != SPI_OK:
  ##   let errCode = spi.checkError()
  ##   echo "SPI error code: ", errCode
  ## ```

# ============================================================================
# Helper Procedures
# ============================================================================

# Overloaded helpers for arrays
proc blockingTransmit*(this: var MultiSlaveSpiHandle,
                       device_index: int,
                       data: openArray[uint8],
                       timeout: uint32 = 100): SpiResult =
  ## Convenience wrapper for transmitting from arrays
  ## 
  ## **Example:**
  ## ```nim
  ## var cmd = [0x01'u8, 0x02, 0x03]
  ## discard spi.blockingTransmit(0, cmd)
  ## ```
  this.blockingTransmit(csize_t(device_index), 
                        unsafeAddr data[0], 
                        csize_t(data.len), 
                        timeout)

proc blockingReceive*(this: var MultiSlaveSpiHandle,
                      device_index: int,
                      data: var openArray[uint8],
                      timeout: uint32 = 100): SpiResult =
  ## Convenience wrapper for receiving into arrays
  ## 
  ## **Example:**
  ## ```nim
  ## var buffer: array[16, uint8]
  ## discard spi.blockingReceive(1, buffer)
  ## ```
  this.blockingReceive(csize_t(device_index),
                       addr data[0],
                       uint16(data.len),
                       timeout)

proc blockingTransmitAndReceive*(this: var MultiSlaveSpiHandle,
                                  device_index: int,
                                  tx_data: openArray[uint8],
                                  rx_data: var openArray[uint8],
                                  timeout: uint32 = 100): SpiResult =
  ## Convenience wrapper for full-duplex transfer with arrays
  ## 
  ## **Example:**
  ## ```nim
  ## var tx = [0x03'u8, 0x00, 0x00, 0x00]  # Read command
  ## var rx: array[4, uint8]
  ## discard spi.blockingTransmitAndReceive(0, tx, rx)
  ## echo "Read: ", rx
  ## ```
  let size = min(tx_data.len, rx_data.len)
  this.blockingTransmitAndReceive(csize_t(device_index),
                                   unsafeAddr tx_data[0],
                                   addr rx_data[0],
                                   csize_t(size),
                                   timeout)

# ============================================================================
# Documentation Example (see EXAMPLES.md for usage patterns)
# ============================================================================
