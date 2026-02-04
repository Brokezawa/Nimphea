## I2C support for libDaisy Nim wrapper
##
## This module provides I2C (Inter-Integrated Circuit) communication support
## for the Daisy Audio Platform. It supports both master and slave modes,
## blocking and DMA transfers.
##
## ⚠️ **IMPORTANT - Blocking vs DMA Functions:**
##
## - **Blocking functions** (`write`, `read`, `writeRegister`, `readRegister`) will stall
##   the CPU while waiting for the I2C transaction to complete. This can cause **audio glitches**
##   if called from the audio callback or main loop during audio processing.
##
## - **DMA functions** (`transmitDma`, `receiveDma`) use Direct Memory Access to transfer
##   data in the background without blocking the CPU. These are **safe to use during audio
##   processing** if your buffers are in the correct memory region.
##
## **DMA Buffer Requirements:**
## - Buffers must be in D2 memory domain (not stack variables!)
## - Use `{.section: ".sram1_bss".}` or allocate on heap
## - Or use `dsy_dma_clear_cache_for_buffer()` before transfer (advanced)
##
## **DMA Availability:**
## - I2C1, I2C2, I2C3: Share a single DMA channel (only one can use DMA at a time)
## - I2C4: No DMA support (use blocking functions only)
##
## Example - Simple I2C master (blocking):
## ```nim
## import nimphea, per/i2c, per/uart
## 
## var daisy = initDaisy()
## var i2c = initI2C(I2C_1, D11(), D12(), I2C_400KHZ)
## 
## startLog()
## 
## # Scan for devices (BLOCKS - don't use in audio callback!)
## var foundDevices: array[112, uint8]
## let count = i2c.scan(foundDevices)
## print("Found ")
## print(count)
## printLine(" devices")
## 
## # Write to device (BLOCKS)
## var txData = [0x01'u8, 0xFF]
## if i2c.write(0x48, txData) == I2C_OK:
##   printLine("Write OK")
## 
## # Read from device (BLOCKS)
## var rxData: array[4, uint8]
## if i2c.read(0x48, rxData) == I2C_OK:
##   printLine("Read OK")
## ```
##
## Example - Register access (blocking):
## ```nim
## # Write to register (BLOCKS)
## discard i2c.writeRegister(0x3C, 0x00, 0xAF)
## 
## # Read from register (BLOCKS)
## let (result, value) = i2c.readRegister(0x3C, 0x01)
## ```
##
## Example - Non-blocking DMA transfer:
## ```nim
## import nimphea, per/i2c
##
## # DMA buffers MUST be in D2 memory, not on stack!
## var txBuffer {.section: ".sram1_bss".}: array[64, uint8]
## var transferComplete = false
##
## proc onTransferComplete(context: pointer, result: I2CResult) {.cdecl.} =
##   # Called from interrupt - keep this FAST!
##   transferComplete = true
##
## var daisy = initDaisy()
## var i2c = initI2C(I2C_1, D11(), D12(), I2C_400KHZ)
##
## # Start DMA transfer (non-blocking)
## discard i2c.transmitDma(0x48, txBuffer, onTransferComplete, nil)
##
## # CPU is free to do other work while transfer happens in background
## while not transferComplete:
##   # Do audio processing or other tasks
##   discard
## ```

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(i2c)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # Forward declaration for internal implementation
  I2CHandleImpl* {.importcpp: "daisy::I2CHandle::Impl".} = object

  # I2C Configuration enums
  I2CMode* {.importcpp: "daisy::I2CHandle::Config::Mode", size: sizeof(cint).} = enum
    I2C_MASTER = 0
    I2C_SLAVE

  I2CPeripheral* {.importcpp: "daisy::I2CHandle::Config::Peripheral", size: sizeof(cint).} = enum
    I2C_1 = 0
    I2C_2
    I2C_3
    I2C_4

  I2CSpeed* {.importcpp: "daisy::I2CHandle::Config::Speed", size: sizeof(cint).} = enum
    I2C_100KHZ = 0
    I2C_400KHZ
    I2C_1MHZ

  I2CResult* {.importcpp: "daisy::I2CHandle::Result", size: sizeof(cint).} = enum
    I2C_OK = 0
    I2C_ERR

  I2CDirection* {.importcpp: "daisy::I2CHandle::Direction", size: sizeof(cint).} = enum
    I2C_TRANSMIT = 0
    I2C_RECEIVE

  # Pin configuration structure
  I2CPinConfig* {.importcpp: "daisy::I2CHandle::Config::pin_config", bycopy.} = object
    scl* {.importc: "scl".}: Pin
    sda* {.importc: "sda".}: Pin

  # I2C Configuration structure
  I2CConfig* {.importcpp: "daisy::I2CHandle::Config", bycopy.} = object
    periph* {.importc: "periph".}: I2CPeripheral
    pin_config* {.importc: "pin_config".}: I2CPinConfig
    speed* {.importc: "speed".}: I2CSpeed
    mode* {.importc: "mode".}: I2CMode
    address* {.importc: "address".}: uint8

  # I2C callback function pointer
  I2CCallbackFunctionPtr* = proc(context: pointer, result: I2CResult) {.cdecl.}

  # Main I2C Handle
  I2CHandle* {.importcpp: "daisy::I2CHandle".} = object
    pimpl {.importc: "pimpl_".}: ptr I2CHandleImpl

