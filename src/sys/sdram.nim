## External SDRAM support for libDaisy Nim wrapper
##
## This module provides support for the external SDRAM chip on Daisy Seed.
## The SDRAM provides 64MB of additional RAM for audio buffers, delay lines,
## wavetables, and other large data structures.
##
## Basic Usage:
## ```nim
## import nimphea
## import sys/sdram
## 
## var hw = newDaisySeed()
## var sdram = newSdramHandle()
## 
## # Large buffer in SDRAM
## var delayBuffer {.codegenDecl: "$# $# __attribute__((section(\".sdram_bss\")))".}: array[480000, float32]
## 
## proc main() =
##   hw.init()
##   
##   # Initialize SDRAM
##   if sdram.init() != SDRAM_OK:
##     return
##   
##   # Now you can use delayBuffer and other SDRAM variables
##   for i in 0..<len(delayBuffer):
##     delayBuffer[i] = 0.0
##   
##   while true:
##     hw.delayMs(100)
## ```
##
## SDRAM Memory Details:
## - Base Address: 0xC0000000
## - Size: 64MB (on Daisy Seed)
## - Speed: 100MHz
## - Chip: AS4C16M16SA or equivalent
##
## Important Notes:
## - SDRAM must be initialized before accessing SDRAM variables
## - Use codegenDecl pragma with section attribute for SDRAM placement
## - SDRAM is not suitable for real-time audio processing (use internal RAM)
## - Perfect for buffers, wavetables, delay lines, sample storage

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(sdram)

{.push header: "dev/sdram.h".}

type
  # SDRAM Result codes
  SdramResult* {.importcpp: "SdramHandle::Result", size: sizeof(cint).} = enum
    SDRAM_OK = 0
    SDRAM_ERR

  # SDRAM Handle
  SdramHandle* {.importcpp: "SdramHandle".} = object

# SDRAM Handle methods
proc init*(this: var SdramHandle): SdramResult {.importcpp: "#.Init(@)", header: "dev/sdram.h".}
proc deInit*(this: var SdramHandle): SdramResult {.importcpp: "#.DeInit(@)", header: "dev/sdram.h".}

# Nim-friendly constructor
proc newSdramHandle*(): SdramHandle {.importcpp: "SdramHandle()", constructor, header: "dev/sdram.h".}

# SDRAM memory information constants
const
  SDRAM_BASE_ADDRESS* = 0xC0000000'u32  ## Base address of SDRAM
  SDRAM_SIZE* = 64 * 1024 * 1024        ## Total SDRAM size (64MB)
  SDRAM_SPEED* = 100_000_000            ## SDRAM clock speed (100MHz)

# Helper functions for SDRAM management

proc getSdramAddress*(): uint32 =
  ## Get the base address of SDRAM
  result = SDRAM_BASE_ADDRESS

proc getSdramSize*(): int =
  ## Get the total size of SDRAM in bytes
  result = SDRAM_SIZE

# External linker symbols
var ssdram_bss {.importc: "_ssdram_bss", nodecl.}: uint32
var esdram_bss {.importc: "_esdram_bss", nodecl.}: uint32

proc clearSdramBss*() =
  ## Clear all SDRAM BSS memory to zero.
  ## This should be called after SDRAM initialization if you want
  ## to ensure all SDRAM variables start at zero.
  ## 
  ## **Safety:** Pointer arithmetic is safe because bounds are guaranteed
  ## by linker symbols (_ssdram_bss, _esdram_bss) defined in the linker script.
  ## Both symbols are aligned to 4-byte boundaries by the linker.
  ## 
  ## Note: This is a slow operation and may take several milliseconds.
  var start = addr ssdram_bss
  let theEnd = addr esdram_bss
  while cast[uint](start) < cast[uint](theEnd):
    start[] = 0
    start = cast[ptr uint32](cast[uint](start) + sizeof(uint32).uint)

proc getSdramBssSize*(): int {.inline.} =
  ## Get the size of used SDRAM BSS memory
  result = cast[int](addr esdram_bss) - cast[int](addr ssdram_bss)

# Utility macros for creating SDRAM arrays

template sdramArray*(T: typedesc, size: int): untyped =
  ## Create an array in SDRAM BSS section
  ## Example: var buffer = sdramArray(float32, 100000)
  var arr {.sdramBss.}: array[size, T]
  arr

# Common use cases and size calculations

