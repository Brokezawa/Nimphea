## Nimphea - C++ Interop Macros
##
## This module contains the compile-time macro system for automatic C++ type generation.
## It provides two macros:
## - useNimpheaNamespace() - Include all typedefs (recommended)
## - useNimpheaModules(...) - Selective inclusion of specific modules
##
## Users should import this module indirectly through nimphea.nim

import macros

# ============================================================================
# Type Definition Lists - Organized by Module
# ============================================================================

# DAC module typedefs
const dacTypedefs* = [
  "DacHandle::Result DacResult",
  "DacHandle::Channel DacChannel",
  "DacHandle::Mode DacMode",
  "DacHandle::BitDepth DacBitDepth",
  "DacHandle::BufferState DacBufferState",
  "DacHandle::Config DacConfig",
  "DacHandle DacHandle"
]

# Timer module typedefs
const timerTypedefs* = [
  "TimerHandle::Config::Peripheral TimerPeripheral",
  "TimerHandle::Config::CounterDir TimerCounterDir",
  "TimerHandle::Result TimerResult",
  "TimerHandle::Config TimerConfig",
  "TimerHandle TimerHandle"
]

# Parameter module typedefs
const parameterTypedefs* = [
  "Parameter::Curve Curve"
]

# WavPlayer module typedefs
const wavPlayerTypedefs* = [
  "WavPlayer<4096> WavPlayer4K",
  "WavPlayer<8192> WavPlayer8K",
  "WavPlayer<16384> WavPlayer16K",
  "WavPlayer<4096>::FileInfo WavPlayerFileInfo"
]

# WavWriter module typedefs
const wavWriterTypedefs* = [
  "WavWriter<4096> WavWriter4K",
  "WavWriter<8192> WavWriter8K",
  "WavWriter<16384> WavWriter16K",
  "WavWriter<4096>::Config WavWriterConfig"
]

# Core typedefs - always included
const coreTypedefs* = [
  "GPIO::Mode GPIOMode",
  "GPIO::Pull GPIOPull",
  "GPIO::Speed GPIOSpeed",
  "SaiHandle::Config::SampleRate SampleRate",
  "DaisySeed::BoardVersion BoardVersion"
]

# Controls module typedefs (switches, encoders)
const controlsTypedefs* = [
  "Switch::Type SwitchType",
  "Switch::Polarity SwitchPolarity",
  "GPIO::Pull SwitchPull"
]

# ADC module typedefs
const adcTypedefs* = [
  "AdcChannelConfig AdcChannelConfig",
  "AdcHandle::OverSampling OverSampling",
  "AdcChannelConfig::ConversionSpeed ConversionSpeed",
  "AdcChannelConfig::MuxPin MuxPin"
]

# PWM module typedefs
const pwmTypedefs* = [
  "PWMHandle PwmHandle",
  "PWMHandle::Config PwmConfig",
  "PWMHandle::Config::Peripheral PwmPeripheral",
  "PWMHandle::Result PwmResult",
  "PWMHandle::Channel PwmChannel",
  "PWMHandle::Channel::Config PwmChannelConfig",
  "PWMHandle::Channel::Config::Polarity PwmPolarity"
]

# OLED module typedefs
const oledTypedefs* = [
  "SSD130xI2CTransport SSD130xI2CTransport",
  "SSD130xI2CTransport::Config SSD130xI2CTransportConfig",
  "SSD130x4WireSpiTransport SSD130x4WireSpiTransport",
  "SSD130x4WireSpiTransport::Config SSD130x4WireSpiTransportConfig",
  "SSD130xI2c128x64Driver OledDisplay128x64I2c",
  "SSD130xI2c128x32Driver OledDisplay128x32I2c",
  "SSD130xI2c64x48Driver OledDisplay64x48I2c",
  "SSD130xI2c64x32Driver OledDisplay64x32I2c",
  "SSD130x4WireSpi128x64Driver OledDisplay128x64Spi",
  "SSD130x4WireSpi128x32Driver OledDisplay128x32Spi",
  "SSD130x4WireSpi64x48Driver OledDisplay64x48Spi",
  "SSD130x4WireSpi64x32Driver OledDisplay64x32Spi",
  "SSD130xI2c128x64Driver::Config OledDisplayI2cConfig",
  "SSD130x4WireSpi128x64Driver::Config OledDisplaySpiConfig"
]

# I2C module typedefs
const i2cTypedefs* = [
  "I2CHandle I2CHandle",
  "I2CHandle::Config I2CConfig",
  "I2CHandle::Config::Speed I2CSpeed",
  "I2CHandle::Config::Peripheral I2CPeripheral",
  "I2CHandle::Config::Mode I2CMode",
  "I2CHandle::Result I2CResult"
]

# SPI module typedefs
const spiTypedefs* = [
  "SpiHandle::Config SpiConfig",
  "SpiHandle::Config::Peripheral SpiPeripheral",
  "SpiHandle::Config::Mode SpiMode",
  "SpiHandle::Config::ClockPolarity SpiClockPolarity",
  "SpiHandle::Config::ClockPhase SpiClockPhase",
  "SpiHandle::Config::Direction SpiDirection",
  "SpiHandle::Config::NSS SpiNSS",
  "SpiHandle::Config::BaudPrescaler SpiBaudPrescaler",
  "SpiHandle::Result SpiResult"
]

