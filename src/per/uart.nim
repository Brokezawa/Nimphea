## UART and Serial Printing support for libDaisy Nim wrapper
##
## This module provides UART serial communication and logging/printing
## capabilities for the Daisy Seed. It includes both low-level UART
## control and high-level logging via USB CDC or UART.
##
## Basic Usage (High-Level Logging):
## ```nim
## import nimphea
## import per/uart
## 
## var hw = newDaisySeed()
## 
## proc main() =
##   hw.init()
##   
##   # Start USB logging (appears as serial port on computer)
##   startLog()
##   
##   printLine("Hello from Daisy!")
##   print("Counter: ")
##   
##   var counter = 0
##   while true:
##     printLine($counter)
##     counter += 1
##     hw.delayMs(1000)
## ```
##
## UART Usage (Low-Level):
## ```nim
## var uart = newUartHandler()
## var config = newUartConfig()
## 
## config.periph = USART_1
## config.pin_config.tx = hw.getPin(14)  # Pin D14
## config.pin_config.rx = hw.getPin(15)  # Pin D15
## config.baudrate = 115200
## 
## if uart.init(config) == UART_OK:
##   let msg = "Hello UART!"
##   uart.blockingTransmit(msg.cstring, msg.len.csize_t)
## ```

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
# Serial module includes both per/uart.h and hid/logger.h
useNimpheaModules(serial)

{.push header: "per/uart.h".}
{.push importcpp.}

type
  # UART Peripheral selection
  UartPeripheral* {.importcpp: "daisy::UartHandler::Config::Peripheral", 
                    size: sizeof(cint).} = enum
    USART_1 = 0
    USART_2
    USART_3
    UART_4
    UART_5
    USART_6
    UART_7
    UART_8
    LPUART_1

  # Stop bits configuration
  UartStopBits* {.importcpp: "daisy::UartHandler::Config::StopBits",
                  size: sizeof(cint).} = enum
    STOP_BITS_0_5 = 0
    STOP_BITS_1
    STOP_BITS_1_5
    STOP_BITS_2

  # Parity configuration
  UartParity* {.importcpp: "daisy::UartHandler::Config::Parity",
                size: sizeof(cint).} = enum
    PARITY_NONE = 0
    PARITY_EVEN
    PARITY_ODD

  # UART mode (RX, TX, or both)
  UartMode* {.importcpp: "daisy::UartHandler::Config::Mode",
             size: sizeof(cint).} = enum
    MODE_RX = 0
    MODE_TX
    MODE_TX_RX

  # Word length
  UartWordLength* {.importcpp: "daisy::UartHandler::Config::WordLength",
                    size: sizeof(cint).} = enum
    WORD_BITS_7 = 0
    WORD_BITS_8
    WORD_BITS_9

  # UART result codes
  UartResult* {.importcpp: "daisy::UartHandler::Result",
                size: sizeof(cint).} = enum
    UART_OK = 0
    UART_ERR

  # DMA direction
  UartDmaDirection* {.importcpp: "daisy::UartHandler::DmaDirection",
                      size: sizeof(cint).} = enum
    DMA_RX = 0
    DMA_TX

  # Pin configuration for UART
  UartPinConfig* {.importcpp: "daisy::UartHandler::Config::pin_config".} = object
    tx* {.importcpp: "tx".}: Pin
    rx* {.importcpp: "rx".}: Pin

  # UART Configuration
  UartConfig* {.importcpp: "daisy::UartHandler::Config".} = object
    pin_config* {.importcpp: "pin_config".}: UartPinConfig
    periph* {.importcpp: "periph".}: UartPeripheral
    stopbits* {.importcpp: "stopbits".}: UartStopBits
    parity* {.importcpp: "parity".}: UartParity
    mode* {.importcpp: "mode".}: UartMode
    wordlength* {.importcpp: "wordlength".}: UartWordLength
    baudrate* {.importcpp: "baudrate".}: uint32

  # UART Handler
  UartHandler* {.importcpp: "daisy::UartHandler".} = object

# UART Handler methods
proc init*(this: var UartHandler, config: UartConfig): UartResult {.importcpp: "Init".}
proc getConfig*(this: UartHandler): UartConfig {.importcpp: "GetConfig".}

proc blockingTransmit*(this: var UartHandler, buff: ptr uint8, size: csize_t, 
                       timeout: uint32 = 100): UartResult {.importcpp: "BlockingTransmit".}
proc blockingReceive*(this: var UartHandler, buffer: ptr uint8, size: uint16,
                      timeout: uint32 = 100): UartResult {.importcpp: "BlockingReceive".}

proc checkError*(this: var UartHandler): cint {.importcpp: "CheckError".}

{.pop.} # importcpp
{.pop.} # header

# =============================================================================
# High-Level Logging/Printing API
# =============================================================================

# Note: Logging functions (StartLog, Print, PrintLine) have been moved to
# libdaisy.nim to prevent circular dependencies and ambiguity.
# They are available via `import nimphea`.

# C++ constructors
proc newUartHandler*(): UartHandler {.importcpp: "daisy::UartHandler()", 
                                      constructor, header: "per/uart.h".}

proc newUartConfig*(): UartConfig {.importcpp: "daisy::UartHandler::Config()",
                                    constructor, header: "per/uart.h".}

# =============================================================================
# Helper Functions for UART
# =============================================================================

