## MCP23X17 GPIO Expander Module - 16-bit I/O Expansion via I2C/SPI
##
## Barebones driver for MCP23017/MCP23S17 16-bit I/O expanders.
## Currently supports I2C transport only (polling mode).

import ../nimphea
import ../nimphea_macros
import ../per/i2c

useNimpheaModules(mcp23x17, i2c)

type
  MCPPort* = enum
    MCP_PORT_A = 0
    MCP_PORT_B = 1

  MCPMode* = enum
    MCP_INPUT
    MCP_INPUT_PULLUP
    MCP_OUTPUT

  Mcp23017TransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*, sda*: Pin
    address*: uint8

  Mcp23017Config* = object
    transport_config*: Mcp23017TransportConfig

  Mcp23017* = object
    i2c: I2CHandle
    address: uint8
    pinData: uint16

const MCP_DEFAULT_ADDR* = 0x27'u8

proc defaults*(config: var Mcp23017TransportConfig) =
  config.periph = I2C_1
  config.speed = I2C_1MHZ
  config.scl = newPin(PORTB, 8)
  config.sda = newPin(PORTB, 9)
  config.address = MCP_DEFAULT_ADDR

proc defaults*(config: var Mcp23017Config) =
  config.transport_config.defaults()

proc init*(mcp: var Mcp23017, config: Mcp23017Config) =
  mcp.address = config.transport_config.address
  
  mcp.i2c = initI2C(
    config.transport_config.periph,
    config.transport_config.scl,
    config.transport_config.sda,
    config.transport_config.speed,
    I2C_MASTER
  )
  
  # Configure IOCON: sequential mode disabled
  discard mcp.i2c.writeRegister(mcp.address, 0x0A, 0b00100000'u8, 10)
  
  # Enable all pull-ups
  discard mcp.i2c.writeRegister(mcp.address, 0x0C, 0xFF'u8, 10) # GPPU_A
  discard mcp.i2c.writeRegister(mcp.address, 0x0D, 0xFF'u8, 10) # GPPU_B

proc portMode*(mcp: var Mcp23017, port: MCPPort, directions, pullups, inverted: uint8) =
  let regBase = if port == MCP_PORT_A: 0x00'u8 else: 0x01'u8
  discard mcp.i2c.writeRegister(mcp.address, regBase, directions, 10)
  discard mcp.i2c.writeRegister(mcp.address, regBase + 0x0C, pullups, 10)
  discard mcp.i2c.writeRegister(mcp.address, regBase + 0x02, inverted, 10)

proc digitalWrite*(mcp: var Mcp23017, port: MCPPort, value: uint8) =
  let reg = if port == MCP_PORT_A: 0x12'u8 else: 0x13'u8
  discard mcp.i2c.writeRegister(mcp.address, reg, value, 10)

proc readPort*(mcp: var Mcp23017, port: MCPPort): uint8 =
  let reg = if port == MCP_PORT_A: 0x12'u8 else: 0x13'u8
  let (res, val) = mcp.i2c.readRegister(mcp.address, reg, 10)
  return val

proc read*(mcp: var Mcp23017): uint16 =
  let a = mcp.readPort(MCP_PORT_A)
  let b = mcp.readPort(MCP_PORT_B)
  mcp.pinData = a.uint16 or (b.uint16 shl 8)
  return mcp.pinData

proc getPin*(mcp: Mcp23017, pin: uint8): bool =
  return ((mcp.pinData shr pin) and 1) != 0