# Low-level C++ interface
proc Init*(this: var I2CHandle, config: I2CConfig): I2CResult {.importcpp: "#.Init(@)".}
proc GetConfig*(this: I2CHandle): I2CConfig {.importcpp: "#.GetConfig()".}

proc TransmitBlocking*(this: var I2CHandle, address: uint16, data: ptr uint8, 
                        size: uint16, timeout: uint32): I2CResult {.importcpp: "#.TransmitBlocking(@)".}

proc ReceiveBlocking(this: var I2CHandle, address: uint16, data: ptr uint8, 
                       size: uint16, timeout: uint32): I2CResult {.importcpp: "#.ReceiveBlocking(@)".}

proc TransmitDma*(this: var I2CHandle, address: uint16, data: ptr uint8, size: uint16, 
                   callback: I2CCallbackFunctionPtr, callback_context: pointer): I2CResult {.importcpp: "#.TransmitDma(@)".}

proc ReceiveDma(this: var I2CHandle, address: uint16, data: ptr uint8, size: uint16, 
                  callback: I2CCallbackFunctionPtr, callback_context: pointer): I2CResult {.importcpp: "#.ReceiveDma(@)".}

proc ReadDataAtAddress(this: var I2CHandle, address: uint16, mem_address: uint16,
                         mem_address_size: uint16, data: ptr uint8, data_size: uint16,
                         timeout: uint32): I2CResult {.importcpp: "#.ReadDataAtAddress(@)".}

proc WriteDataAtAddress(this: var I2CHandle, address: uint16, mem_address: uint16,
                          mem_address_size: uint16, data: ptr uint8, data_size: uint16,
                          timeout: uint32): I2CResult {.importcpp: "#.WriteDataAtAddress(@)".}

{.pop.} # importcpp
{.pop.} # header

# C++ constructor
proc cppNewI2CHandle(): I2CHandle {.importcpp: "daisy::I2CHandle()", constructor, header: "daisy_seed.h".}

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc initI2C*(peripheral: I2CPeripheral, sclPin, sdaPin: Pin, 
              speed: I2CSpeed = I2C_400KHZ, mode: I2CMode = I2C_MASTER,
              slaveAddress: uint8 = 0x10): I2CHandle =
  ## Initialize I2C interface
  ## 
  ## Parameters:
  ##   peripheral: I2C_1, I2C_2, I2C_3, or I2C_4
  ##   sclPin: Clock pin (e.g., D11())
  ##   sdaPin: Data pin (e.g., D12())
  ##   speed: I2C_100KHZ, I2C_400KHZ, or I2C_1MHZ
  ##   mode: I2C_MASTER or I2C_SLAVE
  ##   slaveAddress: Device address when in slave mode
  ## 
  ## Example:
  ## ```nim
  ## var i2c = initI2C(I2C_1, D11(), D12(), I2C_400KHZ)
  ## ```
  result = cppNewI2CHandle()
  var config: I2CConfig
  config.periph = peripheral
  config.pin_config.scl = sclPin
  config.pin_config.sda = sdaPin
  config.speed = speed
  config.mode = mode
  config.address = slaveAddress
  discard result.Init(config)

