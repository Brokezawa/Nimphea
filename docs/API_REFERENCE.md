# API Reference

Complete API reference for **Nimphea**, the Nim wrapper for libDaisy.
This document covers all **85 modules** available in the library.

## Table of Contents

1.  **[Core System](#core-system)**
    *   [DaisySeed](#daisyseed-nimpheanim)
    *   [System Utilities](#system-utilities-syssystemnim)
    *   [Logging](#logger-hidloggernim)
    *   [Unique ID](#unique-id-nimphea_uniqueidnim)
    *   [CPU Load Meter](#cpu-load-meter-nimphea_cpuloadnim)
    *   [Interrupt Handling](#scoped-irq-blocker-nimphea_scoped_irqnim)
    *   [Panic Handler](#panic-handler-panicoverridenim)

2.  **[Audio & Signal Processing](#audio--signal-processing)**
    *   [Audio Handling](#audio-handling-nimpheanim)
    *   [WAV Writer](#wav-file-writer-nimphea_wavwriternim)
    *   [WAV Player](#wav-file-player-nimphea_wavplayernim)
    *   [WAV Parser](#wav-file-parser-nimphea_wavparsernim)
    *   [WAV Format](#wav-format-nimphea_wavformatnim)
    *   [Wavetable Loader](#wavetable-loader-nimphea_wavetable_loadernim)
    *   [SAI (Low Level)](#sai-module-nimphea_sainim)

3.  **[Memory & Filesystem](#memory--filesystem)**
    *   [FatFS](#fatfs-module-sysfatfsnim)
    *   [SDRAM](#sdram-module-syssdramnim)
    *   [DMA & Cache](#dma-cache-control-sysdmanim)
    *   [Persistent Storage](#persistent-storage-nimphea_persistent_storagenim)
    *   [File Reader](#file-reader-nimphea_filereadernim)

4.  **[Peripherals](#peripherals)**
    *   [ADC](#adc-module-peradcnim)
    *   [DAC](#dac-module-perdacnim)
    *   [GPIO](#gpio-module-nimpheanim)
    *   [I2C](#i2c-module-peri2cnim)
    *   [SPI](#spi-module-perspinim)
    *   [Multi-Slave SPI](#multi-slave-spi-perspi_multislavenim)
    *   [UART](#uart-module-peruartnim)
    *   [PWM](#pwm-module-perpwmnim)
    *   [Timer (TIM)](#hardware-timer-pertimnim)
    *   [RNG](#rng-module-perrngnim)
    *   [QSPI](#qspi-module-perqspinim)
    *   [SDMMC](#sdmmc-module-persdmmcnim)

5.  **[HID & Controls](#hid--controls)**
    *   [Controls (Encoder, Analog)](#controls-module-hidctrlnim)
    *   [Switch](#switch-module-hidswitchnim)
    *   [3-Position Switch](#switch-3-pos-hidswitch3nim)
    *   [Gate Input](#gate-input-hidgateinnim)
    *   [LED](#led-control-hidlednim)
    *   [RGB LED](#rgb-led-control-hidrgb_lednim)
    *   [Parameter Mapping](#parameter-mapping-hidparameternim)
    *   [MIDI](#midi-module-hidmidinim)
    *   [USB](#usb-module-hidusbnim)
    *   [Shift Register (Nim)](#shift-register-nim-nimphea_shift_registernim)

6.  **[UI & Graphics](#ui--graphics)**
    *   [UI Core](#ui-core-system-nimphea_ui_corenim)
    *   [Menu System](#menu-system-nimphea_menunim)
    *   [Menu Builder DSL](#menu-builder-dsl-uimenu_buildernim)
    *   [UI Controls](#ui-controls-nimphea_ui_controlsnim)
    *   [UI Events](#ui-events-nimphea_ui_eventsnim)
    *   [Event Helpers](#event-helpers-uieventsnim)
    *   [OLED Display (SSD130x)](#oled-display-ssd130x-hiddispoled_displaynim)
    *   [Display Concepts](#display-concepts-uidisplaynim)
    *   [Graphics Primitives](#graphics-primitives-hiddispgraphics_commonnim)
    *   [Fonts](#fonts-utiloled_fontsnim)
    *   [Color Utilities](#color-utilities-nimphea_colornim)
    *   [Mapped Values](#mapped-values-nimphea_mapped_valuenim)

7.  **[Board Support](#board-support)**
    *   [Daisy Patch](#daisy-patch-boardsdaisy_patchnim)
    *   [Daisy Patch SM](#daisy-patch-sm-boardsdaisy_patch_smnim)
    *   [Daisy Pod](#daisy-pod-boardsdaisy_podnim)
    *   [Daisy Field](#daisy-field-boardsdaisy_fieldnim)
    *   [Daisy Petal](#daisy-petal-boardsdaisy_petalnim)
    *   [Daisy Versio](#daisy-versio-boardsdaisy_versionim)
    *   [Daisy Legio](#daisy-legio-boardsdaisy_legionim)

8.  **[Device Drivers](#device-drivers)**
    *   [Sensors (IMU, Env)](#sensors)
        *   [APDS9960](#apds9960-devapds9960nim)
        *   [DPS310](#dps310-devdps310nim)
        *   [ICM20948](#icm20948-devicm20948nim)
        *   [TLV493D](#tlv493d-devtlv493dnim)
    *   [LED Drivers](#led-drivers)
        *   [NeoPixel](#neopixel-driver-devneopixelnim)
        *   [DotStar](#dotstar-driver-devdotstarnim)
        *   [PCA9685](#led-driver-pca9685-devleddrivernim)
    *   [Input & IO](#input--io)
        *   [MPR121](#mpr121-touch-devmpr121nim)
        *   [NeoTrellis](#neotrellis-devneotrellisnim)
        *   [MCP23x17](#mcp23x17-devmcp23x17nim)
        *   [MAX11300](#max11300-devmax11300nim)
        *   [ShiftRegister 4021](#shift-register-4021-devsr4021nim)
        *   [ShiftRegister 595](#shift-register-595-devsr595nim)
    *   [Displays](#displays)
        *   [SSD1351](#ssd1351-color-oled-devoled_ssd1351nim)
        *   [SSD1327](#ssd1327-grayscale-oled-devoled_ssd1327nim)
        *   [SH1106](#sh1106-oled-devoled_sh1106nim)
        *   [HD44780](#hd44780-lcd-devlcd_hd44780nim)
    *   [Audio Codecs](#audio-codecs)
        *   [AK4556](#ak4556-devcodec_ak4556nim)
        *   [PCM3060](#pcm3060-devcodec_pcm3060nim)
        *   [WM8731](#wm8731-devcodec_wm8731nim)

9.  **[Data Structures & Utils](#data-structures--utils)**
    *   [FileTable](#file-table-nimphea_filetablenim)
    *   [Stack](#stack-nimphea_stacknim)
    *   [FIFO](#fifo-nimphea_fifonim)
    *   [RingBuffer](#ringbuffer-nimphea_ringbuffernim)
    *   [FixedStr](#fixedstr-nimphea_fixedstrnim)
    *   [V/Oct Calibration](#voct-calibration-nimphea_voct_calibrationnim)
    *   [Macros](#macros-nimphea_macrosnim)

---

# Core System

## DaisySeed (`nimphea.nim`)

The main hardware abstraction for the Daisy Seed board.

**Types:**
```nim
type DaisySeed* = object
type BoardVersion* = enum BOARD_DAISY_SEED, BOARD_DAISY_SEED_1_1, BOARD_DAISY_SEED_2_DFM
```

**Initialization:**
```nim
proc initDaisy*(boost: bool = false): DaisySeed
proc init*(daisy: var DaisySeed, boost: bool = false)
proc deinit*(daisy: var DaisySeed)
```
- `boost`: If true, runs CPU at 480MHz (default 400MHz).

**System Control:**
```nim
proc delay*(daisy: var DaisySeed, milliseconds: int)
proc setLed*(daisy: var DaisySeed, state: bool)
proc toggleLed*(daisy: var DaisySeed)
proc setTestPoint*(daisy: var DaisySeed, state: bool)
proc boardVersion*(daisy: var DaisySeed): BoardVersion
proc now*(daisy: var DaisySeed): float  # Seconds since boot
```

**Example:**
```nim
import nimphea

var hw = initDaisy()
hw.setLed(true)
hw.delay(1000)
hw.toggleLed()
```

## System Utilities (`sys/system.nim`)

Low-level system control, clocks, and bootloader.

**Clock Info:**
```nim
proc getSysClkFreq*(): uint32  # System clock (Hz)
proc getHClkFreq*(): uint32    # AHB clock
proc getPClk1Freq*(): uint32   # APB1 clock
proc getPClk2Freq*(): uint32   # APB2 clock
proc getTickFreq*(): uint32    # Tick timer frequency
```

**Timing:**
```nim
proc getNow*(): uint32   # Milliseconds since boot
proc getUs*(): uint32    # Microseconds since boot
proc getTick*(): uint32  # CPU ticks
proc delay*(ms: uint32)
proc delayUs*(us: uint32)
proc delayTicks*(ticks: uint32)
```

**Bootloader & Memory:**
```nim
type BootloaderMode* = enum STM, DAISY, DAISY_SKIP_TIMEOUT, DAISY_INFINITE_TIMEOUT
type MemoryRegion* = enum INTERNAL_FLASH, QSPI, SRAM_D1, SDRAM, ...

proc resetToBootloader*(mode: BootloaderMode = STM)
proc getProgramMemoryRegion*(): MemoryRegion
```

## Logger (`hid/logger.nim`)

USB/UART logging facility. Appears as a serial port on the host computer.

```nim
proc startLog*(wait_for_pc: bool = false)
proc print*(text: cstring)
proc printLine*(text: cstring)
proc log*(msg: string)  # Nim-friendly wrapper
```

## Unique ID (`nimphea_uniqueid.nim`)

Read the STM32 96-bit unique factory identifier.

```nim
type UniqueId* = object
  w0*, w1*, w2*: uint32

proc getUniqueId*(): UniqueId
proc getUniqueIdString*(): string  # Format: "XXXXXXXX-XXXXXXXX-XXXXXXXX"
```

## CPU Load Meter (`nimphea_cpuload.nim`)

Measure audio callback performance.

```nim
proc init*(this: var CpuLoadMeter, sampleRate: float32, blockSize: int, smoothing: float32 = 1.0)
proc onBlockStart*(this: var CpuLoadMeter)
proc onBlockEnd*(this: var CpuLoadMeter)
proc getAvgCpuLoad*(this: CpuLoadMeter): float32 # 0.0 to 1.0
proc getMinCpuLoad*(this: CpuLoadMeter): float32
proc getMaxCpuLoad*(this: CpuLoadMeter): float32
proc reset*(this: var CpuLoadMeter)
```

## Scoped IRQ Blocker (`nimphea_scoped_irq.nim`)

RAII-style interrupt disabling for critical sections.

```nim
template withoutInterrupts*(body: untyped)
template criticalSection*(body: untyped)
```

## Panic Handler (`panicoverride.nim`)

Custom panic handler for bare-metal environment. Overrides default Nim panic behavior (which would try to print to stdout/stderr). Used internally.

---

# Audio & Signal Processing

## Audio Handling (`nimphea.nim`)

**Types:**
```nim
type AudioBuffer* = ptr UncheckedArray[ptr UncheckedArray[cfloat]]
type AudioCallback* = proc(input, output: AudioBuffer, size: int) {.cdecl.}
type InterleavedAudioCallback* = proc(input, output: InterleavedAudioBuffer, size: int) {.cdecl.}
type SampleRate* = enum SAI_8KHZ, ..., SAI_48KHZ, SAI_96KHZ
```

**Methods:**
```nim
proc startAudio*(daisy: var DaisySeed, callback: AudioCallback)
proc startAudio*(daisy: var DaisySeed, callback: InterleavingAudioCallback)
proc stopAudio*(daisy: var DaisySeed)
proc changeAudioCallback*(daisy: var DaisySeed, callback: AudioCallback)
proc setSampleRate*(daisy: var DaisySeed, rate: SampleRate)
proc sampleRate*(daisy: var DaisySeed): float
proc setBlockSize*(daisy: var DaisySeed, size: int)
proc blockSize*(daisy: var DaisySeed): int
proc callbackRate*(daisy: DaisySeed): float
```

**Example:**
```nim
proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  for i in 0..<size:
    output[0][i] = input[0][i] * 0.5  # Stereo passthrough with gain

var hw = initDaisy()
hw.startAudio(audioCallback)
while true:
  discard  # Audio runs in background
```

## WAV File Writer (`nimphea_wavwriter.nim`)

Record audio to SD card.

```nim
type WavWriterConfig* = object
  samplerate*: cfloat
  channels*: int32
  bitspersample*: int32

proc init*(writer: var WavWriter, config: WavWriterConfig)
proc openFile*(writer: var WavWriter, name: cstring)
proc sample*(writer: var WavWriter, input: ptr cfloat)
proc write*(writer: var WavWriter)  # Call in main loop
proc saveFile*(writer: var WavWriter)
proc isRecording*(writer: WavWriter): bool
```

## WAV File Player (`nimphea_wavplayer.nim`)

Stream audio from SD card.

```nim
proc init*(player: var WavPlayer, name: cstring): WavPlayerResult
proc open*(player: var WavPlayer, name: cstring): WavPlayerResult
proc close*(player: var WavPlayer): WavPlayerResult
proc prepare*(player: var WavPlayer): WavPlayerResult  # Call in main loop
proc stream*(player: var WavPlayer, samples: ptr cfloat, numChannels: csize_t): WavPlayerResult
proc setLooping*(player: var WavPlayer, state: bool)
proc setPlaybackSpeedRatio*(player: var WavPlayer, speed: cfloat)
proc getPosition*(player: WavPlayer): uint32
proc setPlaying*(player: var WavPlayer, state: bool)
```

## WAV File Parser (`nimphea_wavparser.nim`)

Read WAV headers without loading data.

```nim
proc parse*(parser: var WavParser, reader: var IReader): bool
proc info*(parser: WavParser): WavFormatInfo
proc dataOffset*(parser: WavParser): uint32
proc dataSize*(parser: WavParser): uint32
```

## WAV Format (`nimphea_wavformat.nim`)

WAV file format constants and structures.

```nim
type WavFormatTypeDef* = object
  ChunkId*, FileSize*, FileFormat*: uint32
  AudioFormat*, NbrChannels*: uint16
  SampleRate*, ByteRate*: uint32
  BlockAlign*, BitPerSample*: uint16
```

## Wavetable Loader (`nimphea_wavetable_loader.nim`)

Load multiple wavetables from a single WAV file into memory.

```nim
proc init*(loader: var WaveTableLoader, mem: ptr cfloat, memSize: csize_t)
proc setWaveTableInfo*(loader: var WaveTableLoader, samps: csize_t, count: csize_t): WaveTableResult
proc import*(loader: var WaveTableLoader, filename: cstring): WaveTableResult
proc getTable*(loader: var WaveTableLoader, idx: csize_t): ptr cfloat
```

## SAI Module (`nimphea_sai.nim`)

Low-level Serial Audio Interface control.

```nim
proc init*(sai: var SaiHandle, config: SaiConfig): SaiResult
proc startDma*(sai: var SaiHandle, bufferRx, bufferTx: ptr int32, size: int, callback: SaiCallback): SaiResult
proc stopDma*(sai: var SaiHandle): SaiResult
proc getSampleRate*(sai: SaiHandle): float
```

---

# Memory & Filesystem

## FatFS Module (`sys/fatfs.nim`)

Filesystem support for SD cards and USB drives.

```nim
type FatFSMedia* = enum MEDIA_SD = 0x01, MEDIA_USB = 0x02

proc init*(fatfs: var FatFSInterface, media: uint8): FatFSResult
proc deinit*(fatfs: var FatFSInterface): FatFSResult
proc mount*(fatfs: var FatFSInterface, media: FatFSMedia): FRESULT
proc unmount*(fatfs: var FatFSInterface, media: FatFSMedia): FRESULT
proc getSDPath*(fatfs: FatFSInterface): cstring
proc getUSBPath*(fatfs: FatFSInterface): cstring
```

## SDRAM Module (`sys/sdram.nim`)

Access 64MB external SDRAM.

```nim
proc init*(this: var SdramHandle): SdramResult
proc newSdramHandle*(): SdramHandle

# Utilities
template sdramArray*(T: typedesc, size: int): untyped
proc clearSdramBss*()
proc getMemoryInfo*(): SdramMemoryInfo
```

## DMA & Cache Control (`sys/dma.nim`)

Manage CPU cache coherency for DMA transfers.

```nim
template dmaClearCache*[T](buffer: var openArray[T])      # Flush before transmit
template dmaInvalidateCache*[T](buffer: var openArray[T]) # Invalidate after receive
proc dmaClearCacheFor*(p: pointer, size: int)
proc dmaInvalidateCacheFor*(p: pointer, size: int)
```

## Persistent Storage (`nimphea_persistent_storage.nim`)

Type-safe settings storage in QSPI flash.

**Important:** You must define C++ `operator==` and `operator!=` for your settings struct using `{.emit.}`.

```nim
proc init*[T](this: var PersistentStorage[T], defaults: T, offset: uint32 = 0)
proc save*[T](this: var PersistentStorage[T])
proc restoreDefaults*[T](this: var PersistentStorage[T])
proc getSettings*[T](this: var PersistentStorage[T]): var T
proc getState*[T](this: PersistentStorage[T]): StorageState
```

## File Reader (`nimphea_filereader.nim`)

Wrapper for reading files from FatFS.

```nim
proc newFileReader*(f: ptr FIL): FileReader
proc read*(this: var FileReader, dst: pointer, bytes: csize_t): csize_t
proc seek*(this: var FileReader, pos: uint32): bool
proc size*(this: FileReader): uint32
```

---

# Peripherals

## ADC Module (`per/adc.nim`)

Analog-to-Digital Converter.

**Configuration:**
```nim
type AdcChannelConfig* = object
proc initSingle*(cfg: var AdcChannelConfig, pin: Pin)
proc initMux*(cfg: var AdcChannelConfig, adc_pin: Pin, mux_channels: csize_t, mux_0, mux_1, mux_2: Pin)
```

**Handle:**
```nim
proc init*(adc: var AdcHandle, cfg: ptr AdcChannelConfig, num_channels: csize_t)
proc start*(adc: var AdcHandle)
proc stop*(adc: var AdcHandle)
proc get*(adc: AdcHandle, chn: uint8): uint16
proc getFloat*(adc: AdcHandle, chn: uint8): cfloat
proc getMuxFloat*(adc: AdcHandle, chn: uint8, idx: uint8): cfloat
```

**Example:**
```nim
import per/adc

var adcConfig: AdcChannelConfig
adcConfig.initSingle(A0())

var adc: AdcHandle
adc.init(addr adcConfig, 1)
adc.start()

let rawValue = adc.get(0)       # 0-65535
let floatValue = adc.getFloat(0) # 0.0-1.0
```

## DAC Module (`per/dac.nim`)

Digital-to-Analog Converter (on-chip).

```nim
type DacChannel* = enum DAC_CHN_ONE, DAC_CHN_TWO, DAC_CHN_BOTH

proc init*(dac: var DacHandle, config: DacConfig): DacResult
proc writeValue*(dac: var DacHandle, chn: DacChannel, val: uint16)
```

## GPIO Module (`nimphea.nim`)

General Purpose I/O.

```nim
proc initGpio*(pin: Pin, mode: GPIOMode = OUTPUT, pull: GPIOPull = NOPULL): GPIO
proc write*(gpio: var GPIO, state: bool)
proc read*(gpio: var GPIO): bool
proc toggle*(gpio: var GPIO)
```

## I2C Module (`per/i2c.nim`)

Inter-Integrated Circuit bus.

```nim
proc init*(i2c: var I2CHandle, config: I2CConfig): I2CResult
proc write*(i2c: var I2CHandle, address: uint16, data: openArray[uint8], timeout: uint32)
proc read*(i2c: var I2CHandle, address: uint16, buffer: var openArray[uint8], timeout: uint32)
proc transmitDma*(i2c: var I2CHandle, address: uint16, buffer: var openArray[uint8], callback: I2CCallback, ctx: pointer)
proc receiveDma*(i2c: var I2CHandle, address: uint16, buffer: var openArray[uint8], callback: I2CCallback, ctx: pointer)
```

## SPI Module (`per/spi.nim`)

Serial Peripheral Interface.

```nim
proc init*(spi: var SpiHandle, config: SpiConfig): SpiResult
proc blockingTransmit*(spi: var SpiHandle, buffer: openArray[uint8])
proc blockingReceive*(spi: var SpiHandle, buffer: var openArray[uint8])
proc dmaTransmit*(spi: var SpiHandle, buffer: openArray[uint8], ...)
proc dmaReceive*(spi: var SpiHandle, buffer: var openArray[uint8], ...)
```

## Multi-Slave SPI (`per/spi_multislave.nim`)

SPI bus shared by multiple devices with individual Chip Selects.

```nim
proc init*(spi: var MultiSlaveSpiHandle, config: MultiSlaveSpiConfig): SpiResult
proc blockingTransmit*(spi: var MultiSlaveSpiHandle, device_index: int, data: openArray[uint8])
proc blockingReceive*(spi: var MultiSlaveSpiHandle, device_index: int, data: var openArray[uint8])
```

## UART Module (`per/uart.nim`)

Universal Asynchronous Receiver/Transmitter.

```nim
proc init*(uart: var UartHandler, config: UartConfig): UartResult
proc blockingTransmit*(uart: var UartHandler, data: openArray[uint8])
proc blockingReceive*(uart: var UartHandler, buffer: var openArray[uint8])
```

## PWM Module (`per/pwm.nim`)

Pulse Width Modulation.

```nim
proc initPwm*(peripheral: PwmPeripheral, frequency: float): PwmHandle
proc channel1*(pwm: var PwmHandle): var PwmChannel
# ... channel2, channel3, channel4
proc init*(chan: var PwmChannel, pin: Pin)
proc set*(chan: var PwmChannel, duty: float) # 0.0-1.0
```

## Hardware Timer (`per/tim.nim`)

High-resolution hardware timers (TIM2-TIM5).

```nim
proc init*(timer: var TimerHandle, config: TimerConfig): TimerResult
proc start*(timer: var TimerHandle)
proc stop*(timer: var TimerHandle)
proc getTick*(timer: var TimerHandle): uint32
proc delayUs*(timer: var TimerHandle, us: uint32)
proc setCallback*(timer: var TimerHandle, cb: TimerCallback)
```

## RNG Module (`per/rng.nim`)

True Random Number Generator.

```nim
proc randomGetValue*(): uint32
proc randomGetFloat*(min, max: cfloat): cfloat
proc randomIsReady*(): bool
```

## QSPI Module (`per/qspi.nim`)

Quad-SPI Flash interface.

```nim
proc init*(qspi: var QSPIHandle, config: QSPIConfig): QSPIResult
proc write*(qspi: var QSPIHandle, address: uint32, size: uint32, buffer: ptr uint8)
proc eraseSector*(qspi: var QSPIHandle, address: uint32)
```

## SDMMC Module (`per/sdmmc.nim`)

SD Card hardware interface. Typically used via FatFS.

```nim
proc init*(sd: var SdmmcHandler, config: SdmmcHandlerConfig): SdmmcResult
proc readBlocks*(sd: var SdmmcHandler, address: uint32, buffer: ptr uint8, count: uint32): SdmmcResult
proc writeBlocks*(sd: var SdmmcHandler, address: uint32, buffer: ptr uint8, count: uint32): SdmmcResult
```

---

# HID & Controls

## Controls Module (`hid/ctrl.nim`)

**Encoder:**
```nim
proc initEncoder*(pinA, pinB: Pin, clickPin: Pin, ...): Encoder
proc update*(enc: var Encoder)
proc increment*(enc: var Encoder): int
proc pressed*(enc: var Encoder): bool
```

**AnalogControl (Knobs/CV):**
```nim
proc initAnalogControl*(adcPtr: ptr uint16, sampleRate: float, ...): AnalogControl
proc process*(ctrl: var AnalogControl): float
proc value*(ctrl: AnalogControl): float
```

## Switch Module (`hid/switch.nim`)

Momentary/Latching Switch with Debouncing.

```nim
proc init*(sw: var Switch, pin: Pin, type: SwitchType, polarity: SwitchPolarity, pull: GpioPull)
proc debounce*(sw: var Switch)
proc pressed*(sw: Switch): bool
proc risingEdge*(sw: Switch): bool
proc timeHeldMs*(sw: Switch): float
```

## Switch 3-Pos (`hid/switch3.nim`)

3-position switch (ON-OFF-ON).

```nim
proc init*(sw: var Switch3, pinA, pinB: Pin)
proc read*(sw: var Switch3): cint  # 0=Center, 1=Up, 2=Down
```

## Parameter Mapping (`hid/parameter.nim`)

```nim
type Curve* = enum LINEAR, EXPONENTIAL, LOGARITHMIC, CUBE
proc mapParameter*(input: float32, min, max: float32, curve: Curve): float32
```

## Gate Input (`hid/gatein.nim`)

```nim
proc init*(gate: var GateIn, pin: Pin, invert: bool)
proc trig*(gate: var GateIn): bool
proc state*(gate: var GateIn): bool
```

## LED Control (`hid/led.nim`)

Single LED with software PWM.

```nim
proc init*(led: var Led, pin: Pin, invert: bool, sampleRate: float)
proc set*(led: var Led, brightness: float)
proc update*(led: var Led)
```

## RGB LED Control (`hid/rgb_led.nim`)

3-channel LED control.

```nim
proc init*(rgb: var RgbLed, r, g, b: Pin, invert: bool)
proc set*(rgb: var RgbLed, r, g, b: float)
proc setColor*(rgb: var RgbLed, c: Color)
proc update*(rgb: var RgbLed)
```

## MIDI Module (`hid/midi.nim`)

**USB MIDI:**
```nim
proc initMidiUsb*(midi: var MidiUsbHandler)
proc listen*(midi: var MidiUsbHandler)
proc hasEvents*(midi: var MidiUsbHandler): bool
proc popEvent*(midi: var MidiUsbHandler): MidiEvent
proc sendMessage*(midi: var MidiUsbHandler, bytes: ptr uint8, size: int)
```

**UART MIDI:**
```nim
proc initMidiUart*(midi: var MidiUartHandler, config: MidiUartHandlerConfig)
# Methods same as USB MIDI
```

## USB Module (`hid/usb.nim`)

**USB CDC (Serial):**
```nim
proc newUsbHandle*(): UsbHandle
proc init*(usb: var UsbHandle, dev: UsbPeriph)
proc transmitInternal*(usb: var UsbHandle, data: cstring): UsbResult
```

**USB Host:**
```nim
proc newUSBHostHandle*(): USBHostHandle
proc init*(host: var USBHostHandle, config: var USBHostConfig): USBHostResult
proc process*(host: var USBHostHandle): USBHostResult
```

## Shift Register (Nim) (`nimphea_shift_register.nim`)

High-level Nim wrapper for CD4021 shift registers. Provides type-safe configurations for common device counts (1-4 chained, 1-2 parallel lines).

**Types:**
```nim
# Single-line configurations (daisy-chained)
type ShiftRegister4021_1*   # 1 device (8 inputs)
type ShiftRegister4021_2*   # 2 devices (16 inputs) - Used by Daisy Field keyboard
type ShiftRegister4021_3*   # 3 devices (24 inputs)
type ShiftRegister4021_4*   # 4 devices (32 inputs)

# Parallel configurations (multiple data lines)
type ShiftRegister4021_1x2* # 1 device × 2 lines (16 inputs)
type ShiftRegister4021_2x2* # 2 devices × 2 lines (32 inputs)

type ShiftRegisterConfig_1* = object
  clk*: Pin            ## Clock pin (CD4021 pin 10)
  latch*: Pin          ## Latch pin (CD4021 pin 9)
  data*: array[1, Pin] ## Data pin (CD4021 pin 11)
  delay_ticks*: uint32 ## Timing delay (default: 10)
```

**Methods:**
```nim
proc init*(sr: var ShiftRegister4021_N, config: ShiftRegisterConfig_N)
proc update*(sr: var ShiftRegister4021_N)
proc state*(sr: ShiftRegister4021_N, index: cint): bool
proc pressed*(sr: ShiftRegister4021_N, index: cint): bool  # Active-low helper
```

---

# UI & Graphics

## UI Core System (`nimphea_ui_core.nim`)

```nim
proc initUI*(): UI
proc init*(ui: var UI, queue: var UiEventQueue, controls: UiSpecialControlIds, canvases: openArray[UiCanvasDescriptor])
proc openPage*(ui: var UI, page: var UiPage)
proc process*(ui: var UI)
```

## Menu System (`nimphea_menu.nim`)

```nim
proc initFullScreenMenu*(items: var openArray[MenuItemConfig]): FullScreenItemMenu
proc createValueItemFloat*(text: string, valuePtr: ptr MappedFloatValue): MenuItemConfig
proc createCloseItem*(text: cstring): MenuItemConfig
```

## Menu Builder DSL (`ui/menu_builder.nim`)

Macros for defining menus statically.

```nim
defineMenu myMenu:
  value "Volume", volumeVar
  checkbox "Mute", muteVar
  action "Save", saveCallback
  close "Back"
```

## UI Controls (`nimphea_ui_controls.nim`)

Templates for event-based monitoring.

```nim
template createButtonMonitor*[B; N](backend: B, n: int)
template createPotMonitor*[B; N](backend: B, n: int)
```

## UI Events (`nimphea_ui_events.nim`)

Thread-safe event queue.

```nim
proc initUiEventQueue*(): UiEventQueue
proc addButtonPressed*(queue: var UiEventQueue, id: uint16, presses: uint16)
proc getAndRemoveNextEvent*(queue: var UiEventQueue): Event
```

## Event Helpers (`ui/events.nim`)

Closure-based event dispatcher.

```nim
proc createEventDispatcher*(queue: var UiEventQueue): EventDispatcher
proc onButtonPress*(dispatcher: var EventDispatcher, handler: ButtonHandler)
proc process*(dispatcher: var EventDispatcher)
```

## OLED Display (SSD130x) (`hid/disp/oled_display.nim`)

Base support for SSD1306/SH1106 displays.

```nim
template initOledI2c*(width, height: static[int], ...): untyped
template initOledSpi*(width, height: static[int], ...): untyped

proc fill*(display: var OledDisplay, on: bool)
proc drawPixel*(display: var OledDisplay, x, y: int, on: bool)
proc update*(display: var OledDisplay)
```

## Display Concepts (`ui/display.nim`)

Generic display concepts and templates.

```nim
template withDisplay*(display: var auto, body: untyped)
template clearAndDraw*(display: var auto, body: untyped)
```

## Graphics Primitives (`hid/disp/graphics_common.nim`)

Rectangle and alignment types.

```nim
proc initRectangle*(x, y, w, h: int16): Rectangle
proc getCenterX*(r: Rectangle): int16
proc withCenter*(r: Rectangle, cx, cy: int16): Rectangle
```

## Fonts (`util/oled_fonts.nim`)

Bitmap fonts: `Font_4x6`, `Font_6x8`, `Font_7x10`, `Font_11x18`, `Font_16x26`.

## Color Utilities (`nimphea_color.nim`)

```nim
proc createColor*(r, g, b: cfloat): Color
proc colorBlend*(a, b: Color, amt: cfloat): Color
proc setRed*(c: var Color, val: cfloat)
```

## Mapped Values (`nimphea_mapped_value.nim`)

```nim
proc createMappedFloatValue*(min, max, default: float, ...): MappedFloatValue
proc get*(v: var MappedFloatValue): cfloat
proc set*(v: var MappedFloatValue, val: cfloat)
```

---

# Board Support

## Daisy Patch (`boards/daisy_patch.nim`)
- `display`: OledDisplay128x64Spi
- `encoder`: Encoder
- `gate_in` / `gate_out`: Gate I/O
- `cv`: Array of 4 AnalogControl
- `knob`: Array of 4 AnalogControl
- `processAnalogControls()`, `processDigitalControls()`

## Daisy Patch SM (`boards/daisy_patch_sm.nim`)
- `getAdcValue(idx)`: Read CV/ADC (0.0-1.0)
- `writeCvOut(chn, val)`: Write DAC (0-5V)
- `gate_in_1`, `gate_in_2`, `gate_out_1`, `gate_out_2`
- `startAdc()`, `startDac()`

## Daisy Pod (`boards/daisy_pod.nim`)
- `led1`, `led2`: RGB LEDs
- `knob1`, `knob2`: AnalogControl
- `button1`, `button2`: Switch
- `encoder`: Encoder
- `processAllControls()`

## Daisy Field (`boards/daisy_field.nim`)
- `keyboardState(idx)`: Read touch keys
- `led_driver`: PCA9685 driver for 26 LEDs
- `gate_in`, `gate_out`, `cv`, `knob`, `sw`
- `display`: OLED

## Daisy Petal (`boards/daisy_petal.nim`)
- `switches`: 7 switches (4 foot, 3 toggle)
- `ring_led`: 8 RGB LEDs
- `footswitch_led`: 4 LEDs
- `expression`: Pedal input
- `knob`: 6 knobs

## Daisy Versio (`boards/daisy_versio.nim`)
- `knobs`: 7 CV/Knobs
- `leds`: 4 RGB LEDs
- `tap`: Momentary switch
- `sw`: 2 Toggle switches
- `gate`: Gate input

## Daisy Legio (`boards/daisy_legio.nim`)
- `encoder`: With button
- `leds`: 2 RGB LEDs
- `controls`: 3 CV (Pitch + 2 Knobs)
- `sw`: 2 Toggle switches

---

# Device Drivers

## Sensors

### APDS9960 (`dev/apds9960.nim`)
Gesture, Proximity, Color, Light sensor.
```nim
proc init*(sensor: var Apds9960I2C, config: Apds9960Config)
proc readGesture*(sensor: var Apds9960I2C): uint8
proc readProximity*(sensor: var Apds9960I2C): uint8
proc getColorData*(sensor: var Apds9960I2C, r, g, b, c: ptr uint16)
```

### DPS310 (`dev/dps310.nim`)
Barometric Pressure & Altitude sensor.
```nim
proc init*(sensor: var Dps310I2C, config: Dps310I2CConfig)
proc getPressure*(sensor: var Dps310I2C): float
proc getTemperature*(sensor: var Dps310I2C): float
proc getAltitude*(sensor: var Dps310I2C, seaLevel: float): float
```

### ICM20948 (`dev/icm20948.nim`)
9-Axis IMU (Accel, Gyro, Mag).
```nim
proc init*(imu: var Icm20948I2C, config: Icm20948I2CConfig)
proc getAccelVect*(imu: var Icm20948I2C): Icm20948Vect
proc getGyroVect*(imu: var Icm20948I2C): Icm20948Vect
proc getMagVect*(imu: var Icm20948I2C): Icm20948Vect
```

### TLV493D (`dev/tlv493d.nim`)
3D Magnetic Sensor.
```nim
proc init*(sensor: var Tlv493dI2C, config: Tlv493dConfig)
proc updateData*(sensor: var Tlv493dI2C)
proc getX*(sensor: var Tlv493dI2C): float
```

## LED Drivers

### NeoPixel Driver (`dev/neopixel.nim`)
Control WS2812B LEDs via I2C bridge.
```nim
proc init*(neo: var NeoPixelI2C, config: NeoPixelI2CConfig)
proc setPixelColor*(neo: var NeoPixelI2C, n: uint16, r, g, b: uint8)
proc show*(neo: var NeoPixelI2C)
```

### DotStar Driver (`dev/dotstar.nim`)
APA102/SK9822 SPI LEDs.
```nim
proc init*(ds: var DotStarSpi, config: DotStarConfig)
proc setPixelColor*(ds: var DotStarSpi, idx: uint16, color: Color)
proc show*(ds: var DotStarSpi)
```

### LED Driver PCA9685 (`dev/leddriver.nim`)
16-channel 12-bit PWM LED driver (I2C).
```nim
proc init*[N, P](driver: var LedDriverPca9685[N, P], ...)
proc setLed*(driver: var LedDriverPca9685, idx: int, brightness: float32)
proc swapBuffersAndTransmit*(driver: var LedDriverPca9685): bool
```

## Input & IO

### MPR121 Touch (`dev/mpr121.nim`)
12-channel capacitive touch sensor.
```nim
proc init*(mpr: var Mpr121I2C, config: Mpr121Config)
proc touched*(mpr: var Mpr121I2C): uint16
proc filteredData*(mpr: var Mpr121I2C, ch: uint8): uint16
```

### NeoTrellis (`dev/neotrellis.nim`)
4x4 RGB Button Pad.
```nim
proc init*(trellis: var NeoTrellisI2C, config: NeoTrellisConfig)
proc activateKey*(trellis: var NeoTrellisI2C, x, y, edge: uint8, enable: bool)
proc getRising*(trellis: var NeoTrellisI2C, idx: uint8): bool
```

### MCP23x17 (`dev/mcp23x17.nim`)
16-bit GPIO Expander.
```nim
proc init*(mcp: var Mcp23017, config: Mcp23017Config)
proc portMode*(mcp: var Mcp23017, port: MCPPort, dir, pull, inv: uint8)
proc digitalWrite*(mcp: var Mcp23017, port: MCPPort, val: uint8)
proc read*(mcp: var Mcp23017): uint16
```

### MAX11300 (`dev/max11300.nim`)
20-port Mixed Signal IO (ADC/DAC/GPIO).
```nim
proc init*[N](max: var MAX11300[N], config: MAX11300Config)
proc configurePinAsAnalogRead*(max: var MAX11300, dev, pin, range)
proc readAnalogPinVolts*(max: var MAX11300, dev, pin): float32
```

### Shift Register 4021 (`dev/sr4021.nim`)
Input shift register (e.g. CD4021).
```nim
proc init*[ND, NP](sr: var ShiftRegister4021[ND, NP], config: ShiftRegister4021Config)
proc update*(sr: var ShiftRegister4021)
proc state*(sr: ShiftRegister4021, idx: int): bool
```

### Shift Register 595 (`dev/sr595.nim`)
Output shift register (e.g. 74HC595).
```nim
proc init*(sr: var ShiftRegister595, pin_cfg: ptr Pin, num: csize_t)
proc set*(sr: var ShiftRegister595, idx: uint8, state: bool)
proc write*(sr: var ShiftRegister595)
```

## Displays

### SSD1351 Color OLED (`dev/oled_ssd1351.nim`)
128x128 RGB.
```nim
template initSSD1351Spi*(width, height: static[int], ...): untyped
proc setColorRGB*(disp: var SSD1351Spi128x128, r, g, b: uint8)
```

### SSD1327 Grayscale OLED (`dev/oled_ssd1327.nim`)
128x128 4-bit Grayscale.
```nim
template initSSD1327Spi*(width, height: static[int], ...): untyped
proc setGrayscale*(disp: var SSD1327Spi128x128, level: uint8)
```

### SH1106 OLED (`dev/oled_sh1106.nim`)
128x64 Monochrome (compatible with SSD1306).
```nim
template initSH1106I2c*(width, height: static[int], ...): untyped
template initSH1106Spi*(width, height: static[int], ...): untyped
```

### HD44780 LCD (`dev/lcd_hd44780.nim`)
Character LCD (16x2, 20x4).
```nim
proc init*(lcd: var LcdHD44780, config: LcdHD44780Config)
proc print*(lcd: var LcdHD44780, text: cstring)
proc setCursor*(lcd: var LcdHD44780, row, col: uint8)
```

## Audio Codecs

### AK4556 (`dev/codec_ak4556.nim`)
Simple 24-bit codec (Daisy Seed 1.0).
```nim
proc init*(codec: var Ak4556, resetPin: Pin)
```

### PCM3060 (`dev/codec_pcm3060.nim`)
High-performance 24-bit codec (Daisy Seed 2).
```nim
proc init*(codec: var Pcm3060, i2c: I2CHandle)
```

### WM8731 (`dev/codec_wm8731.nim`)
Flexible codec with I2C control (Daisy Seed 1.1).
```nim
proc init*(codec: var Wm8731, config: Wm8731Config, i2c: I2CHandle)
```

---

# Data Structures & Utils

## FileTable (`nimphea_filetable.nim`)
Index files on storage.
```nim
proc fill*(table: var FileTable[N], path: cstring, suffix: cstring)
proc getFileName*(table: FileTable[N], idx: csize_t): cstring
```

## Stack (`nimphea_stack.nim`)
Fixed-capacity LIFO.
```nim
proc push*(stack: var Stack[N, T], val: T): bool
proc pop*(stack: var Stack[N, T], val: var T): bool
```

## FIFO (`nimphea_fifo.nim`)
Fixed-capacity FIFO queue.
```nim
proc push*(fifo: var Fifo[N, T], val: T): bool
proc pop*(fifo: var Fifo[N, T], val: var T): bool
```

## RingBuffer (`nimphea_ringbuffer.nim`)
Circular buffer for streaming.
```nim
proc write*(rb: var RingBuffer[N, T], val: T): bool
proc read*(rb: var RingBuffer[N, T], val: var T): bool
```

## FixedStr (`nimphea_fixedstr.nim`)
Stack-allocated string.
```nim
proc add*(s: var FixedStr[N], c: char)
proc clear*(s: var FixedStr[N])
```

## V/Oct Calibration (`nimphea_voct_calibration.nim`)

1V/octave calibration for musical pitch CV (Control Voltage) inputs. Converts ADC readings to MIDI note numbers for accurate pitch tracking in Eurorack applications.

**Background:**
- **1V/octave** is the standard CV pitch control in modular synthesizers
- 1V = +12 semitones (one octave), 83.33mV = +1 semitone
- 0V = C0 (MIDI 0), 1V = C1 (MIDI 12), 4V = C4 (MIDI 48, middle C)

**Types:**
```nim
type VoctCalibration* = object
```

**Calibration Methods:**
```nim
proc record*(this: var VoctCalibration, val1V, val3V: cfloat): bool
proc getData*(this: var VoctCalibration, scale, offset: var cfloat): bool
proc getCalibrationData*(this: var VoctCalibration): tuple[scale, offset: float32, valid: bool]
proc setData*(this: var VoctCalibration, scale, offset: cfloat)
proc isCalibrated*(this: var VoctCalibration): bool
```

**Processing Methods:**
```nim
proc processInput*(this: var VoctCalibration, inval: cfloat): cfloat
proc cvToMidiNote*(this: var VoctCalibration, cvInput: float32): float32
proc cvToNoteName*(this: var VoctCalibration, cvInput: float32): string
```

**Helper Functions:**
```nim
proc midiNoteToFreq*(midiNote: float32): float32
proc midiNoteToName*(midiNote: int): string
```

## Macros (`nimphea_macros.nim`)
C++ Interop macro system. Used internally by wrappers to generate C++ code.
- `useNimpheaNamespace()`
- `useNimpheaModules()`
