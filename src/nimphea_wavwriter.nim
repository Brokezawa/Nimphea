## WAV File Recording Module
## =========================
##
## This module provides WAV file recording functionality for the Daisy platform.
## It supports real-time recording to SD card with 16-bit and 32-bit formats.
##
## Features:
## - Real-time audio recording to WAV files
## - 16-bit and 32-bit signed integer formats
## - Float input with automatic conversion
## - Double-buffered streaming for uninterrupted recording
## - Automatic WAV header generation and finalization
##
## Memory Usage:
## - (2 * transfer_size) bytes
## - Default 32KB transfer = 64KB total memory
## - 16KB transfer = 32KB total (lower latency, more disk I/O)
##
## Supported Formats:
## - 16-bit PCM (signed integer)
## - 32-bit PCM (signed integer)
##
## Future Support (not yet implemented):
## - 24-bit PCM
## - 32-bit float
##
## Usage Example:
## ```nim
## import nimphea_wavwriter
## 
## var writer: WavWriter32K
## var config = WavWriterConfig(
##   samplerate: 48000.0,
##   channels: 2,
##   bitspersample: 16
## )
## 
## # Initialize
## writer.init(config)
## 
## # Open file for recording
## writer.openFile("recording.wav")
## 
## # In audio callback
## proc audioCallback(input, output: AudioBuffer, size: int) =
##   for i in 0..<size:
##     writer.sample(input[0][i].unsafeAddr)  # Record input
## 
## # In main loop
## while recording:
##   writer.write()  # Write to SD card
##   delay(1)
## 
## # When done
## writer.saveFile()  # Finalize and close
## ```

import nimphea_macros

useNimpheaModules(wav_writer)

# Forward declarations
type
  WavWriterResult* {.importcpp: "daisy::WavWriter<32768>::Result", size: sizeof(cint).} = enum
    OK = "daisy::WavWriter<32768>::Result::OK"
    ERROR = "daisy::WavWriter<32768>::Result::ERROR"

  WavWriterConfig* {.importcpp: "daisy::WavWriter<32768>::Config", bycopy.} = object
    samplerate* {.importcpp: "samplerate".}: cfloat
    channels* {.importcpp: "channels".}: int32
    bitspersample* {.importcpp: "bitspersample".}: int32

  WavWriterBufferState* {.importcpp: "daisy::WavWriter<32768>::BufferState", pure.} = enum
    IDLE = "daisy::WavWriter<32768>::BufferState::IDLE"
    FLUSH0 = "daisy::WavWriter<32768>::BufferState::FLUSH0"
    FLUSH1 = "daisy::WavWriter<32768>::BufferState::FLUSH1"

  # Fixed 16KB transfer size (lower latency, more frequent disk writes)
  WavWriter16K* {.importcpp: "daisy::WavWriter<16384>", byref.} = object
  
  # Fixed 32KB transfer size (balanced performance)
  WavWriter32K* {.importcpp: "daisy::WavWriter<32768>", byref.} = object
  
  # Fixed 64KB transfer size (maximum throughput, higher latency)
  WavWriter64K* {.importcpp: "daisy::WavWriter<65536>", byref.} = object

# Type aliases for convenience
type
  WavWriter* = WavWriter32K  ## Default WavWriter with 32KB transfer size

# ============================================================================
# Core Methods
# ============================================================================

proc init*(writer: var WavWriter16K, config: WavWriterConfig) {.
  importcpp: "#.Init(reinterpret_cast<const daisy::WavWriter<16384>::Config&>(@))", cdecl.}
  ## Initialize the WAV writer with the given configuration.
  ## This prepares the WAV header and internal buffers.
  ## 
  ## Must be called before openFile().
  ## 
  ## Parameters:
  ## - config: Configuration with sample rate, channels, and bit depth
  ## 
  ## Example:
  ## ```nim
  ## var config = WavWriterConfig(
  ##   samplerate: 48000.0,
  ##   channels: 2,
  ##   bitspersample: 16
  ## )
  ## writer.init(config)
  ## ```

proc init*(writer: var WavWriter32K, config: WavWriterConfig) {.
  importcpp: "#.Init(@)", cdecl.}

proc init*(writer: var WavWriter64K, config: WavWriterConfig) {.
  importcpp: "#.Init(reinterpret_cast<const daisy::WavWriter<65536>::Config&>(@))", cdecl.}

proc openFile*(writer: var WavWriter16K, name: cstring) {.
  importcpp: "#.OpenFile(@)", cdecl.}
  ## Open a new file for recording.
  ## This will create the file (overwriting if it exists) and write the initial WAV header.
  ## 
  ## After calling this, use sample() in the audio callback to record audio.
  ## 
  ## Parameters:
  ## - name: Filename to create on the SD card

proc openFile*(writer: var WavWriter32K, name: cstring) {.
  importcpp: "#.OpenFile(@)", cdecl.}

