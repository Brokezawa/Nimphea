## WAV File Streaming Playback Module
## ====================================
##
## This module provides WAV file streaming playback functionality for the Daisy platform.
## It supports 16-bit WAV files with float output, variable playback speed, and looping.
##
## Features:
## - Streaming playback from SD card (no full file loading required)
## - Variable playback speed with linear interpolation
## - Looping support
## - Low-latency buffered streaming using FIFO
## - Pitch shifting via semitone offset
##
## Memory Usage:
## - Approximately 2 * workspace_bytes
## - Default 4KB workspace = ~8KB total memory
##
## Limitations:
## - 16-bit WAV files only at this time
## - No reverse playback support
## - Forward playback only
##
## Usage Example:
## ```nim
## import nimphea_wavplayer
## 
## var player: WavPlayer4K
## 
## # Initialize with file
## if player.init("sample.wav") == WavPlayerResult.Ok:
##   player.setLooping(true)
##   player.play()
## 
## # In audio callback
## proc audioCallback(input, output: AudioBuffer, size: int) =
##   for i in 0..<size:
##     let res = player.stream(output[0][i].addr, 2)  # 2 channels
## 
## # In main loop
## while true:
##   discard player.prepare()  # Refill buffer
##   delay(1)
## ```

import nimphea_macros

useNimpheaModules(wav_player)

# Forward declarations
type
  WavPlayerResult* {.size: sizeof(cint).} = enum
    Ok = 0
    FileNotFoundError = 1
    PlaybackUnderrun = 2
    PrepareOverrun = 3
    NewSamplesRequested = 4
    DiskError = 5

  WavPlayerFileInfo* {.importcpp: "daisy::WavPlayer<4096>::FileInfo", bycopy.} = object
    channels* {.importcpp: "channels".}: csize_t
    length* {.importcpp: "length".}: csize_t
    samplerate* {.importcpp: "samplerate".}: csize_t
    data_start* {.importcpp: "data_start".}: csize_t
    data_size_bytes* {.importcpp: "data_size_bytes".}: csize_t

  # Fixed 4KB workspace size (sufficient for most use cases)
  WavPlayer4K* {.importcpp: "daisy::WavPlayer<4096>", byref.} = object
  
  # Fixed 8KB workspace size (for higher performance requirements)
  WavPlayer8K* {.importcpp: "daisy::WavPlayer<8192>", byref.} = object
  
  # Fixed 16KB workspace size (for maximum performance)
  WavPlayer16K* {.importcpp: "daisy::WavPlayer<16384>", byref.} = object

# Type aliases for convenience
type
  WavPlayer* = WavPlayer4K  ## Default WavPlayer with 4KB workspace

# ============================================================================
# Core Methods
# ============================================================================

proc init*(player: var WavPlayer4K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Init(@))", cdecl.}
  ## Initialize and open a WAV file for playback.
  ## This will open the file, parse the header, and prepare audio for streaming.
  ## 
  ## Parameters:
  ## - name: Path to the WAV file on the SD card
  ## 
  ## Returns:
  ## - WavPlayerResult.Ok on success
  ## - WavPlayerResult.FileNotFoundError if file doesn't exist
  ## - WavPlayerResult.DiskError on disk I/O errors

proc init*(player: var WavPlayer8K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Init(@))", cdecl.}

proc init*(player: var WavPlayer16K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Init(@))", cdecl.}

proc open*(player: var WavPlayer4K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Open(@))", cdecl.}
  ## Open a WAV file and prepare for streaming.
  ## Similar to init() but doesn't reset playback state.

proc open*(player: var WavPlayer8K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Open(@))", cdecl.}

proc open*(player: var WavPlayer16K, name: cstring): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Open(@))", cdecl.}

proc close*(player: var WavPlayer4K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Close())", cdecl.}
  ## Close the currently open file and clear all data.

proc close*(player: var WavPlayer8K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Close())", cdecl.}

proc close*(player: var WavPlayer16K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Close())", cdecl.}

proc prepare*(player: var WavPlayer4K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Prepare())", cdecl.}
  ## Refill the playback buffer with new samples from disk.
  ## **Must be called regularly in the main loop** (not in audio callback).
  ## This performs the actual disk I/O for streaming.
  ## 
  ## Returns:
  ## - WavPlayerResult.Ok on success
  ## - WavPlayerResult.DiskError on disk I/O errors
  ## - WavPlayerResult.PrepareOverrun if buffer is already full

proc prepare*(player: var WavPlayer8K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Prepare())", cdecl.}

proc prepare*(player: var WavPlayer16K): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Prepare())", cdecl.}

