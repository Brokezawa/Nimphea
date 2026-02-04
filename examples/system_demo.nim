## System Demo - Hardware Info, Timing, and Performance
## ====================================================
##
## Comprehensive demonstration of system-level features:
## - Clock frequencies and timing
## - Memory region detection
## - Bootloader version
## - USB logging
## - Unique device ID
## - CPU load monitoring
## - Performance profiling
##
## Hardware Requirements:
## - Any Daisy board (tested on Daisy Seed)
## - USB connection for serial output
##
## Demo Modes (select by uncommenting one):
## - MODE_SYSINFO: System clocks, memory regions, bootloader info
## - MODE_CPULOAD: Real-time CPU load monitoring during audio
## - MODE_PROFILING: Performance measurement and logging
##
## LED Indicators:
## - Heartbeat blink shows system is running
## - Fast blink during CPU load monitoring

import ../src/nimphea
import ../src/sys/system
import ../src/hid/logger

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_SYSINFO = true
const MODE_CPULOAD = false
const MODE_PROFILING = false

var daisy: DaisySeed

# ============================================================================
# DEMO 1: SYSTEM INFORMATION
# ============================================================================
## Demonstrates:
## - Clock frequency readout (SYSCLK, AHB, APB1/2)
## - Memory region detection (where is code running from)
## - Bootloader version check
## - Delay functions (ms, us, ticks)

when MODE_SYSINFO:
  proc printClockInfo() =
    UsbLogger.printLine("Clock Frequencies:")
    UsbLogger.printLine("-----------------")
    
    let sysclk = getSysClkFreq()
    let hclk = getHClkFreq()
    let pclk1 = getPClk1Freq()
    let pclk2 = getPClk2Freq()
    let tickFreq = getTickFreq()
    
    UsbLogger.print("System Clock: ")
    UsbLogger.print(cstring($sysclk))
    UsbLogger.printLine(" Hz")
    
    UsbLogger.print("AHB Clock:    ")
    UsbLogger.print(cstring($hclk))
    UsbLogger.printLine(" Hz")
    
    UsbLogger.print("APB1 Clock:   ")
    UsbLogger.print(cstring($pclk1))
    UsbLogger.printLine(" Hz")
    
    UsbLogger.print("APB2 Clock:   ")
    UsbLogger.print(cstring($pclk2))
    UsbLogger.printLine(" Hz")
    
    UsbLogger.print("SysTick Freq: ")
    UsbLogger.print(cstring($tickFreq))
    UsbLogger.printLine(" Hz")
    UsbLogger.printLine("")
  
  proc printMemoryRegion() =
    UsbLogger.printLine("Program Location:")
    UsbLogger.printLine("-----------------")
    
    let region = getProgramMemoryRegion()
    case region
    of INTERNAL_FLASH:
      UsbLogger.printLine("Running from: INTERNAL_FLASH (128KB)")
    of QSPI:
      UsbLogger.printLine("Running from: QSPI Flash (8MB)")
    of ITCMRAM:
      UsbLogger.printLine("Running from: ITCM RAM (64KB)")
    of DTCMRAM:
      UsbLogger.printLine("Running from: DTCM RAM (128KB)")
    of SRAM_D1:
      UsbLogger.printLine("Running from: SRAM D1 (512KB)")
    of SRAM_D2:
      UsbLogger.printLine("Running from: SRAM D2 (288KB)")
    of SRAM_D3:
      UsbLogger.printLine("Running from: SRAM D3 (64KB)")
    of SDRAM:
      UsbLogger.printLine("Running from: External SDRAM")
    else:
      UsbLogger.printLine("Running from: UNKNOWN")
    UsbLogger.printLine("")
  
  proc printBootloaderInfo() =
    UsbLogger.printLine("Bootloader:")
    UsbLogger.printLine("-----------")
    
    let bootVer = getBootloaderVersion()
    case bootVer
    of NONE:
      UsbLogger.printLine("Daisy Bootloader: NOT INSTALLED")
      UsbLogger.printLine("(Use STM32 DFU mode only)")
    of LT_v6_0:
      UsbLogger.printLine("Daisy Bootloader: < v6.0 (legacy)")
    of v6_0:
      UsbLogger.printLine("Daisy Bootloader: v6.0")
    of v6_1:
      UsbLogger.printLine("Daisy Bootloader: v6.1+")
    else:
      UsbLogger.printLine("Daisy Bootloader: UNKNOWN")
    UsbLogger.printLine("")
  
  proc testDelays() =
    UsbLogger.printLine("Delay Tests:")
    UsbLogger.printLine("-----------")
    
    # Millisecond delay
    UsbLogger.printLine("Testing 500ms delay...")
    let startMs = getNow()
    delay(500)
    let elapsedMs = getNow() - startMs
    UsbLogger.print("Actual: ")
    UsbLogger.print(cstring($elapsedMs))
    UsbLogger.printLine(" ms")
    
    # Microsecond delay
    UsbLogger.printLine("Testing 1000us delay...")
    let startUs = getUs()
    delayUs(1000)
    let elapsedUs = getUs() - startUs
    UsbLogger.print("Actual: ")
    UsbLogger.print(cstring($elapsedUs))
    UsbLogger.printLine(" us")
    
    # Tick delay
    UsbLogger.printLine("Testing 10000 tick delay...")
    let startTicks = getTick()
    delayTicks(10000)
    let elapsedTicks = getTick() - startTicks
    UsbLogger.print("Actual: ")
    UsbLogger.print(cstring($elapsedTicks))
    UsbLogger.printLine(" ticks")
    UsbLogger.printLine("")
  
  proc runSysInfoDemo() =
    daisy = initDaisy()
    UsbLogger.startLog(false)
    delay(500)
    
    UsbLogger.printLine("================================")
    UsbLogger.printLine("  Daisy System Information")
    UsbLogger.printLine("================================")
    UsbLogger.printLine("")
    
    printClockInfo()
    printMemoryRegion()
    printBootloaderInfo()
    testDelays()
    
    UsbLogger.printLine("LED blinking at 1 Hz...")
    UsbLogger.printLine("Heartbeat every 10 seconds")
    UsbLogger.printLine("")
    
    var ledState = false
    var lastBlink = getNow()
    var blinkCount: uint32 = 0
    
    while true:
      let now = getNow()
      if now - lastBlink >= 500:
        ledState = not ledState
        daisy.setLed(ledState)
        lastBlink = now
        blinkCount += 1
        
        if blinkCount mod 20 == 0:
          UsbLogger.print("Heartbeat: uptime = ")
          UsbLogger.print(cstring($(now div 1000)))
          UsbLogger.printLine(" seconds")
      
      delay(10)

