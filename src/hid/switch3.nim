## 3-Position Switch
## ==================
##
## Simple 3-position switch (toggle switch or encoder switch positions).
##
## **Positions:**
## - CENTER (0)
## - UP/LEFT (1)
## - DOWN/RIGHT (2)
##
## **Usage:**
## ```nim
## import hid/switch3
##
## var sw: Switch3
## sw.init(D0, D1)  # Two pins for 3 positions
##
## # Read position
## let pos = sw.read()
## case pos
## of SWITCH3_POS_CENTER:
##   echo "Center"
## of SWITCH3_POS_UP:
##   echo "Up/Left"
## of SWITCH3_POS_DOWN:
##   echo "Down/Right"
## else:
##   discard
## ```

import nimphea_macros
import nimphea  # For Pin type

useNimpheaModules(switch3)

const
  SWITCH3_POS_CENTER* = 0  ## Center position
  SWITCH3_POS_LEFT* = 1    ## Left position (same as UP)
  SWITCH3_POS_UP* = 1      ## Up position (same as LEFT)
  SWITCH3_POS_RIGHT* = 2   ## Right position (same as DOWN)
  SWITCH3_POS_DOWN* = 2    ## Down position (same as RIGHT)

type
  Switch3* {.importcpp: "daisy::Switch3", header: "hid/switch3.h".} = object
    ## 3-position switch handler

proc init*(this: var Switch3, pina, pinb: Pin)
  {.importcpp: "#.Init(#, #)".} =
  ## Initialize 3-position switch
  ##
  ## **Parameters:**
  ## - `pina` - First pin
  ## - `pinb` - Second pin
  ##
  ## **Note:** Both pins use internal pull-up resistors
  ##
  ## **Example:**
  ## ```nim
  ## var sw: Switch3
  ## sw.init(D0, D1)
  ## ```
  discard

proc read*(this: var Switch3): cint {.importcpp: "#.Read()".} =
  ## Read current switch position
  ##
  ## **Returns:**
  ## - SWITCH3_POS_CENTER (0) - Center/neutral position
  ## - SWITCH3_POS_UP/LEFT (1) - Up or left position
  ## - SWITCH3_POS_DOWN/RIGHT (2) - Down or right position
  ##
  ## **Example:**
  ## ```nim
  ## let pos = sw.read()
  ## if pos == SWITCH3_POS_UP:
  ##   echo "Switch is up!"
  ## ```
  discard
