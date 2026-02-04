## WAV File Parser Module
## 
## Minimal, allocation-free WAV (RIFF) parser for embedded systems.
## Parses WAV file headers and validates format without loading sample data.
##
## **Key Features:**
## - Zero heap allocation
## - Supports PCM and IEEE float formats
## - Handles JUNK and unknown chunks
## - Records data offset for streaming
## - Metadata extraction support
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import nimphea_wavparser
##   import per/sdmmc
##   
##   var parser: WavParser
##   var fil: FIL
##   
##   # Open WAV file
##   discard f_open(addr fil, "sample.wav", FA_READ)
##   
##   # Create file reader and parse
##   var reader = createFileReader(addr fil)
##   if parser.parse(reader):
##     let info = parser.info()
##     echo "Sample Rate: ", info.sampleRate
##     echo "Channels: ", info.numChannels
##     echo "Bits/Sample: ", info.bitsPerSample
##     echo "Data Offset: ", parser.dataOffset()
##     echo "Data Size: ", parser.dataSize()
##   
##   f_close(addr fil)
##
## **Supported Formats:**
## - PCM (16-bit, 24-bit, 32-bit)
## - IEEE Float (32-bit, 64-bit)
## - Extensible format (basic parsing)
##
## **Limitations:**
## - Does not load sample data (use with WavPlayer for streaming)
## - Maximum 16 metadata chunks
## - Little-endian host assumed (STM32/Cortex-M)

import nimphea_macros
import per/sdmmc

useNimpheaModules(wav_parser)

# Required: Enable FatFS FileReader implementation in libDaisy/src/util/FileReader.h
{.passC: "-DFILEIO_ENABLE_FATFS_READER".}

type
  WavFormatInfo* {.importcpp: "daisy::WavFormatInfo", 
                   header: "util/WavParser.h".} = object
    ## WAV format information extracted from header
    audioFormat*: uint16       ## 1 = PCM, 3 = IEEE float, 0xFFFE = extensible
    numChannels*: uint16       ## Number of channels (1=mono, 2=stereo, etc.)
    sampleRate*: uint32        ## Sample rate in Hz
    byteRate*: uint32          ## Byte rate (sampleRate * channels * bytesPerSample)
    blockAlign*: uint16        ## Block alignment (channels * bytesPerSample)
    bitsPerSample*: uint16     ## Bits per sample (8, 16, 24, 32, etc.)
    validBitsPerSample*: uint16  ## For extensible format
    channelMask*: uint32       ## Channel mask for extensible format
    subFormat*: uint16         ## Sub-format for extensible format

  MetadataEntry* {.importcpp: "daisy::MetadataEntry",
                   header: "util/WavParser.h".} = object
    ## Metadata chunk information
    fourcc*: uint32  ## Chunk ID (FourCC code)
    size*: uint32    ## Payload size in bytes
    offset*: uint32  ## File offset of chunk data

  IReader* {.importcpp: "daisy::IReader", header: "util/FileReader.h".} = object
    ## Abstract reader interface

  FileReader* {.importcpp: "daisy::FileReader",
                header: "util/FileReader.h".} = object
    ## Concrete file reader for FatFS
  
  WavParser* {.importcpp: "daisy::WavParser",
               header: "util/WavParser.h".} = object
    ## WAV file parser
    ## 
    ## Parses RIFF/WAV file format and extracts:
    ## - Format information (sample rate, channels, bit depth)
    ## - Data chunk location and size
    ## - Optional metadata chunks

# FourCC Constants
const
  FOURCC_RIFF* = 0x46464952'u32  ## "RIFF"
  FOURCC_WAVE* = 0x45564157'u32  ## "WAVE"
  FOURCC_FMT*  = 0x20746d66'u32  ## "fmt "
  FOURCC_DATA* = 0x61746164'u32  ## "data"
  FOURCC_JUNK* = 0x4b4e554a'u32  ## "JUNK"
  FOURCC_FACT* = 0x74636166'u32  ## "fact"
  FOURCC_LIST* = 0x5453494c'u32  ## "LIST"
  FOURCC_INFO* = 0x4f464e49'u32  ## "INFO"

  MAX_METADATA_CHUNKS* = 16  ## Maximum metadata chunks to store

# Format codes
const
  WAVE_FORMAT_PCM* = 0x0001'u16         ## PCM format
  WAVE_FORMAT_IEEE_FLOAT* = 0x0003'u16  ## IEEE float format
  WAVE_FORMAT_EXTENSIBLE* = 0xFFFE'u16  ## Extensible format

# FileReader constructor
proc createFileReader*(fil: ptr FIL): FileReader {.importcpp: "daisy::FileReader(@)", 
                                                    header: "util/FileReader.h".}
  ## Create a FileReader from a FatFS file handle
  ## 
  ## **Parameters:**
  ## - fil: Pointer to opened FIL structure
  ## 
  ## **Returns:**
  ## FileReader instance for use with WavParser
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var fil: FIL
  ##   discard f_open(addr fil, "test.wav", FA_READ)
  ##   var reader = createFileReader(addr fil)

