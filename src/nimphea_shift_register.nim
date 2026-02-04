## nimphea_shift_register
## ========================
##
## Nim wrapper for CD4021 shift register device driver.
##
## The CD4021 is an 8-stage CMOS shift register commonly used for:
## - Expanding digital inputs (buttons, switches)
## - Keyboard scanning (e.g., Daisy Field uses 2 daisy-chained for 16 keys)
## - General-purpose parallel-to-serial conversion
##
## **Hardware Specifications:**
## - Supply Voltage: 3V to 18V
## - Clock Frequency: 3MHz at 5V, 8.5MHz at 15V
## - 8 parallel inputs per device
## - Supports daisy-chaining (series connection)
## - Supports parallel operation (multiple data lines, shared clock/latch)
##
## **Typical Applications:**
## - Button matrix scanning
## - Keyboard input (Daisy Field: 16 keys with 2 chained devices)
## - Multi-switch panels
##
## **Example - Simple 8-button scanner:**
## ```nim
## import nimphea
## import nimphea_shift_register
##
## var sr: ShiftRegister4021_1  # Single device (8 inputs)
## var config: ShiftRegisterConfig_1
## 
## config.clk = D0()
## config.latch = D1()
## config.data[0] = D2()
## config.delay_ticks = 10
##
## sr.init(config)
##
## while true:
##   sr.update()  # Read all 8 inputs
##   
##   for i in 0..<8:
##     if sr.state(i):
##       # Button i is pressed (HIGH)
##   
##   hw.delay(10)
## ```
##
## **Example - Daisy Field keyboard (16 keys, 2 chained devices):**
## ```nim
## var keyboard: ShiftRegister4021_2  # 2 daisy-chained devices
## var config: ShiftRegisterConfig_2
##
## config.clk = D8()
## config.latch = D7()
## config.data[0] = D10()
##
## keyboard.init(config)
##
## while true:
##   keyboard.update()
##   
##   for key in 0..<16:  # 8 inputs × 2 devices
##     if keyboard.state(key):
##       # Key is pressed
## ```

import nimphea
import nimphea_macros

useNimpheaModules(sr4021)

{.push header: "dev/sr_4021.h".}

# Config structures for common device counts
# Pattern: data array size = num_parallel

type
  ShiftRegisterConfig_1* {.importcpp: "daisy::ShiftRegister4021<1, 1>::Config",
                            bycopy.} = object
    ## Configuration for single shift register (8 inputs)
    clk* {.importc: "clk".}: Pin          ## Clock pin (pin 10 of CD4021)
    latch* {.importc: "latch".}: Pin      ## Latch pin (pin 9 of CD4021)
    data* {.importc: "data".}: array[1, Pin]  ## Data pin (pin 11 of CD4021)
    delay_ticks* {.importc: "delay_ticks".}: uint32  ## Timing delay (default 10)

  ShiftRegisterConfig_2* {.importcpp: "daisy::ShiftRegister4021<2, 1>::Config",
                            bycopy.} = object
    ## Configuration for 2 daisy-chained shift registers (16 inputs)
    clk* {.importc: "clk".}: Pin
    latch* {.importc: "latch".}: Pin
    data* {.importc: "data".}: array[1, Pin]
    delay_ticks* {.importc: "delay_ticks".}: uint32

  ShiftRegisterConfig_3* {.importcpp: "daisy::ShiftRegister4021<3, 1>::Config",
                            bycopy.} = object
    ## Configuration for 3 daisy-chained shift registers (24 inputs)
    clk* {.importc: "clk".}: Pin
    latch* {.importc: "latch".}: Pin
    data* {.importc: "data".}: array[1, Pin]
    delay_ticks* {.importc: "delay_ticks".}: uint32

  ShiftRegisterConfig_4* {.importcpp: "daisy::ShiftRegister4021<4, 1>::Config",
                            bycopy.} = object
    ## Configuration for 4 daisy-chained shift registers (32 inputs)
    clk* {.importc: "clk".}: Pin
    latch* {.importc: "latch".}: Pin
    data* {.importc: "data".}: array[1, Pin]
    delay_ticks* {.importc: "delay_ticks".}: uint32

  # Parallel configurations (2 data lines)
  ShiftRegisterConfig_1x2* {.importcpp: "daisy::ShiftRegister4021<1, 2>::Config",
                              bycopy.} = object
    ## Configuration for 1 device × 2 parallel lines (16 inputs total)
    clk* {.importc: "clk".}: Pin
    latch* {.importc: "latch".}: Pin
    data* {.importc: "data".}: array[2, Pin]
    delay_ticks* {.importc: "delay_ticks".}: uint32

  ShiftRegisterConfig_2x2* {.importcpp: "daisy::ShiftRegister4021<2, 2>::Config",
                              bycopy.} = object
    ## Configuration for 2 devices × 2 parallel lines (32 inputs total)
    clk* {.importc: "clk".}: Pin
    latch* {.importc: "latch".}: Pin
    data* {.importc: "data".}: array[2, Pin]
    delay_ticks* {.importc: "delay_ticks".}: uint32

# Device types for common configurations

