# QSPI Flash Memory Guide

[← Home](index.md)


Complete guide to using the onboard QSPI flash memory on Daisy Seed for persistent storage, sample storage, and firmware assets.


## Important Distinction

This guide covers **QSPI data storage** (persistent user data, audio samples, etc.). For information about deploying applications via DFU bootloaders to QSPI memory, see [BOOT_MODES](./BOOT_MODES.md#boot_qspi-bootloader--external-flash).


## Table of Contents

1. [Overview](#overview)
2. [Hardware Specifications](#hardware-specifications)
3. [Flash Memory Modes](#flash-memory-modes)
4. [Quick Start](#quick-start)
5. [Basic Operations](#basic-operations)
6. [Persistent Settings Storage](#persistent-settings-storage)
7. [Memory Layout Planning](#memory-layout-planning)
8. [Performance Characteristics](#performance-characteristics)
9. [Best Practices](#best-practices)
10. [Common Use Cases](#common-use-cases)
11. [Troubleshooting](#troubleshooting)


## Overview

The Daisy Seed includes onboard QSPI (Quad SPI) flash memory for non-volatile storage. This memory persists across power cycles and is perfect for:

- **Persistent settings** - User preferences, calibration data
- **Audio samples** - Wavetables, drum samples, impulse responses
- **Firmware assets** - Graphics, fonts, lookup tables
- **Data logging** - Recording sensor data, events

Unlike internal MCU flash (which holds your program), QSPI flash is dedicated storage accessible via the `QSPIHandle` API.


## Hardware Specifications

### Older Daisy Seed Boards (IS25LP080D)

- **Chip**: IS25LP080D
- **Capacity**: 1 MB (1,048,576 bytes)
- **Address Range**: `0x00000000` - `0x000FFFFF`
- **Found on**: Some earlier Daisy Seed boards

### Newer Daisy Seed Boards (IS25LP064A)

- **Chip**: IS25LP064A  
- **Capacity**: 8 MB (8,388,608 bytes)
- **Address Range**: `0x00000000` - `0x007FFFFF`
- **Found on**: Daisy Seed Rev 4 and later (most common)

### Common Properties (Both Chips)

- **Page Size**: 256 bytes (write unit)
- **Sector Size**: 4 KB (minimum erase unit)
- **Block Size**: 32 KB (larger erase unit)
- **Interface**: Quad SPI (4-bit data bus)
- **Voltage**: 3.3V
- **Endurance**: ~100,000 erase/write cycles per sector

**How to determine which chip your board has:**
1. Check the board silkscreen for revision number (Rev 4+ typically has 8MB)
2. Look at the QSPI chip markings (small 8-pin chip near the Seed)
3. Try initializing with `QSPI_DEVICE_IS25LP064A` first (most common)
4. If init fails, try `QSPI_DEVICE_IS25LP080D`
5. Most boards manufactured after 2020 have the 8MB chip


## Flash Memory Modes

The QSPI flash supports two operating modes:

### 1. INDIRECT_POLLING Mode

**Use for:** Erase and write operations

```nim
var qspi: QSPIHandle
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING):
  echo "Init failed"

# Can now erase and write
qspi.eraseSector(0)
qspi.write(0, dataSize, addr data[0])
```

**Characteristics:**
-  Required for erase/write operations
-  CPU controls all operations explicitly
-  Cannot read from flash (use write mode only)
-  Slower than memory-mapped mode

### 2. MEMORY_MAPPED Mode

**Use for:** Fast read access

```nim
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  echo "Init failed"

# Flash is now mapped to memory address space
# Direct memory access for reading
# (Actual base address depends on STM32 memory map)
```

**Characteristics:**
-  Extremely fast read access (DMA-capable)
-  Flash appears as memory array
-  Required for PersistentStorage module
-  Cannot erase or write in this mode
-  Must switch modes for write operations

**Important:** You must re-initialize to switch modes:

```nim
# Mode 1: Erase and write
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
qspi.eraseSector(0)
qspi.write(0, size, addr data[0])

# Mode 2: Switch to read mode
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)
# Now can read via memory mapping
```


## Quick Start

### Example 1: Basic Erase/Write/Read

```nim
import nimphea
import per/qspi
import per/uart

var daisy = initDaisy()
startLog()

var qspi: QSPIHandle

# Initialize in INDIRECT mode for writing
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING):
  printLine("QSPI init failed!")
  while true: daisy.delay(1000)

# Erase first sector (4KB)
printLine("Erasing sector...")
if not qspi.eraseSector(0):
  printLine("Erase failed!")

# Write some data
var writeData = [0xDE'u8, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE, 0xBA, 0xBE]
printLine("Writing data...")
if not qspi.write(0, 8, addr writeData[0]):
  printLine("Write failed!")

# Switch to memory-mapped mode for reading
printLine("Switching to read mode...")
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  printLine("Mode switch failed!")

printLine("Flash operations complete!")
daisy.setLed(true)

while true:
  daisy.delay(1000)
```

### Example 2: Persistent Settings

```nim
import nimphea
import per/qspi
import nimphea_persistent_storage

# Define settings struct (must be POD)
type
  MySettings {.bycopy, exportc: "MySettings".} = object
    volume {.exportc.}: cfloat
    frequency {.exportc.}: cfloat
    mode {.exportc.}: uint8

# Implement comparison operators
{.emit: """
typedef daisy::PersistentStorage<int>::State StorageState;

inline bool operator==(const MySettings& a, const MySettings& b) {
  return a.volume == b.volume && 
         a.frequency == b.frequency && 
         a.mode == b.mode;
}
inline bool operator!=(const MySettings& a, const MySettings& b) {
  return !(a == b);
}
""".}

var daisy = initDaisy()
var qspi: QSPIHandle

# MUST use memory-mapped mode for PersistentStorage
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  echo "QSPI init failed"

# Create storage
var storage = newPersistentStorage[MySettings](qspi)

# Initialize with defaults
let defaults = MySettings(volume: 0.5, frequency: 440.0, mode: 0)
storage.init(defaults, address_offset = 0)

# Check if this is first boot
if storage.getState() == FACTORY:
  echo "First boot - using defaults"
else:
  echo "User settings loaded"

# Modify settings
var settings = storage.getSettings()
settings.volume = 0.8
storage.save()  # Only writes if changed (dirty detection)

# Later: restore defaults
storage.restoreDefaults()
```


## Basic Operations

### Initializing Flash

```nim
import per/qspi

var qspi: QSPIHandle

# For newer Daisy Seed boards (8MB) - try this first
let success = qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)

# For older Daisy Seed boards (1MB) - if above fails
let success = qspi.init(QSPI_DEVICE_IS25LP080D, QSPI_MODE_INDIRECT_POLLING)

if not success:
  echo "QSPI initialization failed"
```

### Erasing Flash

Flash memory must be erased before writing. Erased bytes have value `0xFF`.

**Erase a 4KB sector:**
```nim
let address: uint32 = 0x1000  # Must be sector-aligned (multiple of 0x1000)
if qspi.eraseSector(address):
  echo "Sector erased"
```

**Erase a range:**
```nim
let start_addr: uint32 = 0x0000
let end_addr: uint32 = 0x3FFF  # Erase 16KB (4 sectors)

if qspi.erase(start_addr, end_addr):
  echo "Range erased"
```

**Important erase rules:**
-  Erasing sets all bytes to `0xFF`
-  Can erase multiple times safely
-  `erase()` automatically handles sector boundaries
-  Erase is SLOW (~100ms per sector)
-  Do NOT erase from audio callback!

### Writing Data

Flash writes can only change bits from `1` to `0`. You cannot write `1` bits without erasing first.

**Write bytes to flash:**
```nim
var data = [0x01'u8, 0x02, 0x03, 0x04, 0x05]
let address: uint32 = 0x0000

if qspi.write(address, 5, addr data[0]):
  echo "Write successful"
```

**Write to specific page:**
```nim
# Pages are 256 bytes each
let pageAddress: uint32 = 0x0100  # Start of page 1
let offset: uint32 = 10           # Offset within page
let size: uint32 = 20             # Bytes to write

if qspi.writePage(pageAddress, offset, size, addr data[0]):
  echo "Page write successful"
```

**Important write rules:**
-  Can write multiple times to same location (bits only go 0→0)
-  Writes within page boundaries are atomic
-  Must erase before writing `1` bits
-  Write is SLOW (~1ms per page)
-  Do NOT write from audio callback!

### Reading Data

Switch to memory-mapped mode for reading:

```nim
# Switch to memory-mapped mode
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)

# Flash is now accessible via memory mapping
# (Reading is handled by hardware - no explicit read function)
```

In memory-mapped mode, flash appears as normal memory. You can:
- Read bytes directly via DMA
- Use as source for audio sample playback
- Access via `PersistentStorage` module


## Persistent Settings Storage

The `PersistentStorage[T]` module provides a type-safe wrapper for settings storage with automatic dirty detection.

### Setting Up Persistent Storage

**Step 1: Define your settings struct**

Must be a POD (Plain Old Data) type - no Nim strings, seqs, or refs!

```nim
type
  UserSettings {.bycopy, exportc: "UserSettings".} = object
    # Use C types only
    volume {.exportc.}: cfloat
    pan {.exportc.}: cfloat
    frequency {.exportc.}: cfloat
    waveform {.exportc.}: uint8
    enabled {.exportc.}: bool
```

**Step 2: Implement comparison operators**

Required for dirty detection:

```nim
{.emit: """
typedef daisy::PersistentStorage<int>::State StorageState;

inline bool operator==(const UserSettings& a, const UserSettings& b) {
  return a.volume == b.volume &&
         a.pan == b.pan &&
         a.frequency == b.frequency &&
         a.waveform == b.waveform &&
         a.enabled == b.enabled;
}

inline bool operator!=(const UserSettings& a, const UserSettings& b) {
  return !(a == b);
}
""".}
```

**Step 3: Initialize QSPI and storage**

```nim
var qspi: QSPIHandle
var storage: PersistentStorage[UserSettings]

# Initialize QSPI in memory-mapped mode (required!)
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED):
  echo "QSPI init failed"

# Create storage wrapper
storage = newPersistentStorage[UserSettings](qspi)

# Initialize with factory defaults
let defaults = UserSettings(
  volume: 0.5,
  pan: 0.0,
  frequency: 440.0,
  waveform: 0,
  enabled: true
)

storage.init(defaults, address_offset = 0)
```

**Step 4: Use settings**

```nim
# Get reference to current settings
var settings = storage.getSettings()

# Modify settings
settings.volume = 0.8
settings.waveform = 2

# Save (only writes if changed - dirty detection)
storage.save()

# Check storage state
case storage.getState()
of UNKNOWN: echo "Not initialized"
of FACTORY: echo "Factory defaults"
of USER: echo "User modified"

# Restore factory defaults
storage.restoreDefaults()
```

### Dirty Detection

The `save()` function only writes to flash if settings have changed:

```nim
var settings = storage.getSettings()
settings.volume = 0.8
storage.save()  # Writes to flash

settings.volume = 0.8  # No change
storage.save()  # Does NOT write (dirty flag not set)

settings.pan = 0.5  # Changed
storage.save()  # Writes to flash
```

This prevents unnecessary flash wear and improves performance.

### Multiple Settings Objects

You can store multiple settings structs at different addresses:

```nim
var globalSettings = newPersistentStorage[GlobalSettings](qspi)
var patchSettings = newPersistentStorage[PatchSettings](qspi)

globalSettings.init(globalDefaults, address_offset = 0x0000)
patchSettings.init(patchDefaults, address_offset = 0x1000)  # 4KB offset
```


## Memory Layout Planning

Plan your flash memory layout to avoid conflicts:

### Example Layout (8MB Flash)

```
0x00000000 - 0x00000FFF (4KB)   : Global settings
0x00001000 - 0x00001FFF (4KB)   : Patch 1 settings  
0x00002000 - 0x00002FFF (4KB)   : Patch 2 settings
...
0x00010000 - 0x0001FFFF (64KB)  : Wavetable bank 1
0x00020000 - 0x0002FFFF (64KB)  : Wavetable bank 2
...
0x00100000 - 0x003FFFFF (3MB)   : Drum sample library
0x00400000 - 0x007FFFFF (4MB)   : User recordings / data logs
```

### Address Alignment Rules

- **Sectors**: Must align to 4KB (0x1000) boundaries
  - Example: `0x0000`, `0x1000`, `0x2000`, `0x3000`
  
- **Pages**: Align to 256 bytes (0x100) boundaries
  - Example: `0x0000`, `0x0100`, `0x0200`, `0x0300`

- **PersistentStorage**: Automatically aligns to 256-byte pages
  - `address_offset` is masked to nearest page boundary

### Calculating Offsets

```nim
const SECTOR_SIZE = 0x1000  # 4KB
const PAGE_SIZE = 0x100     # 256 bytes

const GLOBAL_SETTINGS_ADDR = 0 * SECTOR_SIZE      # 0x0000
const PATCH_SETTINGS_ADDR = 1 * SECTOR_SIZE       # 0x1000
const WAVETABLE_START = 16 * SECTOR_SIZE          # 0x10000
const SAMPLES_START = 256 * SECTOR_SIZE           # 0x100000
```


## Performance Characteristics

### Operation Timings (Typical)

| Operation | Duration | Notes |
|-----------|----------|-------|
| Sector Erase (4KB) | ~100ms | Blocking |
| Page Write (256B) | ~1ms | Blocking |
| Sequential Read | ~40 MB/s | Memory-mapped |
| Random Read | ~20 MB/s | Memory-mapped |
| Mode Switch | ~10ms | Re-initialization |

### Performance Tips

** DO:**
- Read in memory-mapped mode (fastest)
- Batch writes together (amortize erase cost)
- Use dirty detection to avoid unnecessary writes
- Plan memory layout to minimize erases
- Erase larger blocks when possible (32KB vs 4KB)

** DON'T:**
- Call erase/write from audio callback (will cause glitches!)
- Erase/write on every parameter change (use dirty detection)
- Frequently switch between modes (expensive)
- Write without erasing first (data corruption)

### Audio Callback Safety

```nim
#  WRONG - Blocks audio!
proc audioCallback(input: AudioBuffer, output: var AudioBuffer) =
  if saveRequested:
    storage.save()  # BAD: ~100ms blocking call!

#  CORRECT - Defer to main loop
var saveRequested = false

proc audioCallback(input: AudioBuffer, output: var AudioBuffer) =
  if saveButtonPressed:
    saveRequested = true  # Just set flag

proc main() =
  while true:
    if saveRequested:
      storage.save()  # OK: Main loop can block
      saveRequested = false
    daisy.delay(10)
```


## Best Practices

### 1. Minimize Flash Wear

Flash has limited write endurance (~100,000 cycles per sector).

**Good practices:**
```nim
#  Only save when changed
storage.save()  # Uses dirty detection

#  Batch multiple changes
settings.volume = 0.8
settings.pan = 0.5
settings.frequency = 880.0
storage.save()  # One write for all changes

#  Debounce user input
var lastSaveTime: uint32 = 0
if (daisy.getTime() - lastSaveTime) > 1000:  # 1 second debounce
  storage.save()
  lastSaveTime = daisy.getTime()
```

**Bad practices:**
```nim
#  Save on every knob turn
proc onKnobChange(newValue: float) =
  settings.volume = newValue
  storage.save()  # Wears flash quickly!

#  Save in tight loop
while true:
  settings.value = readAdc()
  storage.save()  # Will wear out flash fast!
```

### 2. Validate Data After Read

Flash can occasionally corrupt data (bit flips, cosmic rays, etc.).

```nim
# Add magic number for validation
type
  SafeSettings {.bycopy, exportc.} = object
    magic {.exportc.}: uint32  # Magic number for validation
    version {.exportc.}: uint8
    volume {.exportc.}: cfloat
    # ... other fields

const SETTINGS_MAGIC: uint32 = 0xDEADBEEF

storage.init(defaults)

# Validate after loading
if settings.magic != SETTINGS_MAGIC:
  echo "Settings corrupted - restoring defaults"
  storage.restoreDefaults()
```

### 3. Version Your Settings

Allow for future updates:

```nim
type
  VersionedSettings {.bycopy, exportc.} = object
    version {.exportc.}: uint8
    # ... other fields

const CURRENT_VERSION: uint8 = 2

proc migrateSettings(old_version: uint8) =
  case old_version
  of 1:
    # Migrate v1 → v2
    echo "Migrating from v1"
    # ... migration logic
  else:
    echo "Unknown version - resetting"
    storage.restoreDefaults()

# On init:
storage.init(defaults)
if settings.version != CURRENT_VERSION:
  migrateSettings(settings.version)
  settings.version = CURRENT_VERSION
  storage.save()
```

### 4. Plan for Power Loss

Flash writes are not atomic. Power loss during write can corrupt data.

**Mitigation strategies:**

```nim
# Strategy 1: Double buffering
# Write to alternate sectors, keep both valid
var activeSlot: uint8 = 0
const SLOT_A_ADDR = 0x0000
const SLOT_B_ADDR = 0x1000

proc safeSave() =
  let targetAddr = if activeSlot == 0: SLOT_A_ADDR else: SLOT_B_ADDR
  # Write to inactive slot
  # If successful, mark it active
  activeSlot = 1 - activeSlot

# Strategy 2: CRC checksums
type
  ChecksummedSettings {.bycopy, exportc.} = object
    data: MySettings
    crc32 {.exportc.}: uint32

proc calculateCRC(data: ptr uint8, size: int): uint32 =
  # ... CRC implementation

proc loadWithValidation(): bool =
  let crc = calculateCRC(addr settings.data, sizeof(MySettings))
  if crc != settings.crc32:
    echo "CRC mismatch - data corrupted"
    return false
  return true
```


## Common Use Cases

### Use Case 1: Audio Sample Storage

Store wavetables or drum samples in flash:

```nim
# Store sample in flash (do this once, during development)
const SAMPLE_SIZE = 48000  # 1 second at 48kHz
var sample: array[SAMPLE_SIZE, int16]

# Load sample from SD card or USB
# ... 

# Write to flash
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
qspi.erase(SAMPLES_START, SAMPLES_START + SAMPLE_SIZE * 2)
qspi.write(SAMPLES_START, SAMPLE_SIZE * 2, cast[ptr uint8](addr sample[0]))

# Switch to memory-mapped for playback
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)

# In audio callback, read from flash via DMA
# (Flash is mapped to memory, so direct access is fast)
```

### Use Case 2: Multi-Patch Storage

Store multiple patches with quick recall:

```nim
const MAX_PATCHES = 128
const PATCH_SIZE = 256  # bytes per patch

type
  PatchData {.bycopy, exportc.} = object
    name: array[16, char]
    parameters: array[32, cfloat]
    # ... other patch data

var currentPatch: uint8 = 0

proc loadPatch(patchNum: uint8) =
  if patchNum >= MAX_PATCHES:
    return
  
  let offset = patchNum * PATCH_SIZE
  # Load from flash at offset
  # (In memory-mapped mode, flash acts like RAM)
  currentPatch = patchNum

proc savePatch(patchNum: uint8) =
  # Switch to indirect mode
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
  
  let offset = patchNum * PATCH_SIZE
  qspi.eraseSector(offset)
  # Write patch data
  
  # Switch back to memory-mapped
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)
```

### Use Case 3: Data Logging

Log sensor data or events to flash:

```nim
const LOG_START = 0x100000
const LOG_SIZE = 0x100000  # 1MB log space

var logWritePtr: uint32 = LOG_START

proc logEvent(data: ptr uint8, size: uint32) =
  if logWritePtr + size > LOG_START + LOG_SIZE:
    # Log full - wrap around or stop
    echo "Log buffer full"
    return
  
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
  qspi.write(logWritePtr, size, data)
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)
  
  logWritePtr += size

proc clearLog() =
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
  qspi.erase(LOG_START, LOG_START + LOG_SIZE - 1)
  qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)
  logWritePtr = LOG_START
```


## Troubleshooting

### Problem: Flash init fails

**Symptoms:** `qspi.init()` returns `false`

**Causes:**
- Wrong device type for your Seed version
- Hardware fault
- Flash already initialized in different mode

**Solutions:**
```nim
# Try both device types
if not qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING):
  echo "8MB flash failed, trying 1MB..."
  if not qspi.init(QSPI_DEVICE_IS25LP080D, QSPI_MODE_INDIRECT_POLLING):
    echo "Both flash types failed - hardware issue?"

# Deinitialize first
qspi.deinit()
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
```

### Problem: Erase fails or times out

**Symptoms:** `eraseSector()` returns `false` or hangs

**Causes:**
- Not in INDIRECT_POLLING mode
- Invalid address (not sector-aligned)
- Hardware fault

**Solutions:**
```nim
# Ensure correct mode
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)

# Align address to sector boundary
let aligned_addr = (address div 0x1000) * 0x1000
if qspi.eraseSector(aligned_addr):
  echo "Erase OK"
else:
  echo "Erase failed - check address"
```

### Problem: Write fails

**Symptoms:** `write()` returns `false` or data reads back incorrectly

**Causes:**
- Not in INDIRECT_POLLING mode
- Sector not erased first
- Writing beyond flash size
- Hardware fault

**Solutions:**
```nim
# Always erase before writing
qspi.eraseSector(address)
if qspi.write(address, size, data):
  echo "Write OK"
else:
  echo "Write failed"

# Check address bounds
if address + size > MAX_FLASH_SIZE:
  echo "Write exceeds flash capacity"
```

### Problem: Data reads back as all 0xFF

**Symptoms:** After writing, data reads as `0xFF` bytes

**Causes:**
- Still in INDIRECT_POLLING mode (can't read)
- Never wrote data (flash is erased)
- Write failed silently

**Solutions:**
```nim
# Switch to memory-mapped after writing
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
qspi.write(0, size, data)

# Must switch modes to read!
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)
# Now can read
```

### Problem: PersistentStorage always returns FACTORY state

**Symptoms:** `getState()` always returns `FACTORY`, settings don't persist

**Causes:**
- Flash not erased before first init
- Not in MEMORY_MAPPED mode
- Comparison operators not working

**Solutions:**
```nim
# Manually erase settings area first
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)
qspi.eraseSector(0)

# Switch to memory-mapped (required!)
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)

# Now init storage
storage.init(defaults)

# Verify operators work
var a = MySettings(value: 1.0)
var b = MySettings(value: 2.0)
{.emit: """
if (a == b) printf("BUG: Equal when different!\n");
if (!(a != b)) printf("BUG: != operator broken!\n");
""".}
```

### Problem: Flash wears out quickly

**Symptoms:** After many writes, flash becomes unreliable

**Causes:**
- Writing too frequently
- Not using dirty detection
- Writing on every parameter change

**Solutions:**
```nim
# Use dirty detection (built into PersistentStorage)
storage.save()  # Only writes if changed

# Debounce saves
var lastSaveTime: uint32 = 0
const SAVE_DEBOUNCE_MS = 1000

if (getCurrentTime() - lastSaveTime) > SAVE_DEBOUNCE_MS:
  storage.save()
  lastSaveTime = getCurrentTime()

# Implement wear leveling for frequently-written data
# (Rotate writes across multiple sectors)
```

### Problem: Settings corrupt after power loss

**Symptoms:** Random values or checksum failures after reboot

**Causes:**
- Power lost during write operation
- Flash bit flip (rare)
- No data validation

**Solutions:**
```nim
# Add validation
type
  ValidatedSettings {.bycopy, exportc.} = object
    magic: uint32
    version: uint8
    crc: uint32
    data: MySettings

const MAGIC = 0xDEADBEEF

proc validate(): bool =
  if settings.magic != MAGIC:
    echo "Bad magic"
    return false
  
  let crc = calculateCRC(addr settings.data, sizeof(MySettings))
  if crc != settings.crc:
    echo "Bad CRC"
    return false
  
  return true

# On load:
storage.init(defaults)
if not validate():
  echo "Corrupted - restoring defaults"
  storage.restoreDefaults()
```


## Summary

### Key Takeaways

 **DO:**
- Erase before writing
- Switch to MEMORY_MAPPED mode for reading
- Use PersistentStorage for settings (dirty detection!)
- Plan your memory layout
- Validate data integrity
- Minimize writes (flash wear)

 **DON'T:**
- Write/erase from audio callback (blocking!)
- Write without erasing first
- Exceed flash capacity
- Forget to switch modes
- Save on every parameter change

### Quick Reference

```nim
# Initialize
var qspi: QSPIHandle
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_INDIRECT_POLLING)

# Erase
qspi.eraseSector(0x0000)

# Write
qspi.write(0x0000, size, addr data[0])

# Switch to read mode
qspi.init(QSPI_DEVICE_IS25LP064A, QSPI_MODE_MEMORY_MAPPED)

# Persistent settings
var storage = newPersistentStorage[MySettings](qspi)
storage.init(defaults)
var settings = storage.getSettings()
settings.value = 1.0
storage.save()  # Dirty detection
```


**For more examples, see:**
- `examples/flash_storage.nim` - Basic flash operations
- `examples/settings_manager.nim` - Persistent settings
- `docs/API_REFERENCE.md` - Complete API documentation