proc write*(i2c: var I2CHandle, deviceAddr: uint16, data: openArray[uint8], 
            timeout: uint32 = 100): I2CResult {.inline.} =
  ## Write bytes to an I2C device
  if data.len > 0:
    result = i2c.TransmitBlocking(deviceAddr, addr data[0], uint16(data.len), timeout)
  else:
    result = I2C_OK

proc read*(i2c: var I2CHandle, deviceAddr: uint16, buffer: var openArray[uint8], 
           timeout: uint32 = 100): I2CResult {.inline.} =
  ## Read bytes from an I2C device into provided buffer
  if buffer.len > 0:
    result = i2c.ReceiveBlocking(deviceAddr, addr buffer[0], uint16(buffer.len), timeout)
  else:
    result = I2C_OK

proc writeRegister*(i2c: var I2CHandle, deviceAddr: uint16, regAddr: uint8, 
                    value: uint8, timeout: uint32 = 100): I2CResult {.inline.} =
  ## Write a single byte to a device register
  var data = value
  result = i2c.WriteDataAtAddress(deviceAddr, regAddr, 1, addr data, 1, timeout)

proc readRegister*(i2c: var I2CHandle, deviceAddr: uint16, regAddr: uint8, 
                   timeout: uint32 = 100): tuple[result: I2CResult, value: uint8] {.inline.} =
  ## Read a single byte from a device register
  result.value = 0
  result.result = i2c.ReadDataAtAddress(deviceAddr, regAddr, 1, addr result.value, 1, timeout)

proc writeRegisters*(i2c: var I2CHandle, deviceAddr: uint16, regAddr: uint8,
                     values: openArray[uint8], timeout: uint32 = 100): I2CResult {.inline.} =
  ## Write multiple bytes to consecutive device registers
  if values.len > 0:
    result = i2c.WriteDataAtAddress(deviceAddr, regAddr, 1, addr values[0], uint16(values.len), timeout)
  else:
    result = I2C_OK

proc readRegisters*(i2c: var I2CHandle, deviceAddr: uint16, regAddr: uint8,
                    buffer: var openArray[uint8], timeout: uint32 = 100): I2CResult {.inline.} =
  ## Read multiple bytes from consecutive device registers into provided buffer
  if buffer.len > 0:
    result = i2c.ReadDataAtAddress(deviceAddr, regAddr, 1, addr buffer[0], uint16(buffer.len), timeout)
  else:
    result = I2C_OK

proc scan*(i2c: var I2CHandle, found: var openArray[uint8], timeout: uint32 = 10): int =
  ## Scan the I2C bus for devices, storing responding addresses in provided buffer
  ## Returns number of devices found. Only works in master mode.
  ## Buffer should be at least 112 bytes to hold all possible addresses (0x08-0x77)
  result = 0
  var dummy: uint8 = 0
  
  # Scan addresses 0x08 to 0x77 (valid 7-bit I2C addresses)
  for addr in 0x08'u16 .. 0x77'u16:
    if result >= found.len:
      break
    let res = i2c.TransmitBlocking(addr, addr(dummy), 0, timeout)
    if res == I2C_OK:
      found[result] = uint8(addr)
      inc result

# =============================================================================
# DMA (Non-Blocking) API
# =============================================================================

