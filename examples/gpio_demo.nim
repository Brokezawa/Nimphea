## GPIO Demonstration
##
## Comprehensive example showing all GPIO capabilities in Nimphea:
## - LED blinking (output)
## - Button reading (input with debouncing)
## - Raw GPIO input (with pull-up/pull-down)
## - External GPIO output
##
## **Hardware Setup (Basic)**:
## - Daisy Seed (has built-in LED on PC7)
## - No additional hardware needed for basic LED blink
##
## **Hardware Setup (Full Demo)**:
## - Button connected to D2 (active low - button pulls to GND)
## - External LED on D7 with current-limiting resistor (~220Ω to GND)
## - Optionally: Second button on D3 for comparison
##
## **Features Demonstrated**:
## 1. setLed() / toggleLed() - Built-in LED control
## 2. initSwitch() - Debounced button input
## 3. initGpio() - Raw GPIO configuration
## 4. GPIO modes: INPUT, OUTPUT, PULLUP, PULLDOWN
## 5. Rising/falling edge detection with Switch
##
## **Modes**: Cycles through different demos automatically.

import panicoverride
import ../src/nimphea
import ../src/hid/ctrl
import ../src/per/uart

useNimpheaNamespace()

# =============================================================================
# Mode 1: Simple LED Blink
# =============================================================================
proc demoLedBlink(daisy: var DaisySeed) =
  ## The classic "Hello World" of embedded programming.
  ## Blinks the built-in LED using setLed().
  
  printLine("=== Mode 1: LED Blink ===")
  printLine("Blinking built-in LED 5 times")
  printLine()
  
  for i in 0..<5:
    print("Blink ")
    print(i + 1)
    printLine("/5")
    
    daisy.setLed(true)
    daisy.delay(200)
    daisy.setLed(false)
    daisy.delay(200)
  
  printLine("Done.")
  printLine()

# =============================================================================
# Mode 2: Toggle LED Shortcut
# =============================================================================
proc demoToggleLed(daisy: var DaisySeed) =
  ## Demonstrates the toggleLed() convenience function.
  ## More concise than tracking state manually.
  
  printLine("=== Mode 2: Toggle LED ===")
  printLine("Using toggleLed() 10 times")
  printLine()
  
  for i in 0..<10:
    daisy.toggleLed()
    print("Toggle ")
    print(i + 1)
    printLine()
    daisy.delay(150)
  
  daisy.setLed(false)  # Ensure LED is off
  printLine("Done.")
  printLine()

# =============================================================================
# Mode 3: Debounced Button Input
# =============================================================================
proc demoButtonInput(daisy: var DaisySeed) =
  ## Demonstrates the Switch class for debounced button reading.
  ## The Switch class handles debouncing and edge detection automatically.
  
  printLine("=== Mode 3: Button Input ===")
  printLine("Press button on D2 to toggle LED")
  printLine("Running for 10 seconds...")
  printLine()
  
  # Initialize debounced switch on D2
  var button = initSwitch(D2())
  var ledState = false
  var pressCount = 0
  
  for i in 0..<1000:  # Run for ~10 seconds at 10ms intervals
    button.update()
    
    # Check for rising edge (button pressed)
    if button.risingEdge():
      ledState = not ledState
      daisy.setLed(ledState)
      inc pressCount
      print("Button pressed! Count: ")
      print(pressCount)
      printLine()
    
    # Also show continuous pressed state
    if button.pressed:
      # Button is currently held down
      discard  # Could do something here
    
    daisy.delay(10)
  
  daisy.setLed(false)
  print("Total presses: ")
  print(pressCount)
  printLine()
  printLine()

# =============================================================================
# Mode 4: Raw GPIO Configuration
# =============================================================================
proc demoRawGpio(daisy: var DaisySeed) =
  ## Demonstrates low-level GPIO configuration using initGpio().
  ## Shows different modes: INPUT, OUTPUT, PULLUP, PULLDOWN.
  
  printLine("=== Mode 4: Raw GPIO ===")
  printLine("Input with pull-up on PC10 (D2)")
  printLine("Output on PG10 (D7)")
  printLine("Running for 5 seconds...")
  printLine()
  
  # Initialize button on D2 as input with pull-up
  # When using raw GPIO, you specify the port and pin number directly
  var buttonGpio = initGpio(newPin(PORTC, 10), INPUT, PULLUP)
  
  # Initialize external LED on D7 as output (push-pull)
  var ledGpio = initGpio(newPin(PORTG, 10), OUTPUT)
  
  for i in 0..<250:  # Run for ~5 seconds at 20ms intervals
    # Read button state
    # With pull-up, the pin reads HIGH when not pressed, LOW when pressed
    let buttonState = buttonGpio.read()
    let buttonPressed = not buttonState  # Invert for logic convenience
    
    # Mirror button to both LEDs
    daisy.setLed(buttonPressed)      # Built-in LED
    ledGpio.write(buttonPressed)      # External LED
    
    # Print state changes
    if (i mod 25) == 0:  # Every 0.5 seconds
      print("Button GPIO: ")
      if buttonPressed: print("PRESSED")
      else: print("released")
      printLine()
    
    daisy.delay(20)
  
  # Clean up
  daisy.setLed(false)
  ledGpio.write(false)
  printLine("Done.")
  printLine()

# =============================================================================
# Mode 5: Multiple GPIO Outputs (Pattern)
# =============================================================================
proc demoMultiOutput(daisy: var DaisySeed) =
  ## Demonstrates controlling multiple GPIO outputs.
  ## Creates a simple LED chaser pattern.
  
  printLine("=== Mode 5: Multi-Output ===")
  printLine("LED pattern on D7 + built-in LED")
  printLine()
  
  # Initialize external LED
  var led1 = initGpio(newPin(PORTG, 10), OUTPUT)  # D7
  
  # Simple alternating pattern
  for cycle in 0..<5:
    print("Cycle ")
    print(cycle + 1)
    printLine("/5")
    
    # Pattern 1: Both on
    daisy.setLed(true)
    led1.write(true)
    daisy.delay(200)
    
    # Pattern 2: Built-in only
    daisy.setLed(true)
    led1.write(false)
    daisy.delay(200)
    
    # Pattern 3: External only
    daisy.setLed(false)
    led1.write(true)
    daisy.delay(200)
    
    # Pattern 4: Both off
    daisy.setLed(false)
    led1.write(false)
    daisy.delay(200)
  
  printLine("Done.")
  printLine()

# =============================================================================
# Main Program
# =============================================================================
proc main() =
  var daisy = initDaisy()
  
  startLog()
  printLine("========================================")
  printLine("     GPIO Demonstration Example")
  printLine("========================================")
  printLine()
  printLine("This example demonstrates 5 GPIO modes:")
  printLine("  1. LED Blink (basic output)")
  printLine("  2. Toggle LED (convenience API)")
  printLine("  3. Button Input (debounced)")
  printLine("  4. Raw GPIO (direct control)")
  printLine("  5. Multi-Output (LED pattern)")
  printLine()
  
  while true:
    demoLedBlink(daisy)
    daisy.delay(500)
    
    demoToggleLed(daisy)
    daisy.delay(500)
    
    demoButtonInput(daisy)
    daisy.delay(500)
    
    demoRawGpio(daisy)
    daisy.delay(500)
    
    demoMultiOutput(daisy)
    daisy.delay(500)
    
    printLine("========================================")
    printLine("       Restarting demonstration")
    printLine("========================================")
    printLine()

when isMainModule:
  main()
