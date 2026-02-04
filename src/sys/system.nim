## System
## ======
##
## Core system utilities for Daisy hardware platform.
##
## This module provides access to essential system-level functionality including:
## - Clock configuration (400MHz or 480MHz CPU speeds)
## - Timing functions (milliseconds, microseconds, ticks)
## - Bootloader control (firmware updates via DFU/USB)
## - Memory region detection
## - Cache management (instruction and data caches)
##
## The System class manages the STM32H750 microcontroller's clock tree,
## MPU (Memory Protection Unit), DMA initialization, and cache handling.
##
## Basic Usage
## -----------
##
## **Example 1: Default initialization (400MHz, caches enabled)**
##
## .. code-block:: nim
##    import sys/system
##    
##    var sys: System
##    sys.init()  # Uses default 400MHz configuration
##
## **Example 2: Boost mode initialization (480MHz)**
##
## .. code-block:: nim
##    import sys/system
##    
##    var sys: System
##    var cfg = boostSystemConfig()  # 480MHz preset
##    sys.init(cfg)
##
## **Example 3: Custom configuration**
##
## .. code-block:: nim
##    import sys/system
##    
##    var cfg = defaultSystemConfig()
##    cfg.cpu_freq = FREQ_480MHZ
##    cfg.use_dcache = true
##    cfg.use_icache = true
##    
##    var sys: System
##    sys.init(cfg)
##
## Timing Functions
## ----------------
##
## The System class provides three timing mechanisms:
##
## 1. **Millisecond timing** - 1kHz SysTick timer
## 2. **Microsecond timing** - High-resolution internal timer
## 3. **CPU tick timing** - Direct CPU cycle counting
##
## .. code-block:: nim
##    let ms = getNow()        # Milliseconds since boot
##    let us = getUs()         # Microseconds (wraps every ~71 minutes)
##    let ticks = getTick()    # CPU ticks (frequency varies)
##    
##    delay(1000)              # Wait 1 second
##    delayUs(500)             # Wait 500 microseconds
##    
##    # Measure execution time
##    let start = getUs()
##    performOperation()
##    let duration = getUs() - start
##    echo "Operation took ", duration, " us"
##
## Clock Information
## -----------------
##
## Query the system clock frequencies:
##
## .. code-block:: nim
##    echo "System Clock: ", getSysClkFreq(), " Hz"
##    echo "AHB Clock: ", getHClkFreq(), " Hz"
##    echo "APB1 Clock: ", getPClk1Freq(), " Hz"
##    echo "APB2 Clock: ", getPClk2Freq(), " Hz"
##
## Bootloader Control
## ------------------
##
## Return to bootloader for firmware updates:
##
## .. code-block:: nim
##    # Option 1: STM32 DFU bootloader (default)
##    resetToBootloader(STM)
##    
##    # Option 2: Daisy bootloader (if installed)
##    resetToBootloader(DAISY)
##    
##    # Option 3: Daisy bootloader, skip timeout
##    resetToBootloader(DAISY_SKIP_TIMEOUT)
##    
##    # Option 4: Daisy bootloader, infinite timeout
##    resetToBootloader(DAISY_INFINITE_TIMEOUT)
##
## Memory Region Detection
## -----------------------
##
## Determine which memory region an address belongs to:
##
## .. code-block:: nim
##    let region = getProgramMemoryRegion()
##    case region
##    of INTERNAL_FLASH:
##      echo "Running from internal flash"
##    of QSPI:
##      echo "Running from external QSPI flash"
##    else:
##      echo "Running from RAM or other region"
##
## See Also
## --------
## - `sys/dma <dma.html>`_ - DMA cache coherency functions
## - `examples/system_control.nim` - Complete usage example

import nimphea
import nimphea_macros

useNimpheaModules(system)

