## PWM Demonstration
##
## Comprehensive example showing all PWM capabilities in Nimphea:
## - Basic LED dimming (single channel fade)
## - RGB LED control (multi-channel color mixing)
## - Servo motor control (pulse width timing)
##
## **Hardware Setup (Basic)**:
## - Daisy Seed
## - LED connected to pin (varies by timer)
## - External LEDs need current-limiting resistors (~220Ω for 3.3V)
##
## **Hardware Setup (RGB LED)**:
## - Common cathode RGB LED (or 3 separate LEDs)
## - Red → D13 (TIM4 CH1) with resistor
## - Green → D14 (TIM4 CH2) with resistor
## - Blue → D11 (TIM4 CH3) with resistor
## - Common cathode → GND
##
## **Hardware Setup (Servo)**:
## - Standard servo (SG90, MG996R, etc.)
## - Signal → D25 (TIM5 CH1)
## - Power → External 5V (NOT from Daisy 3.3V!)
## - Ground → Shared GND with Daisy
## - WARNING: Servos need external 5V power supply
##
## **Timer/Pin Mapping**:
## - TIM3: CH1=PB4, CH2=PC7(LED), CH3=PB0, CH4=PB1
## - TIM4: CH1=D13, CH2=D14, CH3=D11, CH4=D12
## - TIM5: CH1=D25, CH2=D26, CH3=D27, CH4=D28
##
## **Features Demonstrated**:
## 1. PwmHandle initialization with frequency
## 2. Channel configuration
## 3. Duty cycle control (0.0 to 1.0)
## 4. HSV to RGB color conversion
## 5. Servo pulse width calculation
##
## **Modes**: Cycles through LED fade, RGB rainbow, and servo sweep.

import panicoverride
import ../src/nimphea
import ../src/per/pwm
import ../src/per/uart

useNimpheaNamespace()

# =============================================================================
# Mode 1: LED Fading (Single Channel)
# =============================================================================
proc demoLedFade(hw: var DaisySeed) =
  ## Demonstrates basic PWM usage by fading an LED.
  ## Uses TIM3 Channel 2 (PC7 - the built-in LED on Daisy Seed).
  
  printLine("=== Mode 1: LED Fading ===")
  printLine("PWM on TIM3 CH2 (PC7/LED) at 1kHz")
  printLine()
  
  # Initialize PWM on TIM3 at 1kHz
  var pwm {.noinit.}: PwmHandle
  pwm.cppInit(TIM_3, 1000.0)
  
  # Initialize channel 2 (LED - default pin PC7)
  discard pwm.channel2.init()
  
  printLine("Fading LED in/out 3 times...")
  
  for cycle in 0..<3:
    print("Cycle ")
    print(cycle + 1)
    printLine("/3")
    
    # Fade in (0% to 100%)
    for brightness in 0..100:
      pwm.channel2.set(brightness.float / 100.0)
      hw.delay(10)
    
    # Fade out (100% to 0%)
    for brightness in countdown(100, 0):
      pwm.channel2.set(brightness.float / 100.0)
      hw.delay(10)
  
  # Turn off
  pwm.channel2.set(0.0)
  printLine("Done.")
  printLine()

# =============================================================================
# Mode 2: RGB LED Rainbow (Multi-Channel)
# =============================================================================
proc demoRgbRainbow(hw: var DaisySeed) =
  ## Demonstrates multi-channel PWM with HSV color cycling.
  ## Creates a smooth rainbow effect on an RGB LED.
  
  printLine("=== Mode 2: RGB LED Rainbow ===")
  printLine("PWM on TIM4 CH1-3 at 10kHz")
  printLine("Red=D13, Green=D14, Blue=D11")
  printLine()
  
  # Initialize PWM on TIM4 at 10kHz for smooth LED dimming
  var pwm {.noinit.}: PwmHandle
  pwm.cppInit(TIM_4, 10000.0)
  
  # Initialize 3 channels for RGB
  discard pwm.channel1.init()  # D13 - Red
  discard pwm.channel2.init()  # D14 - Green
  discard pwm.channel3.init()  # D11 - Blue
  
  printLine("Running rainbow for 10 seconds...")
  
  var hue: float = 0.0
  
  for i in 0..<500:  # ~10 seconds at 20ms interval
    # Simple HSV to RGB conversion (saturation=1, value=1)
    let sector = int(hue * 6.0)
    let f = hue * 6.0 - sector.float
    let q = 1.0 - f
    let t = f
    
    var r, g, b: float
    
    case sector mod 6
    of 0: r = 1.0; g = t; b = 0.0    # Red → Yellow
    of 1: r = q; g = 1.0; b = 0.0    # Yellow → Green
    of 2: r = 0.0; g = 1.0; b = t    # Green → Cyan
    of 3: r = 0.0; g = q; b = 1.0    # Cyan → Blue
    of 4: r = t; g = 0.0; b = 1.0    # Blue → Magenta
    else: r = 1.0; g = 0.0; b = q    # Magenta → Red
    
    # Set RGB values
    pwm.channel1.set(r)  # Red
    pwm.channel2.set(g)  # Green
    pwm.channel3.set(b)  # Blue
    
    # Print color info every 50 iterations
    if (i mod 50) == 0:
      print("Hue=")
      print(hue)
      print(" R=")
      print(r)
      print(" G=")
      print(g)
      print(" B=")
      print(b)
      printLine()
    
    # Increment hue
    hue += 0.004
    if hue >= 1.0:
      hue = 0.0
    
    hw.delay(20)
  
  # Turn off all LEDs
  pwm.channel1.set(0.0)
  pwm.channel2.set(0.0)
  pwm.channel3.set(0.0)
  
  printLine("Done.")
  printLine()

