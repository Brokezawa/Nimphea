## Persistent Storage Module for libDaisy
## ========================================
##
## This module wraps libDaisy's `PersistentStorage<T>` template class to provide
## type-safe, non-volatile storage of settings in QSPI flash memory.
##
## **Features:**
## - Automatic dirty detection (only saves if settings changed)
## - Factory defaults restoration
## - State tracking (UNKNOWN, FACTORY, USER)
## - Memory-mapped QSPI access (no explicit erase needed)
## - Cache invalidation for DMA safety
##
## **Requirements:**
## - Settings struct MUST use POD (Plain Old Data) types only
## - No pointers, Nim strings, seqs, or ref types
## - Use C-compatible types: `cfloat`, `cint`, `uint8`, `uint16`, etc.
## - Settings struct MUST implement C++ `operator==` for dirty detection
## - Settings struct MUST implement C++ `operator!=`
##
## **About the C++ Operator Requirement:**
## 
## PersistentStorage uses C++ `operator==` internally to detect if settings have
## changed. This is called "dirty detection" - the `save()` method only writes to
## flash if the settings are different from what's already stored.
##
## **Why you need a {.emit.} block:**
## 
## Nim cannot export C++ operators using `{.exportcpp.}` or `{.exportc.}` because
## Nim's FFI doesn't support the exact C++ operator syntax required. The generated
## code would have Nim calling conventions and wrong parameter types.
##
## Therefore, you MUST define the operators in a small `{.emit.}` block:
##
## ```nim
## type
##   MySettings {.bycopy, exportc: "MySettings".} = object
##     param1 {.exportc.}: cfloat
##     param2 {.exportc.}: uint8
##
## # This emit block is REQUIRED - no pure-Nim alternative exists
## {.emit: """
## inline bool operator==(const MySettings& a, const MySettings& b) {
##   return a.param1 == b.param1 && a.param2 == b.param2;
## }
## inline bool operator!=(const MySettings& a, const MySettings& b) {
##   return !(a == b);
## }
## """.}
## ```
##
## This is NOT boilerplate - it's a necessary FFI boundary for C++ interop.
## See `examples/settings_manager.nim` for a complete working example.
##
## **QSPI Flash Layout:**
## - Each PersistentStorage instance uses `sizeof(SettingsStruct) + 4 bytes`
## - Extra 4 bytes store the state (UNKNOWN/FACTORY/USER)
## - Address offset must be page-aligned (256 bytes)
## - Seed 1.0: 1MB flash (IS25LP080D)
## - Seed 1.1+: 8MB flash (IS25LP064A)
##
## **Usage Example:**
## ```nim
## import nimphea
## import per/qspi
## import nimphea_persistent_storage
##
## # Define settings struct (POD types only!)
## type
##   SynthSettings {.bycopy, exportc: "SynthSettings".} = object
##     gain {.exportc.}: cfloat
##     frequency {.exportc.}: cfloat
##     waveform {.exportc.}: uint8
##
## # Implement C++ comparison operators (REQUIRED for dirty detection)
## # This cannot be done in pure Nim - emit block is necessary
## {.emit: """
## inline bool operator==(const SynthSettings& a, const SynthSettings& b) {
##   return a.gain == b.gain && 
##          a.frequency == b.frequency && 
##          a.waveform == b.waveform;
## }
## inline bool operator!=(const SynthSettings& a, const SynthSettings& b) {
##   return !(a == b);
## }
## """.}
##
## # Initialize QSPI in memory-mapped mode
## var qspi: QSPIHandle
## var qspiConfig = QSPIConfig(
##   device: QSPIDevice.IS25LP064A,
##   mode: QSPIMode.MEMORY_MAPPED
## )
## discard qspi.init(qspiConfig)
##
## # Create persistent storage
## var storage = newPersistentStorage[SynthSettings](qspi)
##
## # Initialize with factory defaults
## let defaults = SynthSettings(
##   gain: 0.5,
##   frequency: 440.0,
##   waveform: 0
## )
## storage.init(defaults, address_offset = 0)
##
## # Check state
## if storage.getState() == FACTORY:
##   echo "First boot - using factory settings"
## else:
##   echo "User settings loaded"
##
## # Modify settings
## storage.getSettings().gain = 0.8
## storage.getSettings().frequency = 880.0
##
## # Save to flash (only writes if changed)
## storage.save()
##
## # Restore factory defaults
## storage.restoreDefaults()
## ```
##
## **Important Notes:**
## - QSPI MUST be initialized in MEMORY_MAPPED mode for PersistentStorage
## - Save operations can take ~100ms due to erase/write operations
## - Do NOT call `save()` from audio callback (causes audio glitches)
## - Each save performs sector erase (~50ms) + write (~50ms)
## - Settings struct size is limited by available flash space
##
## **Memory Layout Example:**
## ```
## Flash Address 0x00000000: [State: 4 bytes][SettingsStruct: N bytes]
## Flash Address 0x00000100: [State: 4 bytes][NextSettings: N bytes]
## ...
## ```

