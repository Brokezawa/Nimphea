## UI Event Queue System
## ======================
##
## This module wraps libDaisy's UI event queue system for handling user input events.
## The event queue is thread-safe (uses ScopedIrqBlocker) and can be safely accessed
## from interrupt handlers.
##
## **Features:**
## - Button press/release events with double-click detection
## - Encoder rotation events with increment tracking
## - Potentiometer/slider movement events
## - Activity tracking (user started/stopped interaction)
## - Thread-safe FIFO queue (256 event capacity)
##
## **Wrapped Header:** `ui/UiEventQueue.h`
##
## Example - Basic event processing:
## ```nim
## import nimphea_ui_events
## 
## var eventQueue = initUiEventQueue()
## 
## # In button interrupt handler:
## eventQueue.addButtonPressed(0, 1, false)  # button 0, single press
## 
## # In main loop:
## while not eventQueue.isQueueEmpty():
##   var evt = eventQueue.getAndRemoveNextEvent()
##   if evt.eventType == EventType.buttonPressed:
##     echo "Button ", evt.asButtonPressed.id, " pressed"
## ```
##
## Example - Double-click detection:
## ```nim
## var evt = eventQueue.getAndRemoveNextEvent()
## if evt.eventType == EventType.buttonPressed:
##   if evt.asButtonPressed.numSuccessivePresses == 2:
##     echo "Double click detected!"
## ```
##
## Example - Encoder events:
## ```nim
## var evt = eventQueue.getAndRemoveNextEvent()
## if evt.eventType == EventType.encoderTurned:
##   let increments = evt.asEncoderTurned.increments
##   echo "Encoder turned ", increments, " steps"
## ```

import nimphea
import nimphea_macros

# UiEventQueue doesn't need special typedefs, uses core types
useNimpheaModules(ui_core)

{.push header: "ui/UiEventQueue.h".}

## Invalid button ID constant
const INVALID_BUTTON_ID* = uint16.high

## Invalid encoder ID constant
const INVALID_ENCODER_ID* = uint16.high

## Invalid potentiometer ID constant
const INVALID_POT_ID* = uint16.high

## Event type enumeration
type
  EventType* {.importcpp: "daisy::UiEventQueue::Event::EventType", 
               size: sizeof(uint8).} = enum
    ## Invalid event (returned when queue is empty)
    invalid
    ## Button was pressed
    buttonPressed
    ## Button was released
    buttonReleased
    ## Encoder was turned
    encoderTurned
    ## Encoder activity changed (user started/stopped turning)
    encoderActivityChanged
    ## Potentiometer was moved
    potMoved
    ## Potentiometer activity changed (user started/stopped moving)
    potActivityChanged

## Activity state for controls
type
  ActivityType* {.importcpp: "daisy::UiEventQueue::Event::ActivityType",
                  size: sizeof(uint8).} = enum
    ## Control is not being used
    inactive
    ## Control is actively being used
    active

# Helper types for event union data - these mirror the C++ anonymous structs
type
  ButtonPressedData* {.bycopy.} = object
    id* {.importc.}: uint16
    numSuccessivePresses* {.importc.}: uint16
    isRetriggering* {.importc.}: bool

type
  ButtonReleasedData* {.bycopy.} = object
    id* {.importc.}: uint16

type
  EncoderTurnedData* {.bycopy.} = object
    id* {.importc.}: uint16
    increments* {.importc.}: int16
    stepsPerRev* {.importc.}: uint16

type
  EncoderActivityData* {.bycopy.} = object
    id* {.importc.}: uint16
    newActivityType* {.importc.}: ActivityType

type
  PotMovedData* {.bycopy.} = object
    id* {.importc.}: uint16
    newPosition* {.importc.}: cfloat

type
  PotActivityData* {.bycopy.} = object
    id* {.importc.}: uint16
    newActivityType* {.importc.}: ActivityType