{.push header: "sys/system.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  SysClkFreq* {.importcpp: "daisy::System::Config::SysClkFreq",
                size: sizeof(cint).} = enum
    ## System clock frequency options for the STM32H750.
    ##
    ## The system clock drives all peripheral buses (AHB, APB1, APB2).
    ##
    ## - **FREQ_400MHZ**: Default safe speed, lower power consumption
    ## - **FREQ_480MHZ**: Maximum speed, higher performance, higher power draw
    ##
    ## **Note**: Some Daisy Seed boards may not reliably run at 480MHz.
    ## If you experience instability, use 400MHz.
    FREQ_400MHZ ## 400MHz system clock (default, recommended)
    FREQ_480MHZ ## 480MHz system clock (boost mode, max performance)

  SystemConfig* {.importcpp: "daisy::System::Config".} = object
    ## Configuration structure for System initialization.
    ##
    ## Controls clock frequency and cache settings.
    ##
    ## **Default values** (via `defaultSystemConfig()`):
    ## - cpu_freq: FREQ_400MHZ
    ## - use_dcache: true (data cache enabled)
    ## - use_icache: true (instruction cache enabled)
    ## - skip_clocks: false (configure clocks normally)
    ##
    ## **Boost values** (via `boostSystemConfig()`):
    ## - cpu_freq: FREQ_480MHZ (maximum speed)
    ## - Caches enabled
    cpu_freq*: SysClkFreq    ## System clock frequency selection
    use_dcache*: bool        ## Enable data cache (D-cache)
    use_icache*: bool        ## Enable instruction cache (I-cache)
    skip_clocks*: bool       ## Skip clock configuration (advanced use only)

{.pop.} # header (temporarily close to add methods)

# SystemConfig methods
proc defaults*(this: var SystemConfig) {.importcpp: "#.Defaults()", header: "sys/system.h".}
  ## Set configuration to default values.
  ##
  ## Initializes the configuration with:
  ## - CPU frequency: 400MHz
  ## - Data cache: Enabled
  ## - Instruction cache: Enabled
  ## - Skip clocks: false
  ##
  ## **Example:**
  ## ```nim
  ## var cfg: SystemConfig
  ## cfg.defaults()
  ## ```

proc boost*(this: var SystemConfig) {.importcpp: "#.Boost()", header: "sys/system.h".}
  ## Set configuration to boost mode.
  ##
  ## Initializes the configuration with:
  ## - CPU frequency: 480MHz (maximum)
  ## - Data cache: Enabled
  ## - Instruction cache: Enabled
  ## - Skip clocks: false
  ##
  ## **Warning**: Some Daisy Seed boards may not run reliably at 480MHz.
  ## If you experience instability, use `defaults()` instead.
  ##
  ## **Example:**
  ## ```nim
  ## var cfg: SystemConfig
  ## cfg.boost()
  ## ```

{.push header: "sys/system.h".} # Re-open header pragma