# SDRAM module typedefs
const sdramTypedefs* = [
  "SdramHandle::Result SdramResult"
]

# USB module typedefs
const usbTypedefs* = [
  "UsbHandle::Result UsbResult",
  "UsbHandle::UsbPeriph UsbPeriph"
]

# QSPI module typedefs
const qspiTypedefs* = [
  "QSPIHandle::Result QSPIResult",
  "QSPIHandle::Config QSPIConfig",
  "QSPIHandle::Config::Mode QSPIMode",
  "QSPIHandle::Config::Device QSPIDevice"
]

# SPI Multi-Slave module typedefs (uses SPI typedefs)
const spiMultislaveTypedefs* : seq[string] = @[]  # Uses SPI typedefs, no additional types

# Persistent Storage module typedefs
const persistentStorageTypedefs* = [
  "PersistentStorage<int>::State StorageState"
]

const saiTypedefs* : seq[string] = @[]
const usbMidiTypedefs* : seq[string] = @[]
const usbHostTypedefs* : seq[string] = @[]

# SDMMC module typedefs
const sdmmcTypedefs* = [
  "SdmmcHandler::Result SdmmcResult",
  "SdmmcHandler::BusWidth SdmmcBusWidth",
  "SdmmcHandler::Speed SdmmcSpeed",
  "SdmmcHandler::Config SdmmcConfig",
  "SdmmcHandler SdmmcHandler",
  "FatFSInterface::Result FatFSResult",
  "FatFSInterface::Config::Media FatFSMedia",
  "FatFSInterface::Config FatFSConfig",
  "FatFSInterface FatFSInterface"
]

# Codec module typedefs
const codec_ak4556Typedefs* : seq[string] = @[]
const codec_wm8731Typedefs* = [
  "Wm8731::Result Wm8731Result",
  "Wm8731::Config Wm8731Config",
  "Wm8731::Config::Format Wm8731Format",
  "Wm8731::Config::WordLength Wm8731WordLength"
]
const codec_pcm3060Typedefs* = [
  "Pcm3060::Result Pcm3060Result"
]

# LCD module typedefs
const lcd_hd44780Typedefs* = [
  "LcdHD44780::Config LcdHD44780Config"
]

# OLED fonts module typedefs
const oled_fontsTypedefs* = [
  "FontDef FontDef"
]

# SH1106 OLED module typedefs (v0.15.0)
const sh1106Typedefs* = [
  "SH1106I2c128x64Driver SH1106I2c128x64",
  "SH11064WireSpi128x64Driver SH1106Spi128x64",
  "SH1106I2c128x64::Config SH1106I2cConfig",
  "SH1106Spi128x64::Config SH1106SpiConfig"
]

# SSD1327 grayscale OLED module typedefs (v0.15.0)
const ssd1327Typedefs* = [
  "SSD13274WireSpi128x128Driver SSD1327Spi128x128",
  "SSD1327Spi128x128::Config SSD1327SpiConfig"
]

# SSD1351 color OLED module typedefs (v0.15.0)
const ssd1351Typedefs* = [
  "SSD13514WireSpi128x128Driver SSD1351Spi128x128",
  "SSD1351Spi128x128::Config SSD1351SpiConfig"
]

# UI framework module typedefs (v0.15.0)
const uiTypedefs*: seq[string] = @[]  # UI module (template-based, no typedefs needed)

# Menu system typedefs (v0.15.0)
const menuTypedefs* = [
  "daisy::AbstractMenu::ItemType MenuItemType",
  "daisy::AbstractMenu::Orientation MenuOrientation",
  "daisy::AbstractMenu::ItemConfig MenuItemConfig",
  "daisy::ArrowButtonType ArrowButtonType",
  "daisy::UiCanvasDescriptor UiCanvasDescriptor",
  "daisy::MappedValue MappedValue",
  "daisy::MappedFloatValue MappedFloatValue",
  "daisy::MappedFloatValue::Mapping MappedValueMapping"
]

# UI Core system typedefs (v0.15.0)
const uiCoreTypedefs* = [
  "daisy::UI::SpecialControlIds UiSpecialControlIds"
]

# LED/IO expansion module typedefs (v0.9.0)
const leddriver* : seq[string] = @[]  # Uses templates, no typedefs needed
const dotstar* : seq[string] = @[]
const neopixel* : seq[string] = @[]
const mcp23x17* : seq[string] = @[]
const sr595* : seq[string] = @[]
const sr4021* : seq[string] = @[]
const max11300* : seq[string] = @[]

