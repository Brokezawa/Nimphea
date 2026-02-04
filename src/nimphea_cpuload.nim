## CPU Load Meter Module
## 
## This module provides real-time CPU load measurement for audio processing.
## Measures the percentage of available time consumed by the audio callback,
## helping identify performance bottlenecks and optimize DSP algorithms.
##
## **Key Features:**
## - Real-time CPU load monitoring (0-100%)
## - Tracks minimum, maximum, and smoothed average load
## - Configurable smoothing filter for average calculation
## - Integration with audio callback timing
## - Zero overhead when not actively reading values
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import nimphea_cpuload
##   import nimphea_seed
##   
##   var
##     seed: Seed
##     cpuMeter: CpuLoadMeter
##   
##   proc audioCallback(input: ptr float32, output: ptr float32, size: csize_t) {.cdecl.} =
##     cpuMeter.onBlockStart()
##     
##     # Your DSP processing here
##     for i in 0 ..< size:
##       output[i] = input[i]  # Simple passthrough
##     
##     cpuMeter.onBlockEnd()
##   
##   seed.init()
##   seed.setAudioBlockSize(48)
##   cpuMeter.init(seed.audioSampleRate(), 48, smoothingCutoff = 1.0)
##   
##   seed.startAudio(audioCallback)
##   
##   # Monitor in main loop
##   while true:
##     let avgLoad = cpuMeter.getAvgCpuLoad()
##     let maxLoad = cpuMeter.getMaxCpuLoad()
##     echo "CPU: ", int(avgLoad * 100), "% (max ", int(maxLoad * 100), "%)"
##     seed.delayMs(1000)
##
## **Performance Notes:**
## - OnBlockStart/End calls are lightweight (just timestamp reads)
## - Load values range from 0.0 (idle) to 1.0 (100% utilized)
## - Values > 1.0 indicate audio dropouts/overruns
## - Smoothing filter reduces jitter in average reading
## - Reset() clears min/max/avg for new measurement period

import nimphea_macros

useNimpheaModules(cpuload)

type
  CpuLoadMeter* {.importcpp: "daisy::CpuLoadMeter", header: "util/CpuLoadMeter.h".} = object
    ## Real-time CPU load measurement for audio processing.
    ## 
    ## Tracks the fraction of available time consumed by audio callbacks.
    ## Initialize with sample rate and block size, then call OnBlockStart/OnBlockEnd
    ## at the beginning and end of each audio callback.

proc init*(this: var CpuLoadMeter, sampleRateInHz: float32, 
           blockSizeInSamples: int, smoothingFilterCutoffHz: float32 = 1.0)
  {.importcpp: "#.Init(@)", header: "util/CpuLoadMeter.h".} =
  ## Initialize the CPU load meter.
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## - sampleRateInHz: Audio sample rate in Hz (e.g., 48000.0)
  ## - blockSizeInSamples: Audio buffer size in samples (e.g., 48)
  ## - smoothingFilterCutoffHz: Cutoff frequency for average smoothing (default: 1.0 Hz)
  ## 
  ## **Note:** The smoothing filter is a 1-pole lowpass that reduces jitter in
  ## the average CPU load reading. Lower cutoff = more smoothing but slower response.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   var meter: CpuLoadMeter
  ##   meter.init(48000.0, 48)  # 48kHz, 48 samples per block
  discard

proc onBlockStart*(this: var CpuLoadMeter)
  {.importcpp: "#.OnBlockStart()", header: "util/CpuLoadMeter.h".} =
  ## Call this at the very beginning of the audio callback.
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Note:** Records the current timestamp. Must be paired with OnBlockEnd().
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   proc audioCallback(input: ptr float32, output: ptr float32, size: csize_t) {.cdecl.} =
  ##     cpuMeter.onBlockStart()
  ##     # ... DSP processing ...
  ##     cpuMeter.onBlockEnd()
  discard

proc onBlockEnd*(this: var CpuLoadMeter)
  {.importcpp: "#.OnBlockEnd()", header: "util/CpuLoadMeter.h".} =
  ## Call this at the very end of the audio callback.
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Note:** Calculates elapsed time since OnBlockStart() and updates load statistics.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   proc audioCallback(input: ptr float32, output: ptr float32, size: csize_t) {.cdecl.} =
  ##     cpuMeter.onBlockStart()
  ##     # ... DSP processing ...
  ##     cpuMeter.onBlockEnd()
  discard

proc getAvgCpuLoad*(this: CpuLoadMeter): float32
  {.importcpp: "#.GetAvgCpuLoad()", header: "util/CpuLoadMeter.h".} =
  ## Get the smoothed average CPU load.
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Returns:**
  ## Average CPU load in range 0.0 to 1.0 (multiply by 100 for percentage)
  ## Values > 1.0 indicate audio buffer underruns
  ## 
  ## **Note:** This value is smoothed by a lowpass filter configured in Init().
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let load = cpuMeter.getAvgCpuLoad()
  ##   echo "CPU Load: ", int(load * 100), "%"
  discard

proc getMinCpuLoad*(this: CpuLoadMeter): float32
  {.importcpp: "#.GetMinCpuLoad()", header: "util/CpuLoadMeter.h".} =
  ## Get the minimum CPU load observed since initialization or last Reset().
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Returns:**
  ## Minimum CPU load in range 0.0 to 1.0
  ## 
  ## **Note:** Useful for understanding best-case performance.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let minLoad = cpuMeter.getMinCpuLoad()
  ##   echo "Best case: ", int(minLoad * 100), "%"
  discard

proc getMaxCpuLoad*(this: CpuLoadMeter): float32
  {.importcpp: "#.GetMaxCpuLoad()", header: "util/CpuLoadMeter.h".} =
  ## Get the maximum CPU load observed since initialization or last Reset().
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Returns:**
  ## Maximum CPU load in range 0.0 to 1.0 (values > 1.0 indicate dropouts)
  ## 
  ## **Note:** Useful for identifying worst-case performance spikes.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let maxLoad = cpuMeter.getMaxCpuLoad()
  ##   if maxLoad > 0.95:
  ##     echo "Warning: CPU usage spike at ", int(maxLoad * 100), "%"
  discard

proc reset*(this: var CpuLoadMeter)
  {.importcpp: "#.Reset()", header: "util/CpuLoadMeter.h".} =
  ## Reset the min, max, and average load readings.
  ## 
  ## **Parameters:**
  ## - this: The CpuLoadMeter instance
  ## 
  ## **Note:** Use this to start a new measurement period. All values will be
  ## recalculated from scratch after the next OnBlockEnd() call.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   # Measure load for a specific operation
  ##   cpuMeter.reset()
  ##   # ... perform operation ...
  ##   seed.delayMs(5000)  # Measure for 5 seconds
  ##   echo "Operation CPU usage: ", int(cpuMeter.getMaxCpuLoad() * 100), "%"
  discard
