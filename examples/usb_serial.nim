## USB Serial Echo Example
## 
## This example demonstrates USB CDC (Communications Device Class) for serial communication.
## It creates a virtual serial port that echoes back any data received.
## LED blinks slowly to indicate the device is running.
## 
## To test:
## 1. Flash this program to Daisy Seed
## 2. Connect USB cable
## 3. Open serial terminal (e.g., screen, minicom, or Arduino Serial Monitor)
## 4. Type messages - they will be echoed back

import ../src/nimphea except UsbHandle
import ../src/hid/usb as usb_module
useNimpheaNamespace()


var 
  daisy: DaisySeed
  usb: UsbHandle

proc usbReceiveCallback(buffer: ptr uint8, len: ptr uint32) {.cdecl.} =
  ## Called when data is received over USB
  ## Echo the data back
  if len[] > 0:
    discard usb.transmitInternal(buffer, len[].csize_t)

proc main() =
  # Initialize hardware
  daisy = initDaisy()
  
  # Initialize USB
  usb = newUsbHandle()
  usb.init(FS_INTERNAL)
  usb.setReceiveCallback(usbReceiveCallback, FS_INTERNAL)
  
  # Small delay to let USB enumerate
  daisy.delay(100)
  
  # Send greeting message
  var greeting = "USB Serial Echo Ready\r\n"
  discard usb.transmitInternal(greeting)
  
  # Blink LED to show we're running
  var ledState = false
  var counter = 0
  
  while true:
    daisy.delay(100)
    counter.inc
    
    # Toggle LED every 500ms
    if counter >= 5:
      ledState = not ledState
      daisy.setLed(ledState)
      counter = 0

when isMainModule:
  main()