proc stream*(player: var WavPlayer4K, samples: ptr cfloat, numChannels: csize_t): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Stream(@))", cdecl.}
  ## Stream audio samples from the file.
  ## **Call this from your audio callback.**
  ## 
  ## The function will fill the samples buffer with audio data, handling:
  ## - Variable playback speed with linear interpolation
  ## - Looping behavior
  ## - Automatic buffer refill requests
  ## 
  ## Parameters:
  ## - samples: Buffer to fill with audio samples
  ## - numChannels: Number of channels to fill (can differ from file channels)
  ## 
  ## Returns:
  ## - WavPlayerResult.Ok on success
  ## - WavPlayerResult.NewSamplesRequested when buffer needs refilling (call prepare())
  ## - WavPlayerResult.PlaybackUnderrun if buffer is empty during playback

proc stream*(player: var WavPlayer8K, samples: ptr cfloat, numChannels: csize_t): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Stream(@))", cdecl.}

proc stream*(player: var WavPlayer16K, samples: ptr cfloat, numChannels: csize_t): WavPlayerResult {.
  importcpp: "static_cast<int>(#.Stream(@))", cdecl.}

# ============================================================================
# Playback Control
# ============================================================================

proc restart*(player: var WavPlayer4K) {.
  importcpp: "#.Restart()", cdecl.}
  ## Clear all playback samples and return to the beginning of the file.
  ## This will clear buffers, seek to start, and request new samples.

proc restart*(player: var WavPlayer8K) {.
  importcpp: "#.Restart()", cdecl.}

proc restart*(player: var WavPlayer16K) {.
  importcpp: "#.Restart()", cdecl.}

proc setPlaying*(player: var WavPlayer4K, state: bool) {.
  importcpp: "#.SetPlaying(@)", cdecl.}
  ## Start or stop playback.
  ## 
  ## Parameters:
  ## - state: true to start playing, false to stop

proc setPlaying*(player: var WavPlayer8K, state: bool) {.
  importcpp: "#.SetPlaying(@)", cdecl.}

proc setPlaying*(player: var WavPlayer16K, state: bool) {.
  importcpp: "#.SetPlaying(@)", cdecl.}

proc play*(player: var WavPlayer4K) {.inline.} =
  ## Start playback (convenience wrapper for setPlaying(true))
  player.setPlaying(true)

proc play*(player: var WavPlayer8K) {.inline.} =
  player.setPlaying(true)

proc play*(player: var WavPlayer16K) {.inline.} =
  player.setPlaying(true)

proc stop*(player: var WavPlayer4K) {.inline.} =
  ## Stop playback (convenience wrapper for setPlaying(false))
  player.setPlaying(false)

proc stop*(player: var WavPlayer8K) {.inline.} =
  player.setPlaying(false)

proc stop*(player: var WavPlayer16K) {.inline.} =
  player.setPlaying(false)

proc setLooping*(player: var WavPlayer4K, state: bool) {.
  importcpp: "#.SetLooping(@)", cdecl.}
  ## Enable or disable looping playback.
  ## When enabled, playback will automatically restart from the beginning.

proc setLooping*(player: var WavPlayer8K, state: bool) {.
  importcpp: "#.SetLooping(@)", cdecl.}

proc setLooping*(player: var WavPlayer16K, state: bool) {.
  importcpp: "#.SetLooping(@)", cdecl.}

# ============================================================================
# Playback Speed Control
# ============================================================================

proc setPlaybackSpeedRatio*(player: var WavPlayer4K, speed: cfloat) {.
  importcpp: "#.SetPlaybackSpeedRatio(@)", cdecl.}
  ## Set playback speed as a ratio of original speed.
  ## 
  ## Examples:
  ## - 1.0 = original speed (normal playback)
  ## - 0.5 = half speed (slower)
  ## - 2.0 = double speed (faster)
  ## - 0.0 = paused
  ## 
  ## Note: Negative values are not supported (no reverse playback)

proc setPlaybackSpeedRatio*(player: var WavPlayer8K, speed: cfloat) {.
  importcpp: "#.SetPlaybackSpeedRatio(@)", cdecl.}

proc setPlaybackSpeedRatio*(player: var WavPlayer16K, speed: cfloat) {.
  importcpp: "#.SetPlaybackSpeedRatio(@)", cdecl.}

proc setPlaybackSpeedSemitones*(player: var WavPlayer4K, semitones: cfloat) {.
  importcpp: "#.SetPlaybackSpeedSemitones(@)", cdecl.}
  ## Set playback speed as semitone offset from original pitch.
  ## 
  ## Examples:
  ## - 0 = original pitch
  ## - +12 = one octave up (2x speed)
  ## - -12 = one octave down (0.5x speed)
  ## - +7 = perfect fifth up (1.5x speed)
  ## 
  ## The speed ratio is calculated as: 2^(semitones/12)

proc setPlaybackSpeedSemitones*(player: var WavPlayer8K, semitones: cfloat) {.
  importcpp: "#.SetPlaybackSpeedSemitones(@)", cdecl.}

proc setPlaybackSpeedSemitones*(player: var WavPlayer16K, semitones: cfloat) {.
  importcpp: "#.SetPlaybackSpeedSemitones(@)", cdecl.}

