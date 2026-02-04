# API Reference

Complete reference for all Nimphea wrapper modules.

## Core Module (nimphea.nim)

### DaisySeed Object

Main hardware controller object.

**Creation:**
```nim
var hw = newDaisySeed()
```

**Initialization:**
```nim
proc init*(this: var DaisySeed)
```
Initialize all hardware with default configuration.

**LED Control:**
```nim
proc setLed*(this: var DaisySeed, state: bool)
```
Control onboard LED. `true` = on, `false` = off.

**Timing:**
```nim
proc delayMs*(this: var DaisySeed, milliseconds: uint32)
```
Blocking delay in milliseconds.

**Audio:**
```nim
proc startAudio*(this: var DaisySeed, callback: AudioCallback)
proc stopAudio*(this: var DaisySeed)
proc changeAudioCallback*(this: var DaisySeed, callback: AudioCallback)
```

Audio callback signature:
```nim
proc myCallback(input: ptr ptr cfloat, output: ptr ptr cfloat,
                size: csize_t) {.cdecl.} =
  # input[channel][sample] - Read audio in
  # output[channel][sample] - Write audio out
  # size - Number of samples per channel
```

**GPIO:**
```nim
proc getPin*(this: var DaisySeed, pin: DaisyPin): var DaisyGPIO
```
Get GPIO object for a pin.

### DaisyGPIO Object

GPIO pin controller.

**Configuration:**
```nim
type
  PinMode* = enum
    INPUT, OUTPUT, OPEN_DRAIN, ANALOG

  Pull* = enum
    NOPULL, PULLUP, PULLDOWN

var pin = hw.getPin(DPin10)
pin.mode = PinMode.OUTPUT
pin.pull = Pull.NOPULL
pin.init()
```

**Digital I/O:**
```nim
proc write*(this: var DaisyGPIO, state: bool)
proc read*(this: var DaisyGPIO): bool
proc toggle*(this: var DaisyGPIO)
```

**Pin Names:**
```
DPin0..DPin31  # 32 GPIO pins
```

---

## ADC Module (per/adc.nim)

**Import:**
```nim
import src/libdaisy_adc
```

### AdcHandle Object

Analog to Digital Converter for reading analog inputs.

**Configuration:**
```nim
type
  AdcChannelConfig* = object
    InitMux*: bool        # Enable multiplexed inputs
    MuxChannels*: uint8   # Number of mux channels (1-8)

var adc: AdcHandle
var channel1, channel2: AdcChannelConfig

# Simple single-ended channel
channel1.InitMux = false
adc.init(addr channel1, 1)  # 1 channel

# Multiplexed channel (4 mux inputs)
channel2.InitMux = true
channel2.MuxChannels = 4
adc.init(addr channel2, 1)  # 1 channel x 4 mux = 4 inputs
```

**Reading Values:**
```nim
# Start continuous conversion
adc.start()

# Read raw 12-bit value (0-4095)
let raw = adc.get(0)  # Channel 0

# Read as float (0.0 - 1.0)
let normalized = adc.getFloat(0)

# Read multiplexed input
let muxValue = adc.getMuxFloat(0, 2)  # Channel 0, Mux index 2

# Stop conversion
adc.stop()
```

**Pin Assignment:**
Analog pins on Daisy Seed:
- `PIN_ADC_0` through `PIN_ADC_7` - 8 ADC-capable pins
- Can be single-ended or differential pairs
- Multiplexed channels allow 32 total inputs

**High-Level API:**
```nim
# Create with specific channels
let adc = createAdc(1)  # 1 simple channel
let adc = createAdcMux(1, 8)  # 1 channel with 8 mux inputs

# Read values
let value = adc.read(0)  # Returns float 0.0-1.0
```

**Example:**
```nim
import src/libdaisy
import src/libdaisy_adc

var hw = newDaisySeed()
hw.init()

# Configure ADC for 2 channels
var channels: array[2, AdcChannelConfig]
channels[0].InitMux = false
channels[1].InitMux = false

var adc = newAdcHandle()
discard adc.init(addr channels[0], 2)
adc.start()

while true:
  let knob1 = adc.getFloat(0)
  let knob2 = adc.getFloat(1)
  # Use knob values...
  hw.delayMs(10)
```

---

## PWM Module (per/pwm.nim)

**Import:**
```nim
import src/libdaisy_pwm
```

### PwmHandle Object

Pulse Width Modulation for controlling servos, LEDs, motors.

**Configuration:**
```nim
type
  PwmPeripheral* = enum
    TIM_1, TIM_2, TIM_3, TIM_4, TIM_5, TIM_8

  PwmPolarity* = enum
    PWM_POL_NORMAL   # High during pulse
    PWM_POL_INVERTED # Low during pulse

var pwm: PwmHandle
var pwmCfg: PwmConfig
var ch1Cfg: PwmChannelConfig

# Configure timer (frequency = clock / (prescaler * period))
pwmCfg.periph = TIM_2
pwmCfg.prescaler = 0
pwmCfg.period = 47999  # ~1kHz at 48MHz clock

# Configure channel
ch1Cfg.pin = DPin10
ch1Cfg.polarity = PWM_POL_NORMAL

discard pwm.init(pwmCfg)
discard pwm.channel1().init(ch1Cfg)
```

**Setting Duty Cycle:**
```nim
# Using float (0.0 = 0%, 1.0 = 100%)
pwm.channel1().set(0.5)  # 50% duty cycle

# Using raw value
pwm.channel1().setRaw(24000)  # 50% of period (47999)
```

**Channel Access:**
```nim
var ch1 = pwm.channel1()  # Channel 1
var ch2 = pwm.channel2()  # Channel 2
var ch3 = pwm.channel3()  # Channel 3
var ch4 = pwm.channel4()  # Channel 4
```

**High-Level API:**
```nim
# Create PWM with frequency in Hz
let pwm = createPwm(TIM_2, 1000)  # 1kHz

# Setup a channel
pwm.setupChannel(1, DPin10)  # Channel 1 on pin 10

# Set duty cycle
pwm.setDutyCycle(1, 0.75)  # 75% duty
```

**Example - LED Dimming:**
```nim
import src/libdaisy
import src/libdaisy_pwm

var hw = newDaisySeed()
hw.init()

let pwm = createPwm(TIM_2, 1000)  # 1kHz
pwm.setupChannel(1, DPin10)

var brightness = 0.0
while true:
  pwm.setDutyCycle(1, brightness)
  brightness += 0.01
  if brightness > 1.0:
    brightness = 0.0
  hw.delayMs(20)
```

**Example - Servo Control:**
```nim
# Servo: 50Hz, 1-2ms pulse width
let pwm = createPwm(TIM_2, 50)  # 50Hz
pwm.setupChannel(1, DPin10)

proc setServoAngle(pwm: PwmHandle, angle: float) =
  # Map angle (0-180) to duty (0.05-0.10)
  let duty = 0.05 + (angle / 180.0) * 0.05
  pwm.setDutyCycle(1, duty)

pwm.setServoAngle(90.0)  # Center position
```

---

## OLED Display Module (hid/disp/oled_display.nim)

**Import:**
```nim
import src/libdaisy_oled
```

### SSD1306 OLED Driver

Generic driver supporting multiple screen sizes and transports.

**Supported Configurations:**
- **Sizes:** 128x64, 128x32, 96x16 pixels
- **Transports:** I2C, SPI (4-wire)

**Creating a Display:**
```nim
# I2C transport
var display = newOledDisplay[OledSize128x64, OledI2cTransport]()

# SPI transport
var display = newOledDisplay[OledSize128x64, OledSpiTransport]()
```

**Configuration:**
```nim
var cfg: OledDisplayConfig[OledI2cTransport]

# I2C configuration
cfg.transport.periph = I2C_PERIPH_1
cfg.transport.speed = I2C_400KHZ
cfg.transport.pin_config.scl = DPin11
cfg.transport.pin_config.sda = DPin12
cfg.transport.address = 0x3C

# SPI configuration (for SPI transport)
cfg.transport.periph = SPI_PERIPH_1
cfg.transport.pin_config.sclk = DPin8
cfg.transport.pin_config.mosi = DPin10
cfg.transport.pin_config.dc = DPin9   # Data/Command
cfg.transport.pin_config.reset = DPin30

display.init(cfg)
```

**Basic Drawing:**
```nim
# Clear display
display.fill(false)

# Set individual pixel
display.drawPixel(x, y, true)  # true = on, false = off

# Get display dimensions
let w = display.width()
let h = display.height()

# Send buffer to display
display.update()
```

**Drawing Functions:**
```nim
proc drawPixel*(x, y: uint32, on: bool)
proc drawLine*(x0, y0, x1, y1: uint32, on: bool)
proc drawRect*(x, y, width, height: uint32, on: bool, fill: bool)
proc drawCircle*(x, y, radius: uint32, on: bool)
proc drawChar*(ch: char, x, y: uint32, on: bool)
proc drawString*(str: string, x, y: uint32, on: bool)
```

**Example - Basic Text:**
```nim
import src/libdaisy
import src/libdaisy_oled

var hw = newDaisySeed()
hw.init()

var display = newOledDisplay[OledSize128x64, OledI2cTransport]()
var cfg: OledDisplayConfig[OledI2cTransport]
cfg.transport = getDefaultI2cConfig(I2C_PERIPH_1, DPin11, DPin12)
cfg.transport.address = 0x3C

display.init(cfg)
display.fill(false)
display.drawString("Hello Daisy!", 0, 0, true)
display.update()
```

**Example - Graphics:**
```nim
display.fill(false)

# Draw a box
display.drawRect(10, 10, 50, 30, true, false)

# Draw a filled circle
display.drawCircle(80, 32, 20, true)

# Draw a line
display.drawLine(0, 0, 127, 63, true)

display.update()
```

**Example - Animation:**
```nim
var x = 0
while true:
  display.fill(false)
  display.drawCircle(x, 32, 5, true)
  display.update()
  
  x = (x + 1) mod 128
  hw.delayMs(10)
```

---

## I2C Module (libdaisy_i2c.nim)

**IMPORTANT - Blocking vs DMA Functions:**
- **Blocking functions** (`write`, `read`, `writeRegister`, `readRegister`) stall the CPU and can cause **audio glitches** if used during audio processing
- **DMA functions** (`transmitDma`, `receiveDma`) use hardware to transfer data in the background without blocking
- **DMA Availability:** I2C1/I2C2/I2C3 share one DMA channel; I2C4 has NO DMA support

**Import:**
```nim
import src/libdaisy_i2c
```

### I2CHandle Object

**Configuration:**
```nim
type
  I2CSpeed* = enum
    I2C_100KHZ = 100000
    I2C_400KHZ = 400000
    I2C_1MHZ = 1000000

var i2c: I2CHandle
var cfg: I2CConfig
cfg.periph = I2C_PERIPH_1
cfg.speed = I2C_400KHZ
cfg.pin_config.scl = DPin11
cfg.pin_config.sda = DPin12
i2c.init(cfg)
```

**Blocking Communication (DO NOT use in audio callback):**
```nim
proc write*(this: var I2CHandle, deviceAddr: uint16, data: openArray[uint8], timeout: uint32 = 100): I2CResult
proc read*(this: var I2CHandle, deviceAddr: uint16, buffer: var openArray[uint8], timeout: uint32 = 100): I2CResult
proc writeRegister*(this: var I2CHandle, deviceAddr: uint16, regAddr: uint8, value: uint8, timeout: uint32 = 100): I2CResult
proc readRegister*(this: var I2CHandle, deviceAddr: uint16, regAddr: uint8, timeout: uint32 = 100): tuple[result: I2CResult, value: uint8]
```

**Non-Blocking DMA Communication (safe for audio processing):**
```nim
proc transmitDma*(this: var I2CHandle,
                  deviceAddr: uint16,
                  buffer: var openArray[uint8],
                  callback: I2CCallbackFunctionPtr = nil,
                  context: pointer = nil): I2CResult

proc receiveDma*(this: var I2CHandle,
                 deviceAddr: uint16,
                 buffer: var openArray[uint8],
                 callback: I2CCallbackFunctionPtr = nil,
                 context: pointer = nil): I2CResult
```

**DMA Buffer Requirements:**
- Buffers MUST be in D2 memory domain
- Use `{.section: ".sram1_bss".}` pragma on buffer declaration
- Or allocate on heap with alloc/create
- **DO NOT use stack variables** (will cause DMA errors)

**Example - DMA Transfer:**
```nim
# DMA buffers MUST be in D2 memory
var txBuffer {.section: ".sram1_bss".}: array[64, uint8]
var transferComplete = false

proc onComplete(context: pointer, result: I2CResult) {.cdecl.} =
  transferComplete = true

# Start non-blocking transfer
discard i2c.transmitDma(0x48, txBuffer, onComplete, nil)

# CPU is free while transfer happens
while not transferComplete:
  # Do other work
  discard
```

**Result Codes:**
```nim
type
  I2CResult* = enum
    I2C_OK = 0
    I2C_ERR = 1
```

---

## SPI Module (per/spi.nim)

**IMPORTANT - Blocking vs DMA Functions:**
- **Blocking functions** (`write`, `read`, `transfer`) stall the CPU and can cause **audio glitches** if used during audio processing
- **DMA functions** (`dmaTransmit`, `dmaReceive`, `dmaTransmitAndReceive`) use hardware to transfer data in the background without blocking

**Import:**
```nim
import src/libdaisy_spi
```

### SPIHandle Object

**Configuration:**
```nim
type
  SPIMode* = enum
    SPI_MODE_0 = 0  # CPOL=0, CPHA=0
    SPI_MODE_1 = 1  # CPOL=0, CPHA=1
    SPI_MODE_2 = 2  # CPOL=1, CPHA=0
    SPI_MODE_3 = 3  # CPOL=1, CPHA=1

var spi: SPIHandle
var cfg: SPIConfig
cfg.periph = SPI_PERIPH_1
cfg.mode = SPI_MODE_0
cfg.direction = SPI_DIRECTION_2LINES
cfg.baud_prescaler = SPI_BaudPrescaler.PS_8
spi.init(cfg)
```

**Blocking Communication (DO NOT use in audio callback):**
```nim
proc write*(this: var SpiHandle, data: openArray[uint8], timeout: uint32 = 100): SpiResult
proc read*(this: var SpiHandle, buffer: var openArray[uint8], timeout: uint32 = 100): SpiResult
proc transfer*(this: var SpiHandle, txData: openArray[uint8], rxBuffer: var openArray[uint8], timeout: uint32 = 100): SpiResult
```

**Non-Blocking DMA Communication (safe for audio processing):**
```nim
proc dmaTransmit*(this: var SpiHandle, 
                  buffer: var openArray[uint8],
                  startCallback: SpiStartCallbackFunctionPtr = nil,
                  endCallback: SpiEndCallbackFunctionPtr = nil,
                  context: pointer = nil): SpiResult

proc dmaReceive*(this: var SpiHandle,
                 buffer: var openArray[uint8],
                 startCallback: SpiStartCallbackFunctionPtr = nil,
                 endCallback: SpiEndCallbackFunctionPtr = nil,
                 context: pointer = nil): SpiResult

proc dmaTransmitAndReceive*(this: var SpiHandle,
                            txBuffer: var openArray[uint8],
                            rxBuffer: var openArray[uint8],
                            startCallback: SpiStartCallbackFunctionPtr = nil,
                            endCallback: SpiEndCallbackFunctionPtr = nil,
                            context: pointer = nil): SpiResult
```

**DMA Buffer Requirements:**
- Buffers MUST be in D2 memory domain
- Use `{.section: ".sram1_bss".}` pragma on buffer declaration
- Or allocate on heap with alloc/create
- **DO NOT use stack variables** (will cause DMA errors)

**Example - DMA Transfer:**
```nim
# DMA buffers MUST be in D2 memory
var txBuffer {.section: ".sram1_bss".}: array[256, uint8]
var transferComplete = false

proc onComplete(context: pointer, result: SpiResult) {.cdecl.} =
  transferComplete = true

# Start non-blocking transfer
discard spi.dmaTransmit(txBuffer, nil, onComplete, nil)

# CPU is free while transfer happens
while not transferComplete:
  # Do other work
  discard
```

---

## Multi-Slave SPI Module (per/spi_multislave.nim)

**Import:**
```nim
import per/spi_multislave
```

Provides support for sharing a single SPI bus between multiple slave devices (up to 4). Each device has its own chip select (NSS) pin while SCLK, MISO, and MOSI are shared.

### MultiSlaveSpiHandle Object

Manages a single SPI bus shared between multiple slave devices.

**Key Features:**
- Support for up to 4 SPI slave devices on one bus
- Software-controlled chip select per device  
- Blocking and DMA-based transfers
- Compatible with SPI1-SPI6 peripherals

**Methods:**

- `init(config: MultiSlaveSpiConfig): SpiResult` - Initialize multi-slave SPI bus
- `getConfig(): MultiSlaveSpiConfig` - Get current configuration

**Blocking Transfer Methods:**

- `blockingTransmit(device_index: csize_t, buff: ptr uint8, size: csize_t, timeout: uint32 = 100): SpiResult` - Transmit to specific device
- `blockingReceive(device_index: csize_t, buff: ptr uint8, size: uint16, timeout: uint32 = 100): SpiResult` - Receive from specific device
- `blockingTransmitAndReceive(device_index: csize_t, tx_buff: ptr uint8, rx_buff: ptr uint8, size: csize_t, timeout: uint32 = 100): SpiResult` - Full-duplex transfer

**DMA Transfer Methods:**