# WavParser methods
proc parse*(this: var WavParser, reader: var IReader): bool {.importcpp: "#.parse(@)".}
  ## Parse WAV file using provided reader
  ## 
  ## **Parameters:**
  ## - reader: IReader implementation (e.g., FileReader)
  ## 
  ## **Returns:**
  ## true if parsing succeeded, false on error
  ## 
  ## **Note:** After successful parsing, use info(), dataOffset(), and dataSize() 
  ## to access file information
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var parser: WavParser
  ##   var reader = createFileReader(addr fil)
  ##   if parser.parse(reader):
  ##     echo "Parse successful!"

proc info*(this: WavParser): WavFormatInfo {.importcpp: "#.info()", noSideEffect.}
  ## Get format information from parsed WAV file
  ## 
  ## **Returns:**
  ## WavFormatInfo structure with sample rate, channels, bit depth, etc.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let info = parser.info()
  ##   echo "Sample Rate: ", info.sampleRate
  ##   echo "Channels: ", info.numChannels
  ##   echo "Bits/Sample: ", info.bitsPerSample

proc dataOffset*(this: WavParser): uint32 {.importcpp: "#.dataOffset()", noSideEffect.}
  ## Get file offset of audio data chunk
  ## 
  ## **Returns:**
  ## Byte offset from start of file where audio samples begin
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let offset = parser.dataOffset()
  ##   discard f_lseek(addr fil, offset)  # Seek to audio data

proc dataSize*(this: WavParser): uint32 {.importcpp: "#.dataSize()", noSideEffect.}
  ## Get size of audio data chunk in bytes
  ## 
  ## **Returns:**
  ## Size of audio data in bytes
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let numSamples = parser.dataSize() div 
  ##                    (parser.info().bitsPerSample div 8) div
  ##                    parser.info().numChannels

proc metadata*(this: WavParser): ptr MetadataEntry {.importcpp: "#.metadata()", noSideEffect.}
  ## Get pointer to metadata entries array
  ## 
  ## **Returns:**
  ## Pointer to array of MetadataEntry (up to MAX_METADATA_CHUNKS)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let meta = parser.metadata()
  ##   for i in 0..<parser.metadataCount():
  ##     echo "Chunk: ", cast[ptr UncheckedArray[MetadataEntry]](meta)[i].fourcc

proc metadataCount*(this: WavParser): cint {.importcpp: "#.metadataCount()", noSideEffect.}
  ## Get number of metadata chunks found
  ## 
  ## **Returns:**
  ## Number of metadata entries (0 to MAX_METADATA_CHUNKS)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   echo "Found ", parser.metadataCount(), " metadata chunks"

# Helper functions
proc isValidWav*(parser: WavParser): bool {.inline.} =
  ## Check if parsed file is a valid WAV file
  ## 
  ## **Returns:**
  ## true if format info indicates valid WAV
  let info = parser.info()
  result = info.numChannels > 0 and 
           info.sampleRate > 0 and 
           info.bitsPerSample > 0

proc isPcm*(info: WavFormatInfo): bool {.inline.} =
  ## Check if format is PCM
  ## 
  ## **Returns:**
  ## true if audio format is PCM
  result = info.audioFormat == WAVE_FORMAT_PCM

proc isFloat*(info: WavFormatInfo): bool {.inline.} =
  ## Check if format is IEEE float
  ## 
  ## **Returns:**
  ## true if audio format is IEEE float
  result = info.audioFormat == WAVE_FORMAT_IEEE_FLOAT

proc isExtensible*(info: WavFormatInfo): bool {.inline.} =
  ## Check if format is extensible
  ## 
  ## **Returns:**
  ## true if audio format is extensible
  result = info.audioFormat == WAVE_FORMAT_EXTENSIBLE

proc bytesPerSample*(info: WavFormatInfo): int {.inline.} =
  ## Calculate bytes per sample
  ## 
  ## **Returns:**
  ## Bytes per sample (bit depth / 8)
  result = int(info.bitsPerSample) div 8

proc bytesPerFrame*(info: WavFormatInfo): int {.inline.} =
  ## Calculate bytes per sample frame
  ## 
  ## **Returns:**
  ## Bytes per frame (channels * bytesPerSample)
  result = int(info.numChannels) * bytesPerSample(info)

proc numSamples*(parser: WavParser): uint32 {.inline.} =
  ## Calculate total number of sample frames
  ## 
  ## **Returns:**
  ## Total sample frames in file
  let info = parser.info()
  let frameBytes = bytesPerFrame(info)
  if frameBytes > 0:
    result = parser.dataSize() div uint32(frameBytes)
  else:
    result = 0

proc durationSeconds*(parser: WavParser): float32 {.inline.} =
  ## Calculate audio duration in seconds
  ## 
  ## **Returns:**
  ## Duration in seconds
  let info = parser.info()
  if info.sampleRate > 0:
    result = float32(parser.numSamples()) / float32(info.sampleRate)
  else:
    result = 0.0
