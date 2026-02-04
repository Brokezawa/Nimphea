## Eurorack Basics Example
import panicoverride
## 
## Demonstrates eurorack-style gate/trigger inputs and 3-position switch
## - Gate input with trigger detection (rising edge)
## - Gate state monitoring (high/low)
## - 3-position switch reading
## - Typical eurorack input handling patterns

import ../src/nimphea
import ../src/per/uart
import ../src/hid/gatein
import ../src/hid/switch3
useNimpheaNamespace()

proc main() =
  var daisy = initDaisy()
  
  # Initialize gate inputs on pins D0 and D1
  # inverted=true is typical for eurorack (BJT input circuits)
  var gate1: GateIn
  var gate2: GateIn
  gate1.init(D0(), true)   # Gate 1 input
  gate2.init(D1(), true)   # Gate 2 input
  
  # Initialize 3-position switch on pins D2 and D3
  var mode_switch: Switch3
  mode_switch.init(D2(), D3())
  
  startLog()
  printLine("Eurorack Basics Example")
  printLine("Gate In + Switch3")
  printLine()
  printLine("Gate 1: D0 | Gate 2: D1")
  printLine("Switch: D2/D3 (UP/CENTER/DOWN)")
  printLine()
  
  var trigCount1 = 0
  var trigCount2 = 0
  var lastSwitchPos = -1
  
  while true:
    # Check for gate triggers (rising edges)
    if gate1.trig():
      trigCount1.inc
      print("TRIG 1! Count=")
      printLine(trigCount1)
    
    if gate2.trig():
      trigCount2.inc
      print("TRIG 2! Count=")
      printLine(trigCount2)
    
    # Read current gate states
    let g1_state = gate1.state()
    let g2_state = gate2.state()
    
    # Read switch position
    let switchPos = mode_switch.read()
    
    # Print switch changes
    if switchPos != lastSwitchPos:
      lastSwitchPos = switchPos
      print("Switch: ")
      case switchPos
      of SWITCH3_POS_CENTER:
        printLine("CENTER")
      of SWITCH3_POS_UP:
        printLine("UP")
      of SWITCH3_POS_DOWN:
        printLine("DOWN")
      else:
        printLine("UNKNOWN")
    
    # Print periodic status (every 500ms)
    # This shows combined state: switch position + gate states
    var statusCount {.global.} = 0
    statusCount.inc
    
    if statusCount >= 500:
      statusCount = 0
      
      print("Status: Mode=")
      case switchPos
      of SWITCH3_POS_CENTER:
        print("CENTER")
      of SWITCH3_POS_UP:
        print("UP")
      of SWITCH3_POS_DOWN:
        print("DOWN")
      else:
        print("???")
      
      print(" | G1=")
      if g1_state:
        print("HIGH")
      else:
        print("LOW")
      
      print(" | G2=")
      if g2_state:
        print("HIGH")
      else:
        print("LOW")
      
      print(" | Trigs: ")
      print(trigCount1)
      print("/")
      printLine(trigCount2)
    
    daisy.delay(1)  # 1ms poll rate

when isMainModule:
  main()