- `dmaTransmit(device_index: csize_t, buff: ptr uint8, size: csize_t, start_callback, end_callback, callback_context: pointer): SpiResult`
- `dmaReceive(device_index: csize_t, buff: ptr uint8, size: csize_t, start_callback, end_callback, callback_context: pointer): SpiResult`
- `dmaTransmitAndReceive(device_index: csize_t, tx_buff: ptr uint8, rx_buff: ptr uint8, size: csize_t, start_callback, end_callback, callback_context: pointer): SpiResult`

**Helper Methods (array overloads):**

- `blockingTransmit(device_index: int, data: openArray[uint8], timeout: uint32 = 100): SpiResult`
- `blockingReceive(device_index: int, data: var openArray[uint8], timeout: uint32 = 100): SpiResult`
- `blockingTransmitAndReceive(device_index: int, tx_data: openArray[uint8], rx_data: var openArray[uint8], timeout: uint32 = 100): SpiResult`

**Error Handling:**

- `checkError(): cint` - Get HAL SPI error code

**Example:**
```nim
import nimphea
import per/spi
import per/spi_multislave

var daisy = initDaisy()

# Configure for 3 devices on SPI1
var config = MultiSlaveSpiConfig(
  periph: SPI_1,
  direction: SPI_TWO_LINES,
  datasize: 8,
  clock_polarity: SPI_CLOCK_POL_LOW,
  clock_phase: SPI_CLOCK_PHASE_1,
  baud_prescaler: SPI_PS_16,
  num_devices: 3
)

# Configure pins
config.pin_config.sclk = D7()
config.pin_config.miso = D8()
config.pin_config.mosi = D9()
config.pin_config.nss[0] = D10()  # Device 0 CS
config.pin_config.nss[1] = D11()  # Device 1 CS
config.pin_config.nss[2] = D12()  # Device 2 CS

# Initialize
var spi = initMultiSlaveSpi()
if spi.init(config) != SPI_OK:
  echo "SPI init failed"

# Communicate with device 0
var txData = [0x01'u8, 0x02, 0x03]
if spi.blockingTransmit(0, txData) == SPI_OK:
  echo "Sent to device 0"

# Communicate with device 1
var rxData: array[4, uint8]
if spi.blockingReceive(1, rxData) == SPI_OK:
  echo "Received from device 1"
```

---

## QSPI Flash Module (per/qspi.nim)

**Import:**
```nim
import per/qspi
```

Provides access to the onboard QSPI flash memory (IS25LP080D on Seed 1.0, IS25LP064A on Seed 1.1+). Used for persistent data storage, firmware updates, or sample storage.

### QSPIHandle Object

Interface to QSPI flash memory.

**Key Features:**
- Memory-mapped mode for fast read access
- Indirect mode for erase/write operations
- 1MB (Seed 1.0) or 8MB (Seed 1.1+) capacity
- 4KB sector erase, 32KB block erase, full chip erase

**Methods:**

- `init(device: QSPIDevice, mode: QSPIMode): bool` - Initialize QSPI peripheral
- `deinit()` - Deinitialize QSPI
- `erase(start_addr: uint32, end_addr: uint32): bool` - Erase address range
- `eraseSector(address: uint32): bool` - Erase 4KB sector
- `write(address: uint32, size: uint32, buffer: ptr uint8): bool` - Write data
- `writePage(address: uint32, offset: uint32, size: uint32, buffer: ptr uint8): bool` - Write to 256-byte page

**Device Configuration:**

- `QSPI_DEVICE_IS25LP080D` - 1MB flash (Seed 1.0)
- `QSPI_DEVICE_IS25LP064A` - 8MB flash (Seed 1.1+)

**Modes:**

- `QSPI_MODE_INDIRECT_POLLING` - For erase/write operations
- `QSPI_MODE_MEMORY_MAPPED` - For fast read access (maps to memory address space)

**Example:**
```nim
import nimphea
import per/qspi

var daisy = initDaisy()
var qspi: QSPIHandle

# Initialize QSPI
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING):
  echo "QSPI init failed"

# Erase first sector (4KB)
if qspi.eraseSector(0):
  echo "Sector erased"

# Write data
var data = [0x01'u8, 0x02, 0x03, 0x04]
if qspi.write(0, 4, addr data[0]):
  echo "Data written"

# Switch to memory-mapped mode for reading
if qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  # Flash is now accessible at base address
  # Read operations are automatic
  discard
```

---

## Persistent Storage Module (nimphea_persistent_storage.nim)

**Import:**
```nim
import nimphea_persistent_storage
```

Provides type-safe persistent settings storage in QSPI flash with dirty detection, versioning, and factory defaults restoration.

### PersistentStorage[T] Generic Object

Manages persistent storage for a settings struct of type T.

**Key Features:**
- Automatic dirty detection (only writes when settings change)
- Factory defaults restoration
- State tracking (UNKNOWN, FACTORY, USER)
- Type-safe generic wrapper
- Requires settings struct with `==` and `!=` operators

**Methods:**

- `init(defaults: T, address_offset: uint32 = 0)` - Initialize with factory defaults
- `save()` - Save settings if changed (dirty flag)
- `restoreDefaults()` - Restore factory defaults
- `getSettings(): var T` - Get reference to current settings
- `getState(): StorageState` - Get storage state
- `overwritePreventionIsEnabled(): bool` - Check if overwrite protection is on
- `setOverwritePrevention(enabled: bool)` - Enable/disable overwrite protection

**Storage States:**

- `UNKNOWN` - Before initialization
- `FACTORY` - Factory defaults are loaded
- `USER` - User-modified settings are loaded

**Example:**
```nim
import nimphea
import per/qspi
import nimphea_persistent_storage

# Define settings struct (must be POD type)
type
  SynthSettings {.bycopy, exportc: "SynthSettings".} = object
    gain {.exportc.}: cfloat
    frequency {.exportc.}: cfloat
    waveform {.exportc.}: uint8

# Implement == and != operators
{.emit: """
typedef daisy::PersistentStorage<int>::State StorageState;

inline bool operator==(const SynthSettings& a, const SynthSettings& b) {
  return a.gain == b.gain && 
         a.frequency == b.frequency && 
         a.waveform == b.waveform;
}
inline bool operator!=(const SynthSettings& a, const SynthSettings& b) {
  return !(a == b);
}
""".}

var daisy = initDaisy()
var qspi: QSPIHandle

# Initialize QSPI in memory-mapped mode
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  echo "QSPI init failed"

# Create persistent storage
var storage = newPersistentStorage[SynthSettings](qspi)

# Initialize with defaults
let defaults = SynthSettings(gain: 0.5, frequency: 440.0, waveform: 0)
storage.init(defaults)

# Check state
case storage.getState()
of UNKNOWN: echo "Not initialized"
of FACTORY: echo "Using factory defaults"
of USER: echo "User settings loaded"

# Modify and save
var settings = storage.getSettings()
settings.gain = 0.8
storage.save()  # Only writes if changed

# Restore factory defaults
storage.restoreDefaults()
```

**Important Notes:**
- Settings struct must be Plain Old Data (POD) type
- Must implement `operator==` and `operator!=` in C++
- Use `{.exportc.}` pragma for stable struct name
- QSPI must be initialized in `MEMORY_MAPPED` mode
- First call to `init()` writes defaults to flash (~100ms)
- Address offset is masked to 256-byte page boundary

---

## Serial/UART Module (per/uart.nim)

**Import:**
```nim
import src/libdaisy_serial
```

### UartHandler Object

**Configuration:**
```nim
var uart: UartHandler
var cfg: UartConfig
cfg.periph = USART_1
cfg.baudrate = 115200
cfg.stopbits = UART_StopBits.BITS_1
cfg.parity = UART_Parity.NONE
uart.init(cfg)
```

**Communication:**
```nim
proc transmitBlocking*(this: var UartHandler, data: ptr uint8,
                       size: csize_t, timeout: uint32): cint

proc receiveBlocking*(this: var UartHandler, data: ptr uint8,
                      size: csize_t, timeout: uint32): cint

proc readable*(this: var UartHandler): cint
proc popRx*(this: var UartHandler): uint8
```

---

## MIDI Module (hid/midi.nim)

**Import:**
```nim
import src/libdaisy_midi
```

### MidiHandler Object

**Configuration:**
```nim
var midi: MidiHandler
var cfg: MidiUartConfig
cfg.transport = MidiTransport.UART
midi.init(cfg)
```

**Usage:**
```nim
midi.listen()

while midi.hasEvents():
  let event = midi.popEvent()
  if event.`type` == NoteOn:
    let note = event.data[0]
    let velocity = event.data[1]
```

---

## USB Module (hid/usb.nim)

**Import:**
```nim
import src/libdaisy_usb
```

### USB CDC (Serial)

```nim
var usb: USBHandler
usb.init()

# Read
if usb.readable() > 0:
  let c = usb.getRx()

# Write
usb.transmit(data, size)
```

---

## SD Card Module (per/sdmmc.nim)

**Import:**
```nim
import src/libdaisy_sdmmc
```

### SdmmcHandler Object

**Initialization:**
```nim
var sd: SdmmcHandler
sd.init()
```

**File Operations:**
```nim
# Mount filesystem
fatfs.mount()

# Open file
var file: FIL
var result = fatfs.open(file, "test.txt", FA_READ or FA_WRITE or FA_CREATE_ALWAYS)

# Write
var buffer = "Hello, SD card!"
var written: UINT
fatfs.write(file, buffer, written)

# Close
fatfs.close(file)
```

---

## SDRAM Module (sys/sdram.nim)

**Import:**
```nim
import src/libdaisy_sdram
```

### SdramHandler Object

**Initialization:**
```nim
var sdram: SdramHandler
sdram.init()
```

**Usage:**
```nim
# Allocate memory
let bufferSize = 48000 * 4  # 4 seconds at 48kHz
var buffer = sdram.malloc(bufferSize)

# Use as array
buffer[0] = 1.0'f32
buffer[1] = 0.5'f32
```

---

## Controls Module (hid/ctrl.nim)

**Import:**
```nim
import src/libdaisy_controls
```

### Switch Object

**Configuration:**
```nim
var button: Switch
button.init(DPin10, updateRate = 1000)
```

**Usage:**
```nim
button.debounce()
if button.risingEdge():
  echo "Button pressed!"
```

### Encoder Object

**Configuration:**
```nim
var encoder: Encoder
encoder.init(pinA = DPin11, pinB = DPin12, pinClick = DPin13)
```

**Usage:**
```nim
encoder.debounce()
let increment = encoder.increment()
if increment != 0:
  position += increment
```

---

## Macros Module (nimphea_macros.nim)

Compile-time include generation. Not used directly in user code.

---

## Constants and Enums

### Sample Rates
```nim
const
  SAMPLE_RATE_8K* = 8000
  SAMPLE_RATE_16K* = 16000
  SAMPLE_RATE_32K* = 32000
  SAMPLE_RATE_48K* = 48000
  SAMPLE_RATE_96K* = 96000
```

### Buffer Sizes
```nim
const
  DEFAULT_BLOCK_SIZE* = 48  # Audio samples per callback
```

---

## Complete Example

Here's a complete example using multiple modules:

```nim
import src/libdaisy
import src/libdaisy_i2c
import src/libdaisy_controls

var hw = newDaisySeed()
var i2c: I2CHandle
var button: Switch

proc audioCallback(input: ptr ptr cfloat, output: ptr ptr cfloat,
                   size: csize_t) {.cdecl.} =
  for i in 0..<size:
    output[0][i] = input[0][i] * 0.5  # Reduce volume
    output[1][i] = input[1][i] * 0.5

proc main() =
  # Initialize hardware
  hw.init()
  
  # Setup I2C
  var i2cCfg: I2CConfig
  i2cCfg.periph = I2C_PERIPH_1
  i2cCfg.speed = I2C_400KHZ
  i2cCfg.pin_config.scl = DPin11
  i2cCfg.pin_config.sda = DPin12
  i2c.init(i2cCfg)
  
  # Setup button
  button.init(DPin10)
  
  # Start audio
  hw.startAudio(audioCallback)
  
  # Main loop
  while true:
    button.debounce()
    if button.risingEdge():
      hw.setLed(true)
    if button.fallingEdge():
      hw.setLed(false)
    
    hw.delayMs(1)

when isMainModule:
  main()
```

---

## DAC Module (per/dac.nim)

**Import:**
```nim
import src/libdaisy_dac
```

### DacHandle Object

Digital to Analog Converter for analog voltage output.

**Pins:**
- DAC Channel 1: PA4
- DAC Channel 2: PA5

**Configuration:**
```nim
type
  DacChannel* = enum
    DAC_CHN_ONE    # PA4
    DAC_CHN_TWO    # PA5
    DAC_CHN_BOTH   # Both channels

  DacMode* = enum
    DAC_MODE_POLLING  # Single value writes
    DAC_MODE_DMA      # Buffered output

  DacBitDepth* = enum
    DAC_BITS_8   # 8-bit (0-255)
    DAC_BITS_12  # 12-bit (0-4095)

var dac: DacHandle
var config = DacConfig(
  target_samplerate: 48000,
  chn: DAC_CHN_ONE,
  mode: DAC_MODE_POLLING,
  bitdepth: DAC_BITS_12,
  buff_state: DAC_BUFFER_ENABLED
)
discard dac.init(config)
```

**Basic Operations:**
```nim
# Write single value (polling mode)
discard dac.writeValue(DAC_CHN_ONE, 2048)  # Mid-range

# Start DMA mode (single channel)
proc dacCallback(output: ptr ptr uint16, size: csize_t) {.cdecl.} =
  for i in 0..<size:
    output[0][i] = uint16(i * 100)  # Generate pattern

discard dac.start(buffer, bufferSize, dacCallback)

# Stop DAC
discard dac.stop()
```

---

## WAV Format Module (nimphea_wavformat.nim)

**Import:**
```nim
import src/libdaisy_wavformat
```

### WAV File Format

Structures and constants for WAV audio files.

**Constants:**
```nim
const
  kWavFileChunkId* = 0x46464952'u32     # "RIFF"
  kWavFileWaveId* = 0x45564157'u32      # "WAVE"
  kWavFileSubChunk1Id* = 0x20746d66'u32 # "fmt "
  kWavFileSubChunk2Id* = 0x61746164'u32 # "data"
```

**Format Codes:**
```nim
type WavFileFormatCode* = enum
  WAVE_FORMAT_PCM = 0x0001
  WAVE_FORMAT_IEEE_FLOAT = 0x0003
  WAVE_FORMAT_ALAW = 0x0006
  WAVE_FORMAT_ULAW = 0x0007
  WAVE_FORMAT_EXTENSIBLE = 0xFFFE
```

**Header Structure:**
```nim
type WavFormatTypeDef* = object
  ChunkId*: uint32       # "RIFF"
  FileSize*: uint32      # File size - 8
  FileFormat*: uint32    # "WAVE"
  SubChunk1ID*: uint32   # "fmt "
  SubChunk1Size*: uint32 # Format chunk size
  AudioFormat*: uint16   # Format code
  NbrChannels*: uint16   # Number of channels
  SampleRate*: uint32    # Sample rate (Hz)
  ByteRate*: uint32      # Bytes per second
  BlockAlign*: uint16    # Frame size in bytes
  BitPerSample*: uint16  # Bits per sample
  SubChunk2ID*: uint32   # "data"
  SubCHunk2Size*: uint32 # Data size

# Usage example (with SDMMC)
var header: WavFormatTypeDef
# Read from file...
if header.ChunkId == kWavFileChunkId:
  echo "Valid WAV: ", header.SampleRate, "Hz, ", header.NbrChannels, " channels"
```

---

## Daisy Patch Board Module (boards/daisy_patch.nim)

**Import:**
```nim
import src/libdaisy_patch
```

### DaisyPatch Object

Complete Daisy Patch Eurorack module support.

**Hardware Features:**
- 4 CV/Knob inputs with gate inputs
- OLED display (128x64)
- Rotary encoder
- MIDI I/O
- Gate inputs/outputs
- Audio I/O with AK4556 codec

**Initialization:**
```nim
var patch: DaisyPatch
patch.init()  # Or patch.init(boost = true) for 480MHz
```

**Audio:**
```nim
proc audioCallback(input, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
  # 4 input channels, 4 output channels
  for i in 0..<size:
    output[0][i] = input[0][i]  # Channel 1
    output[1][i] = input[1][i]  # Channel 2
    output[2][i] = input[2][i]  # Channel 3
    output[3][i] = input[3][i]  # Channel 4

patch.startAudio(audioCallback)
patch.stopAudio()
patch.setAudioSampleRate(SR_48KHZ)
patch.setAudioBlockSize(48)
```

**Controls:**
```nim
type PatchCtrl* = enum
  CTRL_1, CTRL_2, CTRL_3, CTRL_4

# Process controls
patch.processAllControls()  # Both analog and digital
# Or separately:
patch.processAnalogControls()
patch.processDigitalControls()

# Read control values
let knob1 = patch.getKnobValue(CTRL_1)  # 0.0 to 1.0

# Display control values on OLED
patch.displayControls()
```

**Direct Hardware Access:**
```nim
# Access underlying components
patch.seed.setLed(true)
patch.encoder  # Rotary encoder
patch.display  # OLED display
patch.midi     # MIDI handler
patch.gate_input[0]  # Gate input 1
patch.gate_output    # Gate output
```

---

## Random Number Generator Module (per/rng.nim)

**Import:**
```nim
import src/libdaisy_rng
```

Hardware True Random Number Generator (TRNG) peripheral wrapper.

**Check Availability:**
```nim
proc randomIsReady*(): bool
```
Returns `true` if the hardware RNG is ready for use.

**Get Random Value:**
```nim
proc randomGetValue*(): uint32
```
Returns a random 32-bit unsigned integer.

**Get Random Float:**
```nim
proc randomGetFloat*(): cfloat
```
Returns a random float between 0.0 and 1.0.