# Board support module typedefs (v0.11.0+)
const podTypedefs* : seq[string] = @[]  # DaisyPod board (uses existing component types)
const fieldTypedefs* = [
  "LedDriverPca9685<2, true> FieldLedDriver"  # Field LED driver (2× PCA9685, persistent buffer)
]
const patchSmTypedefs*: seq[string] = @[]  # DaisyPatchSM board (uses existing component types)
const petalTypedefs* = [
  "LedDriverPca9685<2, true> PetalLedDriver"  # Petal LED driver (2× PCA9685, persistent buffer)
]
const versioTypedefs*: seq[string] = @[]  # DaisyVersio board (uses existing component types)
const legioTypedefs*: seq[string] = @[]   # DaisyLegio board (uses existing component types)

# System utilities typedefs (v0.14.0+)
const systemTypedefs* = [
  "System::Config SystemConfig",
  "System::Config::SysClkFreq SysClkFreq",
  "System::MemoryRegion MemoryRegion",
  "System::BootInfo BootInfo"
]
const dmaTypedefs*: seq[string] = @[]  # DMA utilities (C functions only, no typedefs needed)
const fatfsTypedefs*: seq[string] = @[]
const midiTypedefs*: seq[string] = @[]
const voctTypedefs*: seq[string] = @[]  # V/Oct calibration (simple class, no nested types)
const scopedIrqTypedefs*: seq[string] = @[]  # Scoped IRQ blocker (simple class, no nested types)
const loggerTypedefs* = [
  "LoggerDestination LoggerDestination"
]
const fileReaderTypedefs*: seq[string] = @[]
const fileTableTypedefs* = [
  "daisy::FileTable<8> FileTable8",
  "daisy::FileTable<16> FileTable16",
  "daisy::FileTable<32> FileTable32",
  "daisy::FileTable<64> FileTable64",
  "daisy::FileTable<128> FileTable128"
]

# All typedefs combined (for full inclusion)
const daisyTypedefsList* = @coreTypedefs & @controlsTypedefs & @adcTypedefs & @pwmTypedefs &
                           @oledTypedefs & @i2cTypedefs & @spiTypedefs & @sdramTypedefs & @usbTypedefs & @sdmmcTypedefs &
                           @codec_wm8731Typedefs & @codec_pcm3060Typedefs & @lcd_hd44780Typedefs & @oled_fontsTypedefs &
                           @qspiTypedefs & @persistentStorageTypedefs

# ============================================================================
# C++ Header Includes
# ============================================================================