proc blockingTransmit*(uart: var UartHandler, data: cstring, 
                       timeout: uint32 = 100): UartResult =
  ## Transmit a C string via UART (blocking)
  let len = data.len
  result = uart.blockingTransmit(cast[ptr uint8](data), len.csize_t, timeout)

proc blockingTransmit*(uart: var UartHandler, data: openArray[uint8],
                       timeout: uint32 = 100): UartResult {.inline.} =
  ## Transmit a byte array via UART (blocking)
  if data.len > 0:
    result = uart.blockingTransmit(addr data[0], data.len.csize_t, timeout)
  else:
    result = UART_OK

proc blockingReceive*(uart: var UartHandler, buffer: var openArray[uint8],
                      timeout: uint32 = 100): UartResult =
  ## Receive data via UART (blocking) into provided buffer
  if buffer.len > 0:
    result = uart.blockingReceive(addr buffer[0], buffer.len.uint16, timeout)
  else:
    result = UART_OK

# Common baud rates
const
  BAUD_9600* = 9600'u32
  BAUD_19200* = 19200'u32
  BAUD_38400* = 38400'u32
  BAUD_57600* = 57600'u32
  BAUD_115200* = 115200'u32
  BAUD_230400* = 230400'u32
  BAUD_460800* = 460800'u32
  BAUD_921600* = 921600'u32
  BAUD_1000000* = 1000000'u32
  BAUD_2000000* = 2000000'u32

# MIDI baud rate
const BAUD_31250* = 31250'u32  ## Standard MIDI baud rate

# Helper to configure UART for common scenarios
proc configureForDebug*(config: var UartConfig, txPin, rxPin: Pin) =
  ## Configure UART for debug output (115200 baud, 8N1)
  config.periph = USART_1
  config.pin_config.tx = txPin
  config.pin_config.rx = rxPin
  config.baudrate = BAUD_115200
  config.mode = MODE_TX_RX
  config.stopbits = STOP_BITS_1
  config.parity = PARITY_NONE
  config.wordlength = WORD_BITS_8

proc configureForMidi*(config: var UartConfig, txPin, rxPin: Pin) =
  ## Configure UART for MIDI (31250 baud, 8N1)
  config.periph = USART_1
  config.pin_config.tx = txPin
  config.pin_config.rx = rxPin
  config.baudrate = BAUD_31250
  config.mode = MODE_TX_RX
  config.stopbits = STOP_BITS_1
  config.parity = PARITY_NONE
  config.wordlength = WORD_BITS_8

# =============================================================================
# Documentation and Examples
# =============================================================================

## USB Serial Logging Example:
## ```nim
## import nimphea
## import per/uart
## 
## var hw = newDaisySeed()
## 
## proc main() =
##   hw.init()
##   startLog()  # Initialize USB CDC serial
##   
##   printLine("Daisy Seed Started!")
##   printLine()
##   
##   var counter = 0
##   while true:
##     print("Counter: ")
##     printLine(counter)
##     
##     # Or use printf-style:
##     # printf("Counter: %d\n", counter)
##     
##     counter += 1
##     hw.delayMs(1000)
## 
## when isMainModule:
##   main()
## ```

## UART Debug Output Example:
## ```nim
## import nimphea
## import per/uart
## 
## var hw = newDaisySeed()
## var uart = newUartHandler()
## 
## proc uartPrint(msg: string) =
##   discard uart.blockingTransmit(msg)
## 
## proc main() =
##   hw.init()
##   
##   # Configure UART on pins D14/D15
##   var config = newUartConfig()
##   config.configureForDebug(hw.getPin(14), hw.getPin(15))
##   
##   if uart.init(config) != UART_OK:
##     return
##   
##   uartPrint("UART Debug Started\r\n")
##   
##   var counter = 0
##   while true:
##     uartPrint("Count: ")
##     uartPrint($counter)
##     uartPrint("\r\n")
##     counter += 1
##     hw.delayMs(1000)
## ```

## UART Echo Example:
## ```nim
## import nimphea
## import per/uart
## 
## var hw = newDaisySeed()
## var uart = newUartHandler()
## 
## proc main() =
##   hw.init()
##   
##   var config = newUartConfig()
##   config.configureForDebug(hw.getPin(14), hw.getPin(15))
##   
##   if uart.init(config) != UART_OK:
##     return
##   
##   discard uart.blockingTransmit("UART Echo Ready\r\n")
##   
##   while true:
##     # Receive one byte
##     let (result, data) = uart.blockingReceive(1, timeout = 1000)
##     
##     if result == UART_OK and data.len > 0:
##       # Echo it back
##       discard uart.blockingTransmit(data)
## ```

## Multiple UART Ports Example:
## ```nim
## var uart1 = newUartHandler()
## var uart2 = newUartHandler()
## 
## var config1 = newUartConfig()
## config1.periph = USART_1
## config1.pin_config.tx = hw.getPin(14)
## config1.pin_config.rx = hw.getPin(15)
## config1.baudrate = BAUD_115200
## 
## var config2 = newUartConfig()
## config2.periph = USART_2
## config2.pin_config.tx = hw.getPin(16)
## config2.pin_config.rx = hw.getPin(17)
## config2.baudrate = BAUD_9600
## 
## discard uart1.init(config1)
## discard uart2.init(config2)
## ```

when isMainModule:
  echo "libDaisy Serial/UART wrapper"
  echo "Provides USB logging and UART communication"
