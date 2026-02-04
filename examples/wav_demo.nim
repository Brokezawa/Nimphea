## WAV File Demo - Playback and Recording
## ========================================
##
## Comprehensive demonstration of WAV file handling with SD card storage.
## Combines playback and recording functionality in a single example.
##
## Hardware Requirements:
## - Daisy Seed (or compatible board)
## - SD card with FAT32 filesystem
## - For playback: WAV file named "sample.wav" on SD card (16-bit PCM)
## - For recording: Audio input source (line in, microphone, etc.)
##
## Demo Modes (select by uncommenting one):
## - MODE_PLAYBACK: Play WAV file from SD card with loop/speed control
## - MODE_RECORDER: Record audio input to WAV file on SD card
## - MODE_LOOPER: Record then play back (simple looper)
##
## Controls:
## - User button: Stop/start (mode dependent)
## - LED: Status indication (blinking=active, solid=idle/error)

{.define: useWavPlayer.}
{.define: useWavWriter.}
{.define: useSDMMC.}
{.define: useSwitch.}

import ../src/nimphea
import ../src/per/sdmmc as sdmmc_module
import ../src/nimphea_wavplayer
import ../src/nimphea_wavwriter
import ../src/hid/switch
useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_PLAYBACK = true
const MODE_RECORDER = false
const MODE_LOOPER = false

# ============================================================================
# COMMON VARIABLES
# ============================================================================
var
  daisy: DaisySeed
  sdmmc: SDMMCHandler
  userButton: Switch
  fs: FATFS

# ============================================================================
# DEMO 1: WAV FILE PLAYBACK
# ============================================================================
## Demonstrates:
## - Loading WAV files from SD card
## - Streaming audio playback
## - Looping and playback speed control
## - Buffer management (prepare() calls)

when MODE_PLAYBACK:
  var
    player: WavPlayer4K  # 4KB workspace buffer
    isPlaying = false
  
  proc audioCallbackPlayback(input, output: AudioBuffer, size: int) {.cdecl.} =
    ## Stream samples from WAV file to audio output
    for i in 0..<size:
      var samples: array[2, cfloat]
      
      if isPlaying:
        discard player.stream(samples[0].addr, 2)
      else:
        samples[0] = 0.0
        samples[1] = 0.0
      
      output[0][i] = samples[0]
      output[1][i] = samples[1]
  
  proc runPlaybackDemo() =
    ## WAV playback demo main function
    
    # Initialize WAV player with file
    let result = player.init("sample.wav")
    if result != WavPlayerResult.Ok:
      # File not found or format error - solid LED
      daisy.setLed(true)
      while true:
        daisy.delay(1000)
    
    # Configure playback
    player.setLooping(true)           # Loop continuously
    player.setPlaybackSpeedRatio(1.0) # Normal speed (try 0.5, 2.0, etc.)
    player.play()
    isPlaying = true
    
    # Start audio
    daisy.startAudio(audioCallbackPlayback)
    
    # Main loop
    var ledState = false
    var counter = 0
    
    while true:
      # CRITICAL: Refill buffer regularly to prevent dropouts
      discard player.prepare()
      
      # Check button for pause/resume
      userButton.debounce()
      if userButton.risingEdge():
        isPlaying = not isPlaying
        player.setPlaying(isPlaying)
      
      # Blink LED while playing
      if isPlaying:
        counter += 1
        if counter >= 500:
          counter = 0
          ledState = not ledState
          daisy.setLed(ledState)
      else:
        daisy.setLed(false)
      
      daisy.delay(1)

# ============================================================================
# DEMO 2: WAV FILE RECORDER
# ============================================================================
## Demonstrates:
## - Recording audio to SD card
## - WAV file creation with proper headers
## - Buffer writing (write() calls)
## - File finalization

when MODE_RECORDER:
  var
    writer: WavWriter32K  # 32KB transfer buffer
    recording = false
  
  proc audioCallbackRecorder(input, output: AudioBuffer, size: int) {.cdecl.} =
    ## Record audio input to buffer and pass through to output
    for i in 0..<size:
      # Record stereo samples
      if recording:
        var frame = [input[0][i], input[1][i]]
        writer.sample(frame[0].addr)
      
      # Pass through to output (monitoring)
      output[0][i] = input[0][i]
      output[1][i] = input[1][i]
  
  proc runRecorderDemo() =
    ## WAV recorder demo main function
    
    # Configure WAV format
    var config = createConfig(
      samplerate = 48000.0,
      channels = 2,
      bitspersample = 16
    )
    writer.init(config)
    
    # Open file for recording
    writer.openFile("recording.wav")
    
    if not writer.isRecording():
      # Failed to open file - solid LED
      daisy.setLed(true)
      while true:
        daisy.delay(1000)
    
    recording = true
    daisy.setLed(true)  # LED on = recording
    
    # Start audio
    daisy.startAudio(audioCallbackRecorder)
    
    # Main loop - write to SD and check for stop
    while recording:
      # CRITICAL: Write buffered audio to SD card regularly
      writer.write()
      
      # Check button to stop recording
      userButton.debounce()
      if userButton.risingEdge():
        recording = false
        daisy.setLed(false)
        
        # Finalize WAV file (writes header with correct size)
        writer.saveFile()
        
        # Blink to indicate save complete
        for i in 0..5:
          daisy.setLed(true)
          daisy.delay(100)
          daisy.setLed(false)
          daisy.delay(100)
      
      daisy.delay(1)
    
    # Recording stopped - idle
    while true:
      daisy.delay(1000)