# Helper to get headers for a specific module
proc getModuleHeaders*(moduleName: string): string =
  ## Returns the C++ header includes needed for a specific module
  case moduleName
  of "core":
    """#include "daisy_seed.h"
"""
  of "sdmmc":
    """#include "daisy_seed.h"
"""
  of "dac":
    """#include "per/dac.h"
"""
  of "tim":
    """#include "per/tim.h"
"""
  of "rng":
    """#include "per/rng.h"
"""
  of "gatein":
    """#include "hid/gatein.h"
"""
  of "led":
    """#include "hid/led.h"
"""
  of "rgb_led":
    """#include "hid/rgb_led.h"
"""
  of "switch":
    """#include "hid/switch.h"
"""
  of "switch3":
    """#include "hid/switch3.h"
"""
  of "unique_id":
    """#include "util/unique_id.h"
"""
  of "cpuload":
    """#include "util/CpuLoadMeter.h"
"""
  of "parameter":
    """#include "hid/parameter.h"
"""
  of "wav_player":
    """#include "util/WavPlayer.h"
"""
  of "wav_writer":
    """#include "util/WavWriter.h"
"""
  of "wav_parser":
    """#include "util/WavParser.h"
#include "util/FileReader.h"
"""
  of "wav_format":
    """#include "util/wav_format.h"
"""
  of "wavetable_loader":
    """#include "util/WaveTableLoader.h"
"""
  of "color":
    """#include "util/color.h"
"""
  of "mapped_value":
    """#include "util/MappedValue.h"
"""
  of "controls":
    """#include "hid/switch.h"
#include "hid/encoder.h"
"""
  of "adc":
    """#include "per/adc.h"
"""
  of "pwm":
    """#include "per/pwm.h"
"""
  of "sai":
    """#include "per/sai.h"
"""
  of "oled":
    """#include "dev/oled_ssd130x.h"
"""
  of "i2c":
    """#include "per/i2c.h"
"""
  of "spi":
    """#include "per/spi.h"
"""
  of "serial":
    """#include "per/uart.h"
#include "hid/logger.h"
"""
  of "sdram":
    """#include "dev/sdram.h"
"""
  of "usb":
    """#include "hid/usb.h"
"""
  of "usb_midi":
    """#include "hid/usb_midi.h"
"""
  of "usb_host":
    """#include "hid/usb_host.h"
"""
  of "codec_ak4556":
    """#include "dev/codec_ak4556.h"
"""
  of "codec_wm8731":
    """#include "dev/codec_wm8731.h"
"""
  of "codec_pcm3060":
    """#include "dev/codec_pcm3060.h"
"""
  of "lcd_hd44780":
    """#include "dev/lcd_hd44780.h"
"""
  of "oled_fonts":
    """#include "util/oled_fonts.h"
"""
  of "icm20948":
    """#include "dev/icm20948.h"
"""
  of "apds9960":
    """#include "dev/apds9960.h"
"""
  of "dps310":
    """#include "dev/dps310.h"
"""
  of "tlv493d":
    """#include "dev/tlv493d.h"
"""
  of "mpr121":
    """#include "dev/mpr121.h"
"""
  of "neotrellis":
    """#include "dev/neotrellis.h"
"""
  of "leddriver":
    """#include "dev/leddriver.h"
"""
  of "dotstar":
    """#include "dev/dotstar.h"
"""
  of "neopixel":
    """#include "dev/neopixel.h"
"""
  of "mcp23x17":
    """#include "dev/mcp23x17.h"
"""
  of "sr595":
    """#include "dev/sr_595.h"
"""
  of "sr4021":
    """#include "dev/sr_4021.h"
"""
  of "max11300":
    """#include "dev/max11300.h"
"""
  of "sh1106":
    """#include "dev/oled_sh1106.h"
"""
  of "ssd1327":
    """#include "dev/oled_ssd1327.h"
"""
  of "ssd1351":
    """#include "dev/oled_ssd1351.h"
"""
  of "qspi":
    """#include "per/qspi.h"
"""
  of "spi_multislave":
    """#include "per/spiMultislave.h"
"""
  of "persistent_storage":
    """#include "util/PersistentStorage.h"
#include "sys/system.h"
"""
  of "pod":
    """#include "daisy_pod.h"
"""
  of "patch":
    """#include "daisy_patch.h"
"""
  of "field":
    """#include "daisy_field.h"
"""
  of "patch_sm":
    """#include "daisy_patch_sm.h"
"""
  of "petal":
    """#include "daisy_petal.h"
"""
  of "versio":
    """#include "daisy_versio.h"
"""
  of "legio":
    """#include "daisy_legio.h"
"""
  of "system":
    """#include "sys/system.h"
"""
  of "fatfs":
    """#include "sys/fatfs.h"
"""
  of "dma":
    """#include "sys/dma.h"
"""
  of "midi":
    """#include "hid/midi.h"
"""
  of "voct":
    """#include "util/VoctCalibration.h"
"""
  of "scoped_irq":
    """#include "util/scopedirqblocker.h"
"""
  of "logger":
    """#include "hid/logger.h"
"""
  of "file_reader":
    """#include "util/FileReader.h"
"""
  of "file_table":
    """#include "util/FileTable.h"
"""
  of "ui":
    """#include "ui/ButtonMonitor.h"
#include "ui/PotMonitor.h"
#include "ui/UiEventQueue.h"
"""
  of "menu":
    """#include "ui/AbstractMenu.h"
#include "ui/FullScreenItemMenu.h"
#include "ui/UI.h"
#include "util/MappedValue.h"
"""
  of "ui_core":
    """#include "ui/UI.h"
#include "ui/UiEventQueue.h"
"""
  else: ""

# All headers combined (for full inclusion)
const daisyHeaders* = """
#include "daisy_seed.h"
#include "hid/switch.h"
#include "hid/encoder.h"
#include "hid/usb.h"
#include "dev/sdram.h"
#include "per/i2c.h"
#include "per/spi.h"
#include "per/uart.h"
#include "per/adc.h"
#include "per/pwm.h"
#include "dev/oled_ssd130x.h"
"""

# ============================================================================
# Helper Functions
# ============================================================================

# SDRAM helper function as C++ code
const sdramHelperFunction* = """
inline void clearSdramBss() {
    extern uint32_t _ssdram_bss;
    extern uint32_t _esdram_bss;
    uint32_t* start = &_ssdram_bss;
    uint32_t* end = &_esdram_bss;
    while(start < end) {
        *start++ = 0;
    }
}
"""

proc buildTypedefsString*(typedefs: openArray[string]): string =
  ## Helper to build typedef emit string from a list of typedefs
  result = ""
  for typedef in typedefs:
    result.add("typedef ")
    result.add(typedef)
    result.add(";\n")

# ============================================================================
# Public Macros
# ============================================================================

macro useNimpheaNamespace*(): untyped =
  ## Automatically generates all necessary C++ emit statements for Daisy types.
  ## This macro runs at compile time and injects the required C++ code.
  ##
  ## **This is the recommended approach for most projects.**
  ##
  ## Includes:
  ## - All C++ headers for Nimphea modules
  ## - Namespace declaration (using namespace daisy;)
  ## - All 26 type aliases
  ## - Helper functions (clearSdramBss)
  ##
  ## Usage:
  ## ```nim
  ## import nimphea
  ## useNimpheaNamespace()  # One line - includes everything!
  ##
  ## proc main() =
  ##   var daisy = initDaisy()
  ##   # ... use any Nimphea features
  ## ```
  ##
  ## **Compile-time code generation** - Zero runtime cost!
  
  result = newStmtList()
  
  # 1. Emit header includes in INCLUDESECTION
  let includesEmit = newNimNode(nnkPragma)
  includesEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit("/*INCLUDESECTION*/\n" & daisyHeaders)
    )
  )
  result.add(includesEmit)
  
  # 2. Emit namespace declaration
  let namespaceEmit = newNimNode(nnkPragma)
  namespaceEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit("using namespace daisy;")
    )
  )
  result.add(namespaceEmit)
  
  # 3. Build and emit typedef section
  var typedefsStr = "/*TYPESECTION*/\nusing namespace daisy;\n"
  for typedef in daisyTypedefsList:
    typedefsStr.add("typedef ")
    typedefsStr.add(typedef)
    typedefsStr.add(";\n")
  
  let typedefsEmit = newNimNode(nnkPragma)
  typedefsEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit(typedefsStr)
    )
  )
  result.add(typedefsEmit)
  
  # 4. Emit helper functions
  let helpersEmit = newNimNode(nnkPragma)
  helpersEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit(sdramHelperFunction)
    )
  )
  result.add(helpersEmit)

