## Multi-Sample Trigger System (Sampler)
##
## This example demonstrates a simple sampler that can trigger multiple
## WAV samples from SD card using gate inputs or MIDI notes.
## Features:
## - Load 4 different WAV samples
## - Trigger samples with gate inputs or buttons
## - Multiple samples can play simultaneously
## - Adjustable playback speed per sample
##
## Hardware Requirements:
## - Daisy Seed
## - SD card with 4 WAV files: "kick.wav", "snare.wav", "hat.wav", "clap.wav"
## - 4 gate inputs or buttons (optional - can use MIDI)
##
## Controls:
## - GPIO pins trigger samples
## - LED blinks with each trigger
##
## File Organization:
## - All WAV files should be 16-bit PCM, 48kHz recommended
## - Keep samples short (< 2 seconds) for best performance

{.define: useWavPlayer.}
{.define: useSDMMC.}
{.define: useSwitch.}

import ../src/nimphea
import ../src/per/sdmmc as sdmmc_module
import ../src/nimphea_wavplayer
import ../src/hid/switch
useNimpheaNamespace()

const NUM_SAMPLES = 4

type
  SampleSlot = object
    player: WavPlayer4K
    active: bool
    volume: float32

var
  daisy: DaisySeed
  sdmmc: SDMMCHandler
  samples: array[NUM_SAMPLES, SampleSlot]
  triggers: array[NUM_SAMPLES, Switch]
  
  # Sample filenames
  sampleFiles = ["kick.wav", "snare.wav", "hat.wav", "clap.wav"]

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Audio callback - mix all active samples
  for i in 0..<size:
    var mixL = 0.0'f32
    var mixR = 0.0'f32
    
    # Mix all active samples
    for s in 0..<NUM_SAMPLES:
      if samples[s].active:
        var frame: array[2, cfloat]
        let res = samples[s].player.stream(frame[0].addr, 2)
        
        # Add to mix
        mixL += frame[0] * samples[s].volume
        mixR += frame[1] * samples[s].volume
        
        # Check if sample finished (not looping)
        if not samples[s].player.getPlaying():
          samples[s].active = false
    
    # Output mixed audio
    output[0][i] = mixL
    output[1][i] = mixR

proc triggerSample(idx: int) =
  ## Trigger a sample to play
  if idx >= 0 and idx < NUM_SAMPLES:
    samples[idx].player.restart()
    samples[idx].player.play()
    samples[idx].active = true

proc main() =
  # Initialize Daisy hardware
  daisy = initDaisy()
  daisy.setSampleRate(SAI_48KHZ)
  daisy.setBlockSize(48)
  
  # Initialize trigger buttons
  triggers[0].init(getPin(15))  # D15
  triggers[1].init(getPin(16))  # D16
  triggers[2].init(getPin(17))  # D17
  triggers[3].init(getPin(18))  # D18
  
  # Initialize SD card
  var sdConfig = newSdmmcConfig()
  if sdmmc.init(sdConfig) != SD_OK:
    # SD init failed
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)
  
  # Mount filesystem
  var fs: FATFS
  if f_mount(addr fs, "", 1) != FR_OK:
    # Mount failed
    while true:
      daisy.setLed(true)
      daisy.delay(500)
      daisy.setLed(false)
      daisy.delay(500)
  
  # Load all samples
  var loadErrors = 0
  for i in 0..<NUM_SAMPLES:
    let result = samples[i].player.init(sampleFiles[i].cstring)
    if result != WavPlayerResult.Ok:
      loadErrors += 1
    else:
      # Configure sample playback
      samples[i].player.setLooping(false)  # One-shot playback
      samples[i].player.setPlaybackSpeedRatio(1.0)
      samples[i].volume = 0.8  # 80% volume
      samples[i].active = false
  
  # Check for load errors
  if loadErrors > 0:
    # Some files failed to load - blink LED pattern
    for i in 0..<loadErrors:
      daisy.setLed(true)
      daisy.delay(200)
      daisy.setLed(false)
      daisy.delay(200)
    daisy.delay(1000)
  
  # Start audio processing
  daisy.startAudio(audioCallback)
  
  # Main loop - check triggers and prepare buffers
  var ledCounter = 0
  var ledState = false
  
  while true:
    # Check trigger inputs
    for i in 0..<NUM_SAMPLES:
      triggers[i].debounce()
      if triggers[i].risingEdge():
        triggerSample(i)
        # Flash LED on trigger
        ledState = true
        ledCounter = 100
    
    # Prepare all sample buffers
    for i in 0..<NUM_SAMPLES:
      if samples[i].active:
        discard samples[i].player.prepare()
    
    # LED management
    if ledCounter > 0:
      ledCounter -= 1
      if ledCounter == 0:
        ledState = false
    daisy.setLed(ledState)
    
    daisy.delay(1)

when isMainModule:
  main()
