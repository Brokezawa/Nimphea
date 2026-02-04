## Wavetable Synthesizer
##
## This example demonstrates wavetable synthesis by loading a bank of
## wavetables from a WAV file and scanning through them.
## Features:
## - Load wavetable bank from SD card
## - Morphing between wavetables
## - CV/knob control of wavetable position
## - Multiple oscillator voices
##
## Hardware Requirements:
## - Daisy Seed
## - SD card with wavetable file "tables.wav"
## - CV input or potentiometer for wavetable position
## - Optional: CV input for pitch
##
## Wavetable File Format:
## - 64 wavetables of 256 samples each (total: 16,384 samples)
## - 16-bit PCM, 48kHz
## - Mono file containing concatenated wavetables
##
## Controls:
## - ADC 0: Wavetable position (morphing)
## - ADC 1: Pitch/frequency control

{.define: useWaveTableLoader.}
{.define: useSDMMC.}
{.define: useADC.}

import ../src/nimphea
import ../src/per/sdmmc as sdmmc_module
import ../src/nimphea_wavetable_loader
import ../src/per/adc as adc_module  # Import as qualified module
import std/math
useNimpheaNamespace()

const
  NUM_TABLES = 64
  SAMPLES_PER_TABLE = 256
  SAMPLE_RATE = 48000.0
  BASE_FREQ = 220.0  # A3

type
  WavetableOsc = object
    phase: float32
    frequency: float32
    tablePos: float32  # 0.0 - 1.0 (morphs between tables)

var
  daisy: DaisySeed
  sdmmc: SDMMCHandler
  loader: WaveTableLoader
  
  # Wavetable storage buffer
  tableBuffer: array[NUM_TABLES * SAMPLES_PER_TABLE, cfloat]
  
  # Oscillator
  osc: WavetableOsc
  
  # ADC for controls
  adc: adc_module.AdcHandle

proc interpolateWavetable(tablePos: float32, phase: float32): float32 =
  ## Interpolate between wavetables based on position
  ## tablePos: 0.0-1.0, which wavetable to use
  ## phase: 0.0-1.0, position within wavetable
  
  # Calculate which two tables to interpolate between
  let scaledPos = tablePos * float32(NUM_TABLES - 1)
  let table1Idx = int(scaledPos)
  let table2Idx = min(table1Idx + 1, NUM_TABLES - 1)
  let tableMix = scaledPos - float32(table1Idx)
  
  # Calculate sample index within table
  let sampleIdx = phase * float32(SAMPLES_PER_TABLE)
  let idx1 = int(sampleIdx) mod SAMPLES_PER_TABLE
  let idx2 = (idx1 + 1) mod SAMPLES_PER_TABLE
  let sampleMix = sampleIdx - float32(idx1)
  
  # Get pointers to the two tables
  let t1 = loader.getTable(csize_t(table1Idx))
  let t2 = loader.getTable(csize_t(table2Idx))
  
  if t1.isNil or t2.isNil:
    return 0.0
  
  # Interpolate samples within each table
  let t1Arr = cast[ptr UncheckedArray[cfloat]](t1)
  let t2Arr = cast[ptr UncheckedArray[cfloat]](t2)
  
  let sample1 = t1Arr[idx1] + sampleMix * (t1Arr[idx2] - t1Arr[idx1])
  let sample2 = t2Arr[idx1] + sampleMix * (t2Arr[idx2] - t2Arr[idx1])
  
  # Interpolate between tables
  result = sample1 + tableMix * (sample2 - sample1)

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  ## Audio callback - generate wavetable synthesis
  
  # Read CV inputs
  let morphCV = adc_module.get(adc, 0).float / 65535.0  # 0.0-1.0
  let pitchCV = adc_module.get(adc, 1).float / 65535.0  # 0.0-1.0
  
  # Map pitch CV to frequency range (1 octave)
  osc.frequency = BASE_FREQ * pow(2.0, pitchCV)
  osc.tablePos = morphCV
  
  let phaseInc = osc.frequency / SAMPLE_RATE
  
  for i in 0..<size:
    # Generate sample using wavetable interpolation
    let sample = interpolateWavetable(osc.tablePos, osc.phase)
    
    # Output to both channels
    output[0][i] = sample * 0.5  # 50% volume
    output[1][i] = sample * 0.5
    
    # Advance phase
    osc.phase += phaseInc
    if osc.phase >= 1.0:
      osc.phase -= 1.0

proc main() =
  # Initialize hardware
  daisy = initDaisy()
  daisy.setSampleRate(SAI_48KHZ)
  daisy.setBlockSize(48)
  
  # Initialize ADC for CV inputs
  var adcChannels: array[2, adc_module.AdcChannelConfig]
  adc_module.initSingle(adcChannels[0], A0())  # Morph CV
  adc_module.initSingle(adcChannels[1], A1())  # Pitch CV
  adc = adc_module.initAdcHandle(adcChannels, adc_module.OVS_32)
  adc_module.start(adc)
  
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
  
  # Initialize wavetable loader
  loader.init(
    tableBuffer[0].addr,
    csize_t(tableBuffer.len * sizeof(cfloat))
  )
  
  # Set wavetable layout
  if loader.setWaveTableInfo(
    csize_t(SAMPLES_PER_TABLE),
    csize_t(NUM_TABLES)
  ) != WaveTableResult.OK:
    # Buffer size error
    daisy.setLed(true)
    while true:
      daisy.delay(1000)
  
  # Load wavetables from file
  if loader.import("tables.wav") != WaveTableResult.OK:
    # File load error - blink pattern
    while true:
      for i in 0..2:
        daisy.setLed(true)
        daisy.delay(200)
        daisy.setLed(false)
        daisy.delay(200)
      daisy.delay(1000)
  
  # Initialize oscillator
  osc.phase = 0.0
  osc.frequency = BASE_FREQ
  osc.tablePos = 0.0
  
  # Start audio
  daisy.startAudio(audioCallback)
  
  # Main loop - blink LED
  var ledState = false
  while true:
    ledState = not ledState
    daisy.setLed(ledState)
    daisy.delay(500)

when isMainModule:
  main()