macro useNimpheaModules*(modules: varargs[untyped]): untyped =
  ## Selective inclusion - only includes typedefs for specified modules.
  ## This is more efficient than including everything.
  ##
  ## **Use this for minimal projects or when you want to reduce generated code size.**
  ##
  ## Available modules:
  ## - `core` - Always included automatically (GPIO, SampleRate, BoardVersion)
  ## - `controls` - Switches, encoders (Switch types)
  ## - `adc` - ADC types (AdcChannelConfig, OverSampling, etc.)
  ## - `pwm` - PWM types (PwmPeripheral, PwmChannel, etc.)
  ## - `oled` - OLED display types (OledDisplay128x64I2c, etc.)
  ## - `i2c` - I2C types (Speed, Peripheral, Mode)
  ## - `spi` - SPI types (Peripheral, Mode, ClockPolarity, etc.)
  ## - `serial` - UART types
  ## - `sdram` - SDRAM types (Result, helper functions)
  ## - `usb` - USB types (Result, UsbPeriph)
  ## - `qspi` - QSPI flash types (Result, Mode, Device)
  ## - `spi_multislave` - Multi-slave SPI (uses SPI typedefs)
  ## - `persistent_storage` - Persistent storage types (StorageState)
  ##
  ## Usage:
  ## ```nim
  ## import nimphea, per/i2c, per/spi
  ## useNimpheaModules(i2c, spi)  # Only I2C and SPI typedefs
  ##
  ## proc main() =
  ##   var daisy = initDaisy()
  ##   var i2c = initI2C(...)
  ##   var spi = initSPI(...)
  ##   # ...
  ## ```
  ##
  ## **Generates minimal C++ code at compile time** - Only what you need!
  
  result = newStmtList()
  
  # Collect which modules to include
  var includeDac = false
  var includeTim = false
  var includeRng = false
  var includeGateIn = false
  var includeLed = false
  var includeRgbLed = false
  var includeSwitch = false
  var includeSwitch3 = false
  var includeUniqueId = false
  var includeCpuLoad = false
  var includeParameter = false
  var includeWavPlayer = false
  var includeWavWriter = false
  var includeWavParser = false
  var includeWavFormat = false
  var includeWavetableLoader = false
  var includeColor = false
  var includeMappedValue = false
  var includeControls = false
  var includeAdc = false
  var includePwm = false
  var includeOled = false
  var includeI2c = false
  var includeSai = false
  var includeSpi = false
  var includeSerial = false
  var includeSdram = false
  var includeUsb = false
  var includeUsbMidi = false
  var includeUsbHost = false
  var includeCodecAk4556 = false
  var includeCodecWm8731 = false
  var includeCodecPcm3060 = false
  var includeLcdHd44780 = false
  var includeOledFonts = false
  var includeIcm20948 = false
  var includeApds9960 = false
  var includeDps310 = false
  var includeTlv493d = false
  var includeMpr121 = false
  var includeNeotrellis = false
  var includeLeddriver = false
  var includeDotstar = false
  var includeNeopixel = false
  var includeMcp23x17 = false
  var includeSr595 = false
  var includeSr4021 = false
  var includeMax11300 = false
  var includeSH1106 = false
  var includeSSD1327 = false
  var includeSSD1351 = false
  var includeQspi = false
  var includeSdmmc = false
  var includeSpiMultislave = false
  var includePersistentStorage = false
  var includePod = false
  var includePatch = false
  var includeField = false
  var includePatchSm = false
  var includePetal = false
  var includeVersio = false
  var includeLegio = false
  var includeSystem = false
  var includeFatfs = false
  var includeDma = false
  var includeMidi = false
  var includeVoct = false
  var includeScopedIrq = false
  var includeLogger = false
  var includeFileReader = false
  var includeFileTable = false
  var includeUi = false
  var includeMenu = false
  var includeUiCore = false
  
  # Parse module arguments
  for module in modules:
    let moduleName = $module
    case moduleName
    of "dac": includeDac = true
    of "tim": includeTim = true
    of "rng": includeRng = true
    of "gatein": includeGateIn = true
    of "led": includeLed = true
    of "rgb_led": includeRgbLed = true
    of "switch": includeSwitch = true
    of "switch3": includeSwitch3 = true
    of "unique_id": includeUniqueId = true
    of "cpuload": includeCpuLoad = true
    of "parameter": includeParameter = true
    of "wav_player": includeWavPlayer = true
    of "wav_writer": includeWavWriter = true
    of "wav_parser": includeWavParser = true
    of "wav_format": includeWavFormat = true
    of "wavetable_loader": includeWavetableLoader = true
    of "color": includeColor = true
    of "mapped_value": includeMappedValue = true
    of "controls": includeControls = true
    of "adc": includeAdc = true
    of "pwm": includePwm = true
    of "oled": includeOled = true
    of "i2c": includeI2c = true
    of "sai": includeSai = true
    of "spi": includeSpi = true
    of "serial": includeSerial = true
    of "sdram": includeSdram = true
    of "usb": includeUsb = true
    of "usb_midi": includeUsbMidi = true
    of "usb_host": includeUsbHost = true
    of "codec_ak4556": includeCodecAk4556 = true
    of "codec_wm8731": includeCodecWm8731 = true
    of "codec_pcm3060": includeCodecPcm3060 = true
    of "lcd_hd44780": includeLcdHd44780 = true
    of "oled_fonts": includeOledFonts = true
    of "icm20948": includeIcm20948 = true
    of "apds9960": includeApds9960 = true
    of "dps310": includeDps310 = true
    of "tlv493d": includeTlv493d = true
    of "mpr121": includeMpr121 = true
    of "neotrellis": includeNeotrellis = true
    of "leddriver": includeLeddriver = true
    of "dotstar": includeDotstar = true
    of "neopixel": includeNeopixel = true
    of "mcp23x17": includeMcp23x17 = true
    of "sr595": includeSr595 = true
    of "sr4021": includeSr4021 = true
    of "max11300": includeMax11300 = true
    of "sh1106": includeSH1106 = true
    of "ssd1327": includeSSD1327 = true
    of "ssd1351": includeSSD1351 = true
    of "qspi": includeQspi = true
    of "sdmmc": includeSdmmc = true
    of "spi_multislave": includeSpiMultislave = true
    of "persistent_storage": includePersistentStorage = true
    of "pod": includePod = true
    of "patch": includePatch = true
    of "field": includeField = true
    of "patch_sm": includePatchSm = true
    of "petal": includePetal = true
    of "versio": includeVersio = true
    of "legio": includeLegio = true
    of "system": includeSystem = true
    of "fatfs": includeFatfs = true
    of "dma": includeDma = true
    of "midi": includeMidi = true
    of "voct": includeVoct = true
    of "scoped_irq": includeScopedIrq = true
    of "logger": includeLogger = true
    of "file_reader": includeFileReader = true
    of "file_table": includeFileTable = true
    of "ui": includeUi = true
    of "menu": includeMenu = true
    of "ui_core": includeUiCore = true
    of "core": discard  # Always included
    else:
      error("Unknown module: " & moduleName & 
            ". Available: core, controls, adc, pwm, oled, i2c, spi, serial, sdram, usb, sdmmc, " &
            "sai, usb_midi, usb_host, " &
            "dac, tim, rng, gatein, led, rgb_led, switch, switch3, unique_id, cpuload, parameter, " &
            "wav_player, wav_writer, wav_parser, wav_format, wavetable_loader, color, mapped_value, " &
            "codec_ak4556, codec_wm8731, codec_pcm3060, lcd_hd44780, oled_fonts, " &
            "codec_ak4556, codec_wm8731, codec_pcm3060, lcd_hd44780, oled_fonts, " &
            "icm20948, apds9960, dps310, tlv493d, mpr121, neotrellis, " &
            "leddriver, dotstar, neopixel, mcp23x17, sr595, sr4021, max11300, sh1106, ssd1327, ssd1351, " &
            "qspi, spi_multislave, persistent_storage, pod, field, patch, patch_sm, petal, versio, legio, " &
            "system, fatfs, dma, midi, voct, scoped_irq, logger, file_reader, file_table, ui, menu, ui_core")
  
  # Build headers string
  var headersStr = "/*INCLUDESECTION*/\n"
  headersStr.add(getModuleHeaders("core"))
  if includeDac: headersStr.add(getModuleHeaders("dac"))
  if includeTim: headersStr.add(getModuleHeaders("tim"))
  if includeRng: headersStr.add(getModuleHeaders("rng"))
  if includeGateIn: headersStr.add(getModuleHeaders("gatein"))
  if includeLed: headersStr.add(getModuleHeaders("led"))
  if includeRgbLed: headersStr.add(getModuleHeaders("rgb_led"))
  if includeSwitch: headersStr.add(getModuleHeaders("switch"))
  if includeSwitch3: headersStr.add(getModuleHeaders("switch3"))
  if includeUniqueId: headersStr.add(getModuleHeaders("unique_id"))
  if includeCpuLoad: headersStr.add(getModuleHeaders("cpuload"))
  if includeParameter: headersStr.add(getModuleHeaders("parameter"))
  if includeWavPlayer: headersStr.add(getModuleHeaders("wav_player"))
  if includeWavWriter: headersStr.add(getModuleHeaders("wav_writer"))
  if includeWavParser: headersStr.add(getModuleHeaders("wav_parser"))
  if includeWavFormat: headersStr.add(getModuleHeaders("wav_format"))
  if includeWavetableLoader: headersStr.add(getModuleHeaders("wavetable_loader"))
  if includeColor: headersStr.add(getModuleHeaders("color"))
  if includeMappedValue: headersStr.add(getModuleHeaders("mapped_value"))
  if includeControls: headersStr.add(getModuleHeaders("controls"))
  if includeAdc: headersStr.add(getModuleHeaders("adc"))
  if includePwm: headersStr.add(getModuleHeaders("pwm"))
  if includeSai: headersStr.add(getModuleHeaders("sai"))
  if includeOled: headersStr.add(getModuleHeaders("oled"))
  if includeI2c: headersStr.add(getModuleHeaders("i2c"))
  if includeSpi: headersStr.add(getModuleHeaders("spi"))
  if includeSerial: headersStr.add(getModuleHeaders("serial"))
  if includeSdram: headersStr.add(getModuleHeaders("sdram"))
  if includeUsb: headersStr.add(getModuleHeaders("usb"))
  if includeUsbMidi: headersStr.add(getModuleHeaders("usb_midi"))
  if includeUsbHost: headersStr.add(getModuleHeaders("usb_host"))
  if includeSdmmc: headersStr.add(getModuleHeaders("sdmmc"))
  if includeCodecAk4556: headersStr.add(getModuleHeaders("codec_ak4556"))
  if includeCodecWm8731: headersStr.add(getModuleHeaders("codec_wm8731"))
  if includeCodecPcm3060: headersStr.add(getModuleHeaders("codec_pcm3060"))
  if includeLcdHd44780: headersStr.add(getModuleHeaders("lcd_hd44780"))
  if includeOledFonts: headersStr.add(getModuleHeaders("oled_fonts"))
  if includeIcm20948: headersStr.add(getModuleHeaders("icm20948"))
  if includeApds9960: headersStr.add(getModuleHeaders("apds9960"))
  if includeDps310: headersStr.add(getModuleHeaders("dps310"))
  if includeTlv493d: headersStr.add(getModuleHeaders("tlv493d"))
  if includeMpr121: headersStr.add(getModuleHeaders("mpr121"))
  if includeNeotrellis: headersStr.add(getModuleHeaders("neotrellis"))
  if includeLeddriver: headersStr.add(getModuleHeaders("leddriver"))
  if includeDotstar: headersStr.add(getModuleHeaders("dotstar"))
  if includeNeopixel: headersStr.add(getModuleHeaders("neopixel"))
  if includeMcp23x17: headersStr.add(getModuleHeaders("mcp23x17"))
  if includeSr595: headersStr.add(getModuleHeaders("sr595"))
  if includeSr4021: headersStr.add(getModuleHeaders("sr4021"))
  if includeMax11300: headersStr.add(getModuleHeaders("max11300"))
  if includeSH1106: headersStr.add(getModuleHeaders("sh1106"))
  if includeSSD1327: headersStr.add(getModuleHeaders("ssd1327"))
  if includeSSD1351: headersStr.add(getModuleHeaders("ssd1351"))
  if includeQspi: headersStr.add(getModuleHeaders("qspi"))
  if includeSpiMultislave: headersStr.add(getModuleHeaders("spi_multislave"))
  if includePersistentStorage: headersStr.add(getModuleHeaders("persistent_storage"))
  if includePod: headersStr.add(getModuleHeaders("pod"))
  if includePatch: headersStr.add(getModuleHeaders("patch"))
  if includeField: headersStr.add(getModuleHeaders("field"))
  if includePatchSm: headersStr.add(getModuleHeaders("patch_sm"))
  if includePetal: headersStr.add(getModuleHeaders("petal"))
  if includeVersio: headersStr.add(getModuleHeaders("versio"))
  if includeLegio: headersStr.add(getModuleHeaders("legio"))
  if includeSystem: headersStr.add(getModuleHeaders("system"))
  if includeFatfs: headersStr.add(getModuleHeaders("fatfs"))
  if includeDma: headersStr.add(getModuleHeaders("dma"))
  if includeMidi: headersStr.add(getModuleHeaders("midi"))
  if includeVoct: headersStr.add(getModuleHeaders("voct"))
  if includeScopedIrq: headersStr.add(getModuleHeaders("scoped_irq"))
  if includeLogger: headersStr.add(getModuleHeaders("logger"))
  if includeFileReader: headersStr.add(getModuleHeaders("file_reader"))
  if includeFileTable: headersStr.add(getModuleHeaders("file_table"))
  if includeUi: headersStr.add(getModuleHeaders("ui"))
  if includeMenu: headersStr.add(getModuleHeaders("menu"))
  if includeUiCore: headersStr.add(getModuleHeaders("ui_core"))
  
  # 1. Emit header includes
  let includesEmit = newNimNode(nnkPragma)
  includesEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit(headersStr)
    )
  )
  result.add(includesEmit)
  
  # 2. Emit namespace
  let namespaceEmit = newNimNode(nnkPragma)
  namespaceEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit("using namespace daisy;")
    )
  )
  result.add(namespaceEmit)
  
  # 3. Build typedefs string
  var typedefsStr = "/*TYPESECTION*/\nusing namespace daisy;\n"
  # Core is always included
  typedefsStr.add(buildTypedefsString(coreTypedefs))
  if includeDac: typedefsStr.add(buildTypedefsString(dacTypedefs))
  if includeTim: typedefsStr.add(buildTypedefsString(timerTypedefs))
  if includeParameter: typedefsStr.add(buildTypedefsString(parameterTypedefs))
  if includeWavPlayer: typedefsStr.add(buildTypedefsString(wavPlayerTypedefs))
  if includeWavWriter: typedefsStr.add(buildTypedefsString(wavWriterTypedefs))
  if includeControls: typedefsStr.add(buildTypedefsString(controlsTypedefs))
  if includeAdc: typedefsStr.add(buildTypedefsString(adcTypedefs))
  if includePwm: typedefsStr.add(buildTypedefsString(pwmTypedefs))
  if includeOled: typedefsStr.add(buildTypedefsString(oledTypedefs))
  if includeI2c: typedefsStr.add(buildTypedefsString(i2cTypedefs))
  if includeSai: typedefsStr.add(buildTypedefsString(saiTypedefs))
  if includeSpi: typedefsStr.add(buildTypedefsString(spiTypedefs))
  if includeSdram: typedefsStr.add(buildTypedefsString(sdramTypedefs))
  if includeUsb: typedefsStr.add(buildTypedefsString(usbTypedefs))
  if includeUsbMidi: typedefsStr.add(buildTypedefsString(usbMidiTypedefs))
  if includeUsbHost: typedefsStr.add(buildTypedefsString(usbHostTypedefs))
  if includeSdmmc: typedefsStr.add(buildTypedefsString(sdmmcTypedefs))
  if includeCodecWm8731: typedefsStr.add(buildTypedefsString(codec_wm8731Typedefs))
  if includeCodecPcm3060: typedefsStr.add(buildTypedefsString(codec_pcm3060Typedefs))
  if includeLcdHd44780: typedefsStr.add(buildTypedefsString(lcd_hd44780Typedefs))
  if includeOledFonts: typedefsStr.add(buildTypedefsString(oled_fontsTypedefs))
  if includeSH1106: typedefsStr.add(buildTypedefsString(sh1106Typedefs))
  if includeSSD1327: typedefsStr.add(buildTypedefsString(ssd1327Typedefs))
  if includeSSD1351: typedefsStr.add(buildTypedefsString(ssd1351Typedefs))
  if includeQspi: typedefsStr.add(buildTypedefsString(qspiTypedefs))
  if includePersistentStorage: typedefsStr.add(buildTypedefsString(persistentStorageTypedefs))
  if includeField: typedefsStr.add(buildTypedefsString(fieldTypedefs))
  if includePatchSm: typedefsStr.add(buildTypedefsString(patchSmTypedefs))
  if includePetal: typedefsStr.add(buildTypedefsString(petalTypedefs))
  if includeVersio: typedefsStr.add(buildTypedefsString(versioTypedefs))
  if includeLegio: typedefsStr.add(buildTypedefsString(legioTypedefs))
  if includeSystem: typedefsStr.add(buildTypedefsString(systemTypedefs))
  if includeFatfs: typedefsStr.add(buildTypedefsString(fatfsTypedefs))
  if includeDma: typedefsStr.add(buildTypedefsString(dmaTypedefs))
  if includeMidi: typedefsStr.add(buildTypedefsString(midiTypedefs))
  if includeVoct: typedefsStr.add(buildTypedefsString(voctTypedefs))
  if includeScopedIrq: typedefsStr.add(buildTypedefsString(scopedIrqTypedefs))
  if includeLogger: typedefsStr.add(buildTypedefsString(loggerTypedefs))
  if includeFileReader: typedefsStr.add(buildTypedefsString(fileReaderTypedefs))
  if includeFileTable: typedefsStr.add(buildTypedefsString(fileTableTypedefs))
  if includeUi: typedefsStr.add(buildTypedefsString(uiTypedefs))
  if includeMenu: typedefsStr.add(buildTypedefsString(menuTypedefs))
  if includeUiCore: typedefsStr.add(buildTypedefsString(uiCoreTypedefs))
  
  let typedefsEmit = newNimNode(nnkPragma)
  typedefsEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit(typedefsStr)
    )
  )
  result.add(typedefsEmit)
  
  # 4. Emit helper functions if sdram is included
  if includeSdram:
    let helpersEmit = newNimNode(nnkPragma)
    helpersEmit.add(
      newNimNode(nnkExprColonExpr).add(
        newIdentNode("emit"),
        newLit(sdramHelperFunction)
      )
    )
    result.add(helpersEmit)