**Example:**
```nim
import src/libdaisy_rng

if randomIsReady():
  let randInt = randomGetValue()
  let randFloat = randomGetFloat()
```

---

## Hardware Timer Module (per/tim.nim)

**Import:**
```nim
import src/libdaisy_timer
```

Hardware timer peripherals (TIM2-TIM5) for precise timing and callbacks.

**Configuration Types:**
```nim
type
  TimerPeripheral = enum
    TIM_PERIPH_TIM2  # 32-bit counter
    TIM_PERIPH_TIM3  # 16-bit counter
    TIM_PERIPH_TIM4  # 16-bit counter
    TIM_PERIPH_TIM5  # 32-bit counter
  
  TimerCounterDir = enum
    TIMER_DIR_UP     # Count up from 0 to period
    TIMER_DIR_DOWN   # Count down from period to 0
  
  TimerResult = enum
    TIMER_OK   # Operation successful
    TIMER_ERR  # Operation failed
  
  TimerConfig = object
    periph: TimerPeripheral
    dir: TimerCounterDir
    period: uint32
    enable_irq: bool
  
  TimerCallback = proc(data: pointer) {.cdecl.}
```

**Initialization:**
```nim
var timer: TimerHandle
var config: TimerConfig
config.periph = TIM_PERIPH_TIM2
config.dir = TIMER_DIR_UP
config.period = 0xffffffff  # Max for 32-bit
config.enable_irq = false

discard timer.init(config)
discard timer.start()
```

**Timing Methods:**
```nim
proc getTick*(this: var TimerHandle): uint32
proc getMs*(this: var TimerHandle): uint32
proc getUs*(this: var TimerHandle): uint32
```

**Callback Support:**
```nim
proc setCallback*(this: var TimerHandle, callback: TimerCallback, data: pointer)

proc onTimer(data: pointer) {.cdecl.} =
  echo "Timer elapsed!"

config.enable_irq = true
discard timer.init(config)
timer.setCallback(onTimer, nil)
```

---

## Color Utilities Module (nimphea_color.nim)

**Import:**
```nim
import src/libdaisy_color
```

RGB color representation and manipulation utilities.

**Preset Colors:**
```nim
type
  PresetColor = enum
    COLOR_RED, COLOR_GREEN, COLOR_BLUE,
    COLOR_WHITE, COLOR_PURPLE, COLOR_CYAN,
    COLOR_GOLD, COLOR_OFF
```

**Create Color:**
```nim
proc createColor*(): Color
proc createColor*(r, g, b: cfloat): Color

var red = createColor()
red.init(COLOR_RED)

var orange = createColor(1.0, 0.5, 0.0)
```

**Getters:**
```nim
proc red*(this: Color): cfloat      # 0.0 to 1.0
proc green*(this: Color): cfloat
proc blue*(this: Color): cfloat
proc red8*(this: Color): uint8      # 0 to 255
proc green8*(this: Color): uint8
proc blue8*(this: Color): uint8
```

**Setters:**
```nim
proc setRed*(this: var Color, val: cfloat)
proc setGreen*(this: var Color, val: cfloat)
proc setBlue*(this: var Color, val: cfloat)
```

**Operators:**
```nim
proc `*`*(this: Color, scale: cfloat): Color  # Scale brightness
proc `+`*(lhs, rhs: Color): Color             # Add/saturate

var dimmed = myColor * 0.5
var combined = red + blue
```

**Blending:**
```nim
proc colorBlend*(a, b: Color, amt: cfloat): Color

var blended = colorBlend(red, blue, 0.5)  # 50/50 mix
```

---

## Gate Input Module (hid/gatein.nim)

**Import:**
```nim
import src/libdaisy_gatein
```

Gate/trigger input handler for eurorack-style gate signals.

**Initialization:**
```nim
var gate: GateIn
gate.init(D0(), true)  # Pin D0, inverted (typical for eurorack BJT circuits)
```

**Trigger Detection:**
```nim
proc trig*(this: var GateIn): bool
```
Returns `true` on rising edge detection. Call regularly to detect edges.

**State Reading:**
```nim
proc state*(this: var GateIn): bool
```
Returns current gate state (high/low).

**Example:**
```nim
while true:
  if gate.trig():
    echo "Gate triggered!"
  
  let isHigh = gate.state()
  delay(1)
```

---

## LED Control Module (hid/led.nim)

**Import:**
```nim
import src/libdaisy_led
```

Single LED control with software PWM and gamma correction.

**Initialization:**
```nim
var led: Led
led.init(D10(), false, 1000.0)  # Pin D10, not inverted, 1kHz update rate
```

**Set Brightness:**
```nim
proc set*(this: var Led, brightness: cfloat)
```
Set brightness 0.0 to 1.0 (automatically gamma corrected).

**Update:**
```nim
proc update*(this: var Led)
```
Must be called at the sample rate specified during init (e.g., 1kHz).

**Example:**
```nim
led.set(0.5)  # 50% brightness

while true:
  led.update()  # Call at 1kHz
  delay(1)
```

---

## RGB LED Module (hid/rgb_led.nim)

**Import:**
```nim
import src/libdaisy_rgbled
import src/libdaisy_color
```

3-channel RGB LED control with software PWM.

**Initialization:**
```nim
var rgb: RgbLed
rgb.init(D10(), D11(), D12(), false)  # R, G, B pins, not inverted
```

**Set by Channels:**
```nim
proc set*(this: var RgbLed, r, g, b: cfloat)

rgb.set(1.0, 0.0, 0.0)  # Red
```

**Set by Color:**
```nim
proc setColor*(this: var RgbLed, c: Color)

var purple = createColor(0.5, 0.0, 0.5)
rgb.setColor(purple)
```

**Individual Channels:**
```nim
proc setRed*(this: var RgbLed, val: cfloat)
proc setGreen*(this: var RgbLed, val: cfloat)
proc setBlue*(this: var RgbLed, val: cfloat)
```

**Update:**
```nim
proc update*(this: var RgbLed)
```
Must be called regularly (e.g., 1kHz) for PWM.

---

## 3-Position Switch Module (libdaisy_switch3.nim)

**Import:**
```nim
import src/libdaisy_switch3
```

3-position switch/toggle handler.

**Position Constants:**
```nim
const
  SWITCH3_POS_CENTER = 0
  SWITCH3_POS_UP = 1     # or POS_LEFT
  SWITCH3_POS_DOWN = 2   # or POS_RIGHT
```

**Initialization:**
```nim
var sw: Switch3
sw.init(D2(), D3())  # Two pins for 3 positions
```

**Read Position:**
```nim
proc read*(this: var Switch3): uint8

let pos = sw.read()
case pos
of SWITCH3_POS_CENTER:
  echo "Center"
of SWITCH3_POS_UP:
  echo "Up"
of SWITCH3_POS_DOWN:
  echo "Down"
```

---

## Data Structures & Utilities

### FIFO Module (nimphea_fifo.nim)

**Import:**
```nim
import src/libdaisy_fifo
```

Lock-free FIFO (First-In-First-Out) queue with fixed capacity. Thread-safe for single-producer/single-consumer scenarios.

**Type:**
```nim
type
  Fifo*[N: static int, T] = object
    # N = capacity (compile-time constant)
    # T = element type
```

**Methods:**
```nim
proc init*[N: static int, T](this: var Fifo[N, T])
  # Initialize empty FIFO

proc clear*[N: static int, T](this: var Fifo[N, T])
  # Clear all elements

proc push*[N: static int, T](this: var Fifo[N, T], value: T): bool
  # Push value to queue. Returns false if full.

proc pop*[N: static int, T](this: var Fifo[N, T], value: var T): bool
  # Pop value from queue. Returns false if empty.

proc peek*[N: static int, T](this: Fifo[N, T], value: var T): bool
  # Peek at front without removing

proc len*[N: static int, T](this: Fifo[N, T]): int
  # Get current number of elements

proc capacity*[N: static int, T](this: Fifo[N, T]): int
  # Get maximum capacity (always N)

proc isEmpty*[N: static int, T](this: Fifo[N, T]): bool
proc isFull*[N: static int, T](this: Fifo[N, T]): bool
```

**Example:**
```nim
var eventQueue: Fifo[16, int]
eventQueue.init()

# Push events
assert eventQueue.push(1)
assert eventQueue.push(2)

# Pop events (FIFO order)
var event: int
while eventQueue.pop(event):
  echo "Processing event: ", event
```

**Performance Notes:**
- Zero heap allocation (all stack-based)
- O(1) push/pop operations
- Audio-rate safe
- Lock-free for SPSC (single producer, single consumer)

---

### Stack Module (nimphea_stack.nim)

**Import:**
```nim
import src/libdaisy_stack
```

Fixed-capacity stack (Last-In-First-Out) with compile-time size.

**Type:**
```nim
type
  Stack*[N: static int, T] = object
```

**Methods:**
```nim
proc init*[N: static int, T](this: var Stack[N, T])
proc clear*[N: static int, T](this: var Stack[N, T])

proc push*[N: static int, T](this: var Stack[N, T], value: T): bool
  # Push to top. Returns false if full.

proc pop*[N: static int, T](this: var Stack[N, T], value: var T): bool
  # Pop from top. Returns false if empty.

proc peek*[N: static int, T](this: Stack[N, T], value: var T): bool
  # Peek at top without removing

proc len*[N: static int, T](this: Stack[N, T]): int
proc capacity*[N: static int, T](this: Stack[N, T]): int
proc isEmpty*[N: static int, T](this: Stack[N, T]): bool
proc isFull*[N: static int, T](this: Stack[N, T]): bool
```

**Example:**
```nim
var undoStack: Stack[8, float32]
undoStack.init()

# Record parameter changes
assert undoStack.push(0.5)
assert undoStack.push(0.7)

# Undo (LIFO order)
var value: float32
while undoStack.pop(value):
  echo "Restored: ", value  # 0.7, then 0.5
```

---

### RingBuffer Module (nimphea_ringbuffer.nim)

**Import:**
```nim
import src/libdaisy_ringbuffer
```

Lock-free circular buffer optimized for audio streaming. Supports block read/write and configurable overflow behavior.

**Type:**
```nim
type
  RingBufferMode* = enum
    OVERWRITE_OLDEST  # Overwrite old data when full
    REJECT_NEW        # Reject new writes when full
  
  RingBuffer*[N: static int, T] = object
```

**Methods:**
```nim
proc init*[N: static int, T](this: var RingBuffer[N, T], 
                             mode: RingBufferMode = OVERWRITE_OLDEST)

proc clear*[N: static int, T](this: var RingBuffer[N, T])

proc write*[N: static int, T](this: var RingBuffer[N, T], value: T): bool
  # Write single value

proc read*[N: static int, T](this: var RingBuffer[N, T], value: var T): bool
  # Read single value

proc writeBlock*[N: static int, T](this: var RingBuffer[N, T], 
                                   data: openArray[T]): int
  # Write multiple values, returns count written

proc readBlock*[N: static int, T](this: var RingBuffer[N, T], 
                                  data: var openArray[T]): int
  # Read multiple values, returns count read

proc peek*[N: static int, T](this: RingBuffer[N, T], value: var T, 
                             offset: int = 0): bool
  # Peek at value without removing

proc available*[N: static int, T](this: RingBuffer[N, T]): int
  # Get number of readable elements

proc remaining*[N: static int, T](this: RingBuffer[N, T]): int
  # Get space remaining for writes

proc capacity*[N: static int, T](this: RingBuffer[N, T]): int
proc isEmpty*[N: static int, T](this: RingBuffer[N, T]): bool
proc isFull*[N: static int, T](this: RingBuffer[N, T]): bool
```

**Example:**
```nim
# 100ms delay buffer at 48kHz
const DELAY_SAMPLES = 4800
var delayLine: RingBuffer[DELAY_SAMPLES, float32]
delayLine.init()

# In audio callback
proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  for i in 0 ..< size:
    var delayed: float32
    discard delayLine.read(delayed)
    discard delayLine.write(input[0][i])
    output[0][i] = input[0][i] * 0.5 + delayed * 0.5
```

---

### FixedStr Module (nimphea_fixedstr.nim)

**Import:**
```nim
import src/libdaisy_fixedstr
```

Stack-allocated fixed-capacity string for embedded displays and UI. No heap allocation.

**Type:**
```nim
type
  FixedStr*[N: static int] = object
    # N = maximum capacity in characters
```

**Methods:**
```nim
proc init*[N: static int](this: var FixedStr[N])
proc clear*[N: static int](this: var FixedStr[N])

proc add*[N: static int](this: var FixedStr[N], c: char): bool
proc add*[N: static int](this: var FixedStr[N], str: string): int
proc add*[N: static int](this: var FixedStr[N], value: int): int
proc add*[N: static int](this: var FixedStr[N], value: float): int
  # Add content. Returns chars added or false if full.

proc set*[N: static int](this: var FixedStr[N], str: string): int
  # Replace entire contents

proc `[]`*[N: static int](this: FixedStr[N], index: int): char
proc `[]=`*[N: static int](this: var FixedStr[N], index: int, c: char)
  # Character access

proc `$`*[N: static int](this: FixedStr[N]): string
  # Convert to string (allocates)

proc len*[N: static int](this: FixedStr[N]): int
proc capacity*[N: static int](this: FixedStr[N]): int
proc isEmpty*[N: static int](this: FixedStr[N]): bool
proc isFull*[N: static int](this: FixedStr[N]): bool
```

**Example:**
```nim
var display: FixedStr[32]
display.init()

discard display.add("Cutoff: ")
discard display.add(1200)
discard display.add(" Hz")

echo $display  # "Cutoff: 1200 Hz"

# Update
display.clear()
discard display.add("Volume: 75%")
```

---

### UniqueId Module (nimphea_uniqueid.nim)

**Import:**
```nim
import src/libdaisy_uniqueid
```

Read STM32 microcontroller's factory-programmed 96-bit unique identifier.

**Type:**
```nim
type
  UniqueId* = object
    w0*: uint32  # Bits 0-31
    w1*: uint32  # Bits 32-63
    w2*: uint32  # Bits 64-95
```

**Functions:**
```nim
proc getUniqueId*(): UniqueId
  # Read 96-bit unique ID

proc getUniqueIdString*(): string
  # Get as "XXXXXXXX-XXXXXXXX-XXXXXXXX" format

proc `$`*(uid: UniqueId): string
  # String representation

proc `==`*(a, b: UniqueId): bool
  # Equality comparison
```

**Example:**
```nim
let uid = getUniqueId()
echo uid  # UniqueId(0x12345678-0x9ABCDEF0-0x13579BDF)

let serial = getUniqueIdString()
echo "Device: ", serial  # Device: 12345678-9ABCDEF0-13579BDF

# Use for device identification
var deviceName: FixedStr[64]
deviceName.init()
discard deviceName.add("DaisySeed-")
discard deviceName.add(serial)
```

**Use Cases:**
- Device identification and registration
- License/authentication systems
- Hardware-based encryption keys
- Generating unique serial numbers

---

### CpuLoadMeter Module (nimphea_cpuload.nim)

**Import:**
```nim
import src/libdaisy_cpuload
```

Real-time CPU load measurement for audio processing optimization.

**Type:**
```nim
type
  CpuLoadMeter* {.importcpp: "daisy::CpuLoadMeter".} = object
```

**Methods:**
```nim
proc init*(this: var CpuLoadMeter, sampleRateInHz: float32, 
           blockSizeInSamples: int, 
           smoothingFilterCutoffHz: float32 = 1.0)
  # Initialize with audio configuration

proc onBlockStart*(this: var CpuLoadMeter)
  # Call at beginning of audio callback

proc onBlockEnd*(this: var CpuLoadMeter)
  # Call at end of audio callback

proc getAvgCpuLoad*(this: CpuLoadMeter): float32
  # Get smoothed average load (0.0 to 1.0)

proc getMinCpuLoad*(this: CpuLoadMeter): float32
  # Get minimum observed load

proc getMaxCpuLoad*(this: CpuLoadMeter): float32
  # Get maximum observed load

proc reset*(this: var CpuLoadMeter)
  # Reset statistics
```

**Example:**
```nim
var cpuMeter: CpuLoadMeter
cpuMeter.init(48000.0, 48)  # 48kHz, 48 samples/block

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  cpuMeter.onBlockStart()
  
  # Your DSP processing here
  for i in 0 ..< size:
    output[0][i] = input[0][i]
  
  cpuMeter.onBlockEnd()

# In main loop
while true:
  let load = cpuMeter.getAvgCpuLoad()
  echo "CPU: ", int(load * 100), "%"
  if load > 0.9:
    echo "WARNING: High CPU usage!"
  daisy.delay(1000)
```

**Interpretation:**
- **0-50%**: Plenty of headroom
- **50-70%**: Moderate usage
- **70-90%**: High usage - consider optimization
- **90-100%**: Critical - risk of audio dropouts
- **>100%**: Audio dropouts occurring

---

### Parameter Module (hid/parameter.nim)

**Import:**
```nim
import src/libdaisy_parameter
```

Parameter mapping with various scaling curves for natural control feel.

**Types:**
```nim
type
  Curve* = enum
    LINEAR       # Direct proportional (y = x)
    EXPONENTIAL  # Fast rise at high end (y = x²)
    LOGARITHMIC  # Fast rise at low end
    CUBE         # Smooth S-curve (y = x³)
```

**Functions:**
```nim
proc mapParameter*(input: float32, min: float32, max: float32, 
                   curve: Curve): float32
  # Map 0-1 input to min-max with curve

proc mapParameterExp*(input: float32, min: float32, max: float32): float32
proc mapParameterLog*(input: float32, min: float32, max: float32): float32
proc mapParameterLin*(input: float32, min: float32, max: float32): float32
proc mapParameterCube*(input: float32, min: float32, max: float32): float32
  # Convenience functions for specific curves
```