import per/qspi
import nimphea_macros

useNimpheaModules(qspi, persistent_storage)

{.push header: "util/PersistentStorage.h".}

type
  # Storage state enum - wrapped from C++ via typedef
  StorageStateRaw {.importcpp: "StorageState",
                    size: sizeof(cint).} = enum
    UNKNOWN_RAW = 0
    FACTORY_RAW = 1
    USER_RAW = 2

  StorageState* = StorageStateRaw
    ## State of the persistent storage
    ## 
    ## - UNKNOWN: Before initialization
    ## - FACTORY: Factory defaults are stored (first boot or after restore)
    ## - USER: User-modified settings are stored

  PersistentStorage*[T] {.importcpp: "daisy::PersistentStorage<'0>",
                          byref.} = object
    ## Persistent storage wrapper for settings struct of type T
    ## 
    ## **Important**: Type T must be a POD type with an `==` operator

const
  UNKNOWN* = UNKNOWN_RAW
  FACTORY* = FACTORY_RAW
  USER* = USER_RAW

{.pop.}

# ============================================================================
# Constructor
# ============================================================================

proc newPersistentStorage*[T](qspi: var QSPIHandle): PersistentStorage[T] {.
  importcpp: "daisy::PersistentStorage<'*0>(@)", 
  constructor.}
  ## Create a new PersistentStorage instance
  ## 
  ## **Parameters:**
  ## - qspi: Reference to initialized QSPIHandle (must be in MEMORY_MAPPED mode)
  ## 
  ## **Returns:** PersistentStorage instance ready to be initialized
  ## 
  ## **Example:**
  ## ```nim
  ## var qspi: QSPIHandle
  ## # ... initialize qspi in MEMORY_MAPPED mode ...
  ## var storage = newPersistentStorage[MySettings](qspi)
  ## ```

# ============================================================================
# Core Methods
# ============================================================================

proc init*[T](this: var PersistentStorage[T], 
              defaults: T, 
              address_offset: uint32 = 0) {.
  importcpp: "#.Init(@)".}
  ## Initialize persistent storage with factory defaults
  ## 
  ## This will:
  ## 1. Store the defaults for later restoration
  ## 2. Check if valid data exists at the target address
  ## 3. If no valid data found, write defaults and set state to FACTORY
  ## 4. If valid data found, load it and set state to FACTORY or USER
  ## 
  ## **Parameters:**
  ## - defaults: Settings struct containing factory default values
  ## - address_offset: Offset from flash base address (default: 0)
  ##                   Will be aligned to 256-byte page boundary
  ## 
  ## **Important:**
  ## - Call this AFTER initializing QSPI in MEMORY_MAPPED mode
  ## - Address offset will be masked to nearest 256-byte boundary
  ## - First call writes defaults to flash (takes ~100ms)
  ## 
  ## **Example:**
  ## ```nim
  ## let defaults = MySettings(param1: 42, param2: 3.14)
  ## storage.init(defaults, address_offset = 0)
  ## ```

proc getState*[T](this: PersistentStorage[T]): StorageState {.
  importcpp: "(StorageState)(#.GetState())".}
  ## Get the current state of the persistent storage
  ## 
  ## **Returns:**
  ## - UNKNOWN: Not yet initialized
  ## - FACTORY: Factory defaults are active
  ## - USER: User-modified settings are active
  ## 
  ## **Example:**
  ## ```nim
  ## if storage.getState() == StorageState.USER:
  ##   echo "User has modified settings"
  ## ```

proc getSettings*[T](this: var PersistentStorage[T]): var T {.
  importcpp: "#.GetSettings()".}
  ## Get a mutable reference to the settings struct
  ## 
  ## Use this to read or modify settings values.
  ## Call `save()` afterwards to persist changes.
  ## 
  ## **Returns:** Mutable reference to the settings struct
  ## 
  ## **Example:**
  ## ```nim
  ## # Read setting
  ## let currentGain = storage.getSettings().gain
  ## 
  ## # Modify setting
  ## storage.getSettings().gain = 0.8
  ## storage.save()  # Don't forget to save!
  ## ```

