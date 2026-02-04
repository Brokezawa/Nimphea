## Basic Peripherals Example
import panicoverride
import ../src/nimphea
import ../src/per/uart
import ../src/per/rng
import ../src/per/tim
import ../src/hid/led
useNimpheaNamespace()

proc main() =
  var daisy = initDaisy()
  
  # Initialize hardware RNG
  if not randomIsReady():
    startLog()
    printLine("ERROR: RNG not ready!")
    return
  
  # Initialize Timer (TIM2, counting up, 1000Hz tick rate)
  var timer: TimerHandle
  var timerConfig: TimerConfig
  timerConfig.periph = TIM_PERIPH_TIM2
  timerConfig.dir = TIMER_DIR_UP
  discard timer.init(timerConfig)
  discard timer.start()
  
  # Initialize LED on pin D7
  var led: Led
  led.init(D7(), false, 1000.0f)  # pin D7, not inverted, 1kHz sample rate
  
  startLog()
  printLine("Basic Peripherals Example")
  printLine("RNG + Timer + LED")
  printLine()
  
  # Main loop - blink LED with random patterns
  var loopCount = 0
  while true:
    loopCount.inc
    
    # Get random values
    let randValue = randomGetValue()
    let randFloat = randomGetFloat()
    
    # Calculate random blink duration (100-500ms)
    let blinkDuration = 100 + int(randValue mod 400)
    
    # Set LED brightness based on random float
    let brightness = randFloat
    led.set(brightness)
    led.update()  # Must call update() for PWM
    
    # Measure timing with hardware timer
    let startTick = timer.getTick()
    daisy.delay(blinkDuration)
    let endTick = timer.getTick()
    let elapsedTicks = endTick - startTick
    let elapsedMs = timer.getMs()
    
    # Print status every 5 iterations
    if loopCount mod 5 == 0:
      print("Loop ")
      print(loopCount)
      print(": Brightness=")
      print(brightness)
      print(" | Delay=")
      print(blinkDuration)
      print("ms | Timer=")
      print(int(elapsedTicks))
      print(" ticks (")
      print(int(elapsedMs))
      printLine("ms total)")
    
    # Turn off LED
    led.set(0.0f)
    led.update()
    daisy.delay(100)

when isMainModule:
  main()