proc transmitDma*(i2c: var I2CHandle,
                  deviceAddr: uint16,
                  buffer: var openArray[uint8],
                  callback: I2CCallbackFunctionPtr = nil,
                  context: pointer = nil): I2CResult =
  ## Non-blocking DMA transmit to I2C device
  ##
  ## ⚠️ **CRITICAL:** Buffer MUST be in D2 memory domain:
  ## - Use `{.section: ".sram1_bss".}` pragma on buffer declaration
  ## - Or allocate on heap with alloc/create
  ## - **DO NOT use stack variables** (will cause DMA errors)
  ##
  ## ⚠️ **DMA Sharing:** I2C1/I2C2/I2C3 share one DMA channel. Only one can use DMA at a time.
  ## I2C4 has NO DMA support - use blocking functions only.
  ##
  ## Parameters:
  ##   deviceAddr: 7-bit I2C device address (e.g., 0x48)
  ##   buffer: Data to transmit (must be in D2 memory!)
  ##   callback: Called when transfer completes (from interrupt, keep fast!)
  ##   context: User data pointer passed to callback
  ##
  ## Returns:
  ##   I2C_OK if transfer queued successfully, I2C_ERR on error
  ##
  ## Example:
  ## ```nim
  ## var txBuf {.section: ".sram1_bss".}: array[64, uint8]
  ## 
  ## proc onComplete(ctx: pointer, res: I2CResult) {.cdecl.} =
  ##   echo "Transfer done!"
  ##
  ## discard i2c.transmitDma(0x48, txBuf, onComplete, nil)
  ## ```
  if buffer.len > 0:
    result = i2c.TransmitDma(deviceAddr, addr buffer[0], uint16(buffer.len), 
                             callback, context)
  else:
    result = I2C_OK

proc receiveDma*(i2c: var I2CHandle,
                 deviceAddr: uint16,
                 buffer: var openArray[uint8],
                 callback: I2CCallbackFunctionPtr = nil,
                 context: pointer = nil): I2CResult =
  ## Non-blocking DMA receive from I2C device
  ##
  ## ⚠️ **CRITICAL:** Buffer MUST be in D2 memory domain:
  ## - Use `{.section: ".sram1_bss".}` pragma on buffer declaration
  ## - Or allocate on heap with alloc/create
  ## - **DO NOT use stack variables** (will cause DMA errors)
  ##
  ## ⚠️ **DMA Sharing:** I2C1/I2C2/I2C3 share one DMA channel. Only one can use DMA at a time.
  ## I2C4 has NO DMA support - use blocking functions only.
  ##
  ## Parameters:
  ##   deviceAddr: 7-bit I2C device address (e.g., 0x48)
  ##   buffer: Buffer to receive data into (must be in D2 memory!)
  ##   callback: Called when transfer completes (from interrupt, keep fast!)
  ##   context: User data pointer passed to callback
  ##
  ## Returns:
  ##   I2C_OK if transfer queued successfully, I2C_ERR on error
  ##
  ## Example:
  ## ```nim
  ## var rxBuf {.section: ".sram1_bss".}: array[64, uint8]
  ##
  ## proc onComplete(ctx: pointer, res: I2CResult) {.cdecl.} =
  ##   # Process received data
  ##   discard
  ##
  ## discard i2c.receiveDma(0x48, rxBuf, onComplete, nil)
  ## ```
  if buffer.len > 0:
    result = i2c.ReceiveDma(deviceAddr, addr buffer[0], uint16(buffer.len),
                            callback, context)
  else:
    result = I2C_OK

# Common I2C device addresses
const
  I2C_ADDR_MPU6050* = 0x68'u8      ## MPU6050 IMU
  I2C_ADDR_BMP280* = 0x76'u8       ## BMP280 pressure sensor
  I2C_ADDR_BMP280_ALT* = 0x77'u8   ## BMP280 alternate address
  I2C_ADDR_SSD1306* = 0x3C'u8      ## SSD1306 OLED display
  I2C_ADDR_SSD1306_ALT* = 0x3D'u8  ## SSD1306 alternate address
  I2C_ADDR_PCF8574* = 0x20'u8      ## PCF8574 I/O expander
  I2C_ADDR_MCP23017* = 0x20'u8     ## MCP23017 I/O expander
  I2C_ADDR_ADS1115* = 0x48'u8      ## ADS1115 ADC
  I2C_ADDR_DS3231* = 0x68'u8       ## DS3231 RTC
  I2C_ADDR_AT24C32* = 0x50'u8      ## AT24C32 EEPROM

when isMainModule:
  echo "libDaisy I2C wrapper - Clean API"
