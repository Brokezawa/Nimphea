## nimphea_wavformat
## ==================
##
## Nim wrapper for libDaisy WAV file format utilities.
##
## Provides structures and constants for reading/writing WAV audio files.
## Used with SDMMC (SD card) module for audio file I/O.
##
## **Example:**
## ```nim
## import src/nimphea_wavformat
##
## var header: WavFormatTypeDef
## # Read header from file...
## if header.ChunkId == kWavFileChunkId:
##   echo "Valid WAV file"
##   echo "Sample Rate: ", header.SampleRate
##   echo "Channels: ", header.NbrChannels
## ```

import nimphea_macros

useNimpheaModules(wav_format)

const
  kWavFileChunkId* = 0x46464952'u32     ## "RIFF"
  kWavFileWaveId* = 0x45564157'u32      ## "WAVE"  
  kWavFileSubChunk1Id* = 0x20746d66'u32 ## "fmt "
  kWavFileSubChunk2Id* = 0x61746164'u32 ## "data"

type
  WavFileFormatCode* = enum
    ## Standard format codes for waveform data
    WAVE_FORMAT_PCM = 0x0001         ## PCM format
    WAVE_FORMAT_IEEE_FLOAT = 0x0003  ## IEEE float format
    WAVE_FORMAT_ALAW = 0x0006        ## A-law format
    WAVE_FORMAT_ULAW = 0x0007        ## μ-law format
    WAVE_FORMAT_EXTENSIBLE = 0xFFFE  ## Extensible format (>16-bit PCM, >2 channels, etc.)

  WavFormatTypeDef* {.importcpp: "daisy::WAV_FormatTypeDef",
                       header: "util/wav_format.h".} = object
    ## WAV file format header structure
    ChunkId*: uint32       ## "RIFF" chunk ID
    FileSize*: uint32      ## File size minus 8 bytes
    FileFormat*: uint32    ## "WAVE" format ID
    SubChunk1ID*: uint32   ## "fmt " subchunk ID
    SubChunk1Size*: uint32 ## Size of fmt subchunk
    AudioFormat*: uint16   ## Audio format code
    NbrChannels*: uint16   ## Number of channels
    SampleRate*: uint32    ## Sample rate in Hz
    ByteRate*: uint32      ## Byte rate (SampleRate * NbrChannels * BitsPerSample/8)
    BlockAlign*: uint16    ## Block alignment (NbrChannels * BitsPerSample/8)
    BitPerSample*: uint16  ## Bits per sample
    SubChunk2ID*: uint32   ## "data" subchunk ID
    SubCHunk2Size*: uint32 ## Size of data subchunk