**Example:**
```nim
let knobValue = 0.6  # ADC reading (0.0 to 1.0)

# Filter cutoff: exponential feels natural for frequency
let cutoff = mapParameterExp(knobValue, 100.0, 10000.0)
echo "Cutoff: ", int(cutoff), " Hz"  # ~3700 Hz

# Volume: logarithmic feels natural for amplitude
let volume = mapParameterLog(knobValue, 0.0, 1.0)

# Mix: linear is fine
let mix = mapParameterLin(knobValue, 0.0, 1.0)
```

**Curve Recommendations:**
- **Frequency parameters**: Use EXPONENTIAL (cutoff, pitch, delay time)
- **Amplitude/Volume**: Use LOGARITHMIC (gain, mix level)
- **Time parameters**: Use EXPONENTIAL (attack, decay, release)
- **Position/Mix**: Use LINEAR (pan, dry/wet)
- **Smooth non-linear**: Use CUBE

---

### MappedValue Module (nimphea_mapped_value.nim)

**Import:**
```nim
import src/libdaisy_mapped_value
```

Value mapping, quantization, and normalization utilities. Pure Nim implementation.

**Functions:**
```nim
# Basic mapping
proc mapValueFloat*(input: float32, min: float32, max: float32): float32
  # Map 0-1 to float range

proc mapValueInt*(input: float32, min: int, max: int): int
  # Map 0-1 to integer range (rounded)

# Quantization
proc mapValueFloatQuantized*(input: float32, min: float32, max: float32, 
                             numSteps: int): float32
  # Map to quantized steps

proc quantizeFloat*(value: float32, stepSize: float32): float32
  # Quantize to nearest multiple

# Bipolar/Unipolar
proc mapValueBipolar*(input: float32, min: float32, max: float32): float32
  # Map with center at 0.5

proc mapValueUnipolar*(input: float32, max: float32): float32
  # Map 0-1 to 0-max

# Normalization (inverse operations)
proc normalizeValue*(value: float32, min: float32, max: float32): float32
proc normalizeValueInt*(value: int, min: int, max: int): float32

# Interpolation
proc lerp*(a: float32, b: float32, t: float32): float32
  # Linear interpolation

proc inverseLerp*(a: float32, b: float32, value: float32): float32
  # Find t for given value
```

**Examples:**
```nim
# Discrete parameter selection
let waveform = mapValueInt(0.7, 0, 3)  # Returns 2
# Maps to: 0=Sine, 1=Saw, 2=Square, 3=Triangle

# Quantize to semitones
let semitone = mapValueFloatQuantized(0.45, 0.0, 12.0, 12)
let freq = 220.0 * pow(2.0, semitone / 12.0)

# Bipolar CV input (0.5 = center/zero)
let panPosition = mapValueBipolar(0.75, -1.0, 1.0)  # Returns 0.5

# Normalize for display
let normalized = normalizeValue(440.0, 20.0, 20000.0)
echo "Frequency slider: ", int(normalized * 100), "%"

# Quantize mix to 5% increments
let mix = quantizeFloat(0.47, 0.05)  # Returns 0.45
```

**Common Patterns:**
```nim
# Octave selection (-2 to +2)
let octave = mapValueInt(knobValue, -2, 2)

# Quantize frequency to 10 Hz steps
let freq = quantizeFloat(mapValueFloat(knobValue, 20.0, 2000.0), 10.0)

# Map CV input ±5V (0.5 = 0V)
let cvVolts = mapValueBipolar(adcValue, -5.0, 5.0)
```

---

## Audio Codecs & Displays

### AK4556 Codec Module (codec_ak4556.nim)

**Import:**
```nim
import src/dev/codec_ak4556
```

**Description:**
Simple 24-bit stereo audio codec used on Daisy Seed 1.0. Requires only reset pin initialization - no I2C configuration.

**Types:**
```nim
type
  Ak4556* = object
    ## AK4556 codec driver
```

**Methods:**
```nim
proc init*(this: var Ak4556, resetPin: Pin)
  ## Initialize codec with reset pin
  
proc deInit*(this: var Ak4556)
  ## Deinitialize codec
```

**Example:**
```nim
import src/libdaisy
import src/dev/codec_ak4556

var codec: Ak4556
codec.init(getPin(0))  # Reset pin on D0
# Audio hardware now configured for Daisy Seed 1.0
codec.deInit()  # Clean up when done
```

---

### WM8731 Codec Module (codec_wm8731.nim)

**Import:**
```nim
import src/libdaisy_i2c
import src/dev/codec_wm8731
```

**Description:**
I2C-controlled 24-bit stereo codec used on Daisy Seed 1.1. Provides configurable audio format and word length.

**Types:**
```nim
type
  Wm8731Result* = enum
    OK   ## Success
    ERR  ## Failure
    
  Wm8731Format* = enum
    MSB_FIRST_RJ  ## MSB first, right-justified
    MSB_FIRST_LJ  ## MSB first, left-justified (default)
    I2S           ## I2S format
    DSP           ## DSP format
    
  Wm8731WordLength* = enum
    BITS_16  ## 16-bit samples
    BITS_20  ## 20-bit samples
    BITS_24  ## 24-bit samples (default)
    BITS_32  ## 32-bit samples
    
  Wm8731Config* = object
    mcu_is_master*: bool        ## MCU master mode
    lr_swap*: bool              ## Swap L/R channels
    csb_pin_state*: bool        ## CSB pin state
    fmt*: Wm8731Format          ## Audio format
    wl*: Wm8731WordLength       ## Word length
```

**Methods:**
```nim
proc defaults*(this: var Wm8731Config)
  ## Set default configuration
  ## MCU master, 24-bit, MSB LJ format
  
proc init*(this: var Wm8731, config: Wm8731Config, i2c: I2CHandle): Wm8731Result
  ## Initialize codec via I2C
```

**Example:**
```nim
import src/libdaisy
import src/libdaisy_i2c
import src/dev/codec_wm8731

var i2c = initI2C(I2C_1, getPin(11), getPin(12), I2C_400KHZ)
var codec: Wm8731
var config: Wm8731Config

config.defaults()  # Standard config
config.fmt = Wm8731Format.I2S  # Override to I2S if needed

if codec.init(config, i2c) == Wm8731Result.OK:
  echo "WM8731 initialized successfully"
```

---

### PCM3060 Codec Module (codec_pcm3060.nim)

**Import:**
```nim
import src/libdaisy_i2c
import src/dev/codec_pcm3060
```

**Description:**
High-performance 24-bit stereo codec used on Daisy Seed 2.0. Auto-configures to 24-bit LJ format.

**Types:**
```nim
type
  Pcm3060Result* = enum
    OK   ## Success
    ERR  ## Failure
```

**Methods:**
```nim
proc init*(this: var Pcm3060, i2c: I2CHandle): Pcm3060Result
  ## Initialize codec via I2C
  ## Auto-configures to 24-bit LJ format
```

**Example:**
```nim
import src/libdaisy
import src/libdaisy_i2c
import src/dev/codec_pcm3060

var i2c = initI2C(I2C_1, getPin(11), getPin(12), I2C_400KHZ)
var codec: Pcm3060

if codec.init(i2c) == Pcm3060Result.OK:
  echo "PCM3060 initialized successfully"
```

---

### HD44780 LCD Module (lcd_hd44780.nim)

**Import:**
```nim
import src/dev/lcd_hd44780
```

**Description:**
Character LCD driver for HD44780-compatible displays (16x2, 20x4). Uses 4-bit data mode with 6 GPIO connections.

**Types:**
```nim
type
  LcdHD44780Config* = object
    cursor_on*: bool      ## Show cursor
    cursor_blink*: bool   ## Blink cursor
    rs*: Pin              ## Register select pin
    en*: Pin              ## Enable pin
    d4*: Pin              ## Data bit 4
    d5*: Pin              ## Data bit 5
    d6*: Pin              ## Data bit 6
    d7*: Pin              ## Data bit 7
```

**Methods:**
```nim
proc init*(this: var LcdHD44780, config: LcdHD44780Config)
  ## Initialize LCD with configuration
  
proc print*(this: var LcdHD44780, text: cstring)
  ## Print text at current cursor position
  
proc printInt*(this: var LcdHD44780, value: cint)
  ## Print integer value
  
proc setCursor*(this: var LcdHD44780, row: uint8, col: uint8)
  ## Set cursor position (row 0-1, col 0-15 for 16x2)
  
proc clear*(this: var LcdHD44780)
  ## Clear display and reset cursor
```

**Example:**
```nim
import src/libdaisy
import src/dev/lcd_hd44780

var lcd: LcdHD44780
var config: LcdHD44780Config

config.cursor_on = false
config.cursor_blink = false
config.rs = getPin(1)
config.en = getPin(2)
config.d4 = getPin(3)
config.d5 = getPin(4)
config.d6 = getPin(5)
config.d7 = getPin(6)

lcd.init(config)
lcd.clear()
lcd.setCursor(0, 0)  # Row 0, Column 0
lcd.print("Hello Daisy!")
lcd.setCursor(1, 0)  # Row 1, Column 0
lcd.print("Volume: ")
lcd.printInt(75)  # Print "75"
```

---

### OLED Fonts Module (oled_fonts.nim)

**Import:**
```nim
import src/util/oled_fonts
```

**Description:**
Font data for OLED displays. Provides 8 bitmap fonts in various sizes for use with SSD1306 and similar displays.

**Types:**
```nim
type
  FontDef* = object
    ## Font definition structure
    ## Contains character bitmap data and dimensions
```

**Available Fonts:**
```nim
var Font_4x6*: FontDef      ## 4x6 pixel font (smallest)
var Font_5x8*: FontDef      ## 5x8 pixel font
var Font_6x8*: FontDef      ## 6x8 pixel font  
var Font_7x10*: FontDef     ## 7x10 pixel font
var Font_11x18*: FontDef    ## 11x18 pixel font
var Font_12x16*: FontDef    ## 12x16 pixel font
var Font_16x26*: FontDef    ## 16x26 pixel font (largest)
```

**Usage:**
```nim
import src/libdaisy_oled
import src/util/oled_fonts

var display: OledDisplay
# ... initialize display ...

# Use font with OLED display
display.setFont(Font_7x10)
display.writeString("Hello", Font_7x10, true)  # true = white text
```

**Font Characteristics:**
- All fonts are monospaced (fixed width)
- Characters are ASCII printable (32-126)
- Stored in flash memory (no RAM overhead)
- Compatible with common OLED libraries

---

## Sensor Modules

### ICM20948 9-Axis IMU Module (icm20948.nim)

**Import:**
```nim
import src/dev/icm20948
import src/libdaisy_i2c  # or libdaisy_spi
```

**Description:**
9-axis motion sensor with 3-axis gyroscope, 3-axis accelerometer, 3-axis magnetometer (AK09916), and temperature sensor. Supports both I2C and SPI interfaces.

**Important:** Requires applying libDaisy patch before use. See `patches/README.md` for details.

**Types:**
```nim
type
  AccelFullScale* {.size: sizeof(cint).} = enum
    ## Accelerometer full scale range
    ACCEL_RANGE_2G = 0
    ACCEL_RANGE_4G = 1
    ACCEL_RANGE_8G = 2
    ACCEL_RANGE_16G = 3

  GyroFullScale* {.size: sizeof(cint).} = enum
    ## Gyroscope full scale range
    GYRO_RANGE_250DPS = 0
    GYRO_RANGE_500DPS = 1
    GYRO_RANGE_1000DPS = 2
    GYRO_RANGE_2000DPS = 3

  ICM20948I2CTransportConfig* = object
    ## I2C transport configuration
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin
    address*: uint8  # 0x68 (AD0=LOW) or 0x69 (AD0=HIGH)

  ICM20948Config* = object
    ## Main configuration structure
    transport_config*: ICM20948I2CTransportConfig  # or SPITransportConfig
    accel_scale*: AccelFullScale
    gyro_scale*: GyroFullScale
    accel_odr_div*: uint16  # Sample rate divider (1-4095)
    gyro_odr_div*: uint8    # Sample rate divider (0-255)

  ICM20948I2C* = object
    ## Main sensor type (I2C version)

  ICM20948Data* = object
    ## Sensor reading structure
    accel_x*, accel_y*, accel_z*: float32  # m/s²
    gyro_x*, gyro_y*, gyro_z*: float32     # degrees/sec
    mag_x*, mag_y*, mag_z*: float32        # microtesla (µT)
    temp*: float32                          # Celsius
```

**Methods:**
```nim
proc init*(config: ICM20948Config): Result[ICM20948I2C, string]
  ## Initialize the sensor. Returns Result with sensor object or error message.

proc read*(imu: var ICM20948I2C): ICM20948Data
  ## Read accelerometer and gyroscope data (not magnetometer)

proc setupMag*(imu: var ICM20948I2C): bool
  ## Initialize magnetometer (AK09916). Returns true on success.
  ## Requires libDaisy patch to function correctly.

proc readMag*(imu: var ICM20948I2C): tuple[x, y, z: float32]
  ## Read magnetometer data in microtesla (µT)

proc getTemp*(imu: var ICM20948I2C): float32
  ## Read temperature in Celsius
```

**Example:**
```nim
import src/dev/icm20948
import src/libdaisy_i2c

var config: ICM20948Config
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()
config.transport_config.address = 0x68
config.accel_scale = ACCEL_RANGE_4G
config.gyro_scale = GYRO_RANGE_500DPS

let result = init(config)
if result.isOk:
  var imu = result.get()
  discard imu.setupMag()  # Enable magnetometer
  
  while true:
    let data = imu.read()
    let mag = imu.readMag()
    # Use data.accel_x, data.gyro_y, mag.x, etc.
```

---

### APDS9960 Gesture/Light Sensor Module (apds9960.nim)

**Import:**
```nim
import src/dev/apds9960
import src/libdaisy_i2c
```

**Description:**
Multi-function sensor with gesture recognition, proximity detection, RGB color sensing, and ambient light detection. I2C interface only.

**Types:**
```nim
type
  Gesture* {.size: sizeof(cint).} = enum
    ## Recognized gestures
    NONE = 0
    UP = 1
    DOWN = 2
    LEFT = 3
    RIGHT = 4
    NEAR = 5
    FAR = 6

  APDS9960I2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin

  APDS9960Config* = object
    transport_config*: APDS9960I2CTransportConfig

  APDS9960I2C* = object
    ## Main sensor type
```

**Methods:**
```nim
proc init*(config: APDS9960Config): Result[APDS9960I2C, string]
  ## Initialize the sensor

proc enableGesture*(sensor: var APDS9960I2C, enable: bool): bool
  ## Enable or disable gesture detection. Returns true on success.

proc readGesture*(sensor: var APDS9960I2C): Gesture
  ## Read detected gesture. Returns NONE if no gesture detected.

proc readProximity*(sensor: var APDS9960I2C): uint8
  ## Read proximity value (0-255, higher = closer)

proc readColor*(sensor: var APDS9960I2C): tuple[r, g, b, c: uint16]
  ## Read RGBC values (16-bit per channel, c = clear/ambient)

proc setGestureGain*(sensor: var APDS9960I2C, gain: uint8): bool
  ## Set gesture sensitivity (0=1x, 1=2x, 2=4x, 3=8x)
```

**Example:**
```nim
import src/dev/apds9960

var config: APDS9960Config
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()

let result = init(config)
if result.isOk:
  var sensor = result.get()
  discard sensor.enableGesture(true)
  
  while true:
    let gesture = sensor.readGesture()
    if gesture != NONE:
      # Handle UP, DOWN, LEFT, RIGHT, NEAR, FAR
      discard
```

---

### DPS310 Barometric Pressure Sensor Module (dps310.nim)

**Import:**
```nim
import src/dev/dps310
import src/libdaisy_i2c  # or libdaisy_spi
```

**Description:**
High-precision barometric pressure and temperature sensor with altitude calculation. Supports both I2C and SPI interfaces.

**Types:**
```nim
type
  DPS310I2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin

  DPS310Config* = object
    transport_config*: DPS310I2CTransportConfig  # or SPITransportConfig

  DPS310I2C* = object
    ## Main sensor type (I2C version)
```

**Methods:**
```nim
proc init*(config: DPS310Config): Result[DPS310I2C, string]
  ## Initialize the sensor

proc startContinuous*(sensor: var DPS310I2C): bool
  ## Start continuous measurement mode. Returns true on success.

proc getData*(sensor: var DPS310I2C): tuple[pressure: float32, hasData: bool]
  ## Read pressure in Pascals (Pa). hasData indicates if new data available.

proc getTemperatureC*(sensor: var DPS310I2C): float32
  ## Read temperature in Celsius

proc getAltitude*(sensor: var DPS310I2C, seaLevelPressure: float32 = 101325.0): float32
  ## Calculate altitude in meters from current pressure
  ## seaLevelPressure: reference pressure in Pa (default 101325 Pa = 1013.25 hPa)
```

**Example:**
```nim
import src/dev/dps310

var config: DPS310Config
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()

let result = init(config)
if result.isOk:
  var sensor = result.get()
  discard sensor.startContinuous()
  
  while true:
    let (pressure, hasData) = sensor.getData()
    if hasData:
      let temp = sensor.getTemperatureC()
      let altitude = sensor.getAltitude()  # Default sea level pressure
      # pressure in Pa, temp in °C, altitude in meters
```

---

### TLV493D 3D Magnetic Sensor Module (tlv493d.nim)

**Import:**
```nim
import src/dev/tlv493d
import src/libdaisy_i2c
```

**Description:**
3-axis magnetic field sensor with 12-bit resolution. I2C interface only. Useful for position sensing, compass applications, and magnetic field measurement.

