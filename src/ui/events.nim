## Event Helpers
## =============
##
## Nim-friendly event handling utilities providing closure-based APIs
## over the low-level UiEventQueue system.
##
## This module provides a higher-level, more Nim-idiomatic way to handle
## UI events using closures and callbacks instead of polling the event queue.

import ../nimphea_ui_events

type
  ButtonHandler* = proc(id: uint16, presses: uint16) {.closure.}
    ## Closure type for button press events
  
  ButtonReleaseHandler* = proc(id: uint16) {.closure.}
    ## Closure type for button release events
  
  EncoderHandler* = proc(id: uint16, increment: int32, velocity: int32) {.closure.}
    ## Closure type for encoder turn events
  
  PotHandler* = proc(id: uint16, value: float32) {.closure.}
    ## Closure type for potentiometer change events

type
  EventDispatcher* = object
    ## Event dispatcher that manages closure-based event handlers
    queue: ptr UiEventQueue
    buttonHandlers: seq[ButtonHandler]
    buttonReleaseHandlers: seq[ButtonReleaseHandler]
    encoderHandlers: seq[EncoderHandler]
    potHandlers: seq[PotHandler]

proc createEventDispatcher*(queue: var UiEventQueue): EventDispatcher =
  ## Create a new event dispatcher for the given event queue
  result.queue = addr queue
  result.buttonHandlers = @[]
  result.buttonReleaseHandlers = @[]
  result.encoderHandlers = @[]
  result.potHandlers = @[]

proc onButtonPress*(dispatcher: var EventDispatcher, handler: ButtonHandler) =
  ## Register a handler for button press events
  ## 
  ## **Example**:
  ## ```nim
  ## dispatcher.onButtonPress proc(id: uint16, presses: uint16) =
  ##   echo "Button ", id, " pressed ", presses, " times"
  ## ```
  dispatcher.buttonHandlers.add(handler)

proc onButtonRelease*(dispatcher: var EventDispatcher, handler: ButtonReleaseHandler) =
  ## Register a handler for button release events
  dispatcher.buttonReleaseHandlers.add(handler)

proc onEncoder*(dispatcher: var EventDispatcher, handler: EncoderHandler) =
  ## Register a handler for encoder turn events
  ## 
  ## **Example**:
  ## ```nim
  ## dispatcher.onEncoder proc(id: uint16, increment: int32, velocity: int32) =
  ##   volume += increment
  ##   if volume < 0: volume = 0
  ##   if volume > 100: volume = 100
  ## ```
  dispatcher.encoderHandlers.add(handler)

proc onPot*(dispatcher: var EventDispatcher, handler: PotHandler) =
  ## Register a handler for potentiometer change events
  dispatcher.potHandlers.add(handler)

proc process*(dispatcher: var EventDispatcher) =
  ## Process all events in the queue and call registered handlers
  ## Call this in your main loop
  while not dispatcher.queue[].isQueueEmpty():
    let event = dispatcher.queue[].getAndRemoveNextEvent()
    case event.eventType
    of buttonPressed:
      for handler in dispatcher.buttonHandlers:
        handler(event.asButtonPressed.id, event.asButtonPressed.numSuccessivePresses)
    of buttonReleased:
      for handler in dispatcher.buttonReleaseHandlers:
        handler(event.asButtonReleased.id)
    of encoderTurned:
      for handler in dispatcher.encoderHandlers:
        handler(event.asEncoderTurned.id, event.asEncoderTurned.increments.int32, 0)
    of potMoved:
      for handler in dispatcher.potHandlers:
        handler(event.asPotMoved.id, event.asPotMoved.newPosition)
    else:
      discard

# Convenience template for event handling in main loop
template processEvents*(dispatcher: var EventDispatcher, body: untyped) =
  ## Process events and execute custom code
  ## 
  ## **Example**:
  ## ```nim
  ## dispatcher.processEvents:
  ##   # Custom per-frame logic here
  ##   updateDisplay()
  ## ```
  dispatcher.process()
  body

# Specific button ID handlers for common patterns
type
  SpecificButtonHandlers* = object
    ## Handlers for specific button IDs
    handlers: array[16, ButtonHandler]  # Support up to 16 buttons

proc createSpecificButtonHandlers*(): SpecificButtonHandlers =
  ## Create handlers for specific button IDs
  discard

proc onButton*(handlers: var SpecificButtonHandlers, buttonId: uint16, 
               handler: ButtonHandler) =
  ## Register handler for a specific button ID
  ## 
  ## **Example**:
  ## ```nim
  ## var buttons = createSpecificButtonHandlers()
  ## buttons.onButton(0, proc(id: uint16, presses: uint16) =
  ##   echo "OK button pressed"
  ## )
  ## ```
  if buttonId < 16:
    handlers.handlers[buttonId] = handler

proc dispatch*(handlers: var SpecificButtonHandlers, id: uint16, presses: uint16) =
  ## Dispatch button event to registered handler
  if id < 16 and handlers.handlers[id] != nil:
    handlers.handlers[id](id, presses)

# Chain multiple handlers together
proc chain*(handlers: varargs[ButtonHandler]): ButtonHandler =
  ## Chain multiple button handlers together
  ## 
  ## **Example**:
  ## ```nim
  ## dispatcher.onButtonPress chain(
  ##   proc(id, presses: auto) = echo "Handler 1",
  ##   proc(id, presses: auto) = echo "Handler 2"
  ## )
  ## ```
  result = proc(id: uint16, presses: uint16) =
    for h in handlers:
      if h != nil:
        h(id, presses)
