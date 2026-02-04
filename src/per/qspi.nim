## QSPI Flash Memory Module
## =========================
##
## This module provides access to QSPI flash memory on the Daisy platform.
## QSPI flash is used for storing large data like wavetables, samples, and presets.
##
## Features:
## - Two operation modes: Memory-Mapped and Indirect Polling
## - Read, Write, and Erase operations
## - Support for IS25LP080D and IS25LP064A flash chips
## - Sector/block erase operations (4KB, 32KB, 64KB)
## - Page write operations (256 bytes)
##
## Memory Modes:
## - **Memory-Mapped Mode**: QSPI memory is directly accessible starting at
##   address 0x90000000. Reading is fast but writing is not possible.
##   Use this for code execution from QSPI or fast data access.
##
## - **Indirect Polling Mode**: Full driver access with read/write/erase
##   operations. Required for writing data to flash.
##
## Flash Chip Sizes:
## - IS25LP080D: 8 Mbit (1 MB)
## - IS25LP064A: 64 Mbit (8 MB)
##
## Erase Granularity:
## - Sector: 4KB (smallest erasable unit)
## - Block (32K): 32KB
## - Block (64K): 64KB
## - **Important**: Must erase before writing!
##
## Usage Example (Indirect Polling):
## ```nim
## import per/qspi
## 
## var qspi: QSPIHandle
## var config = QSPIConfig()
## 
## # Configure pins (Daisy Seed defaults)
## config.device = QSPIDevice.IS25LP064A
## config.mode = QSPIMode.INDIRECT_POLLING
## 
## # Initialize
## if qspi.init(config) == QSPIResult.OK:
##   # Erase sector at address 0
##   if qspi.eraseSector(0) == QSPIResult.OK:
##     # Write data
##     var data: array[256, uint8] = [1'u8, 2, 3, ...]
##     if qspi.writePage(0, 256, data[0].addr) == QSPIResult.OK:
##       echo "Written successfully"
## ```
##
## Usage Example (Memory-Mapped):
## ```nim
## import per/qspi
## 
## var qspi: QSPIHandle
## var config = QSPIConfig()
## 
## config.device = QSPIDevice.IS25LP064A
## config.mode = QSPIMode.MEMORY_MAPPED
## 
## if qspi.init(config) == QSPIResult.OK:
##   # Access memory directly (read-only)
##   let dataPtr = cast[ptr UncheckedArray[uint8]](qspi.getData())
##   echo "First byte: ", dataPtr[0]
## ```

{.push header: "per/qspi.h".}

import nimphea_macros
import nimphea # Import nimphea to get QSPIConfig type

useNimpheaModules(qspi)

# Forward declarations
type
  QSPIResult* {.importcpp: "daisy::QSPIHandle::Result", size: sizeof(cint).} = enum
    OK = "daisy::QSPIHandle::Result::OK"
    ERR = "daisy::QSPIHandle::Result::ERR"

  QSPIStatus* {.importcpp: "daisy::QSPIHandle::Status", pure.} = enum
    GOOD = "daisy::QSPIHandle::Status::GOOD"
    E_HAL_ERROR = "daisy::QSPIHandle::Status::E_HAL_ERROR"
    E_SWITCHING_MODES = "daisy::QSPIHandle::Status::E_SWITCHING_MODES"
    E_INVALID_MODE = "daisy::QSPIHandle::Status::E_INVALID_MODE"

  # QSPIDevice, QSPIMode, QSPIConfig moved to libdaisy.nim

  QSPIHandle* {.importcpp: "daisy::QSPIHandle", byref.} = object
    ## QSPI flash memory interface

{.pop.}

# ============================================================================
# Core Methods
# ============================================================================

proc init*(qspi: var QSPIHandle, config: QSPIConfig): QSPIResult {.
  importcpp: "#.Init(@)", cdecl.}
  ## Initialize QSPI peripheral and prepare memory for access.
  ## 
  ## This will:
  ## 1. Configure the QSPI peripheral
  ## 2. Reset the flash chip
  ## 3. Prepare for memory access
  ## 
  ## Parameters:
  ## - config: Configuration with device type and mode
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure
  ## 
  ## Example:
  ## ```nim
  ## var qspi: QSPIHandle
  ## var config = QSPIConfig(
  ##   device: QSPIDevice.IS25LP064A,
  ##   mode: QSPIMode.INDIRECT_POLLING
  ## )
  ## if qspi.init(config) != QSPIResult.OK:
  ##   echo "QSPI init failed"
  ## ```