**Types:**
```nim
type
  TLV493DI2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin

  TLV493DConfig* = object
    transport_config*: TLV493DI2CTransportConfig

  TLV493DI2C* = object
    ## Main sensor type
```

**Methods:**
```nim
proc init*(config: TLV493DConfig): Result[TLV493DI2C, string]
  ## Initialize the sensor

proc result*(sensor: var TLV493DI2C): tuple[x, y, z: float32]
  ## Read magnetic field values in millitesla (mT)
  ## Returns x, y, z magnetic field components
```

**Example:**
```nim
import src/dev/tlv493d

var config: TLV493DConfig
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()

let result = init(config)
if result.isOk:
  var sensor = result.get()
  
  while true:
    let mag = sensor.result()
    # mag.x, mag.y, mag.z in millitesla (mT)
```

---

### MPR121 Capacitive Touch Sensor Module (mpr121.nim)

**Import:**
```nim
import src/dev/mpr121
import src/libdaisy_i2c
```

**Description:**
12-channel capacitive touch controller. Detects touch/release on 12 independent electrodes. I2C interface only.

**Types:**
```nim
type
  MPR121I2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin

  MPR121Config* = object
    transport_config*: MPR121I2CTransportConfig

  MPR121I2C* = object
    ## Main sensor type
```

**Methods:**
```nim
proc init*(config: MPR121Config): Result[MPR121I2C, string]
  ## Initialize the sensor with default touch/release thresholds

proc touched*(sensor: var MPR121I2C): uint16
  ## Read touch state of all 12 channels as bitmask
  ## Bit 0 = channel 0, bit 1 = channel 1, etc.
  ## Returns 0 if no channels touched

proc setThresholds*(sensor: var MPR121I2C, touch, release: uint8): bool
  ## Set global touch and release thresholds for all channels
  ## Higher values = less sensitive (default: touch=12, release=6)
```

**Example:**
```nim
import src/dev/mpr121

var config: MPR121Config
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()

let result = init(config)
if result.isOk:
  var sensor = result.get()
  
  while true:
    let state = sensor.touched()
    
    # Check individual channels
    if (state and (1 shl 0)) != 0:
      # Channel 0 is touched
      discard
    if (state and (1 shl 5)) != 0:
      # Channel 5 is touched
      discard
```

---

### NeoTrellis 4x4 RGB Button Pad Module (neotrellis.nim)

**Import:**
```nim
import src/dev/neotrellis
import src/libdaisy_i2c
```

**Description:**
4x4 matrix of mechanical switches with RGB LEDs. Based on Adafruit seesaw firmware. I2C interface only.

**Types:**
```nim
type
  NeoTrellisI2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin

  NeoTrellisConfig* = object
    transport_config*: NeoTrellisI2CTransportConfig

  NeoTrellisI2C* = object
    ## Main device type

  KeyEvent* = object
    ## Button event structure
    key*: uint8   # Key number (0-15)
    edge*: uint8  # 0=released, 1=pressed
```

**Methods:**
```nim
proc init*(config: NeoTrellisConfig): Result[NeoTrellisI2C, string]
  ## Initialize the device

proc setPixelColor*(trellis: var NeoTrellisI2C, index: uint8, r, g, b: uint8): bool
  ## Set RGB color for button LED (index 0-15)
  ## Returns true on success

proc show*(trellis: var NeoTrellisI2C): bool
  ## Update all LEDs with set colors. Must call after setPixelColor.

proc readButtons*(trellis: var NeoTrellisI2C): seq[KeyEvent]
  ## Read button events since last call
  ## Returns sequence of press/release events
```

**Example:**
```nim
import src/dev/neotrellis

var config: NeoTrellisConfig
config.transport_config.periph = I2C_1
config.transport_config.speed = I2C_400KHZ
config.transport_config.scl = D11()
config.transport_config.sda = D12()

let result = init(config)
if result.isOk:
  var trellis = result.get()
  
  # Set button 0 to red
  discard trellis.setPixelColor(0, 255, 0, 0)
  discard trellis.show()
  
  while true:
    let events = trellis.readButtons()
    for event in events:
      if event.edge == 1:
        # Button pressed
        discard trellis.setPixelColor(event.key, 0, 255, 0)  # Green
      else:
        # Button released
        discard trellis.setPixelColor(event.key, 0, 0, 0)    # Off
    discard trellis.show()
```

---

## LED Drivers & I/O Expansion Modules

### PCA9685 LED Driver Module (leddriver.nim)

**Import:**
```nim
import src/dev/leddriver
import src/libdaisy_i2c
```

**Description:**
16-channel 12-bit PWM LED driver chip via I2C. Supports multiple chips daisy-chained on a single bus (up to 62 chips). Features double-buffered DMA transfers for flicker-free updates and built-in gamma correction.

**Types:**
```nim
type
  LedDriverConfig*[N: static int] = object
    i2c_config*: I2CConfig
    addresses*: array[N, uint8]  # I2C addresses (0-63, ORed with 0x40)
    oe_pin*: Pin                 # Optional output enable pin
  
  LedDriverPca9685*[N, P: static int] = object
    ## N = number of chips, P = buffer persistence (true/false)
  
  LedDriverDmaBuffer*[N: static int] = array[N, Pca9685TransmitBuffer]
```

**Methods:**
```nim
proc init*[N, P](driver: var LedDriverPca9685[N, P], 
                 config: LedDriverConfig[N],
                 dmaBufferA: ptr LedDriverDmaBuffer[N],
                 dmaBufferB: ptr LedDriverDmaBuffer[N])
  ## Initialize LED driver with double buffers in D2 memory

proc setLed*[N, P](driver: var LedDriverPca9685[N, P], 
                   ledIndex: int, brightness: float32)
  ## Set LED brightness (0.0-1.0) with gamma correction

proc setAllTo*[N, P](driver: var LedDriverPca9685[N, P], brightness: float32)
  ## Set all LEDs to same brightness

proc swapBuffersAndTransmit*[N, P](driver: var LedDriverPca9685[N, P])
  ## Swap draw/transmit buffers and start DMA (non-blocking)
```

**Example:**
```nim
import src/dev/leddriver

# Allocate DMA buffers in D2 memory
var bufferA {.codegenDecl: "$# $# __attribute__((section(\".sram_d2\")))".}: LedDriverDmaBuffer[1]
var bufferB {.codegenDecl: "$# $# __attribute__((section(\".sram_d2\")))".}: LedDriverDmaBuffer[1]

var config: LedDriverConfig[1]
config.i2c_config.periph = I2C_1
config.i2c_config.speed = I2C_400KHZ
config.i2c_config.scl = D11()
config.i2c_config.sda = D12()
config.addresses = [0'u8]  # Address 0 (jumpers open)

var driver: LedDriverPca9685[1, true]
driver.init(config, addr bufferA, addr bufferB)

# Animate LEDs
while true:
  for led in 0 ..< 16:
    driver.setLed(led, 0.5)
  driver.swapBuffersAndTransmit()
```

---

### DotStar RGB LED Module (dotstar.nim)

**Import:**
```nim
import src/dev/dotstar
import src/libdaisy_spi
import src/libdaisy_color  # Optional, for Color type
```

**Description:**
APA102/SK9822 addressable RGB LED strips via SPI. Up to 64 pixels with 24-bit color and 5-bit global brightness control per pixel. No timing constraints (unlike WS2812B).

**Types:**
```nim
type
  ColorOrder* = enum
    RGB, RBG, GRB, GBR, BRG, BGR
  
  DotStarSpiTransportConfig* = object
    periph*: SpiPeripheral
    baud_prescaler*: SpiBaudPrescaler
    clk_pin*: Pin
    data_pin*: Pin
  
  DotStarConfig* = object
    transport_config*: DotStarSpiTransportConfig
    color_order*: ColorOrder
    num_pixels*: uint16  # Max 64
  
  DotStarSpi* = object
  
  DotStarResult* = enum
    DS_OK = 0
    DS_ERR_INVALID_ARGUMENT
    DS_ERR_TRANSPORT
```

**Methods:**
```nim
proc init*(dotstar: var DotStarSpi, config: DotStarConfig): DotStarResult

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, 
                    r, g, b: uint8): DotStarResult
  ## Set pixel RGB color (0-255 per channel)

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, 
                    color: uint32): DotStarResult
  ## Set pixel from 32-bit color value

proc setPixelColor*(dotstar: var DotStarSpi, idx: uint16, 
                    color: Color): DotStarResult
  ## Set pixel from Color object

proc fill*(dotstar: var DotStarSpi, r, g, b: uint8)
  ## Fill all pixels with RGB color

proc clear*(dotstar: var DotStarSpi)
  ## Set all pixels to black

proc setAllGlobalBrightness*(dotstar: var DotStarSpi, brightness: uint16)
  ## Set global brightness for all pixels (0-31)
  ## WARNING: Keep low (<=10) for SK9822-EC20 to avoid overheating

proc show*(dotstar: var DotStarSpi): DotStarResult
  ## Update LED strip with buffered colors
```

**Example:**
```nim
var config: DotStarConfig
config.transport_config.periph = SPI_1
config.transport_config.baud_prescaler = SPI_PS_4
config.transport_config.clk_pin = D10()
config.transport_config.data_pin = D9()
config.color_order = GRB
config.num_pixels = 16

var leds: DotStarSpi
if leds.init(config) == DS_OK:
  leds.setAllGlobalBrightness(5)  # Low brightness
  discard leds.setPixelColor(0, 255, 0, 0)  # Red
  discard leds.fill(0, 255, 0)              # Green all
  discard leds.show()
```

---

### NeoPixel RGB LED Module (neopixel.nim)

**Import:**
```nim
import src/dev/neopixel
import src/libdaisy_i2c
```

**Description:**
Simplified WS2812B control via Adafruit Seesaw I2C bridge. Avoids timing-critical bit-banging by using I2C interface.

**Types:**
```nim
type
  NeoPixelResult* = enum
    NEO_OK = 0
    NEO_ERR = 1
  
  NeoPixelI2CTransportConfig* = object
    periph*: I2CPeripheral
    speed*: I2CSpeed
    scl*: Pin
    sda*: Pin
  
  NeoPixelConfig* = object
    transport_config*: NeoPixelI2CTransportConfig
    num_pixels*: uint16
  
  NeoPixelI2C* = object
```

**Methods:**
```nim
proc init*(config: NeoPixelConfig): Result[NeoPixelI2C, string]

proc setPixelColor*(neo: var NeoPixelI2C, idx: uint16, 
                    r, g, b: uint8): NeoPixelResult

proc show*(neo: var NeoPixelI2C): NeoPixelResult
  ## Update LED strip
```

---

### MCP23017 GPIO Expander Module (mcp23x17.nim)

**Import:**
```nim
import src/dev/mcp23x17
import src/libdaisy_i2c
```

**Description:**
16-bit I/O expander via I2C. Two 8-bit ports (A and B) with configurable direction, pullups, and polarity inversion.

**Types:**
```nim
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
    address*: uint8  # Default 0x27
  
  Mcp23017Config* = object
    transport_config*: Mcp23017TransportConfig
  
  Mcp23017* = object
```

**Methods:**
```nim
proc init*(mcp: var Mcp23017, config: Mcp23017Config)

proc portMode*(mcp: var Mcp23017, port: MCPPort, 
               directions, pullups, inverted: uint8)
  ## Configure 8-bit port (1=input/0=output, 1=pullup, 1=inverted)

proc digitalWrite*(mcp: var Mcp23017, port: MCPPort, value: uint8)
  ## Write 8 bits to port

proc readPort*(mcp: var Mcp23017, port: MCPPort): uint8
  ## Read 8 bits from port

proc read*(mcp: var Mcp23017): uint16
  ## Read all 16 bits (Port A = low byte, Port B = high byte)

proc getPin*(mcp: Mcp23017, pin: uint8): bool
  ## Get single pin state from last read()
```

**Example:**
```nim
var config: Mcp23017Config
config.defaults()

var mcp: Mcp23017
mcp.init(config)

# Port A = inputs with pullups (0xFF = all inputs, 0xFF = all pullups)
mcp.portMode(MCP_PORT_A, 0xFF, 0xFF, 0x00)

# Port B = outputs
mcp.portMode(MCP_PORT_B, 0x00, 0x00, 0x00)

while true:
  let inputs = mcp.readPort(MCP_PORT_A)
  mcp.digitalWrite(MCP_PORT_B, not inputs)  # Mirror inputs to outputs
```

---

### 74HC595 Shift Register Module (sr595.nim)

**Import:**
```nim
import src/dev/sr595
```

**Description:**
8-bit serial-in parallel-out shift register for output expansion. Template-based for compile-time chip count.

**Types:**
```nim
type
  ShiftReg595PinConfig* = object
    data*: Pin    # Serial data
    clock*: Pin   # Shift clock
    latch*: Pin   # Storage register clock
  
  ShiftReg595Config* = object
    pin_config*: ShiftReg595PinConfig
  
  ShiftReg595*[N: static int] = object  # N = number of chips
```

**Methods:**
```nim
proc init*[N](sr: var ShiftReg595[N], config: ShiftReg595Config)

proc set*[N](sr: var ShiftReg595[N], chipIndex: int, value: uint8)
  ## Set 8-bit value for one chip

proc write*[N](sr: var ShiftReg595[N])
  ## Shift out all values to hardware
```

---

### 74HC4021 Shift Register Module (sr4021.nim)

**Import:**
```nim
import src/dev/sr4021
```

**Description:**
8-bit parallel-in serial-out shift register for input expansion. Template-based for compile-time chip count.

**Types:**
```nim
type
  ShiftReg4021PinConfig* = object
    data*: Pin    # Serial data
    clock*: Pin   # Shift clock
    latch*: Pin   # Parallel load
  
  ShiftReg4021Config* = object
    pin_config*: ShiftReg4021PinConfig
  
  ShiftReg4021*[N: static int] = object  # N = number of chips
```

**Methods:**
```nim
proc init*[N](sr: var ShiftReg4021[N], config: ShiftReg4021Config)

proc update*[N](sr: var ShiftReg4021[N])
  ## Read all chips from hardware

proc getPin*[N](sr: ShiftReg4021[N], chipIndex, pinIndex: int): bool
  ## Get single pin state (after update())
```

---

### MAX11300 PIXI Module (max11300.nim)

**Import:**
```nim
import src/dev/max11300
import src/libdaisy_spi
```

**Description:**
20-port programmable mixed-signal I/O for Eurorack modular synthesis. Configurable as ADC/DAC/GPIO with multiple voltage ranges. Simplified blocking SPI implementation.

**Types:**
```nim
type
  MAX11300Result* = enum
    MAX_OK = 0
    MAX_ERR = 1
  
  AdcVoltageRange* = enum
    ADC_0_TO_10 = 0x0100
    ADC_NEG5_TO_5 = 0x0200
    ADC_NEG10_TO_0 = 0x0300
    ADC_0_TO_2P5 = 0x0400
  
  DacVoltageRange* = enum
    DAC_0_TO_10 = 0x0100
    DAC_NEG5_TO_5 = 0x0200
    DAC_NEG10_TO_0 = 0x0300
  
  MAX11300SpiConfig*[N: static int] = object
    periph*: SpiPeripheral
    baud_prescaler*: SpiBaudPrescaler
    nss_pins*: array[N, Pin]  # Chip select pins
    mosi*, miso*, sclk*: Pin
  
  MAX11300Config*[N: static int] = object
    spi_config*: MAX11300SpiConfig[N]
  
  MAX11300*[N: static int] = object
```

**Methods:**
```nim
proc init*[N](pixi: var MAX11300[N], config: MAX11300Config[N]): MAX11300Result

proc configurePinAsAnalogRead*[N](pixi: var MAX11300[N], chipIndex: int, 
                                   pin: int, range: AdcVoltageRange): MAX11300Result
  ## Configure pin as ADC input

proc configurePinAsAnalogWrite*[N](pixi: var MAX11300[N], chipIndex: int,
                                    pin: int, range: DacVoltageRange): MAX11300Result
  ## Configure pin as DAC output

proc readAnalogPinVolts*[N](pixi: var MAX11300[N], chipIndex, pin: int): float32
  ## Read ADC value in volts

proc writeAnalogPinVolts*[N](pixi: var MAX11300[N], chipIndex, pin: int, 
                              volts: float32): MAX11300Result
  ## Write DAC value in volts
```

**Example:**
```nim
var config: MAX11300Config[1]
config.spi_config.defaults()

var pixi: MAX11300[1]
if pixi.init(config) == MAX_OK:
  # Configure for ±5V Eurorack CV
  discard pixi.configurePinAsAnalogRead(0, 0, ADC_NEG5_TO_5)
  discard pixi.configurePinAsAnalogWrite(0, 1, DAC_NEG5_TO_5)
  
  while true:
    let cvIn = pixi.readAnalogPinVolts(0, 0)
    discard pixi.writeAnalogPinVolts(0, 1, cvIn)  # Pass-through
```

---

## System Features & Utilities

### System Module (sys/system.nim)

**Import:**
```nim
import src/libdaisy_system
```

**Description:**
System-level utilities for clock configuration, timing, memory management, and bootloader control on STM32H750.

**System Configuration:**
```nim
type
  SystemConfig* = object
    ## System clock configuration
    ## Access via getSystemConfig()

proc getSystemConfig*(): SystemConfig
  ## Get current system configuration
  ## Pre-configured for 400MHz operation

proc boostSystemConfig*(): SystemConfig
  ## Get boosted configuration (480MHz)
  ## Higher performance, higher power consumption
```

