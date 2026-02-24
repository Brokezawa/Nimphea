## Simple LED Blink Example
## 
## This example demonstrates the clean, Nim-friendly API for blinking the built-in LED

import nimphea
useNimpheaNamespace()
import panicoverride

proc main() =
  var daisy = initDaisy()
  var ledState = false

  while true:
    ledState = not ledState
    daisy.setLed(ledState)
    daisy.delay(500)

when isMainModule:
  main()