type
  MemoryRegion* {.importcpp: "daisy::System::MemoryRegion",
                  size: sizeof(cint).} = enum
    ## Memory regions available on Daisy Seed hardware.
    ##
    ## The STM32H750 has multiple memory regions with different
    ## characteristics (speed, size, persistence).
    ##
    ## **Typical program locations**:
    ## - INTERNAL_FLASH: Small programs (<128KB)
    ## - QSPI: Large programs via Daisy bootloader
    ## - SRAM_D1/D2/D3: RAM-based programs (lost on power cycle)
    INTERNAL_FLASH = 0 ## Internal flash memory (128KB on STM32H750)
    ITCMRAM            ## Instruction Tightly Coupled Memory (64KB)
    DTCMRAM            ## Data Tightly Coupled Memory (128KB)
    SRAM_D1            ## SRAM in D1 domain (512KB)
    SRAM_D2            ## SRAM in D2 domain (288KB)
    SRAM_D3            ## SRAM in D3 domain (64KB)
    SDRAM              ## External SDRAM (if present on board)
    QSPI               ## External QSPI flash (8MB on Daisy Seed)
    INVALID_ADDRESS    ## Address does not map to known region

  BootloaderMode* {.importcpp: "daisy::System::BootloaderMode",
                    size: sizeof(cint).} = enum
    ## Bootloader mode selection for firmware updates.
    ##
    ## **STM mode**: Uses STM32's built-in DFU bootloader.
    ## Works on all boards, allows updating internal flash via USB.
    ##
    ## **DAISY modes**: Require Daisy bootloader to be installed.
    ## Allow updating QSPI flash with larger programs (up to 8MB).
    STM = 0                  ## STM32 DFU bootloader (always available)
    DAISY                    ## Daisy bootloader with timeout
    DAISY_SKIP_TIMEOUT       ## Daisy bootloader, skip timeout window
    DAISY_INFINITE_TIMEOUT   ## Daisy bootloader, wait indefinitely

  BootloaderVersion* {.importcpp: "daisy::System::BootInfo::Version",
                       size: sizeof(cint).} = enum
    ## Daisy bootloader version detection.
    ##
    ## Used to check if Daisy bootloader is installed and which version.
    LT_v6_0 = 0  ## Bootloader version < 6.0 (legacy)
    NONE         ## No Daisy bootloader present
    v6_0         ## Bootloader version 6.0
    v6_1         ## Bootloader version 6.1 or greater
    LAST         ## Sentinel value (not a valid version)

  BootInfoType* {.importcpp: "daisy::System::BootInfo::Type",
                  size: sizeof(uint32).} = enum
    ## Boot information type codes (internal use).
    ##
    ## These magic values are written to backup SRAM to communicate
    ## between application and bootloader.
    INVALID      = 0x00000000  ## No boot command
    JUMP         = 0xDEADBEEF  ## Jump to bootloader
    SKIP_TIMEOUT = 0x5AFEB007  ## Skip bootloader timeout
    INF_TIMEOUT  = 0xB0074EFA  ## Infinite bootloader timeout

  BootInfo* {.importcpp: "daisy::System::BootInfo".} = object
    ## Boot information structure (internal use).
    ##
    ## Stored in backup SRAM to persist across resets.
    ## Used for bootloader communication.
    status*: BootInfoType        ## Boot command type
    data*: uint32                ## Additional data for boot command
    version*: BootloaderVersion  ## Detected bootloader version

  System* {.importcpp: "daisy::System".} = object
    ## System controller for Daisy hardware.
    ##
    ## Manages clock configuration, timing, bootloader access,
    ## and system-level initialization.
    ##
    ## **Note**: Most methods are static - you can call them without
    ## creating a System object. The object is only needed for
    ## initialization (`init()`, `deInit()`).

{.pop.} # header

# ============================================================================
# Instance Methods (require System object)
# ============================================================================

proc init*(this: var System) {.importcpp: "#.Init()".}
  ## Initialize System with default configuration.
  ##
  ## Default settings:
  ## - CPU frequency: 400MHz
  ## - Data cache: Enabled
  ## - Instruction cache: Enabled
  ##
  ## This is equivalent to:
  ## ```nim
  ## var cfg = defaultSystemConfig()
  ## sys.init(cfg)
  ## ```
  ##
  ## **Example:**
  ## ```nim
  ## var sys: System
  ## sys.init()
  ## echo "System initialized at ", getSysClkFreq(), " Hz"
  ## ```

proc init*(this: var System, config: SystemConfig) {.importcpp: "#.Init(#)".}
  ## Initialize System with custom configuration.
  ##
  ## **Parameters:**
  ## - `config` - SystemConfig with desired clock and cache settings
  ##
  ## **Example:**
  ## ```nim
  ## var cfg = boostSystemConfig()  # 480MHz preset
  ## var sys: System
  ## sys.init(cfg)
  ## ```

proc deInit*(this: var System) {.importcpp: "#.DeInit()".}
  ## Deinitialize System and all peripherals.
  ##
  ## Reverses the initialization performed by `init()`.
  ## Rarely needed in embedded applications (no OS to return to).

proc jumpToQspi*(this: var System) {.importcpp: "#.JumpToQspi()".}
  ## Jump to code at external QSPI flash base address (0x90000000).
  ##
  ## **Warning**: If no valid code exists at that address, the CPU
  ## will likely fall into an infinite loop or fault.
  ##
  ## This is used for advanced multi-stage boot scenarios.