**Timing Functions:**
```nim
proc getNow*(): uint32
  ## Get milliseconds since boot
  ## 32-bit counter, wraps after ~49 days
  
proc getUs*(): uint32
  ## Get microseconds since boot
  ## For high-precision timing
  
proc getTick*(): uint32
  ## Get SysTick counter value
  ## 1kHz tick rate

proc delay*(ms: uint32)
  ## Blocking delay in milliseconds
  
proc delayUs*(us: uint32)
  ## Blocking delay in microseconds
  
proc delayTicks*(ticks: uint32)
  ## Blocking delay in SysTick ticks
```

**Clock Information:**
```nim
proc getSysClkFreq*(): uint32
  ## System clock frequency in Hz
  ## Typically 400MHz or 480MHz

proc getHClkFreq*(): uint32
  ## AHB bus clock frequency in Hz
  
proc getPClk1Freq*(): uint32
  ## APB1 peripheral clock frequency in Hz
  
proc getPClk2Freq*(): uint32
  ## APB2 peripheral clock frequency in Hz
  
proc getTickFreq*(): uint32
  ## SysTick frequency in Hz (typically 1000)
```

**Bootloader Control:**
```nim
type
  BootloaderMode* = enum
    SYSTEM     ## System bootloader (DFU mode)
    INTERNAL   ## Internal flash boot

proc resetToBootloader*(mode: BootloaderMode)
  ## Reboot into bootloader
  ## SYSTEM mode enters DFU for firmware updates
```

**Memory Regions:**
```nim
type
  MemoryRegion* = enum
    INTERNAL_FLASH
    QSPI_FLASH
    SRAM
    SDRAM
    DTCM_RAM
    ITCM_RAM

proc getProgramMemoryRegion*(): MemoryRegion
  ## Get region where code is running from
  
proc getMemoryRegion*(address: pointer): MemoryRegion
  ## Detect which region an address belongs to
```

**Example:**
```nim
import src/libdaisy_system

# Clock info
let cpuFreq = getSysClkFreq()
echo "CPU: ", cpuFreq, " Hz"

# High-precision timing
let start = getUs()
# ... operation ...
let elapsed = getUs() - start
echo "Took: ", elapsed, " microseconds"

# Enter DFU mode for firmware update
resetToBootloader(SYSTEM)
```

---

### DMA Cache Management Module (sys/dma.nim)

**Import:**
```nim
import src/libdaisy_dma
```

**Description:**
Cache coherency management for DMA operations on STM32H750. Ensures data consistency between CPU cache and memory.

**Templates:**
```nim
template dmaClearCache*[T](data: var T)
  ## Flush CPU cache to RAM before DMA TX
  ## Call BEFORE starting DMA transmit

template dmaClearCache*[T](data: var openArray[T])
  ## Array version for buffers

template dmaInvalidateCache*[T](data: var T)
  ## Invalidate CPU cache after DMA RX
  ## Call AFTER DMA receive completes

template dmaInvalidateCache*[T](data: var openArray[T])
  ## Array version for buffers
```

**Usage Pattern:**
```nim
var txBuffer: array[256, uint8]
var rxBuffer: array[256, uint8]

# Before DMA TX: flush to RAM
dmaClearCache(txBuffer)
startDmaTransmit(txBuffer)

# After DMA RX: invalidate cache
waitForDmaReceive()
dmaInvalidateCache(rxBuffer)
# Now rxBuffer contains DMA data
```

**When to Use:**
- **Always** when using DMA on STM32H7 series
- Before DMA transmit: `dmaClearCache()`
- After DMA receive: `dmaInvalidateCache()`
- Not needed for non-DMA transfers

---

### V/Oct Calibration Module (nimphea_voct_calibration.nim)

**Import:**
```nim
import src/libdaisy_voct_calibration
```

**Description:**
1V/octave pitch CV calibration for Eurorack modular synthesis. Converts analog CV to accurate MIDI note numbers using two-point calibration.

**Type:**
```nim
type
  VoctCalibration* = object
    ## Calibration state (opaque C++ object)
```

**Calibration:**
```nim
proc record*(this: var VoctCalibration, val1V, val3V: cfloat): bool
  ## Perform two-point calibration
  ## val1V: ADC reading at 1.000V
  ## val3V: ADC reading at 3.000V
  ## Returns: true on success

proc setData*(this: var VoctCalibration, scale, offset: cfloat)
  ## Manually set calibration parameters
  
proc getData*(this: var VoctCalibration, 
              scale, offset: var cfloat): bool
  ## Retrieve calibration parameters
```

**Processing:**
```nim
proc processInput*(this: var VoctCalibration, inval: cfloat): cfloat
  ## Convert calibrated CV to MIDI note number
  ## inval: Raw ADC voltage (0-5V range)
  ## Returns: MIDI note (0-127, float for pitch bend)
```

**Helpers:**
```nim
proc midiNoteToFreq*(midiNote: float32): float32
  ## Convert MIDI note to frequency in Hz
  ## Supports fractional notes (pitch bend)

proc midiNoteToName*(midiNote: int): string
  ## Convert MIDI note to name (e.g., "C4", "A#5")
  
proc cvToNoteName*(this: var VoctCalibration, 
                   cvInput: float32): string
  ## Direct CV → note name conversion

proc cvToMidiNote*(this: var VoctCalibration,
                   cvInput: float32): float32
  ## Alias for processInput()

proc isCalibrated*(this: var VoctCalibration): bool
  ## Check if calibration has been performed
```

**Example:**
```nim
import src/libdaisy_voct_calibration

var voct: VoctCalibration

# Calibration procedure:
# 1. User sets CV to 1.000V
let adc1V = readAdc()  # e.g., 0.2 (on 0-5V scale)

# 2. User sets CV to 3.000V  
let adc3V = readAdc()  # e.g., 0.6

# 3. Record calibration
if voct.record(adc1V, adc3V):
  echo "Calibration successful!"

# Use calibrated CV:
while true:
  let rawCv = readAdc()
  let midiNote = voct.processInput(rawCv)
  let noteName = voct.cvToNoteName(rawCv)
  echo noteName, " (MIDI ", midiNote, ")"
```

---

### Scoped IRQ Blocking Module (nimphea_scoped_irq.nim)

**Import:**
```nim
import src/libdaisy_scoped_irq
```

**Description:**
RAII-style interrupt blocking for thread-safe critical sections. Automatically restores interrupt state on scope exit.

**Templates:**
```nim
template withoutInterrupts*(body: untyped)
  ## Execute code block with interrupts disabled
  ## Interrupts automatically restored on exit

template criticalSection*(body: untyped)
  ## Alias for withoutInterrupts (clearer naming)

template atomicBlock*(body: untyped)
  ## Alias for withoutInterrupts (C++ style)
```

**Example:**
```nim
import src/libdaisy_scoped_irq

var sharedCounter: int = 0

proc incrementSafe() =
  # Critical section - no interrupts
  withoutInterrupts:
    sharedCounter += 1
    # Interrupts automatically restored here
  
  # Interrupts enabled again

# Alternative names:
criticalSection:
  # Modify shared data safely
  sharedCounter = 42

atomicBlock:
  # Atomic operation
  sharedCounter *= 2
```

**Use Cases:**
- Modifying variables accessed by interrupts
- Multi-step operations that must be atomic
- Protecting hardware register sequences

**Important:**
- Keep critical sections **short** (microseconds)
- Long blocks will affect real-time performance
- Nested blocks are safe (uses RAII)

---

### Logger Module (hid/logger.nim)

**Import:**
```nim
import src/libdaisy_logger
```