## Event structure - wraps C++ Event with union
## Access the union field based on eventType (e.g. evt.asButtonPressed.id)
type
  Event* {.importcpp: "daisy::UiEventQueue::Event", bycopy.} = object
    ## Type of event (use this to determine which union field to access)
    eventType* {.importc: "type".}: EventType
    # Union fields - only one is valid at a time based on eventType
    asButtonPressed* {.importc.}: ButtonPressedData
    asButtonReleased* {.importc.}: ButtonReleasedData
    asEncoderTurned* {.importc.}: EncoderTurnedData
    asEncoderActivityChanged* {.importc.}: EncoderActivityData
    asPotMoved* {.importc.}: PotMovedData
    asPotActivityChanged* {.importc.}: PotActivityData

## UI Event Queue
type
  UiEventQueue* {.importcpp: "daisy::UiEventQueue", header: "ui/UiEventQueue.h".} = object
    ## Thread-safe FIFO queue for UI events.
    ## Safe to add events from interrupt handlers.

{.pop.}

# Constructor
proc initUiEventQueue*(): UiEventQueue {.importcpp: "daisy::UiEventQueue()".}
  ## Create new empty event queue

# Add event methods
proc addButtonPressed*(this: var UiEventQueue, buttonId: uint16, 
                      numSuccessivePresses: uint16, isRetriggering = false) 
  {.importcpp: "#.AddButtonPressed(#, #, #)".}
  ## Add button pressed event to queue
  ## 
  ## **Parameters:**
  ## - `buttonId` - Unique button identifier
  ## - `numSuccessivePresses` - Number of successive presses (1 = single, 2 = double, etc.)
  ## - `isRetriggering` - True if auto-retriggered while held down

proc addButtonReleased*(this: var UiEventQueue, buttonId: uint16) 
  {.importcpp: "#.AddButtonReleased(#)".}
  ## Add button released event to queue

proc addEncoderTurned*(this: var UiEventQueue, encoderId: uint16, 
                      increments: int16, stepsPerRev: uint16) 
  {.importcpp: "#.AddEncoderTurned(#, #, #)".}
  ## Add encoder turned event to queue
  ## 
  ## **Parameters:**
  ## - `encoderId` - Unique encoder identifier
  ## - `increments` - Number of steps (positive = CW, negative = CCW)
  ## - `stepsPerRev` - Total steps per full revolution

proc addEncoderActivityChanged*(this: var UiEventQueue, encoderId: uint16, isActive: bool) 
  {.importcpp: "#.AddEncoderActivityChanged(#, #)".}
  ## Add encoder activity changed event to queue
  ## 
  ## **Parameters:**
  ## - `encoderId` - Unique encoder identifier
  ## - `isActive` - True if user started turning, false if stopped

proc addPotMoved*(this: var UiEventQueue, potId: uint16, newPosition: cfloat) 
  {.importcpp: "#.AddPotMoved(#, #)".}
  ## Add potentiometer moved event to queue
  ## 
  ## **Parameters:**
  ## - `potId` - Unique potentiometer identifier
  ## - `newPosition` - New position (0.0 to 1.0)

proc addPotActivityChanged*(this: var UiEventQueue, potId: uint16, isActive: bool) 
  {.importcpp: "#.AddPotActivityChanged(#, #)".}
  ## Add potentiometer activity changed event to queue
  ## 
  ## **Parameters:**
  ## - `potId` - Unique potentiometer identifier
  ## - `isActive` - True if user started moving, false if stopped

# Queue access methods
proc getAndRemoveNextEvent*(this: var UiEventQueue): Event 
  {.importcpp: "#.GetAndRemoveNextEvent()".}
  ## Remove and return next event from queue.
  ## Returns event with `eventType = invalid` if queue is empty.

proc isQueueEmpty*(this: var UiEventQueue): bool 
  {.importcpp: "#.IsQueueEmpty()".}
  ## Returns true if no events are in the queue