# ============================================================================
# DEMO 2: CPU LOAD MONITORING
# ============================================================================
## Demonstrates:
## - Real-time CPU load measurement during audio processing
## - Unique device ID readout
## - Performance optimization tips
## - Workload scaling tests

when MODE_CPULOAD:
  import ../src/nimphea_uniqueid
  import ../src/nimphea_cpuload
  
  var
    cpuMeter: CpuLoadMeter
    sampleRate: float32 = 48000.0
    blockSize: int = 48
    processingLoad: float32 = 0.5
  
  proc simulateProcessing(load: float32) =
    if load <= 0.0: return
    let iterations = int(load * 1000.0)
    var dummy: float32 = 0.0
    for i in 0 ..< iterations:
      dummy += float32(i) * 0.001
      dummy = dummy * 0.99
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    cpuMeter.onBlockStart()
    simulateProcessing(processingLoad)
    for i in 0 ..< size:
      output[0][i] = input[0][i]
      output[1][i] = input[1][i]
    cpuMeter.onBlockEnd()
  
  proc printDeviceInfo() =
    UsbLogger.printLine("Device Information:")
    UsbLogger.printLine("-------------------")
    
    let uid = getUniqueIdString()
    UsbLogger.print("Device ID: ")
    UsbLogger.printLine(cstring(uid))
    UsbLogger.printLine("")
  
  proc printAudioConfig() =
    UsbLogger.printLine("Audio Configuration:")
    UsbLogger.printLine("--------------------")
    
    UsbLogger.print("Sample Rate: ")
    UsbLogger.print(cstring($int(sampleRate)))
    UsbLogger.printLine(" Hz")
    
    UsbLogger.print("Block Size: ")
    UsbLogger.print(cstring($blockSize))
    UsbLogger.printLine(" samples")
    
    let blockTimeUs = int((float32(blockSize) / sampleRate) * 1000000.0)
    UsbLogger.print("Block Time: ")
    UsbLogger.print(cstring($blockTimeUs))
    UsbLogger.printLine(" us")
    UsbLogger.printLine("")
  
  proc printPerformanceTips() =
    UsbLogger.printLine("Performance Tips:")
    UsbLogger.printLine("-----------------")
    UsbLogger.printLine("  0-50%   : Plenty of headroom")
    UsbLogger.printLine("  50-70%  : Moderate usage")
    UsbLogger.printLine("  70-90%  : High - optimize if possible")
    UsbLogger.printLine("  90-100% : Critical - risk of dropouts")
    UsbLogger.printLine("")
  
  proc monitorCpuLoad(durationSec: int) =
    UsbLogger.printLine("CPU Load Monitoring:")
    UsbLogger.printLine("--------------------")
    UsbLogger.print("Simulated workload: ")
    UsbLogger.print(cstring($int(processingLoad * 100.0)))
    UsbLogger.printLine("%")
    UsbLogger.printLine("")
    
    for i in 1..durationSec:
      delay(1000)
      
      let avgLoad = int(cpuMeter.getAvgCpuLoad() * 100.0)
      let maxLoad = int(cpuMeter.getMaxCpuLoad() * 100.0)
      
      UsbLogger.print("[")
      UsbLogger.print(cstring($i))
      UsbLogger.print("s] Avg: ")
      UsbLogger.print(cstring($avgLoad))
      UsbLogger.print("%, Max: ")
      UsbLogger.print(cstring($maxLoad))
      UsbLogger.printLine("%")
      
      if i mod 2 == 0:
        daisy.setLed(true)
      else:
        daisy.setLed(false)
  
  proc runCpuLoadDemo() =
    daisy = initDaisy()
    daisy.setBlockSize(blockSize)
    sampleRate = daisy.sampleRate()
    
    UsbLogger.startLog(false)
    delay(500)
    
    UsbLogger.printLine("================================")
    UsbLogger.printLine("  CPU Load Monitoring Demo")
    UsbLogger.printLine("================================")
    UsbLogger.printLine("")
    
    printDeviceInfo()
    printAudioConfig()
    printPerformanceTips()
    
    cpuMeter.init(sampleRate, blockSize, smoothingFilterCutoffHz = 1.0)
    daisy.startAudio(audioCallback)
    
    # Test at different load levels
    let testLoads = [0.3'f32, 0.5'f32, 0.7'f32]
    for load in testLoads:
      processingLoad = load
      cpuMeter.reset()
      
      UsbLogger.print("Testing ")
      UsbLogger.print(cstring($int(load * 100.0)))
      UsbLogger.printLine("% workload...")
      
      monitorCpuLoad(3)
      UsbLogger.printLine("")
    
    # Continuous monitoring
    processingLoad = 0.5
    cpuMeter.reset()
    UsbLogger.printLine("Continuous monitoring at 50%...")
    
    while true:
      delay(5000)
      let avgLoad = int(cpuMeter.getAvgCpuLoad() * 100.0)
      UsbLogger.print("CPU: ")
      UsbLogger.print(cstring($avgLoad))
      UsbLogger.printLine("%")

# ============================================================================
# DEMO 3: PERFORMANCE PROFILING
# ============================================================================
## Demonstrates:
## - Microsecond-precision timing
## - Operation profiling
## - Structured logging patterns

when MODE_PROFILING:
  proc measureTime(name: cstring, operation: proc()) =
    let startTime = getUs()
    operation()
    let elapsed = getUs() - startTime
    
    UsbLogger.print("  ")
    UsbLogger.print(name)
    UsbLogger.print(": ")
    UsbLogger.print(cstring($elapsed))
    UsbLogger.printLine(" us")
  
  proc runProfilingDemo() =
    daisy = initDaisy()
    UsbLogger.startLog(false)
    delay(100)
    
    UsbLogger.printLine("================================")
    UsbLogger.printLine("  Performance Profiling Demo")
    UsbLogger.printLine("================================")
    UsbLogger.printLine("")
    
    # System info
    UsbLogger.printLine("System Clocks:")
    UsbLogger.print("  CPU: ")
    UsbLogger.print(cstring($getSysClkFreq()))
    UsbLogger.printLine(" Hz")
    UsbLogger.print("  AHB: ")
    UsbLogger.print(cstring($getHClkFreq()))
    UsbLogger.printLine(" Hz")
    UsbLogger.printLine("")
    
    UsbLogger.printLine("Starting profiling loop...")
    UsbLogger.printLine("Stats every 5 seconds")
    UsbLogger.printLine("")
    
    var ledState = false
    var lastBlink = getNow()
    var lastStats = getNow()
    var loopCount: uint32 = 0
    
    while true:
      let now = getNow()
      
      # LED blink
      if now - lastBlink >= 500:
        ledState = not ledState
        daisy.setLed(ledState)
        lastBlink = now
      
      # Stats printout
      if now - lastStats >= 5000:
        UsbLogger.printLine("--- Profile ---")
        UsbLogger.print("Uptime: ")
        UsbLogger.print(cstring($(now div 1000)))
        UsbLogger.printLine(" s")
        UsbLogger.print("Loops: ")
        UsbLogger.print(cstring($loopCount))
        UsbLogger.printLine("")
        
        UsbLogger.printLine("Timings:")
        measureTime("LED toggle"):
          daisy.setLed(ledState)
        measureTime("delay(1)"):
          delay(1)
        measureTime("getNow()"):
          discard getNow()
        
        UsbLogger.printLine("")
        lastStats = now
      
      loopCount += 1
      delay(10)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_SYSINFO:
    runSysInfoDemo()
  elif MODE_CPULOAD:
    runCpuLoadDemo()
  elif MODE_PROFILING:
    runProfilingDemo()
  else:
    daisy = initDaisy()
    while true:
      daisy.setLed(true)
      delay(100)
      daisy.setLed(false)
      delay(100)

when isMainModule:
  main()