**Description:**
USB and UART logging for debugging. String-based API (use Nim's `strformat` for formatting, NOT C printf).

**Logger Types:**
```nim
type
  LoggerInternal*  ## USB internal port (most common)
  LoggerExternal*  ## USB external port (if available)
  LoggerSemihost*  ## Debugger stdout
  LoggerNone*      ## Disabled (zero overhead)
  
  # Convenient aliases:
  UsbLogger* = LoggerInternal
  NullLogger* = LoggerNone
```

**Methods (all loggers):**
```nim
proc startLog*(T: typedesc[LoggerInternal], 
               wait_for_pc: bool = false)
  ## Initialize logging
  ## wait_for_pc: Block until terminal connects

proc printLine*(T: typedesc[LoggerInternal], 
                format: cstring)
  ## Print with newline

proc print*(T: typedesc[LoggerInternal], 
            format: cstring)
  ## Print without newline

proc log*(T: typedesc[LoggerInternal], msg: string)
  ## Convenience: print Nim string with newline
```

**String Formatting:**
Use Nim's `strformat` module, NOT C printf:
```nim
import std/strformat
import src/libdaisy_logger

UsbLogger.startLog(false)

# Option 1: Direct literals
UsbLogger.printLine("Hello from Daisy!")

# Option 2: String concatenation
let value = 42
UsbLogger.printLine(cstring("Value: " & $value))

# Option 3: strformat (recommended)
let temp = 25.3
let msg = &"Temperature: {temp:.1f} °C"
UsbLogger.printLine(cstring(msg))

# Option 4: log() helper
UsbLogger.log(&"Counter: {counter}")
```

**Production Builds:**
```nim
# Conditional logging:
when defined(release):
  type AppLogger = NullLogger  # Zero overhead
else:
  type AppLogger = UsbLogger   # Debug builds

# Use throughout code:
AppLogger.log("Debug message")  # No-op in release
```

**Example:**
```nim
import src/libdaisy_logger
import std/strformat

# Start logger (non-blocking)
UsbLogger.startLog(false)

UsbLogger.printLine("=== System Start ===")

var counter = 0
while true:
  let msg = &"Loop {counter}"
  UsbLogger.log(msg)
  counter += 1
  delay(1000)
```

---

### File Table Module (nimphea_filetable.nim)

**Import:**
```nim
import src/libdaisy_file_table
```

**Description:**
FAT filesystem file indexing for audio sample libraries on SD card or QSPI flash. Efficiently manages file lists with compile-time size limits.

**Type:**
```nim
type
  FileTable*[N: static int] = object
    ## File index with max N entries
    ## N is compile-time constant
```

**Methods:**
```nim
proc fill*(ft: var FileTable, path, extension: cstring): bool
  ## Scan directory for files with extension
  ## path: Directory to scan (e.g., "/samples")
  ## extension: Filter (e.g., ".wav", ".raw")
  ## Returns: true on success

proc getFileCount*(ft: FileTable): int
  ## Number of files found (0 to N)

proc getFileName*(ft: FileTable, index: int): string
  ## Get filename at index
  ## Returns empty string if index out of range

proc getFileSize*(ft: FileTable, index: int): uint32
  ## Get file size in bytes
  ## Returns 0 if index out of range
  
proc getFilePath*(ft: FileTable, index: int): string
  ## Get full path to file
```

**Iterator:**
```nim
iterator items*(ft: FileTable): tuple[index: int, 
                                      name: string,
                                      size: uint32]
  ## Iterate over all files
```

**Example:**
```nim
import src/libdaisy_file_table

# Create table for up to 128 samples
var samples: FileTable[128]

# Scan SD card for WAV files
if samples.fill("/samples", ".wav"):
  echo "Found ", samples.getFileCount(), " samples"
  
  # List all files
  for (idx, name, size) in samples.items():
    echo idx, ": ", name, " (", size, " bytes)"
  
  # Access specific file
  let firstSample = samples.getFileName(0)
  echo "Loading: ", firstSample
```

**Use Cases:**
- Audio sample libraries for samplers
- Preset management systems
- File browser UIs
- Batch processing workflows

---

## UI Framework & Display Drivers

### Overview

introduces a comprehensive UI framework for building multi-page user interfaces with menus, custom pages, and event handling. Includes drivers for multiple OLED displays and ergonomic Nim helper layers.

**Key Features:**
- Multiple display drivers (SH1106, SSD1327, SSD1351)
- Event-driven architecture (button/encoder/pot events)
- Full menu system with value editing
- Multi-page UI coordinator
- File indexing for SD cards
- Ergonomic Nim layers (DSL, helpers, concepts)

---

### Display Drivers

#### SH1106 OLED Driver (oled_sh1106.nim)

**Import:**
```nim
import src/dev/oled_sh1106
```

**Description:**
Monochrome OLED driver for SH1106 controller (128x64 or 128x32). Supports both I2C and SPI interfaces.

**Types:**
```nim
type
  SH1106I2c128x64* = object
    ## 128x64 I2C display
  
  SH1106I2c128x32* = object
    ## 128x32 I2C display
  
  SH1106Spi128x64* = object
    ## 128x64 SPI display (4-wire)
```

**Initialization:**
```nim
proc initSH1106I2c*(width, height: csize_t, 
                    i2cAddress: uint8 = 0x3C): SH1106I2c128x64
  ## Initialize I2C display
  ## Default address: 0x3C (or 0x3D for some modules)

proc initSH1106Spi*(width, height: csize_t,
                    dcPin, resetPin: Pin): SH1106Spi128x64
  ## Initialize SPI display (requires DC and RESET pins)
```

**Graphics Methods:**
```nim
proc fill*(this: var SH1106I2c128x64, on: bool)
  ## Fill entire display (true=white, false=black)

proc drawPixel*(this: var SH1106I2c128x64, x, y: uint32, on: bool)
  ## Set single pixel

proc drawLine*(this: var SH1106I2c128x64, x1, y1, x2, y2: uint32, on: bool)
  ## Draw line between two points

proc drawRect*(this: var SH1106I2c128x64, x, y, width, height: uint32, on: bool)
  ## Draw rectangle outline

proc fillRect*(this: var SH1106I2c128x64, x, y, width, height: uint32, on: bool)
  ## Draw filled rectangle

proc drawCircle*(this: var SH1106I2c128x64, x, y, radius: uint32, on: bool)
  ## Draw circle outline

proc fillCircle*(this: var SH1106I2c128x64, x, y, radius: uint32, on: bool)
  ## Draw filled circle

proc update*(this: var SH1106I2c128x64)
  ## Send framebuffer to display (call after drawing)
```

**Example:**
```nim
import src/dev/oled_sh1106

var display = initSH1106I2c(128, 64)

display.fill(false)  # Clear screen
display.fillRect(10, 10, 50, 20, true)  # Draw box
display.drawCircle(90, 32, 15, true)    # Draw circle
display.update()  # Show on screen
```

---

#### SSD1327 OLED Driver (oled_ssd1327.nim)

**Import:**
```nim
import src/dev/oled_ssd1327
```

**Description:**
Grayscale OLED driver for SSD1327 controller (128x128, 16 gray levels). SPI interface only.

**Types:**
```nim
type
  SSD1327Spi128x128* = object
    ## 128x128 SPI grayscale display
```

**Initialization:**
```nim
proc initSSD1327Spi*(width, height: csize_t,
                     dcPin, resetPin: Pin): SSD1327Spi128x128
  ## Initialize SPI display
```

**Graphics Methods:**
```nim
# Same as SH1106, plus:

proc drawPixel*(this: var SSD1327Spi128x128, x, y: uint32, 
                brightness: uint8)
  ## Set pixel with 4-bit brightness (0-15)

proc fillRect*(this: var SSD1327Spi128x128, x, y, width, height: uint32,
               brightness: uint8)
  ## Draw filled rectangle with gray level

proc drawGradient*(this: var SSD1327Spi128x128, x, y, width, height: uint32,
                   start, stop: uint8)
  ## Draw vertical gradient from start to stop brightness
```

**Example:**
```nim
import src/dev/oled_ssd1327

var display = initSSD1327Spi(128, 128, dcPin, resetPin)

display.fill(false)
# Draw gradient from black (0) to white (15)
display.drawGradient(0, 0, 128, 128, 0, 15)
display.update()
```

---

#### SSD1351 OLED Driver (oled_ssd1351.nim)

**Import:**
```nim
import src/dev/oled_ssd1351
```

**Description:**
Full RGB color OLED driver for SSD1351 controller (128x128, 65K colors). SPI interface only.

**Types:**
```nim
type
  SSD1351Spi128x128* = object
    ## 128x128 SPI RGB color display
```

**Initialization:**
```nim
proc initSSD1351Spi*(width, height: csize_t,
                     dcPin, resetPin: Pin): SSD1351Spi128x128
```

**Graphics Methods:**
```nim
# Same as grayscale, plus:

proc drawPixel*(this: var SSD1351Spi128x128, x, y: uint32,
                r, g, b: uint8)
  ## Set pixel with RGB color (8-bit per channel)

proc fillRect*(this: var SSD1351Spi128x128, x, y, width, height: uint32,
               r, g, b: uint8)
  ## Draw filled rectangle with RGB color

proc drawLine*(this: var SSD1351Spi128x128, x1, y1, x2, y2: uint32,
               r, g, b: uint8)
  ## Draw colored line
```

**Example:**
```nim
import src/dev/oled_ssd1351

var display = initSSD1351Spi(128, 128, dcPin, resetPin)

display.fill(false)
# Red square
display.fillRect(10, 10, 50, 50, 255, 0, 0)
# Green circle
display.fillCircle(90, 64, 20, 0, 255, 0)
# Blue line
display.drawLine(0, 0, 127, 127, 0, 0, 255)
display.update()
```

---

### Display Common Utilities (hid/disp/graphics_common.nim)

**Import:**
```nim
import src/libdaisy_display_common
```

**Description:**
Shared utilities for all displays: Rectangle type, alignment helpers, common operations.

**Rectangle Type:**
```nim
type
  Rectangle* = object
    x*, y*: int32
    width*, height*: int32

proc initRectangle*(x, y, width, height: int32): Rectangle

proc getX2*(rect: Rectangle): int32
  ## Right edge (x + width)

proc getY2*(rect: Rectangle): int32
  ## Bottom edge (y + height)

proc getCenter*(rect: Rectangle): tuple[x, y: int32]
  ## Center point

proc contains*(rect: Rectangle, x, y: int32): bool
  ## Check if point is inside

proc intersects*(a, b: Rectangle): bool
  ## Check if rectangles overlap
```

**Alignment Helpers:**
```nim
type
  Alignment* = enum
    alignLeft, alignCenter, alignRight, alignTop, alignBottom

proc alignHorizontal*(container, item: Rectangle, 
                     align: Alignment): int32
  ## Calculate X position for horizontal alignment

proc alignVertical*(container, item: Rectangle,
                   align: Alignment): int32
  ## Calculate Y position for vertical alignment
```

**Example:**
```nim
import src/libdaisy_display_common

let screen = initRectangle(0, 0, 128, 64)
let box = initRectangle(0, 0, 40, 20)

# Center box on screen
let centerX = screen.alignHorizontal(box, alignCenter)
let centerY = screen.alignVertical(box, alignTop)

display.fillRect(centerX, centerY, box.width, box.height, true)
```

---

### UI Events (nimphea_ui_events.nim)

**Import:**
```nim
import src/libdaisy_ui_events
```

**Description:**
Event queue system for UI interactions. Handles button presses, encoder rotation, potentiometer changes.

**Event Queue:**
```nim
type
  UiEventQueue* = object
    ## FIFO queue for UI events

proc initUiEventQueue*(): UiEventQueue
  ## Create new event queue

proc addButtonPressed*(queue: var UiEventQueue, id: uint16, 
                      presses: uint16, isRetriggering: bool)
  ## Add button press event

proc addButtonReleased*(queue: var UiEventQueue, id: uint16)
  ## Add button release event

proc addEncoderIncrement*(queue: var UiEventQueue, id: uint16,
                         increment: int32, velocity: int32)
  ## Add encoder rotation event

proc addPotChanged*(queue: var UiEventQueue, id: uint16, value: cfloat)
  ## Add potentiometer change event

proc flush*(queue: var UiEventQueue)
  ## Clear all events
```

**Event Processing:**
```nim
proc process*(queue: var UiEventQueue, handler: UiEventHandler)
  ## Process events with callback

type UiEventHandler* = proc(event: UiEvent) {.cdecl.}
```

**Example:**
```nim
import src/libdaisy_ui_events

var eventQueue = initUiEventQueue()

# Button pressed
eventQueue.addButtonPressed(0, 1, false)

# Encoder turned
eventQueue.addEncoderIncrement(1, 5, 10)

# Process events
proc handleEvent(event: UiEvent) {.cdecl.} =
  case event.type
  of buttonPress:
    echo "Button ", event.buttonId, " pressed"
  of encoderIncrement:
    echo "Encoder turned by ", event.increment
  else:
    discard

eventQueue.process(handleEvent)
```

---

### UI Controls (nimphea_ui_controls.nim)

**Import:**
```nim
import src/libdaisy_ui_controls
```

**Description:**
High-level control monitoring with debouncing, multi-press detection, hysteresis.

**Button Monitor:**
```nim
type
  ButtonMonitor* = object
    ## Debounced button with multi-press detection

proc initButtonMonitor*(id: uint16, pin: Pin, 
                       eventQueue: ptr UiEventQueue): ButtonMonitor

proc process*(monitor: var ButtonMonitor)
  ## Call in main loop to update state

proc wasPressed*(monitor: ButtonMonitor): bool
  ## Check if button was pressed since last check

proc getPressCount*(monitor: ButtonMonitor): uint16
  ## Number of rapid presses (double-click, etc.)
```

**Potentiometer Monitor:**
```nim
type
  PotMonitor* = object
    ## ADC input with hysteresis and smoothing

proc initPotMonitor*(id: uint16, adcChannel: uint8,
                    eventQueue: ptr UiEventQueue,
                    hysteresis: cfloat = 0.01): PotMonitor

proc process*(monitor: var PotMonitor)
  ## Call in main loop

proc getValue*(monitor: PotMonitor): cfloat
  ## Current value (0.0 - 1.0)

proc hasChanged*(monitor: PotMonitor): bool
  ## Check if value changed significantly
```

**Example:**
```nim
import src/libdaisy_ui_controls

var eventQueue = initUiEventQueue()
var button = initButtonMonitor(0, getPin(0), addr eventQueue)
var knob = initPotMonitor(0, 0, addr eventQueue, 0.02)

while true:
  button.process()
  knob.process()
  
  if button.wasPressed():
    echo "Button pressed ", button.getPressCount(), " times"
  
  if knob.hasChanged():
    echo "Knob value: ", knob.getValue()
  
  delay(10)
```

---

### Menu System (nimphea_menu.nim)

**Import:**
```nim
import src/libdaisy_menu
```

**Description:**
Full-featured menu system with value editing, checkboxes, callbacks, submenus.

**Menu Types:**
```nim
type
  FullScreenItemMenu* = object
    ## Full-screen menu with item list

  MappedFloatValue* = object
    ## Editable numeric value with mapping

  MappedValueMapping* = enum
    lin    ## Linear mapping
    log    ## Logarithmic (good for frequency)
    pow2   ## Power-of-2 (good for time)
```

**Value Creation:**
```nim
proc createMappedFloatValue*(minVal, maxVal, defaultVal: cfloat,
                            mapping: MappedValueMapping = lin,
                            unitStr: cstring = "",
                            numDecimals: uint8 = 1): ptr MappedFloatValue

# Helpers
proc get*(value: var MappedFloatValue): cfloat
proc set*(value: var MappedFloatValue, newVal: cfloat)
proc step*(value: var MappedFloatValue, steps: int16, coarse: bool)
```

**Menu Item Creation:**
```nim
proc createValueItemFloat*(text: cstring, 
                          value: ptr MappedFloatValue): MenuItemConfig
  ## Value editing item

proc createCheckboxItem*(text: cstring, 
                        valuePtr: ptr bool): MenuItemConfig
  ## Boolean toggle item

proc createCallbackItem*(text: cstring,
                        callback: proc(ctx: pointer) {.cdecl.},
                        context: pointer): MenuItemConfig
  ## Action button item

proc createCloseItem*(text: cstring): MenuItemConfig
  ## Menu exit item
```

**Menu Initialization:**
```nim
proc init*(menu: var FullScreenItemMenu, 
          items: ptr MenuItemConfig, itemCount: csize_t,
          orientation: MenuOrientation, allowEditing: bool)

type MenuOrientation* = enum
  upDownSelectLeftRightModify
  leftRightSelectUpDownModify
```

**Menu Control:**
```nim
proc onOkayButton*(menu: var FullScreenItemMenu, 
                  presses: uint8, retriggering: bool): bool

proc onCancelButton*(menu: var FullScreenItemMenu,
                    presses: uint8, retriggering: bool): bool

proc onArrowButton*(menu: var FullScreenItemMenu,
                   direction: ArrowButtonType,
                   presses: uint8, retriggering: bool): bool

proc selectItem*(menu: var FullScreenItemMenu, index: cint)
```

**Example:**
```nim
import src/libdaisy_menu

# Create values
{.emit: """
  `volumeValue` = new daisy::MappedFloatValue(
    0.0f, 100.0f, 50.0f, 
    daisy::MappedFloatValue::Mapping::lin, 
    "%", 0, false
  );
""".}

var muteEnabled = false

# Create menu items
var items = [
  createValueItemFloat("Volume", volumeValue),
  createCheckboxItem("Mute", addr muteEnabled),
  createCloseItem("Exit")
]

# Initialize menu
var menu: FullScreenItemMenu
menu.init(items[0].addr, 3, upDownSelectLeftRightModify, true)
menu.selectItem(0)

# Handle button presses
discard menu.onArrowButton(up, 1, false)  # Navigate up
discard menu.onOkayButton(1, false)       # Enter edit mode
```

---

### UI Core (nimphea_ui_core.nim)

**Import:**
```nim
import src/libdaisy_ui_core
```

**Description:**
Multi-page UI coordinator. Manages page stack, routes events, coordinates display updates.

**UI Type:**
```nim
type
  UI* = object
    ## Main UI coordinator

  UiPage* = object
    ## Base class for custom pages (C++ virtual)

  UiCanvasDescriptor* = object
    ## Display canvas configuration
    id*: uint16
    handle*: pointer
    updateRateHz*: uint16
```

**Canvas Creation:**
```nim
proc createCanvasDescriptor*(id: uint16, displayPtr: pointer,
                            updateRate: uint16,
                            clearFunc, flushFunc: proc(canvas: ptr UiCanvasDescriptor) {.cdecl.}
                           ): UiCanvasDescriptor
```

**UI Initialization:**
```nim
proc initUI*(): UI

proc init*(ui: var UI, eventQueue: var UiEventQueue,
          controlIds: UiSpecialControlIds,
          canvases: openArray[UiCanvasDescriptor],
          primaryDisplayId: uint16)

type UiSpecialControlIds* = object
  okBttnId*, cancelBttnId*: uint16
  upBttnId*, downBttnId*: uint16
  leftBttnId*, rightBttnId*: uint16
```

**Page Management:**
```nim
proc openPage*(ui: var UI, page: var UiPage)
  ## Push page onto stack

proc closePage*(ui: var UI, page: var UiPage)
  ## Pop page from stack

proc clearPageStack*(ui: var UI)
  ## Remove all pages
```

**Processing:**
```nim
proc process*(ui: var UI)
  ## Call in main loop - processes events and updates displays
```

**Custom Page Pattern:**
```nim
# 1. Forward declare in TYPESECTION
{.emit: """/*TYPESECTION*/
struct MyCustomPage;
""".}

# 2. Declare Nim callback
proc myPageDraw(page: ptr MyCustomPage, 
                canvas: ptr UiCanvasDescriptor) {.exportc, cdecl.}

# 3. Define C++ struct
{.emit: """
struct MyCustomPage : public daisy::UiPage {
    int counter = 0;
    
    void Draw(const daisy::UiCanvasDescriptor& canvas) override {
        MyCustomPage_Draw(this, &canvas);
    }
};
""".}

# 4. Implement callback
proc myPageDraw(page: ptr MyCustomPage, canvas: ptr UiCanvasDescriptor) =
  var counter: cint
  {.emit: "`counter` = `page`->counter;".}
  # Draw using counter...
  {.emit: "`page`->counter++;".}
```

**Example:**
```nim
import src/libdaisy_ui_core
import src/libdaisy_ui_events

var eventQueue = initUiEventQueue()
var ui = initUI()

var controlIds = initUiSpecialControlIds()
controlIds.okBttnId = 0
controlIds.cancelBttnId = 1

var canvases = [
  createCanvasDescriptor(0, addr display, 30, nil, nil)
]

ui.init(eventQueue, controlIds, canvases, 0)

# Main loop
while true:
  # Add events to queue...
  ui.process()  # Process events, update displays
  delay(10)
```

---

### FileTable Module (nimphea_filetable.nim)

**Import:**
```nim
import src/libdaisy_filetable
```

**Description:**
SD card file indexing system. Scans directories and creates indexed lists of files for quick access.

**Types:**
```nim
type
  FileTable8*, FileTable16*, FileTable32*,
  FileTable64*, FileTable128* = object
    ## File tables with max 8, 16, 32, 64, or 128 slots
```

**Construction:**
```nim
proc createFileTable32*(): FileTable32
  ## Create empty table
```

**Methods:**
```nim
proc clear*(table: var FileTable32)
  ## Remove all entries

proc fill*(table: var FileTable32, path, endswith: cstring): bool
  ## Scan directory for files
  ## path: Directory to scan (e.g., "/audio")
  ## endswith: Extension filter (e.g., ".wav", nil for all)
  ## Returns: true on success

proc getNumFiles*(table: FileTable32): csize_t
  ## Count of files in table

proc getFileName*(table: FileTable32, idx: csize_t): cstring
  ## Get filename at index (no path)

proc getFileSize*(table: FileTable32, idx: csize_t): csize_t
  ## Get file size in bytes

proc isFileInSlot*(table: FileTable32, idx: csize_t): bool
  ## Check if index has valid file
```

**Example:**
```nim
import src/libdaisy_filetable

var fileTable = createFileTable32()

# Scan for WAV files
if fileTable.fill("/audio", ".wav"):
  let count = fileTable.getNumFiles()
  echo "Found ", count, " files"
  
  for i in 0..<count:
    let name = fileTable.getFileName(i)
    let size = fileTable.getFileSize(i)
    echo i, ": ", name, " (", size, " bytes)"
```

---

### Ergonomic Nim Layers

#### Display Helpers (ui/display.nim)

**Import:**
```nim
import src/ui/display
```

**Templates:**
```nim
template withDisplay*(display, body: untyped): untyped =
  ## Auto-update pattern
  ## Executes body, then calls display.update()
  body
  display.update()

template clearAndDraw*(display, body: untyped): untyped =
  ## Clear, draw, update pattern
  display.fill(false)
  body
  display.update()
```

**Example:**
```nim
import src/ui/display

display.clearAndDraw:
  display.fillRect(10, 10, 50, 20, true)
  display.drawCircle(90, 32, 15, true)
# Automatically cleared and updated
```

---

#### Event Dispatcher (ui/events.nim)

**Import:**
```nim
import src/ui/events
```

**Description:**
Closure-based event handling for cleaner code.

**Event Dispatcher:**
```nim
type
  EventDispatcher* = object
    ## Manages event callbacks

proc createEventDispatcher*(queue: var UiEventQueue): EventDispatcher

proc onButtonPress*(dispatcher: var EventDispatcher,
                   handler: proc(id: uint16, presses: uint16))
  ## Register button press handler

proc onEncoder*(dispatcher: var EventDispatcher,
               handler: proc(id: uint16, increment, velocity: int32))
  ## Register encoder handler

proc onPotChange*(dispatcher: var EventDispatcher,
                 handler: proc(id: uint16, value: cfloat))
  ## Register pot change handler

proc process*(dispatcher: var EventDispatcher)
  ## Process all events in queue
```

**Example:**
```nim
import src/ui/events

var dispatcher = createEventDispatcher(eventQueue)

dispatcher.onButtonPress proc(id: uint16, presses: uint16) =
  echo "Button ", id, " pressed ", presses, " times"

dispatcher.onEncoder proc(id: uint16, inc, vel: int32) =
  volume += inc
  echo "Volume: ", volume

# In main loop
while true:
  # Add events to queue...
  dispatcher.process()
```

---

#### Menu Builder DSL (ui/menu_builder.nim)

**Import:**
```nim
import src/ui/menu_builder
```

**Description:**
Zero-allocation declarative menu construction using static macros. Guaranteed memory safety for embedded use.

**Value Helpers:**
```nim
template linear*(min, max, initial: cfloat, unit: string = ""): MappedFloatValue
  ## Create linear mapped value (e.g. 0-100%)

template logarithmic*(min, max, initial: cfloat, unit: string = ""): MappedFloatValue
  ## Create logarithmic mapped value (e.g. frequency)
```

**Types:**
```nim
type
  BuiltMenu*[N: static int] = object
    menu*: FullScreenItemMenu
    items*: array[N, MenuItemConfig]

converter toMenu*[N](bm: var BuiltMenu[N]): var FullScreenItemMenu
  ## Auto-convert to FullScreenItemMenu for API compatibility
```

**DSL Macro:**
```nim
macro defineMenu*(varName: untyped, body: untyped): untyped
  ## Define a statically allocated menu.
  ## Generates 'var varName: BuiltMenu[N]' in current scope.
```

**Usage Example:**
```nim
import src/ui/menu_builder

# 1. Define variables
var volume = linear(0.0, 100.0, 50.0, "%")
var mute = false

# 2. Define menu (generates 'mainMenu' variable)
defineMenu mainMenu:
  value "Volume", volume
  checkbox "Mute", mute
  action "Save", saveSettings
  close "Exit"

# 3. Use menu
ui.openPage(addr mainMenu.menu)
```

**Description:**
Declarative menu construction with pre-configured value types.

**Value Presets:**
```nim
proc volumeValue*(initial: cfloat = 50.0): MappedFloatValue
  ## 0-100%, linear, 0 decimals

proc gainValue*(initial: cfloat = 0.0): MappedFloatValue
  ## -60 to +12 dB, linear, 1 decimal

proc frequencyValue*(initial: cfloat = 1000.0): MappedFloatValue
  ## 20-20000 Hz, logarithmic, 0 decimals

proc percentValue*(initial: cfloat = 50.0): MappedFloatValue
  ## 0-100%, linear, 1 decimal
```

**Builder Pattern:**
```nim
type
  MenuBuilder* = object

proc createMenuBuilder*(title: string): MenuBuilder

proc addValueItem*(builder: var MenuBuilder, 
                  text: string, value: var MappedFloatValue)

proc addCheckbox*(builder: var MenuBuilder,
                 text: string, valuePtr: ptr bool)

proc addAction*(builder: var MenuBuilder, text: string,
               callback: proc(ctx: pointer) {.cdecl.})

proc build*(builder: var MenuBuilder): FullScreenItemMenu
```

**Example (simplified concept):**
```nim
import src/ui/menu_builder

var builder = createMenuBuilder("Settings")
var volume = volumeValue(75.0)
var mute = false

builder.addValueItem("Volume", volume)
builder.addCheckbox("Mute", addr mute)
builder.addAction("Save", saveCallback)

var menu = builder.build()
```

---

## Advanced Peripherals & Storage

introduced advanced audio peripherals, filesystem support, enhanced MIDI I/O, and comprehensive module quality improvements.

### SAI Module (nimphea_sai.nim)

Serial Audio Interface for custom audio configurations.

**Import:**
```nim
import src/libdaisy_sai
```

#### SaiHandle Object

Low-level SAI peripheral for I2S audio communication.

**Note:** For most applications, use the high-level audio API in `nimphea.nim`. This module is for advanced custom audio configurations.

**Configuration:**
```nim
type
  SaiHandle* {.importcpp: "daisy::SaiHandle", header: saiHeader,
               bycopy.} = object

  SaiConfig* {.importcpp: "daisy::SaiHandle::Config", header: saiHeader,
               bycopy.} = object
    periph*: Peripheral
    sr*: SampleRate
    bit_depth*: BitDepth
    a_sync*: SyncConfig
    b_sync*: SyncConfig
    a_dir*: Direction
    b_dir*: Direction
    pin_config*: PinConfig

  Peripheral* {.size: sizeof(cint).} = enum
    SAI_1 = 0
    SAI_2 = 1

  SampleRate* {.size: sizeof(cint).} = enum
    SAI_8KHZ = 0
    SAI_16KHZ
    SAI_32KHZ
    SAI_48KHZ
    SAI_96KHZ

  BitDepth* {.size: sizeof(cint).} = enum
    SAI_16BIT = 0
    SAI_24BIT
    SAI_32BIT

  SyncConfig* {.size: sizeof(cint).} = enum
    MASTER = 0
    SLAVE
    INTERNAL

  Direction* {.size: sizeof(cint).} = enum
    TRANSMIT = 0
    RECEIVE
```

**Initialization:**
```nim
proc init*(this: var SaiHandle, config: SaiConfig): Result {.
    importcpp: "Init", header: saiHeader.}
  ## Initialize SAI peripheral with configuration
  ##
  ## Returns:
  ##   OK on success, ERR on failure
```

**DMA Operations:**
```nim
type
  SaiCallbackFunctionPtr* = proc(inputBuf, outputBuf: ptr int32, 
                                  size: csize_t) {.cdecl.}

proc startDma*(this: var SaiHandle, bufferRx, bufferTx: ptr int32,
               size: csize_t, callback: SaiCallbackFunctionPtr): Result {.
    importcpp: "StartDma", header: saiHeader.}
  ## Start DMA audio transfer
  ##
  ## Parameters:
  ##   bufferRx: Receive buffer in DMA memory
  ##   bufferTx: Transmit buffer in DMA memory  
  ##   size: Buffer size in samples
  ##   callback: Audio processing callback

proc stopDma*(this: var SaiHandle): Result {.
    importcpp: "StopDma", header: saiHeader.}
  ## Stop DMA transfer
```

**Pin Configuration:**
```nim
type
  PinConfig* {.importcpp: "daisy::SaiHandle::Config::PinConfig",
               header: saiHeader, bycopy.} = object
    fs*: Pin      ## Frame sync (LRCLK)
    mclk*: Pin    ## Master clock
    sck*: Pin     ## Bit clock (BCLK)
    sa*: Pin      ## Data A (typically receive)
    sb*: Pin      ## Data B (typically transmit)
```

**Example:**
```nim
import nimphea, libdaisy_sai

var sai: SaiHandle
var config = newSaiConfig()

# Configure for 48kHz, 24-bit, I2S master mode
config.periph = SAI_1
config.sr = SAI_48KHZ
config.bit_depth = SAI_24BIT
config.a_sync = MASTER
config.b_sync = SLAVE
config.a_dir = RECEIVE
config.b_dir = TRANSMIT

# Set pin configuration
config.pin_config.fs = initPin(PORTE, 4)
config.pin_config.mclk = initPin(PORTE, 2)
config.pin_config.sck = initPin(PORTE, 5)
config.pin_config.sa = initPin(PORTE, 6)
config.pin_config.sb = initPin(PORTE, 3)

let result = sai.init(config)

proc audioCallback(input, output: ptr int32, size: csize_t) {.cdecl.} =
  for i in 0..<size:
    output[i] = input[i]  # Passthrough

var rxBuf, txBuf: array[256, int32]
discard sai.startDma(rxBuf[0].addr, txBuf[0].addr, 256, audioCallback)
```

---

### FatFS Module (sys/fatfs.nim)

FatFS filesystem wrapper for SD cards and USB storage.

**Import:**
```nim
import src/libdaisy_fatfs
```

#### FatFSInterface Object

High-level FatFS integration for file operations.

**Note:** The hardware (SD card or USB) must be initialized separately before using FatFS.

**Types:**
```nim
type
  FatFSInterface* {.importcpp: "daisy::FatFSInterface", header: fatfsHeader,
                    bycopy.} = object

  FatFSInterface_Result* {.size: sizeof(cint).} = enum
    FATFS_OK = 0
    FATFS_ERR

  MediaType* {.size: sizeof(cint).} = enum
    MEDIA_SD = 0     ## SD card via SDMMC
    MEDIA_USB = 1    ## USB mass storage
```

**Initialization:**
```nim
proc init*(this: var FatFSInterface, media: MediaType): FatFSInterface_Result {.
    importcpp: "Init", header: fatfsHeader.}
  ## Initialize FatFS interface for specified media
  ##
  ## Parameters:
  ##   media: MEDIA_SD or MEDIA_USB
  ##
  ## Returns:
  ##   FATFS_OK on success, FATFS_ERR on failure
  ##
  ## Note: Hardware must be initialized before calling this
```

**Path Helpers:**
```nim
proc getSDPath*(this: FatFSInterface): cstring {.
    importcpp: "GetSDPath", header: fatfsHeader.}
  ## Get SD card mount path (typically "0:/")

proc getUSBPath*(this: FatFSInterface): cstring {.
    importcpp: "GetUSBPath", header: fatfsHeader.}
  ## Get USB mount path (typically "1:/")
```

**FatFS Standard API:**

The module provides access to the standard FatFS API:

```nim
# File operations
proc f_open*(fp: ptr FIL, path: cstring, mode: BYTE): FRESULT
proc f_close*(fp: ptr FIL): FRESULT
proc f_read*(fp: ptr FIL, buff: pointer, btr: UINT, br: ptr UINT): FRESULT
proc f_write*(fp: ptr FIL, buff: pointer, btw: UINT, bw: ptr UINT): FRESULT
proc f_lseek*(fp: ptr FIL, ofs: FSIZE_t): FRESULT
proc f_sync*(fp: ptr FIL): FRESULT

# Directory operations
proc f_opendir*(dp: ptr DIR, path: cstring): FRESULT
proc f_closedir*(dp: ptr DIR): FRESULT
proc f_readdir*(dp: ptr DIR, fno: ptr FILINFO): FRESULT
proc f_mkdir*(path: cstring): FRESULT
proc f_unlink*(path: cstring): FRESULT
proc f_rename*(path_old: cstring, path_new: cstring): FRESULT

# Volume operations
proc f_mount*(fs: ptr FATFS, path: cstring, opt: BYTE): FRESULT
proc f_unmount*(path: cstring): FRESULT
proc f_getfree*(path: cstring, nclst: ptr DWORD, fatfs: ptr ptr FATFS): FRESULT
```

**File Access Modes:**
```nim
const
  FA_READ* = 0x01          ## Read access
  FA_WRITE* = 0x02         ## Write access
  FA_OPEN_EXISTING* = 0x00 ## Open existing file
  FA_CREATE_NEW* = 0x04    ## Create new file
  FA_CREATE_ALWAYS* = 0x08 ## Create or overwrite
  FA_OPEN_ALWAYS* = 0x10   ## Open or create
  FA_OPEN_APPEND* = 0x30   ## Open for append
```

**Result Codes:**
```nim
type
  FRESULT* {.size: sizeof(cint).} = enum
    FR_OK = 0                ## Success
    FR_DISK_ERR              ## Disk I/O error
    FR_INT_ERR               ## Internal error
    FR_NOT_READY             ## Drive not ready
    FR_NO_FILE               ## File not found
    FR_NO_PATH               ## Path not found
    FR_INVALID_NAME          ## Invalid name
    FR_DENIED                ## Access denied
    FR_EXIST                 ## File exists
    FR_INVALID_OBJECT        ## Invalid object
    FR_WRITE_PROTECTED       ## Write protected
    FR_INVALID_DRIVE         ## Invalid drive
    FR_NOT_ENABLED           ## No work area
    FR_NO_FILESYSTEM         ## No filesystem
    FR_MKFS_ABORTED          ## mkfs aborted
    FR_TIMEOUT               ## Timeout
    FR_LOCKED                ## File locked
    FR_NOT_ENOUGH_CORE       ## Not enough memory
    FR_TOO_MANY_OPEN_FILES   ## Too many open files
```

**Example - SD Card:**
```nim
import nimphea, libdaisy_fatfs, libdaisy_sdcard

# Initialize hardware
var sd: SdmmcHandler
var sdConfig = newSdmmcConfig()
discard sd.init(sdConfig)

# Initialize FatFS
var fatfs: FatFSInterface
if fatfs.init(MEDIA_SD) != FATFS_OK:
  echo "FatFS init failed"

# Mount filesystem
var fs: FATFS
if f_mount(fs.addr, fatfs.getSDPath(), 1) != FR_OK:
  echo "Mount failed"

# Write a file
var file: FIL
if f_open(file.addr, "0:/test.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
  let data = "Hello from Daisy!"
  var written: UINT
  discard f_write(file.addr, data.cstring, cast[UINT](data.len), written.addr)
  discard f_close(file.addr)

# Read a file
if f_open(file.addr, "0:/test.txt", FA_READ) == FR_OK:
  var buffer: array[128, char]
  var bytesRead: UINT
  discard f_read(file.addr, buffer[0].addr, 128, bytesRead.addr)
  discard f_close(file.addr)

# Cleanup
discard f_unmount(fatfs.getSDPath())
```

**Example - Directory Operations:**
```nim
# Create directory
discard f_mkdir("0:/data")

# List directory contents
var dir: DIR
var finfo: FILINFO

if f_opendir(dir.addr, "0:/") == FR_OK:
  while true:
    if f_readdir(dir.addr, finfo.addr) != FR_OK or finfo.fname[0] == '\0':
      break
    echo "Found: ", finfo.fname
  discard f_closedir(dir.addr)

# Delete file
discard f_unlink("0:/old.txt")

# Rename file
discard f_rename("0:/old.txt", "0:/new.txt")
```

---

### Enhanced MIDI Module (hid/midi.nim)

MIDI input and output with USB and UART transport.

**Updates:**
- Added MIDI output support (SendMessage)
- Added UART MIDI transport
- Bidirectional MIDI I/O

**Import:**
```nim
import src/libdaisy_midi
```

#### MidiHandler Object

Complete MIDI input/output handler.

**Configuration:**
```nim
type
  MidiTransport* {.size: sizeof(cint).} = enum
    USB_DEVICE = 0    ## USB MIDI device
    USB_HOST = 1      ## USB MIDI host
    UART = 2          ## Hardware UART

  MidiUartConfig* {.importcpp: "daisy::MidiUartHandler::Config",
                    header: midiHeader, bycopy.} = object
    transport*: MidiTransport
    uart_periph*: UartPeriph  ## Only for UART transport
```

**Initialization:**
```nim
proc init*(this: var MidiHandler, config: MidiUartConfig) {.
    importcpp: "Init", header: midiHeader.}
  ## Initialize MIDI handler
  ##
  ## Parameters:
  ##   config: Transport configuration (USB or UART)

proc listen*(this: var MidiHandler) {.
    importcpp: "Listen", header: midiHeader.}
  ## Start listening for incoming MIDI messages
  ##
  ## Call this in your main loop to process incoming data
```

**MIDI Output:**
```nim
proc sendMessage*(this: var MidiHandler, msg: ptr MidiMessage) {.
    importcpp: "SendMessage", header: midiHeader.}
  ## Send a MIDI message
  ##
  ## Parameters:
  ##   msg: Pointer to MidiMessage to send
  ##
  ## Example:
  ##   ```nim
  ##   var noteOn: MidiMessage
  ##   noteOn.type = NoteOn
  ##   noteOn.channel = 0
  ##   noteOn.data[0] = 60  # Middle C
  ##   noteOn.data[1] = 100 # Velocity
  ##   midi.sendMessage(noteOn.addr)
  ##   ```
```

**Message Handling:**
```nim
type
  MidiMessage* {.importcpp: "daisy::MidiEvent", header: midiHeader,
                 bycopy.} = object
    type*: MidiMessageType
    channel*: uint8
    data*: array[2, uint8]

  MidiMessageType* {.size: sizeof(cint).} = enum
    NoteOff = 0x80
    NoteOn = 0x90
    PolyphonicKeyPressure = 0xA0
    ControlChange = 0xB0
    ProgramChange = 0xC0
    ChannelPressure = 0xD0
    PitchBend = 0xE0
    SystemCommon = 0xF0
    SystemRealTime = 0xF8
    ChannelMode = 0xF0

proc hasEvents*(this: var MidiHandler): bool {.
    importcpp: "HasEvents", header: midiHeader.}
  ## Check if MIDI events are available

proc popEvent*(this: var MidiHandler): MidiMessage {.
    importcpp: "PopEvent", header: midiHeader.}
  ## Get next MIDI event from queue
```

**Example - MIDI Input:**
```nim
import nimphea, libdaisy_midi

var midi: MidiHandler
var config: MidiUartConfig
config.transport = USB_DEVICE

midi.init(config)
midi.listen()

# Main loop
while true:
  midi.listen()
  
  while midi.hasEvents():
    let msg = midi.popEvent()
    
    if msg.type == NoteOn:
      echo "Note On: ", msg.data[0], " vel: ", msg.data[1]
    elif msg.type == NoteOff:
      echo "Note Off: ", msg.data[0]
    elif msg.type == ControlChange:
      echo "CC: ", msg.data[0], " = ", msg.data[1]
```

**Example - MIDI Output:**
```nim
import nimphea, libdaisy_midi

var midi: MidiHandler
var config: MidiUartConfig
config.transport = USB_DEVICE

midi.init(config)

# Send Note On
var noteOn: MidiMessage
noteOn.type = NoteOn
noteOn.channel = 0
noteOn.data[0] = 60  # Middle C
noteOn.data[1] = 100 # Velocity
midi.sendMessage(noteOn.addr)

# Wait
delayMs(500)

# Send Note Off
var noteOff: MidiMessage
noteOff.type = NoteOff
noteOff.channel = 0
noteOff.data[0] = 60
noteOff.data[1] = 0
midi.sendMessage(noteOff.addr)
```

**Example - UART MIDI:**
```nim
import nimphea, libdaisy_midi, libdaisy_serial

var midi: MidiHandler
var config: MidiUartConfig
config.transport = UART
config.uart_periph = USART_1  # Use UART1 for MIDI

midi.init(config)

# Now use same API as USB MIDI
midi.listen()
# ... send/receive messages
```

---

### Enhanced AudioHandle API (nimphea.nim)

added advanced audio configuration options.

**New Audio Configuration:**
```nim
proc setPostGain*(this: var DaisySeed, gain: cfloat) {.
    importcpp: "SetPostGain", header: daisyHeader.}
  ## Set post-processing gain applied to audio output
  ##
  ## Parameters:
  ##   gain: Gain multiplier (1.0 = unity, 0.5 = -6dB, 2.0 = +6dB)

proc setOutputCompensation*(this: var DaisySeed, enabled: bool) {.
    importcpp: "SetOutputCompensation", header: daisyHeader.}
  ## Enable/disable automatic output level compensation
  ##
  ## When enabled, adjusts output levels to prevent clipping
```

**Multi-SAI Support:**
```nim
proc getSaiHandle*(this: var DaisySeed, saiNum: cint): ptr SaiHandle {.
    importcpp: "GetSaiHandle", header: daisyHeader.}
  ## Get pointer to SAI peripheral for advanced audio configs
  ##
  ## Parameters:
  ##   saiNum: SAI number (1 or 2)
  ##
  ## Returns:
  ##   Pointer to SaiHandle for low-level configuration
```

---

### Enhanced AnalogControl (hid/ctrl.nim)

added full AnalogControl class with calibration support.

**Import:**
```nim
import src/libdaisy_controls
```

**AnalogControl Object:**
```nim
type
  AnalogControl* {.importcpp: "daisy::AnalogControl",
                   header: controlsHeader, bycopy.} = object

proc initAnalogControl*(this: var AnalogControl) {.
    importcpp: "Init", header: controlsHeader.}
  ## Initialize analog control with default settings

proc process*(this: var AnalogControl, input: cfloat): cfloat {.
    importcpp: "Process", header: controlsHeader.}
  ## Process raw ADC value through filtering and mapping
  ##
  ## Parameters:
  ##   input: Raw ADC value (0.0 to 1.0)
  ##
  ## Returns:
  ##   Processed value with filtering and calibration applied

proc setCoeff*(this: var AnalogControl, coefficient: cfloat) {.
    importcpp: "SetCoeff", header: controlsHeader.}
  ## Set filter coefficient for smoothing
  ##
  ## Parameters:
  ##   coefficient: Filter coefficient (0.0 to 1.0)
  ##     Lower = more smoothing, higher = more responsive
  ##     Recommended: 0.01 to 0.1

proc setCalibration*(this: var AnalogControl, min, max: cfloat) {.
    importcpp: "SetCalibration", header: controlsHeader.}
  ## Set calibration range
  ##
  ## Parameters:
  ##   min: Minimum expected raw ADC value
  ##   max: Maximum expected raw ADC value
```

**Example:**
```nim
import nimphea, libdaisy_controls, libdaisy_adc

var hw = initDaisy()
var pot: AnalogControl

pot.initAnalogControl()
pot.setCoeff(0.05)  # Moderate smoothing
pot.setCalibration(0.01, 0.99)  # Typical potentiometer range

# In main loop
while true:
  let rawValue = hw.readAnalog(PIN_ADC_0)
  let smoothValue = pot.process(rawValue)
  
  # Use smoothValue for parameter control
  let frequency = 20.0 + smoothValue * 20000.0
```

---

For more examples, see [EXAMPLES.md](EXAMPLES.md).

For contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).