proc openFile*(writer: var WavWriter64K, name: cstring) {.
  importcpp: "#.OpenFile(@)", cdecl.}

proc sample*(writer: var WavWriter16K, input: ptr cfloat) {.
  importcpp: "#.Sample(@)", cdecl.}
  ## Record a single audio frame (all channels).
  ## **Call this from your audio callback** for each sample frame.
  ## 
  ## The input should point to an array of floats with as many elements as
  ## the configured number of channels.
  ## 
  ## Float values will be automatically converted to the configured bit depth.
  ## 
  ## Parameters:
  ## - input: Pointer to array of floats (one per channel)
  ## 
  ## Example:
  ## ```nim
  ## # In audio callback
  ## var frame = [input[0][i], input[1][i]]  # Stereo
  ## writer.sample(frame[0].addr)
  ## ```

proc sample*(writer: var WavWriter32K, input: ptr cfloat) {.
  importcpp: "#.Sample(@)", cdecl.}

proc sample*(writer: var WavWriter64K, input: ptr cfloat) {.
  importcpp: "#.Sample(@)", cdecl.}

proc write*(writer: var WavWriter16K) {.
  importcpp: "#.Write()", cdecl.}
  ## Write buffered audio data to the SD card.
  ## **Must be called regularly in the main loop** (not in audio callback).
  ## 
  ## This performs the actual disk I/O. Call this frequently to prevent
  ## buffer overflow.
  ## 
  ## Example:
  ## ```nim
  ## # In main loop
  ## while recording:
  ##   writer.write()
  ##   delay(1)
  ## ```

proc write*(writer: var WavWriter32K) {.
  importcpp: "#.Write()", cdecl.}

proc write*(writer: var WavWriter64K) {.
  importcpp: "#.Write()", cdecl.}

proc saveFile*(writer: var WavWriter16K) {.
  importcpp: "#.SaveFile()", cdecl.}
  ## Finalize and close the recording.
  ## This will:
  ## 1. Flush any remaining data in the buffer
  ## 2. Update the WAV header with the final file size
  ## 3. Close the file
  ## 
  ## **Must be called** when recording is complete to ensure a valid WAV file.
  ## 
  ## After calling this, the file is complete and can be played back.

proc saveFile*(writer: var WavWriter32K) {.
  importcpp: "#.SaveFile()", cdecl.}

proc saveFile*(writer: var WavWriter64K) {.
  importcpp: "#.SaveFile()", cdecl.}

# ============================================================================
# State Query Methods
# ============================================================================

proc isRecording*(writer: WavWriter16K): bool {.
  importcpp: "#.IsRecording()", cdecl.}
  ## Check if recording is currently active.
  ## 
  ## Returns true after openFile() and before saveFile().

proc isRecording*(writer: WavWriter32K): bool {.
  importcpp: "#.IsRecording()", cdecl.}

proc isRecording*(writer: WavWriter64K): bool {.
  importcpp: "#.IsRecording()", cdecl.}

proc getLengthSamps*(writer: var WavWriter16K): uint32 {.
  importcpp: "#.GetLengthSamps()", cdecl.}
  ## Get the current length of the recording in samples.
  ## 
  ## For multi-channel recordings, this is the number of sample frames,
  ## not the total number of individual channel samples.

proc getLengthSamps*(writer: var WavWriter32K): uint32 {.
  importcpp: "#.GetLengthSamps()", cdecl.}

proc getLengthSamps*(writer: var WavWriter64K): uint32 {.
  importcpp: "#.GetLengthSamps()", cdecl.}

proc getLengthSeconds*(writer: var WavWriter16K): cfloat {.
  importcpp: "#.GetLengthSeconds()", cdecl.}
  ## Get the current length of the recording in seconds.

proc getLengthSeconds*(writer: var WavWriter32K): cfloat {.
  importcpp: "#.GetLengthSeconds()", cdecl.}

proc getLengthSeconds*(writer: var WavWriter64K): cfloat {.
  importcpp: "#.GetLengthSeconds()", cdecl.}

# ============================================================================
# Helper Functions
# ============================================================================

proc createConfig*(samplerate: float, channels: int, bitspersample: int): WavWriterConfig {.inline.} =
  ## Helper function to create a WavWriterConfig.
  ## 
  ## Parameters:
  ## - samplerate: Sample rate in Hz (e.g., 48000.0)
  ## - channels: Number of audio channels (1=mono, 2=stereo)
  ## - bitspersample: Bit depth (16 or 32)
  ## 
  ## Returns: WavWriterConfig struct
  ## 
  ## Example:
  ## ```nim
  ## var config = createConfig(48000.0, 2, 16)
  ## writer.init(config)
  ## ```
  result.samplerate = cfloat(samplerate)
  result.channels = int32(channels)
  result.bitspersample = int32(bitspersample)
