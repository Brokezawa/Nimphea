## 74HC595 Shift Register Module - 8-bit Serial-to-Parallel Output
##
## Device driver for CD74HC595 8-bit shift register (output expander).
## Supports daisy-chaining up to 16 devices.
##
## **Hardware:** CD74HC595 8-bit serial-to-parallel shift register
## **Interface:** 3-wire serial (LATCH, CLK, DATA)
## **Supply:** 2V-6V (3.3V compatible)
## **Features:**
## - Up to 16 devices can be daisy-chained (128 outputs)
## - High-current outputs (6mA at 5V)
## - Tri-state outputs (when OE is HIGH)
##
## **Pin Connections:**
## - Pin 11 (SRCLK) → CLK (shift register clock)
## - Pin 12 (RCLK)  → LATCH (storage register clock)
## - Pin 14 (SER)   → DATA (serial data input)
## - Pin 13 (OE)    → GND (output enable, active LOW)
## - Pin 10 (SRCLR) → 3.3V (shift register clear, active LOW)
##
## **Daisy Chaining:**
## Connect QH' (pin 9) of first device to SER (pin 14) of next device.
##
## **Example:**
## ```nim
## import nimphea
## import nimphea/dev/sr595
##
## var sr: ShiftRegister595
## var pins = [newPin(PORTB, 0),  # LATCH
##             newPin(PORTB, 1),  # CLK
##             newPin(PORTB, 2)]  # DATA
##
## sr.init(addr pins[0], 2)  # 2 devices daisy-chained (16 outputs)
## 
## sr.set(0, true)   # Set output QA on first device HIGH
## sr.set(15, true)  # Set output QH on second device HIGH
## sr.write()        # Shift out the data
## ```

import ../nimphea
import ../nimphea_macros

useNimpheaModules(sr595)

{.push header: "dev/sr_595.h".}

const kMaxSr595DaisyChain* = 16

type
  ShiftRegister595Pins* {.importcpp: "daisy::ShiftRegister595::Pins", 
                          size: sizeof(cint).} = enum
    PIN_LATCH = 0  ## LATCH corresponds to Pin 12 "RCLK"
    PIN_CLK = 1    ## CLK corresponds to Pin 11 "SRCLK"
    PIN_DATA = 2   ## DATA corresponds to Pin 14 "SER"
    NUM_PINS = 3

  ShiftRegister595* {.importcpp: "daisy::ShiftRegister595", bycopy.} = object

# C++ API
proc cppInit(this: var ShiftRegister595, pin_cfg: ptr Pin, 
             num_daisy_chained: csize_t = 1) 
  {.importcpp: "#.Init(@)".}

proc cppSet(this: var ShiftRegister595, idx: uint8, state: bool) 
  {.importcpp: "#.Set(@)".}

proc cppWrite(this: var ShiftRegister595) 
  {.importcpp: "#.Write()".}

{.pop.}

# High-level Nim API
proc init*(sr: var ShiftRegister595, pin_cfg: ptr Pin, 
           num_daisy_chained: csize_t = 1) =
  ## Initialize shift register(s)
  ##
  ## **Parameters:**
  ## - `pin_cfg`: Array of 3 pins [LATCH, CLK, DATA]
  ## - `num_daisy_chained`: Number of devices (1-16, default 1)
  ##
  ## **Pin Order:**
  ## - pin_cfg[0] = LATCH (Pin 12 RCLK)
  ## - pin_cfg[1] = CLK (Pin 11 SRCLK)
  ## - pin_cfg[2] = DATA (Pin 14 SER)
  cppInit(sr, pin_cfg, num_daisy_chained)

proc set*(sr: var ShiftRegister595, idx: uint8, state: bool) =
  ## Set the state of a specific output
  ##
  ## **Parameters:**
  ## - `idx`: Output index (0-127 depending on daisy chain length)
  ##   - Device 1: QA=0, QB=1, ..., QH=7
  ##   - Device 2: QA=8, QB=9, ..., QH=15
  ##   - etc.
  ## - `state`: true = HIGH, false = LOW
  ##
  ## **Note:** Call `write()` to shift the data out to the hardware
  cppSet(sr, idx, state)

proc write*(sr: var ShiftRegister595) =
  ## Shift out all buffered data to the shift register(s)
  ##
  ## This latches the data to the output pins.
  ## Call this after setting all desired outputs with `set()`.
  cppWrite(sr)