# ============================================================================
# DEMO 3: SIMPLE LOOPER
# ============================================================================
## Demonstrates:
## - Recording then immediate playback
## - Switching between record and play modes
## - Combined writer/player usage

when MODE_LOOPER:
  var
    player: WavPlayer4K
    writer: WavWriter32K
    state: int = 0  # 0=waiting, 1=recording, 2=playing
  
  proc audioCallbackLooper(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      case state:
      of 1:  # Recording
        var frame = [input[0][i], input[1][i]]
        writer.sample(frame[0].addr)
        # Monitor input while recording
        output[0][i] = input[0][i] * 0.5
        output[1][i] = input[1][i] * 0.5
      
      of 2:  # Playing
        var samples: array[2, cfloat]
        discard player.stream(samples[0].addr, 2)
        output[0][i] = samples[0]
        output[1][i] = samples[1]
      
      else:  # Waiting - silence
        output[0][i] = 0.0
        output[1][i] = 0.0
  
  proc runLooperDemo() =
    ## Simple looper demo main function
    const loopFile = "loop.wav"
    
    # Configure WAV format
    var config = createConfig(
      samplerate = 48000.0,
      channels = 2,
      bitspersample = 16
    )
    writer.init(config)
    
    # Start audio
    daisy.startAudio(audioCallbackLooper)
    
    # Blink LED to indicate ready
    for i in 0..2:
      daisy.setLed(true)
      daisy.delay(200)
      daisy.setLed(false)
      daisy.delay(200)
    
    # Main loop - state machine controlled by button
    while true:
      userButton.debounce()
      
      case state:
      of 0:  # Waiting for record
        if userButton.risingEdge():
          writer.openFile(loopFile)
          if writer.isRecording():
            state = 1
            daisy.setLed(true)  # Solid = recording
      
      of 1:  # Recording
        writer.write()
        if userButton.risingEdge():
          # Stop recording, start playback
          writer.saveFile()
          daisy.setLed(false)
          
          # Initialize player with recorded file
          if player.init(loopFile) == WavPlayerResult.Ok:
            player.setLooping(true)
            player.play()
            state = 2
          else:
            state = 0  # Error, go back to waiting
      
      of 2:  # Playing
        discard player.prepare()
        
        # Blink LED while playing
        if (daisy.system.getTickCount() div 500) mod 2 == 0:
          daisy.setLed(true)
        else:
          daisy.setLed(false)
        
        if userButton.risingEdge():
          # Stop playback, go back to waiting
          player.stop()
          daisy.setLed(false)
          state = 0
      
      else:
        state = 0
      
      daisy.delay(1)

# ============================================================================
# COMMON INITIALIZATION
# ============================================================================

proc initSDCard(): bool =
  ## Initialize SD card and mount filesystem
  ## Returns true on success, false on failure
  
  # Initialize SD card hardware
  var sdConfig: SdmmcConfig
  sdConfig.speed = SD_STANDARD
  sdConfig.width = SD_BITS_4
  sdConfig.clock_powersave = false
  
  if sdmmc.init(sdConfig) != SD_OK:
    # SD card init failed - blink rapidly
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)
    return false
  
  # Mount filesystem
  if f_mount(addr fs, "", 1) != FR_OK:
    # Mount failed - blink slowly
    while true:
      daisy.setLed(true)
      daisy.delay(500)
      daisy.setLed(false)
      daisy.delay(500)
    return false
  
  return true

proc main() =
  # Initialize Daisy hardware
  daisy = initDaisy()
  daisy.setSampleRate(SAI_48KHZ)
  daisy.setBlockSize(48)
  
  # Initialize user button
  userButton.init(getPin(28))  # Pin 28 = user button on Seed
  
  # Initialize SD card (required for all modes)
  discard initSDCard()
  
  # Run selected demo
  when MODE_PLAYBACK:
    runPlaybackDemo()
  elif MODE_RECORDER:
    runRecorderDemo()
  elif MODE_LOOPER:
    runLooperDemo()
  else:
    # No mode selected - blink error pattern
    while true:
      daisy.setLed(true)
      daisy.delay(50)
      daisy.setLed(false)
      daisy.delay(50)
      daisy.setLed(true)
      daisy.delay(50)
      daisy.setLed(false)
      daisy.delay(850)

when isMainModule:
  main()