type
  ShiftRegister4021_1* {.importcpp: "daisy::ShiftRegister4021<1, 1>".} = object
    ## Single CD4021 shift register (8 inputs)

  ShiftRegister4021_2* {.importcpp: "daisy::ShiftRegister4021<2, 1>".} = object
    ## 2 daisy-chained CD4021 devices (16 inputs)
    ## Used by Daisy Field for keyboard scanning

  ShiftRegister4021_3* {.importcpp: "daisy::ShiftRegister4021<3, 1>".} = object
    ## 3 daisy-chained CD4021 devices (24 inputs)

  ShiftRegister4021_4* {.importcpp: "daisy::ShiftRegister4021<4, 1>".} = object
    ## 4 daisy-chained CD4021 devices (32 inputs)

  ShiftRegister4021_1x2* {.importcpp: "daisy::ShiftRegister4021<1, 2>".} = object
    ## 1 device × 2 parallel lines (16 inputs)

  ShiftRegister4021_2x2* {.importcpp: "daisy::ShiftRegister4021<2, 2>".} = object
    ## 2 devices × 2 parallel lines (32 inputs)

{.pop.}  # header

# Generic procedures that work for all configurations

proc init*(this: var ShiftRegister4021_1, config: ShiftRegisterConfig_1)
  {.importcpp: "#.Init(#)".} =
  ## Initialize single shift register
  discard

proc init*(this: var ShiftRegister4021_2, config: ShiftRegisterConfig_2)
  {.importcpp: "#.Init(#)".} =
  ## Initialize 2 daisy-chained shift registers
  discard

proc init*(this: var ShiftRegister4021_3, config: ShiftRegisterConfig_3)
  {.importcpp: "#.Init(#)".} =
  ## Initialize 3 daisy-chained shift registers
  discard

proc init*(this: var ShiftRegister4021_4, config: ShiftRegisterConfig_4)
  {.importcpp: "#.Init(#)".} =
  ## Initialize 4 daisy-chained shift registers
  discard

proc init*(this: var ShiftRegister4021_1x2, config: ShiftRegisterConfig_1x2)
  {.importcpp: "#.Init(#)".} =
  ## Initialize 1×2 parallel shift registers
  discard

proc init*(this: var ShiftRegister4021_2x2, config: ShiftRegisterConfig_2x2)
  {.importcpp: "#.Init(#)".} =
  ## Initialize 2×2 parallel shift registers
  discard

# Update method (same for all types)

proc update*(this: var ShiftRegister4021_1)
  {.importcpp: "#.Update()".} =
  ## Read all 8 input states from the device
  ##
  ## Call this regularly (e.g., 100-1000Hz) to poll button states.
  ## The read values are stored internally and accessed via `state()`.
  discard

proc update*(this: var ShiftRegister4021_2)
  {.importcpp: "#.Update()".} =
  ## Read all 16 input states (2 daisy-chained devices)
  discard

proc update*(this: var ShiftRegister4021_3)
  {.importcpp: "#.Update()".} =
  ## Read all 24 input states (3 daisy-chained devices)
  discard

proc update*(this: var ShiftRegister4021_4)
  {.importcpp: "#.Update()".} =
  ## Read all 32 input states (4 daisy-chained devices)
  discard

proc update*(this: var ShiftRegister4021_1x2)
  {.importcpp: "#.Update()".} =
  ## Read all 16 input states (1×2 parallel)
  discard

proc update*(this: var ShiftRegister4021_2x2)
  {.importcpp: "#.Update()".} =
  ## Read all 32 input states (2×2 parallel)
  discard

# State accessor (same for all types)

proc state*(this: ShiftRegister4021_1, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-7)
  ##
  ## **Returns:** `true` if input is HIGH, `false` if LOW
  ##
  ## **Note:** Inverted logic for buttons with pull-ups:
  ## - `true` = button released (HIGH)
  ## - `false` = button pressed (LOW, pulled to ground)
  discard

proc state*(this: ShiftRegister4021_2, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-15)
  ##
  ## Index order for 2 daisy-chained devices:
  ## - 0-7: First device (closest to MCU)
  ## - 8-15: Second device
  discard

proc state*(this: ShiftRegister4021_3, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-23)
  discard

proc state*(this: ShiftRegister4021_4, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-31)
  discard

proc state*(this: ShiftRegister4021_1x2, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-15)
  ##
  ## Index order for 1×2 parallel:
  ## - 0-7: First data line
  ## - 8-15: Second data line (parallel)
  discard

proc state*(this: ShiftRegister4021_2x2, index: cint): bool
  {.importcpp: "#.State(#)".} =
  ## Get state of input at index (0-31)
  ##
  ## Index order for 2×2 (2 chained, 2 parallel):
  ## - 0-7: Device 0, data line 0
  ## - 8-15: Device 1, data line 0
  ## - 16-23: Device 0, data line 1
  ## - 24-31: Device 1, data line 1
  discard

# Convenience helper for common use case: checking if button is pressed (active-low)

proc pressed*(this: ShiftRegister4021_1, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  ##
  ## Assumes buttons connect input to ground when pressed.
  ## Returns `true` when button is pressed.
  not this.state(index)

proc pressed*(this: ShiftRegister4021_2, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  not this.state(index)

proc pressed*(this: ShiftRegister4021_3, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  not this.state(index)

proc pressed*(this: ShiftRegister4021_4, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  not this.state(index)

proc pressed*(this: ShiftRegister4021_1x2, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  not this.state(index)

proc pressed*(this: ShiftRegister4021_2x2, index: cint): bool {.inline.} =
  ## Check if button at index is pressed (active-low logic)
  not this.state(index)