proc save*[T](this: var PersistentStorage[T]) {.
  importcpp: "#.Save()".}
  ## Save current settings to flash memory
  ## 
  ## This will:
  ## 1. Set state to USER (if not already)
  ## 2. Compare current settings with flash using `==` operator
  ## 3. If different, erase sector and write new data (~100ms)
  ## 4. If same, do nothing (no flash write)
  ## 
  ## **Performance:**
  ## - If no change: <1ms (comparison only)
  ## - If changed: ~100ms (erase + write)
  ## 
  ## **Important:**
  ## - Do NOT call from audio callback (causes glitches)
  ## - Only writes if settings actually changed (dirty detection)
  ## - Settings struct MUST implement `==` operator
  ## 
  ## **Example:**
  ## ```nim
  ## storage.getSettings().volume = 0.5
  ## storage.save()  # Blocks for ~100ms if settings changed
  ## ```

proc restoreDefaults*[T](this: var PersistentStorage[T]) {.
  importcpp: "#.RestoreDefaults()".}
  ## Restore factory default settings
  ## 
  ## This will:
  ## 1. Restore settings to the defaults provided during `init()`
  ## 2. Set state to FACTORY
  ## 3. Save to flash (~100ms)
  ## 
  ## **Performance:** ~100ms (erase + write)
  ## 
  ## **Important:**
  ## - Do NOT call from audio callback (causes glitches)
  ## - Always writes to flash (even if already at defaults)
  ## 
  ## **Example:**
  ## ```nim
  ## # User requested factory reset
  ## storage.restoreDefaults()  # Blocks for ~100ms
  ## echo "Settings restored to factory defaults"
  ## ```

# ============================================================================
# Helper Procedures
# ============================================================================

proc calculateStorageSize*[T](): csize_t {.inline.} =
  ## Calculate the flash storage size needed for a settings type
  ## 
  ## Storage size = sizeof(T) + 4 bytes (for state)
  ## 
  ## **Example:**
  ## ```nim
  ## let bytesNeeded = calculateStorageSize[MySettings]()
  ## echo "This settings struct uses ", bytesNeeded, " bytes in flash"
  ## ```
  result = csize_t(sizeof(T) + sizeof(StorageState))

proc alignToFlashPage*(address: uint32): uint32 {.inline.} =
  ## Align an address to 256-byte flash page boundary
  ## 
  ## PersistentStorage requires page-aligned addresses.
  ## Use this to calculate valid address offsets.
  ## 
  ## **Example:**
  ## ```nim
  ## let offset1 = alignToFlashPage(0)     # 0
  ## let offset2 = alignToFlashPage(100)   # 0
  ## let offset3 = alignToFlashPage(300)   # 256
  ## ```
  const PAGE_SIZE = 256'u32
  result = address and not (PAGE_SIZE - 1)

proc isFlashPageAligned*(address: uint32): bool {.inline.} =
  ## Check if an address is aligned to 256-byte flash page boundary
  ## 
  ## **Example:**
  ## ```nim
  ## if not isFlashPageAligned(myOffset):
  ##   echo "Warning: address will be aligned automatically"
  ## ```
  const PAGE_SIZE = 256'u32
  result = (address and (PAGE_SIZE - 1)) == 0

# ============================================================================
# Compile-time Validation
# ============================================================================

template validateSettingsType*(T: typedesc) =
  ## Compile-time validation that a type is suitable for PersistentStorage
  ## 
  ## Checks:
  ## - Type is not a ref type
  ## - Type is not a pointer
  ## - Type size is reasonable
  ## 
  ## **Example:**
  ## ```nim
  ## type MySettings = object
  ##   value: cfloat
  ## 
  ## validateSettingsType(MySettings)  # OK
  ## 
  ## type BadSettings = ref object
  ##   value: cfloat
  ## 
  ## validateSettingsType(BadSettings)  # Compile error!
  ## ```
  when T is ref:
    {.error: "PersistentStorage type cannot be a ref type - use plain object".}
  when T is ptr:
    {.error: "PersistentStorage type cannot be a pointer type".}
  when sizeof(T) > 65536:
    {.warning: "PersistentStorage type is very large (" & $sizeof(T) & " bytes)".}

# ============================================================================
# Documentation Examples (see examples/settings_manager.nim for usage)
# ============================================================================
    
    # Factory reset button:
    storage.restoreDefaults()
