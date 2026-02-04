## Timer Advanced Example
import panicoverride
import ../src/nimphea
import ../src/per/uart
import ../src/per/tim
useNimpheaNamespace()

# Global counters for callbacks
var timer2Count {.global.}: int = 0
var timer3Count {.global.}: int = 0

# Timer callback functions (called from interrupt context)
proc onTimer2Period(data: pointer) {.cdecl.} =
  ## Called every timer2 period (~1 second)
  timer2Count.inc

proc onTimer3Period(data: pointer) {.cdecl.} =
  ## Called every timer3 period (~500ms)
  timer3Count.inc

proc main() =
  var daisy = initDaisy()
  
  startLog()
  printLine("Timer Advanced Example")
  printLine("Multiple Timers + Callbacks")
  printLine()
  
  # Timer 2: Free-running counter for measurements (32-bit)
  var timer2: TimerHandle
  var config2: TimerConfig
  config2.periph = TIM_PERIPH_TIM2
  config2.dir = TIMER_DIR_UP
  config2.period = 0xffffffff'u32  # Max period (32-bit)
  config2.enable_irq = false       # No interrupts for this one
  
  let result2 = timer2.init(config2)
  if result2 != TIMER_OK:
    printLine("ERROR: Timer2 init failed!")
    return
  
  discard timer2.start()
  printLine("Timer2: Free-running counter (no callback)")
  
  # Timer 3: Periodic callback with moderate period (16-bit timer)
  # We'll use a smaller period to get faster callbacks
  var timer3: TimerHandle
  var config3: TimerConfig
  config3.periph = TIM_PERIPH_TIM3
  config3.dir = TIMER_DIR_UP
  config3.period = 10000'u32        # Moderate period
  config3.enable_irq = true         # Enable interrupts
  
  let result3 = timer3.init(config3)
  if result3 != TIMER_OK:
    printLine("ERROR: Timer3 init failed!")
    return
  
  # Set callback before starting
  timer3.setCallback(onTimer3Period, nil)
  discard timer3.start()
  printLine("Timer3: Periodic callback")
  printLine()
  
  # Timer 5: Different periodic callback (32-bit timer)
  var timer5: TimerHandle
  var config5: TimerConfig
  config5.periph = TIM_PERIPH_TIM5
  config5.dir = TIMER_DIR_UP
  config5.period = 5000'u32         # Shorter period
  config5.enable_irq = true
  
  let result5 = timer5.init(config5)
  if result5 != TIMER_OK:
    printLine("ERROR: Timer5 init failed!")
    return
  
  timer5.setCallback(onTimer2Period, nil)  # Reuse callback, increments timer2Count
  discard timer5.start()
  printLine("Timer5: Faster periodic callback")
  printLine()
  
  printLine("Monitoring for 20 seconds...")
  printLine()
  
  # Measurement loop
  var loopCount = 0
  let startTick = timer2.getTick()
  
  while loopCount < 40:  # 40 iterations * 500ms = 20 seconds
    let currentTick = timer2.getTick()
    let elapsedTicks = currentTick - startTick
    
    # Convert ticks to milliseconds (approximate)
    # Assuming TIM2 runs at 200MHz and counts every clock cycle
    # 1 tick = 1/200MHz = 5ns, so 1ms = 200,000 ticks
    let elapsedMs = int(elapsedTicks div 200_000)
    
    print("T+")
    print(elapsedMs)
    print("ms | Timer3 callbacks: ")
    print(timer3Count)
    print(" | Timer5 callbacks: ")
    print(timer2Count)
    
    # Show tick count
    print(" | Ticks: ")
    print(int(elapsedTicks))
    printLine()
    
    daisy.delay(500)
    loopCount.inc
  
  printLine()
  printLine("Test complete!")
  
  # Show final statistics
  printLine()
  printLine("=== Final Statistics ===")
  print("Timer3 callbacks: ")
  printLine(timer3Count)
  print("Timer5 callbacks: ")
  printLine(timer2Count)
  
  let finalTick = timer2.getTick()
  let totalTicks = finalTick - startTick
  let totalMs = int(totalTicks div 200_000)
  print("Total elapsed: ")
  print(totalMs)
  printLine("ms")
  
  # Stop timers
  discard timer2.stop()
  discard timer3.stop()
  discard timer5.stop()
  
  printLine()
  printLine("All timers stopped.")
  
  # Loop forever
  while true:
    daisy.delay(1000)

when isMainModule:
  main()