proc deInit*(qspi: var QSPIHandle): QSPIResult {.
  importcpp: "#.DeInit()", cdecl.}
  ## Deinitialize the QSPI peripheral.
  ## 
  ## Call this before reinitializing QSPI in a different mode.
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure

proc getConfig*(qspi: QSPIHandle): QSPIConfig {.
  importcpp: "#.GetConfig()", cdecl.}
  ## Get the current QSPI configuration.
  ## 
  ## Returns: Current QSPIConfig

# ============================================================================
# Write Operations (Indirect Polling Mode Only)
# ============================================================================

proc writePage*(qspi: var QSPIHandle, address: uint32, size: uint32, buffer: ptr uint8): QSPIResult {.
  importcpp: "#.WritePage(@)", cdecl.}
  ## Write a single page to QSPI flash.
  ## 
  ## **Important**:
  ## - Page size is 256 bytes for IS25LP* chips
  ## - Must erase sector before writing
  ## - Only works in INDIRECT_POLLING mode
  ## - Writing to unaligned addresses will fail
  ## 
  ## Parameters:
  ## - address: Flash address to write to (must be page-aligned)
  ## - size: Number of bytes to write (max 256)
  ## - buffer: Pointer to data buffer
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure or invalid mode
  ## 
  ## Example:
  ## ```nim
  ## var data: array[256, uint8]
  ## for i in 0..<256:
  ##   data[i] = uint8(i)
  ## if qspi.writePage(0, 256, data[0].addr) != QSPIResult.OK:
  ##   echo "Write failed"
  ## ```

proc write*(qspi: var QSPIHandle, address: uint32, size: uint32, buffer: ptr uint8): QSPIResult {.
  importcpp: "#.Write(@)", cdecl.}
  ## Write data to QSPI flash (multiple pages).
  ## 
  ## This will automatically handle page boundary crossing.
  ## 
  ## **Important**:
  ## - Must erase sectors before writing
  ## - Only works in INDIRECT_POLLING mode
  ## - Slower than writePage for single-page writes
  ## 
  ## Parameters:
  ## - address: Flash address to start writing
  ## - size: Number of bytes to write
  ## - buffer: Pointer to data buffer
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure or invalid mode
  ## 
  ## Example:
  ## ```nim
  ## var data: array[1024, uint8]
  ## # Fill data...
  ## if qspi.write(0, 1024, data[0].addr) != QSPIResult.OK:
  ##   echo "Write failed"
  ## ```

# ============================================================================
# Erase Operations (Indirect Polling Mode Only)
# ============================================================================

proc erase*(qspi: var QSPIHandle, startAddr: uint32, endAddr: uint32): QSPIResult {.
  importcpp: "#.Erase(@)", cdecl.}
  ## Erase a region of QSPI flash.
  ## 
  ## Erases will happen in 4KB, 32KB, or 64KB increments depending on
  ## the size and alignment of the region.
  ## 
  ## **Important**:
  ## - Erasing sets all bits to 1 (0xFF)
  ## - Only works in INDIRECT_POLLING mode
  ## - Minimum erase size is 4KB (one sector)
  ## - Addresses will be aligned to sector boundaries
  ## 
  ## Parameters:
  ## - startAddr: Start address of region to erase
  ## - endAddr: End address of region to erase
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure or invalid mode
  ## 
  ## Example:
  ## ```nim
  ## # Erase first 64KB
  ## if qspi.erase(0, 65536) != QSPIResult.OK:
  ##   echo "Erase failed"
  ## ```