proc calcDelayBufferSize*(sampleRate: float, delayTimeSeconds: float): int =
  ## Calculate the number of samples needed for a delay buffer
  ## Example: let size = calcDelayBufferSize(48000.0, 5.0)  # 5 second delay
  result = int(sampleRate * delayTimeSeconds)

proc calcWavetableSize*(tableSize: int, numTables: int): int =
  ## Calculate total size for multiple wavetables
  ## Example: let size = calcWavetableSize(2048, 64)  # 64 wavetables of 2048 samples
  result = tableSize * numTables

proc megabytesToSamples*(megabytes: float, bytesPerSample: int = 4): int =
  ## Convert megabytes to number of samples (assumes float32 by default)
  ## Example: let samples = megabytesToSamples(10.0)  # 10MB of float32 samples
  result = int((megabytes * 1024.0 * 1024.0) / float(bytesPerSample))

proc samplesToMegabytes*(samples: int, bytesPerSample: int = 4): float =
  ## Convert number of samples to megabytes (assumes float32 by default)
  ## Example: let mb = samplesToMegabytes(1000000)
  result = (float(samples) * float(bytesPerSample)) / (1024.0 * 1024.0)

# Memory usage information helper
type
  SdramMemoryInfo* = object
    totalBytes*: int
    usedBytes*: int
    freeBytes*: int
    usedMegabytes*: float
    freeMegabytes*: float
    percentUsed*: float

proc getMemoryInfo*(): SdramMemoryInfo =
  ## Get information about SDRAM memory usage
  result.totalBytes = SDRAM_SIZE
  result.usedBytes = getSdramBssSize()
  result.freeBytes = result.totalBytes - result.usedBytes
  result.usedMegabytes = float(result.usedBytes) / (1024.0 * 1024.0)
  result.freeMegabytes = float(result.freeBytes) / (1024.0 * 1024.0)
  result.percentUsed = (float(result.usedBytes) / float(result.totalBytes)) * 100.0

# Example usage patterns documented as comments

## Delay Line Example:
## ```nim
## const SAMPLE_RATE = 48000
## const MAX_DELAY_SEC = 10
## 
## var delayLine {.sdramBss.}: array[SAMPLE_RATE * MAX_DELAY_SEC, float32]
## var delayIndex = 0
## 
## proc audioCallback(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
##   for i in 0..<size:
##     # Write to delay line
##     delayLine[delayIndex] = input[0][i]
##     
##     # Read from delay line (simple)
##     output[0][i] = delayLine[delayIndex]
##     
##     delayIndex = (delayIndex + 1) mod len(delayLine)
## ```

## Wavetable Example:
## ```nim
## const TABLE_SIZE = 2048
## const NUM_TABLES = 64
## 
## var wavetables {.sdramBss.}: array[NUM_TABLES * TABLE_SIZE, float32]
## 
## proc initWavetables() =
##   for tableNum in 0..<NUM_TABLES:
##     for i in 0..<TABLE_SIZE:
##       let phase = float32(i) / float32(TABLE_SIZE)
##       let idx = tableNum * TABLE_SIZE + i
##       wavetables[idx] = sin(phase * 2.0 * PI * float32(tableNum + 1))
## ```

## Sample Buffer Example:
## ```nim
## # Store 60 seconds of stereo audio at 48kHz
## const BUFFER_SIZE = 48000 * 60 * 2
## 
## var sampleBuffer {.sdramBss.}: array[BUFFER_SIZE, float32]
## var recordPos = 0
## var playPos = 0
## 
## proc recordSample(left, right: float32) =
##   if recordPos < BUFFER_SIZE - 1:
##     sampleBuffer[recordPos] = left
##     sampleBuffer[recordPos + 1] = right
##     recordPos += 2
## 
## proc playSample(): tuple[left, right: float32] =
##   if playPos < recordPos - 1:
##     result.left = sampleBuffer[playPos]
##     result.right = sampleBuffer[playPos + 1]
##     playPos += 2
##   else:
##     result = (0.0'f32, 0.0'f32)
## ```

when isMainModule:
  import std/strutils
  echo "libDaisy SDRAM wrapper"
  echo "Provides access to 64MB external SDRAM"
  echo "Base Address: 0x", SDRAM_BASE_ADDRESS.toHex()
  echo "Total Size: ", SDRAM_SIZE div (1024 * 1024), " MB"