proc getConfig*(this: System): SystemConfig {.importcpp: "#.GetConfig()".}
  ## Get the current System configuration.
  ##
  ## Returns a copy of the configuration used during initialization.
  ##
  ## **Returns:** SystemConfig struct with current settings
  ##
  ## **Example:**
  ## ```nim
  ## let cfg = sys.getConfig()
  ## echo "Running at: ", cfg.cpu_freq
  ## echo "D-cache: ", cfg.use_dcache
  ## ```

# ============================================================================
# Static Methods - Timing
# ============================================================================

proc getNow*(): uint32 {.importcpp: "daisy::System::GetNow()".}
  ## Get milliseconds since system boot.
  ##
  ## Uses 1kHz SysTick timer. Wraps every ~49.7 days.
  ##
  ## **Returns:** Milliseconds since boot (uint32)
  ##
  ## **Example:**
  ## ```nim
  ## let startTime = getNow()
  ## performTask()
  ## let elapsed = getNow() - startTime
  ## echo "Task took ", elapsed, " ms"
  ## ```

proc getUs*(): uint32 {.importcpp: "daisy::System::GetUs()".}
  ## Get microseconds from internal timer.
  ##
  ## Higher resolution than `getNow()` but wraps faster (~71 minutes).
  ##
  ## **Returns:** Microseconds (uint32, wraps around)
  ##
  ## **Example:**
  ## ```nim
  ## let start = getUs()
  ## criticalOperation()
  ## let duration = getUs() - start
  ## echo "Operation: ", duration, " us"
  ## ```

proc getTick*(): uint32 {.importcpp: "daisy::System::GetTick()".}
  ## Get current CPU tick count.
  ##
  ## Increments at `getTickFreq()` Hz (typically PCLK1 * 2).
  ## Useful for precise performance measurement.
  ##
  ## **Returns:** Tick count (uint32)
  ##
  ## **Example:**
  ## ```nim
  ## let ticksStart = getTick()
  ## someFunction()
  ## let ticksElapsed = getTick() - ticksStart
  ## let freq = getTickFreq()
  ## echo "Function took ", ticksElapsed, " ticks"
  ## echo "At ", freq, " Hz = ", ticksElapsed.float / freq.float, " seconds"
  ## ```

proc delay*(delay_ms: uint32) {.importcpp: "daisy::System::Delay(@)".}
  ## Blocking delay in milliseconds.
  ##
  ## Uses SysTick timer (1ms resolution).
  ##
  ## **Parameters:**
  ## - `delay_ms` - Time to delay in milliseconds
  ##
  ## **Warning**: This is a blocking delay. Audio processing will stop.
  ## Only use during initialization or non-critical sections.
  ##
  ## **Example:**
  ## ```nim
  ## echo "Waiting 1 second..."
  ## delay(1000)
  ## echo "Done!"
  ## ```

proc delayUs*(delay_us: uint32) {.importcpp: "daisy::System::DelayUs(@)".}
  ## Blocking delay in microseconds.
  ##
  ## Uses internal timer for higher precision than `delay()`.
  ##
  ## **Parameters:**
  ## - `delay_us` - Time to delay in microseconds
  ##
  ## **Warning**: Blocking delay. Audio processing will stop.
  ##
  ## **Example:**
  ## ```nim
  ## delayUs(500)  # Wait 500 microseconds
  ## ```

proc delayTicks*(delay_ticks: uint32) {.importcpp: "daisy::System::DelayTicks(@)".}
  ## Blocking delay in CPU ticks.
  ##
  ## Most precise delay mechanism, but tick frequency varies with clock config.
  ##
  ## **Parameters:**
  ## - `delay_ticks` - Number of ticks to delay
  ##
  ## **Example:**
  ## ```nim
  ## let freq = getTickFreq()
  ## let ticksFor1ms = freq div 1000
  ## delayTicks(ticksFor1ms)  # Delay 1ms using ticks
  ## ```

# ============================================================================
# Static Methods - Clock Information
# ============================================================================

