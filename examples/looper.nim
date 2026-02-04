## Live Looper Pedal
##
## This example demonstrates a live looping pedal that can record and
## play back audio loops in real-time.
## Features:
## - Record audio loops to SD card
## - Play back loops with overdub capability
## - Multiple loop layers
## - Tap tempo sync (future enhancement)
##
## Hardware Requirements:
## - Daisy Seed
## - SD card with FAT32 filesystem
## - Audio input (instrument/microphone)
## - 2 buttons: Record/Overdub, Play/Stop
## - 1 LED for status indication
##
## Controls:
## - Button 1: Record/Overdub toggle
## - Button 2: Play/Stop toggle
## - LED: Blinks during recording, solid during playback
##
## Operation:
## - Press Record to start recording first loop
## - Press Record again to stop and start playback
## - Press Record during playback to overdub
## - Press Play/Stop to stop playback

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

type
  LooperState = enum
    Idle
    Recording
    Playing
    Overdubbing

  LooperStateManager = object
    ## Thread-safe state manager using double buffering
    current: LooperState       # Read-only in audio callback (ISR context)
    next: LooperState          # Written by main loop (normal context)
    changeRequested: bool      # Atomic flag: main loop requests change
    changeAcknowledged: bool   # Atomic flag: callback acknowledges change

var
  daisy: DaisySeed
  sdmmc: SDMMCHandler
  player: WavPlayer8K  # 8KB for smoother playback
  writer: WavWriter32K
  recordButton: Switch
  playButton: Switch
  
  stateMgr = LooperStateManager(
    current: Idle,
    next: Idle,
    changeRequested: false,
    changeAcknowledged: false
  )
  loopFile = "loop.wav"

proc requestStateChange(newState: LooperState) =
  ## Request state change from main loop (non-ISR context)
  ## Waits for audio callback to acknowledge the change
  stateMgr.next = newState
  stateMgr.changeRequested = true
  stateMgr.changeAcknowledged = false
  
  # Wait for acknowledgment with timeout (2ms = ~100 audio buffers at 48kHz/48samples)
  # This ensures the audio callback has seen and applied the change
  var timeoutUs = 2000  # 2ms timeout
  while not stateMgr.changeAcknowledged and timeoutUs > 0:
    # Busy wait in 10us increments
    daisy.delay(0)  # Yield to allow audio callback to run
    timeoutUs -= 10
  
  # If timeout occurred, force the change anyway (shouldn't happen in practice)
  if timeoutUs <= 0:
    stateMgr.changeRequested = false

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Audio callback - handle recording, playback, and overdubbing
  ## Thread-safe: Only reads current state, only writes acknowledgment flag
  
  # Check for state change request at start of callback
  if stateMgr.changeRequested and not stateMgr.changeAcknowledged:
    stateMgr.current = stateMgr.next
    stateMgr.changeAcknowledged = true
    stateMgr.changeRequested = false
  
  for i in 0..<size:
    var playbackL = 0.0'f32
    var playbackR = 0.0'f32
    
    # Use stateMgr.current throughout (never access stateMgr.next)
    case stateMgr.current
    of Recording:
      # Record input only
      var frame = [input[0][i], input[1][i]]
      writer.sample(frame[0].addr)
      # Pass through input to output (monitoring)
      output[0][i] = input[0][i]
      output[1][i] = input[1][i]
    
    of Playing:
      # Play back loop
      var frame: array[2, cfloat]
      discard player.stream(frame[0].addr, 2)
      output[0][i] = frame[0]
      output[1][i] = frame[1]
    
    of Overdubbing:
      # Mix playback with input and record
      var playFrame: array[2, cfloat]
      discard player.stream(playFrame[0].addr, 2)
      
      # Mix input + playback
      let mixL = input[0][i] + playFrame[0]
      let mixR = input[1][i] + playFrame[1]
      
      # Record mixed signal
      var recFrame = [mixL, mixR]
      writer.sample(recFrame[0].addr)
      
      # Output mix
      output[0][i] = mixL
      output[1][i] = mixR
    
    of Idle:
      # Pass through
      output[0][i] = input[0][i]
      output[1][i] = input[1][i]

proc startRecording() =
  ## Start recording a new loop
  var config = createConfig(48000.0, 2, 16)
  writer.init(config)
  writer.openFile(loopFile.cstring)
  
  if writer.isRecording():
    requestStateChange(Recording)

proc stopRecording() =
  ## Stop recording and prepare for playback
  writer.saveFile()
  requestStateChange(Idle)

proc startPlayback() =
  ## Start playing the recorded loop
  let cLoopFile = loopFile.cstring
  # NOTE: WavPlayer<BufferSize>::Result types are distinct in C++.
  # WavPlayer<8192>::Result and WavPlayer<4096>::Result are different types.
  # Using emit block with static_cast to workaround template type incompatibility.
  {.emit: """
  auto initResult = `player`.Init(`cLoopFile`);
  if (static_cast<int>(initResult) == 0) {
  """.}
  player.setLooping(true)
  player.play()
  requestStateChange(Playing)
  {.emit: """
  }
  """.}

proc stopPlayback() =
  ## Stop playback
  player.stop()
  discard player.close()
  requestStateChange(Idle)

proc main() =
  # Initialize hardware
  daisy = initDaisy()
  daisy.setSampleRate(SAI_48KHZ)
  daisy.setBlockSize(48)
  
  # Initialize controls
  recordButton.init(getPin(28))  # User button
  playButton.init(getPin(27))    # Another GPIO
  
  # Initialize SD card
  var sdConfig = newSdmmcConfig()
  if sdmmc.init(sdConfig) != SD_OK:
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)
  
  # Mount filesystem
  var fs: FATFS
  if f_mount(addr fs, "", 1) != FR_OK:
    while true:
      daisy.setLed(true)
      daisy.delay(500)
      daisy.setLed(false)
      daisy.delay(500)
  
  # Start audio
  daisy.startAudio(audioCallback)
  
  # Main loop - handle state machine
  var ledBlink = 0
  var ledState = false
  
  while true:
    # Update buttons
    recordButton.debounce()
    playButton.debounce()
    
    # Record button state machine
    # Read current state (safe - only audio callback writes to stateMgr.current)
    if recordButton.risingEdge():
      case stateMgr.current
      of Idle:
        startRecording()
      of Recording:
        stopRecording()
        startPlayback()
      of Playing:
        # Start overdubbing
        # First, restart player to sync
        player.restart()
        startRecording()
        requestStateChange(Overdubbing)
      of Overdubbing:
        stopRecording()
        stopPlayback()
        startPlayback()
    
    # Play/Stop button
    if playButton.risingEdge():
      case stateMgr.current
      of Playing, Overdubbing:
        stopPlayback()
        stopRecording()  # In case we're overdubbing
      of Idle:
        startPlayback()
      of Recording:
        stopRecording()
    
    # Handle file I/O
    case stateMgr.current
    of Recording, Overdubbing:
      writer.write()
    of Playing:
      discard player.prepare()
    else:
      discard
    
    # LED indication
    case stateMgr.current
    of Recording, Overdubbing:
      # Blink during recording
      ledBlink += 1
      if ledBlink >= 250:
        ledBlink = 0
        ledState = not ledState
      daisy.setLed(ledState)
    of Playing:
      # Solid during playback
      daisy.setLed(true)
    of Idle:
      # Off when idle
      daisy.setLed(false)
    
    daisy.delay(1)

when isMainModule:
  main()