# =============================================================================
# Mode 3: Servo Control
# =============================================================================
proc servoPosition(degrees: float): float =
  ## Convert degrees (0-180) to PWM duty cycle for 50Hz servo.
  ##
  ## Standard servo timing (at 50Hz / 20ms period):
  ## - 1.0ms pulse = 5% duty = 0°
  ## - 1.5ms pulse = 7.5% duty = 90°
  ## - 2.0ms pulse = 10% duty = 180°
  
  const
    MIN_PULSE_MS = 1.0   # Minimum pulse width (0°)
    MAX_PULSE_MS = 2.0   # Maximum pulse width (180°)
    PERIOD_MS = 20.0     # 50Hz = 20ms period
  
  # Clamp degrees to valid range
  var deg = degrees
  if deg < 0.0: deg = 0.0
  if deg > 180.0: deg = 180.0
  
  # Calculate pulse width and convert to duty cycle
  let pulseMs = MIN_PULSE_MS + (deg / 180.0) * (MAX_PULSE_MS - MIN_PULSE_MS)
  result = pulseMs / PERIOD_MS

proc demoServoSweep(hw: var DaisySeed) =
  ## Demonstrates PWM for servo motor control.
  ## Sweeps the servo back and forth through its full range.
  
  printLine("=== Mode 3: Servo Control ===")
  printLine("PWM on TIM5 CH1 (D25) at 50Hz")
  printLine("WARNING: Use external 5V for servo!")
  printLine()
  
  # Initialize PWM at 50Hz for servo control
  var pwm {.noinit.}: PwmHandle
  pwm.cppInit(TIM_5, 50.0)
  
  # Initialize channel 1 (D25)
  discard pwm.channel1.init()
  
  printLine("Sweeping servo 0° → 180° → 0°...")
  
  for cycle in 0..<2:
    print("Cycle ")
    print(cycle + 1)
    printLine("/2")
    
    # Sweep from 0 to 180 degrees
    for degrees in countup(0, 180, 5):
      let duty = servoPosition(degrees.float)
      pwm.channel1.set(duty)
      
      if (degrees mod 45) == 0:
        print("  ")
        print(degrees)
        print("° (duty=")
        print(duty)
        printLine(")")
      
      hw.delay(30)
    
    hw.delay(500)  # Pause at end
    
    # Sweep back from 180 to 0 degrees
    for degrees in countdown(180, 0, 5):
      let duty = servoPosition(degrees.float)
      pwm.channel1.set(duty)
      
      if (degrees mod 45) == 0:
        print("  ")
        print(degrees)
        print("° (duty=")
        print(duty)
        printLine(")")
      
      hw.delay(30)
    
    hw.delay(500)  # Pause at end
  
  # Center the servo
  pwm.channel1.set(servoPosition(90.0))
  printLine("Centered at 90°")
  printLine()

# =============================================================================
# Main Program
# =============================================================================
proc main() =
  var hw = initDaisy()
  
  startLog()
  printLine("========================================")
  printLine("     PWM Demonstration Example")
  printLine("========================================")
  printLine()
  printLine("This example demonstrates 3 PWM modes:")
  printLine("  1. LED Fading (TIM3 CH2)")
  printLine("  2. RGB Rainbow (TIM4 CH1-3)")
  printLine("  3. Servo Control (TIM5 CH1)")
  printLine()
  
  while true:
    # Mode 1: LED fading
    demoLedFade(hw)
    hw.delay(1000)
    
    # Mode 2: RGB rainbow
    demoRgbRainbow(hw)
    hw.delay(1000)
    
    # Mode 3: Servo sweep
    demoServoSweep(hw)
    hw.delay(1000)
    
    printLine("========================================")
    printLine("       Restarting demonstration")
    printLine("========================================")
    printLine()

when isMainModule:
  main()