proc getTickFreq*(): uint32 {.importcpp: "daisy::System::GetTickFreq()".}
  ## Get tick timer frequency in Hz.
  ##
  ## Returns the rate at which `getTick()` increments.
  ## Typically PCLK1 * 2.
  ##
  ## **Returns:** Frequency in Hz (e.g., 200000000 for 200MHz)

proc getSysClkFreq*(): uint32 {.importcpp: "daisy::System::GetSysClkFreq()".}
  ## Get system clock frequency in Hz.
  ##
  ## Returns the core system clock that feeds all peripheral buses.
  ##
  ## **Returns:** Frequency in Hz (400000000 or 480000000)
  ##
  ## **Example:**
  ## ```nim
  ## let freq = getSysClkFreq()
  ## echo "System clock: ", freq div 1_000_000, " MHz"
  ## ```

proc getHClkFreq*(): uint32 {.importcpp: "daisy::System::GetHClkFreq()".}
  ## Get AHB (HCLK) frequency in Hz.
  ##
  ## The HCLK clocks the CPU, memory, and DMA controllers.
  ##
  ## **Returns:** Frequency in Hz

proc getPClk1Freq*(): uint32 {.importcpp: "daisy::System::GetPClk1Freq()".}
  ## Get APB1 peripheral clock frequency in Hz.
  ##
  ## Many peripherals use this clock (I2C, UART, SPI, timers).
  ##
  ## **Note**: Some timers run at PCLK1 * 2.
  ##
  ## **Returns:** Frequency in Hz

proc getPClk2Freq*(): uint32 {.importcpp: "daisy::System::GetPClk2Freq()".}
  ## Get APB2 peripheral clock frequency in Hz.
  ##
  ## Some peripherals use this faster clock.
  ##
  ## **Note**: Some timers run at PCLK2 * 2.
  ##
  ## **Returns:** Frequency in Hz

# ============================================================================
# Static Methods - Bootloader
# ============================================================================

proc resetToBootloader*(mode: BootloaderMode = STM) {.
  importcpp: "daisy::System::ResetToBootloader(@)".}
  ## Reset and enter bootloader mode for firmware updates.
  ##
  ## **Parameters:**
  ## - `mode` - Bootloader mode (default: STM)
  ##
  ## **Modes:**
  ## - **STM**: STM32 DFU bootloader (always available, updates internal flash)
  ## - **DAISY**: Daisy bootloader (if installed, updates QSPI flash)
  ## - **DAISY_SKIP_TIMEOUT**: Daisy bootloader, skip timeout
  ## - **DAISY_INFINITE_TIMEOUT**: Daisy bootloader, wait forever
  ##
  ## **Example:**
  ## ```nim
  ## # User holds button for 3 seconds
  ## if buttonHeldFor3Seconds():
  ##   resetToBootloader(STM)  # Enter DFU mode
  ## ```

proc initBackupSram*() {.importcpp: "daisy::System::InitBackupSram()".}
  ## Initialize backup SRAM region.
  ##
  ## Backup SRAM retains data when powered by VBAT (coin cell battery).
  ## Used for bootloader communication and persistent state.
  ##
  ## **Note**: Usually called automatically by `System.init()`.

proc getBootloaderVersion*(): BootloaderVersion {.
  importcpp: "daisy::System::GetBootloaderVersion()".}
  ## Check which version of Daisy bootloader is installed (if any).
  ##
  ## **Returns:** BootloaderVersion enum
  ##
  ## **Example:**
  ## ```nim
  ## let ver = getBootloaderVersion()
  ## case ver
  ## of NONE:
  ##   echo "No Daisy bootloader (STM DFU only)"
  ## of v6_1:
  ##   echo "Daisy bootloader v6.1+ installed"
  ## else:
  ##   echo "Older bootloader version"
  ## ```

# ============================================================================
# Static Methods - Memory
# ============================================================================

