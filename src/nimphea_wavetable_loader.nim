## Wavetable Loader Module
## ========================
##
## This module provides functionality for loading banks of wavetables from WAV files.
## Wavetables are essential for wavetable synthesis, allowing morphing between
## different waveforms for rich timbral variation.
##
## Features:
## - Load multiple wavetables from a single WAV file
## - Automatic conversion from 16-bit/32-bit to float
## - Access individual wavetables by index
## - Memory-efficient loading with internal workspace
##
## Supported Formats:
## - 16-bit PCM WAV files
## - 32-bit PCM WAV files
## - Mono files (stereo will be loaded interleaved)
##
## Memory Usage:
## - User provides buffer for wavetable data
## - 4KB internal workspace for file reading
## - Buffer size = num_tables * samples_per_table * sizeof(float)
##
## Typical Wavetable Sizes:
## - 256 samples per table (standard)
## - 512 samples per table (higher quality)
## - 1024 samples per table (maximum quality)
## - Common banks: 64-256 tables per file
##
## Usage Example:
## ```nim
## import nimphea_wavetable_loader
## 
## # Allocate buffer (64 tables × 256 samples × 4 bytes)
## var tableBuffer: array[64 * 256, float]
## var loader: WaveTableLoader
## 
## # Initialize with memory buffer
## loader.init(tableBuffer[0].addr, tableBuffer.len * sizeof(float))
## 
## # Set table layout: 256 samples per table, 64 tables
## if loader.setWaveTableInfo(256, 64) == WaveTableResult.OK:
##   # Import wavetables from file
##   if loader.import("wavetables.wav") == WaveTableResult.OK:
##     # Access individual tables
##     let table0 = loader.getTable(0)  # First wavetable
##     let table32 = loader.getTable(32)  # 33rd wavetable
## ```

import nimphea_macros

useNimpheaModules(wavetable_loader)

# Forward declarations
type
  WaveTableResult* {.importcpp: "daisy::WaveTableLoader::Result", size: sizeof(cint).} = enum
    OK = "daisy::WaveTableLoader::Result::OK"
    ERR_TABLE_INFO_OVERFLOW = "daisy::WaveTableLoader::Result::ERR_TABLE_INFO_OVERFLOW"
    ERR_FILE_READ = "daisy::WaveTableLoader::Result::ERR_FILE_READ"
    ERR_GENERIC = "daisy::WaveTableLoader::Result::ERR_GENERIC"

  WaveTableLoader* {.importcpp: "daisy::WaveTableLoader", byref.} = object

# ============================================================================
# Core Methods
# ============================================================================

proc init*(loader: var WaveTableLoader, mem: ptr cfloat, memSize: csize_t) {.
  importcpp: "#.Init(@)", cdecl.}
  ## Initialize the wavetable loader with a memory buffer.
  ## 
  ## The memory buffer will store all loaded wavetables as float data.
  ## The buffer must be large enough to hold all tables:
  ##   required_size = num_tables * samples_per_table * sizeof(float)
  ## 
  ## Parameters:
  ## - mem: Pointer to float buffer for wavetable storage
  ## - memSize: Size of buffer in bytes
  ## 
  ## Example:
  ## ```nim
  ## var buffer: array[16384, float]  # 64KB buffer
  ## loader.init(buffer[0].addr, buffer.len * sizeof(float))
  ## ```

proc setWaveTableInfo*(loader: var WaveTableLoader, samps: csize_t, count: csize_t): WaveTableResult {.
  importcpp: "#.SetWaveTableInfo(@)", cdecl.}
  ## Configure the wavetable layout.
  ## 
  ## This tells the loader how to interpret the WAV file:
  ## - How many samples per individual wavetable
  ## - How many wavetables total
  ## 
  ## Must be called before import().
  ## 
  ## Parameters:
  ## - samps: Number of samples per wavetable (e.g., 256)
  ## - count: Number of wavetables in the file (e.g., 64)
  ## 
  ## Returns:
  ## - WaveTableResult.OK on success
  ## - WaveTableResult.ERR_TABLE_INFO_OVERFLOW if buffer too small
  ## 
  ## Example:
  ## ```nim
  ## # 64 wavetables, 256 samples each
  ## if loader.setWaveTableInfo(256, 64) != WaveTableResult.OK:
  ##   echo "Buffer too small!"
  ## ```

proc `import`*(loader: var WaveTableLoader, filename: cstring): WaveTableResult {.
  importcpp: "#.Import(@)", cdecl.}
  ## Load wavetables from a WAV file on the SD card.
  ## 
  ## This will:
  ## 1. Open and parse the WAV file
  ## 2. Read audio data in chunks
  ## 3. Convert to float format
  ## 4. Store in the provided memory buffer
  ## 
  ## The WAV file should contain concatenated wavetables.
  ## For example, a file with 64 tables of 256 samples should be
  ## 16,384 samples long (64 * 256).
  ## 
  ## Supported formats:
  ## - 16-bit PCM
  ## - 32-bit PCM
  ## - Mono (stereo will be loaded interleaved)
  ## 
  ## Parameters:
  ## - filename: Path to WAV file on SD card
  ## 
  ## Returns:
  ## - WaveTableResult.OK on success
  ## - WaveTableResult.ERR_FILE_READ on disk I/O errors
  ## 
  ## Example:
  ## ```nim
  ## if loader.import("saw_tables.wav") == WaveTableResult.OK:
  ##   echo "Loaded successfully"
  ## ```

proc getTable*(loader: var WaveTableLoader, idx: csize_t): ptr cfloat {.
  importcpp: "#.GetTable(@)", cdecl.}
  ## Get a pointer to a specific wavetable.
  ## 
  ## Returns a pointer to the start of the requested wavetable,
  ## or nullptr if the index is invalid.
  ## 
  ## The returned pointer points to `samples_per_table` consecutive
  ## float samples.
  ## 
  ## Parameters:
  ## - idx: Wavetable index (0 to count-1)
  ## 
  ## Returns:
  ## - Pointer to wavetable data, or nullptr if invalid
  ## 
  ## Example:
  ## ```nim
  ## # Get first wavetable
  ## let table = loader.getTable(0)
  ## if not table.isNil:
  ##   # Use wavetable for oscillator
  ##   for i in 0..<256:
  ##     let sample = table[i]
  ## ```

# ============================================================================
# Helper Functions
# ============================================================================

proc calculateBufferSize*(numTables: int, samplesPerTable: int): int {.inline.} =
  ## Calculate required buffer size in bytes for wavetable storage.
  ## 
  ## Parameters:
  ## - numTables: Number of wavetables
  ## - samplesPerTable: Samples per wavetable
  ## 
  ## Returns: Required buffer size in bytes
  ## 
  ## Example:
  ## ```nim
  ## let size = calculateBufferSize(64, 256)  # 65,536 bytes (64KB)
  ## var buffer = newSeq[float](size div sizeof(float))
  ## ```
  result = numTables * samplesPerTable * sizeof(cfloat)

proc isValidTable*(table: ptr cfloat): bool {.inline.} =
  ## Check if a wavetable pointer is valid (not nullptr).
  ## 
  ## Parameters:
  ## - table: Wavetable pointer from getTable()
  ## 
  ## Returns: true if valid, false if nullptr
  result = not table.isNil