# ============================================================================
# State Query Methods
# ============================================================================

proc getDurationInSamples*(player: WavPlayer4K): csize_t {.
  importcpp: "#.GetDurationInSamples()", cdecl.}
  ## Get the total number of samples in the audio file.

proc getDurationInSamples*(player: WavPlayer8K): csize_t {.
  importcpp: "#.GetDurationInSamples()", cdecl.}

proc getDurationInSamples*(player: WavPlayer16K): csize_t {.
  importcpp: "#.GetDurationInSamples()", cdecl.}

proc getChannels*(player: WavPlayer4K): csize_t {.
  importcpp: "#.GetChannels()", cdecl.}
  ## Get the number of audio channels in the file.

proc getChannels*(player: WavPlayer8K): csize_t {.
  importcpp: "#.GetChannels()", cdecl.}

proc getChannels*(player: WavPlayer16K): csize_t {.
  importcpp: "#.GetChannels()", cdecl.}

proc getPosition*(player: WavPlayer4K): uint32 {.
  importcpp: "#.GetPosition()", cdecl.}
  ## Get the current playhead position in samples from the start of the file.

proc getPosition*(player: WavPlayer8K): uint32 {.
  importcpp: "#.GetPosition()", cdecl.}

proc getPosition*(player: WavPlayer16K): uint32 {.
  importcpp: "#.GetPosition()", cdecl.}

proc getNormalizedPosition*(player: WavPlayer4K): cfloat {.
  importcpp: "#.GetNormalizedPosition()", cdecl.}
  ## Get the playhead position as a 0.0-1.0 value within the file.
  ## 
  ## Returns:
  ## - 0.0 = beginning of file
  ## - 1.0 = end of file
  ## - 0.5 = halfway through

proc getNormalizedPosition*(player: WavPlayer8K): cfloat {.
  importcpp: "#.GetNormalizedPosition()", cdecl.}

proc getNormalizedPosition*(player: WavPlayer16K): cfloat {.
  importcpp: "#.GetNormalizedPosition()", cdecl.}

proc getLooping*(player: WavPlayer4K): bool {.
  importcpp: "#.GetLooping()", cdecl.}
  ## Check if looping is enabled.

proc getLooping*(player: WavPlayer8K): bool {.
  importcpp: "#.GetLooping()", cdecl.}

proc getLooping*(player: WavPlayer16K): bool {.
  importcpp: "#.GetLooping()", cdecl.}

proc getPlaying*(player: WavPlayer4K): bool {.
  importcpp: "#.GetPlaying()", cdecl.}
  ## Check if playback is currently active.

proc getPlaying*(player: WavPlayer8K): bool {.
  importcpp: "#.GetPlaying()", cdecl.}

proc getPlaying*(player: WavPlayer16K): bool {.
  importcpp: "#.GetPlaying()", cdecl.}

# ============================================================================
# Helper Functions
# ============================================================================

proc durationSeconds*(player: WavPlayer4K): float {.inline.} =
  ## Get the total duration of the file in seconds.
  ## 
  ## Returns: Duration in seconds as a float
  ## 
  ## Note: Uses the Daisy audio system's default sample rate of 48kHz.
  ## WAV files are resampled to this rate during playback.
  let samples = player.getDurationInSamples()
  let sampleRate = 48000.0  # Daisy audio system runs at 48kHz by default
  result = float(samples) / sampleRate

proc durationSeconds*(player: WavPlayer8K): float {.inline.} =
  ## Get the total duration of the file in seconds.
  ## 
  ## Returns: Duration in seconds as a float
  ## 
  ## Note: Uses the Daisy audio system's default sample rate of 48kHz.
  ## WAV files are resampled to this rate during playback.
  let samples = player.getDurationInSamples()
  let sampleRate = 48000.0  # Daisy audio system runs at 48kHz by default
  result = float(samples) / sampleRate

proc durationSeconds*(player: WavPlayer16K): float {.inline.} =
  ## Get the total duration of the file in seconds.
  ## 
  ## Returns: Duration in seconds as a float
  ## 
  ## Note: Uses the Daisy audio system's default sample rate of 48kHz.
  ## WAV files are resampled to this rate during playback.
  let samples = player.getDurationInSamples()
  let sampleRate = 48000.0  # Daisy audio system runs at 48kHz by default
  result = float(samples) / sampleRate

proc isEof*(player: WavPlayer4K): bool {.inline.} =
  ## Check if playback has reached the end of file.
  ## Only returns true when not looping and playback stopped at end.
  result = not player.getPlaying() and player.getPosition() >= player.getDurationInSamples()

proc isEof*(player: WavPlayer8K): bool {.inline.} =
  result = not player.getPlaying() and player.getPosition() >= player.getDurationInSamples()

proc isEof*(player: WavPlayer16K): bool {.inline.} =
  result = not player.getPlaying() and player.getPosition() >= player.getDurationInSamples()