proc getProgramMemoryRegion*(): MemoryRegion {.
  importcpp: "daisy::System::GetProgramMemoryRegion()".}
  ## Detect which memory region the program is executing from.
  ##
  ## **Returns:** MemoryRegion enum (INTERNAL_FLASH, QSPI, etc.)
  ##
  ## **Example:**
  ## ```nim
  ## let region = getProgramMemoryRegion()
  ## case region
  ## of INTERNAL_FLASH:
  ##   echo "Running from internal flash (< 128KB)"
  ## of QSPI:
  ##   echo "Running from QSPI flash (Daisy bootloader)"
  ## else:
  ##   echo "Running from RAM"
  ## ```

proc getMemoryRegion*(address: uint32): MemoryRegion {.
  importcpp: "daisy::System::GetMemoryRegion(@)".}
  ## Determine which memory region an address belongs to.
  ##
  ## **Parameters:**
  ## - `address` - Memory address to check
  ##
  ## **Returns:** MemoryRegion enum or INVALID_ADDRESS
  ##
  ## **Example:**
  ## ```nim
  ## let data = [1, 2, 3, 4]
  ## let address = cast[uint32](data[0].addr)
  ## let region = getMemoryRegion(address)
  ## echo "Data is in: ", region
  ## ```

# ============================================================================
# Constants
# ============================================================================

const
  kQspiBootloaderOffset* = 0x40000'u32
    ## Daisy bootloader offset from QSPI base address (0x90000000).
    ##
    ## The first 256KB (0x40000 bytes) of QSPI flash is reserved
    ## for the Daisy bootloader. User programs start at 0x90040000.
    ##
    ## **Important**: When writing data to QSPI, avoid the first 256KB
    ## to preserve the bootloader.

# ============================================================================
# Nim Helper Functions
# ============================================================================

proc defaultSystemConfig*(): SystemConfig =
  ## Create SystemConfig with default settings.
  ##
  ## Returns a configuration struct initialized to:
  ## - CPU frequency: 400MHz
  ## - Data cache: Enabled
  ## - Instruction cache: Enabled
  ## - Skip clocks: false
  ##
  ## **Returns:** SystemConfig with defaults
  ##
  ## **Example:**
  ## ```nim
  ## var cfg = defaultSystemConfig()
  ## cfg.cpu_freq = FREQ_480MHZ  # Override to boost mode
  ## sys.init(cfg)
  ## ```
  result.defaults()

proc boostSystemConfig*(): SystemConfig =
  ## Create SystemConfig with boost settings (480MHz).
  ##
  ## Returns a configuration struct initialized to:
  ## - CPU frequency: 480MHz (maximum)
  ## - Data cache: Enabled
  ## - Instruction cache: Enabled
  ## - Skip clocks: false
  ##
  ## **Returns:** SystemConfig with boost settings
  ##
  ## **Warning**: Some Daisy Seed boards may not run reliably at 480MHz.
  ## If you experience instability, use `defaultSystemConfig()` instead.
  ##
  ## **Example:**
  ## ```nim
  ## var cfg = boostSystemConfig()
  ## var sys: System
  ## sys.init(cfg)
  ## ```
  result.boost()

proc getClockInfo*(): tuple[sysclk, hclk, pclk1, pclk2, tickFreq: uint32] =
  ## Get all clock frequencies as a tuple.
  ##
  ## Convenience function for displaying all clock information.
  ##
  ## **Returns:** Tuple with all clock frequencies in Hz
  ##
  ## **Example:**
  ## ```nim
  ## let clocks = getClockInfo()
  ## echo "System: ", clocks.sysclk div 1_000_000, " MHz"
  ## echo "AHB: ", clocks.hclk div 1_000_000, " MHz"
  ## echo "APB1: ", clocks.pclk1 div 1_000_000, " MHz"
  ## echo "APB2: ", clocks.pclk2 div 1_000_000, " MHz"
  ## echo "Tick: ", clocks.tickFreq div 1_000_000, " MHz"
  ## ```
  result = (
    sysclk: getSysClkFreq(),
    hclk: getHClkFreq(),
    pclk1: getPClk1Freq(),
    pclk2: getPClk2Freq(),
    tickFreq: getTickFreq()
  )