proc eraseSector*(qspi: var QSPIHandle, address: uint32): QSPIResult {.
  importcpp: "#.EraseSector(@)", cdecl.}
  ## Erase a single 4KB sector.
  ## 
  ## This is the smallest erasable unit on IS25LP* chips.
  ## 
  ## **Important**:
  ## - Erases 4KB starting at the given address
  ## - Address will be aligned to 4KB boundary
  ## - Only works in INDIRECT_POLLING mode
  ## 
  ## Parameters:
  ## - address: Address within the sector to erase
  ## 
  ## Returns:
  ## - QSPIResult.OK on success
  ## - QSPIResult.ERR on failure or invalid mode
  ## 
  ## Example:
  ## ```nim
  ## # Erase sector 0 (addresses 0-4095)
  ## if qspi.eraseSector(0) != QSPIResult.OK:
  ##   echo "Erase failed"
  ## ```

# ============================================================================
# Memory Access
# ============================================================================

proc getData*(qspi: var QSPIHandle, offset: uint32 = 0): pointer {.
  importcpp: "#.GetData(@)", cdecl.}
  ## Get a pointer to QSPI flash memory.
  ## 
  ## In MEMORY_MAPPED mode, returns a pointer to 0x90000000 + offset.
  ## Memory is read-only in this mode.
  ## 
  ## In INDIRECT_POLLING mode, can be used to verify written data.
  ## 
  ## Parameters:
  ## - offset: Offset from start of flash memory (default: 0)
  ## 
  ## Returns: Pointer to flash memory
  ## 
  ## Example:
  ## ```nim
  ## # Read data from flash
  ## let ptr = cast[ptr UncheckedArray[uint8]](qspi.getData())
  ## for i in 0..<16:
  ##   echo "Byte ", i, ": ", ptr[i]
  ## ```

proc getStatus*(qspi: var QSPIHandle): QSPIStatus {.
  importcpp: "#.GetStatus()", cdecl.}
  ## Get the current status of the QSPI module.
  ## 
  ## Useful for debugging errors.
  ## 
  ## Returns:
  ## - QSPIStatus.GOOD: No errors
  ## - QSPIStatus.E_HAL_ERROR: Hardware abstraction layer error
  ## - QSPIStatus.E_SWITCHING_MODES: Error switching modes
  ## - QSPIStatus.E_INVALID_MODE: Invalid operation for current mode

# ============================================================================
# Helper Functions
# ============================================================================

const
  QSPI_SECTOR_SIZE* = 4096'u32  ## 4KB sector size
  QSPI_BLOCK_32K_SIZE* = 32768'u32  ## 32KB block size
  QSPI_BLOCK_64K_SIZE* = 65536'u32  ## 64KB block size
  QSPI_PAGE_SIZE* = 256'u32  ## 256 byte page size
  QSPI_MEMORY_MAPPED_BASE* = 0x90000000'u32  ## Memory-mapped base address

proc alignToSector*(address: uint32): uint32 {.inline.} =
  ## Align an address down to the nearest sector boundary (4KB).
  ## 
  ## Example:
  ## ```nim
  ## let aligned = alignToSector(4200)  # Returns 4096
  ## ```
  result = address and not (QSPI_SECTOR_SIZE - 1)

proc alignToPage*(address: uint32): uint32 {.inline.} =
  ## Align an address down to the nearest page boundary (256 bytes).
  ## 
  ## Example:
  ## ```nim
  ## let aligned = alignToPage(300)  # Returns 256
  ## ```
  result = address and not (QSPI_PAGE_SIZE - 1)

proc isPageAligned*(address: uint32): bool {.inline.} =
  ## Check if an address is page-aligned (256 byte boundary).
  result = (address and (QSPI_PAGE_SIZE - 1)) == 0

proc isSectorAligned*(address: uint32): bool {.inline.} =
  ## Check if an address is sector-aligned (4KB boundary).
  result = (address and (QSPI_SECTOR_SIZE - 1)) == 0

proc sectorCount*(startAddr, endAddr: uint32): uint32 {.inline.} =
  ## Calculate number of sectors between two addresses.
  ## 
  ## Example:
  ## ```nim
  ## let sectors = sectorCount(0, 8192)  # Returns 2 (8KB = 2 sectors)
  ## ```
  let alignedStart = alignToSector(startAddr)
  let alignedEnd = alignToSector(endAddr)
  result = (alignedEnd - alignedStart) div QSPI_SECTOR_SIZE
