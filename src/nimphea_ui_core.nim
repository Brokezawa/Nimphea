## UI Core System
## ===============
##
## This module wraps libDaisy's UI core system which manages page stacks,
## event routing, and display management for complex user interfaces.
##
## **Features:**
## - Page stack management (up to 32 pages)
## - Event routing from UiEventQueue to pages
## - Multiple canvas support (up to 8 displays)
## - Special control ID mapping (OK, Cancel, arrows, encoders, pots)
## - Automatic refresh rate management per canvas
## - Page visibility and focus management
## - Input muting with optional event queuing
##
## **Wrapped Header:** `ui/UI.h`
##
## Example - Simple UI with one page:
## ```nim
## import nimphea_ui_core
## import nimphea_ui_events
## import nimphea_menu
## 
## # Create event queue
## var eventQueue = initUiEventQueue()
## 
## # Configure special controls
## var controlIds = initUiSpecialControlIds()
## controlIds.okBttnId = 0
## controlIds.cancelBttnId = 1
## controlIds.upBttnId = 2
## controlIds.downBttnId = 3
## 
## # Create canvas descriptor
## var canvas = createCanvasDescriptor(0, displayPtr, 50)
## 
## # Initialize UI
## var ui = initUI()
## ui.init(eventQueue, controlIds, [canvas], 0)
## 
## # Add page
## ui.openPage(myPage)
## 
## # Main loop
## while true:
##   ui.process()  # Handle events and redraw
##   hw.delay(10)
## ```
##
## Example - Multi-page menu system:
## ```nim
## # Create menu pages
## var mainMenu: FullScreenItemMenu
## var settingsMenu: FullScreenItemMenu
## # ... configure menus ...
## 
## # Add main menu
## ui.openPage(cast[ptr UiPage](addr mainMenu))
## 
## # Later, open settings (adds to stack)
## ui.openPage(cast[ptr UiPage](addr settingsMenu))
## 
## # Close settings (returns to main)
## ui.closePage(cast[ptr UiPage](addr settingsMenu))
## ```

import nimphea
import nimphea_macros
import nimphea_ui_events
import nimphea_menu  # For UiPage type

# Include UI core headers and typedefs
useNimpheaModules(ui_core)

{.push header: "ui/UI.h".}

# ============================================================================
# Constants
# ============================================================================

## Maximum number of pages in the UI stack
const UI_MAX_PAGES* = 32

## Maximum number of canvases (displays) supported
const UI_MAX_CANVASES* = 8

## Invalid canvas ID constant
const INVALID_CANVAS_ID* = uint16.high

# ============================================================================
# Special Control IDs Configuration
# ============================================================================

## Configuration for special button/encoder/pot IDs
## Set to INVALID_*_ID constants if control is not available
type
  UiSpecialControlIds* {.importcpp: "daisy::UI::SpecialControlIds",
                          bycopy.} = object
    ## Function button ID (for coarse stepping)
    funcBttnId* {.importc.}: uint16
    ## OK/Enter button ID
    okBttnId* {.importc.}: uint16
    ## Cancel/Back button ID
    cancelBttnId* {.importc.}: uint16
    ## Up arrow button ID
    upBttnId* {.importc.}: uint16
    ## Down arrow button ID
    downBttnId* {.importc.}: uint16
    ## Left arrow button ID
    leftBttnId* {.importc.}: uint16
    ## Right arrow button ID
    rightBttnId* {.importc.}: uint16
    ## Menu navigation encoder ID
    menuEncoderId* {.importc.}: uint16
    ## Value editing encoder ID
    valueEncoderId* {.importc.}: uint16
    ## Value potentiometer/slider ID
    valuePotId* {.importc.}: uint16

# Constructor for SpecialControlIds
proc initUiSpecialControlIds*(): UiSpecialControlIds {.
  importcpp: "daisy::UI::SpecialControlIds()".}
  ## Create SpecialControlIds with all IDs set to invalid

# ============================================================================
# UI Core Class
# ============================================================================

## Main UI coordinator class
type
  UI* {.importcpp: "daisy::UI", header: "ui/UI.h".} = object

# UI constructor/destructor
proc initUI*(): UI {.importcpp: "daisy::UI()".}
  ## Create new UI instance

# UI initialization - needs special handling for initializer_list
# C++ Interop Workaround: std::initializer_list
# The daisy::UI::Init() method takes std::initializer_list<UiCanvasDescriptor> as a parameter.
# Nim cannot pass arrays to initializer_list parameters, so we use a C++ helper function
# that converts array + count into the required brace-initialization syntax.
# This is an approved emit use case similar to operator overloading (see AGENTS.md).
{.emit: """/*INCLUDESECTION*/
// Helper to initialize UI with canvas array
static inline void UI_Init_Helper(daisy::UI* ui, 
                           daisy::UiEventQueue& eventQueue,
                           const daisy::UI::SpecialControlIds& controlIds,
                           const daisy::UiCanvasDescriptor* canvases,
                           size_t numCanvases,
                           uint16_t primaryDisplayId) {
    // Build initializer_list from array by using brace initialization
    switch(numCanvases) {
        case 0: ui->Init(eventQueue, controlIds, {}, primaryDisplayId); break;
        case 1: ui->Init(eventQueue, controlIds, {canvases[0]}, primaryDisplayId); break;
        case 2: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1]}, primaryDisplayId); break;
        case 3: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2]}, primaryDisplayId); break;
        case 4: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2], canvases[3]}, primaryDisplayId); break;
        case 5: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2], canvases[3], canvases[4]}, primaryDisplayId); break;
        case 6: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2], canvases[3], canvases[4], canvases[5]}, primaryDisplayId); break;
        case 7: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2], canvases[3], canvases[4], canvases[5], canvases[6]}, primaryDisplayId); break;
        case 8: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1], canvases[2], canvases[3], canvases[4], canvases[5], canvases[6], canvases[7]}, primaryDisplayId); break;
        default: break; // Max 8 canvases supported
    }
}
""".}

proc cppUiInitHelper*(ui: ptr UI,
                     eventQueue: var UiEventQueue,
                     controlIds: UiSpecialControlIds,
                     canvases: ptr UiCanvasDescriptor,
                     numCanvases: csize_t,
                     primaryDisplayId: uint16) {.
  importcpp: "UI_Init_Helper(@)".}

proc init*(this: var UI,
          eventQueue: var UiEventQueue,
          controlIds: UiSpecialControlIds,
          canvases: openArray[UiCanvasDescriptor],
          primaryDisplayId: uint16 = INVALID_CANVAS_ID) {.inline.} =
  ## Initialize UI system
  ##
  ## **Parameters:**
  ## - `eventQueue` - UiEventQueue to read input events from
  ## - `controlIds` - Special control ID configuration
  ## - `canvases` - Array of canvas descriptors for displays
  ## - `primaryDisplayId` - Canvas ID for primary display (menus, etc.)
  if canvases.len > 0:
    cppUiInitHelper(addr this, eventQueue, controlIds,
                   unsafeAddr canvases[0], canvases.len.csize_t,
                   primaryDisplayId)

# UI core methods
proc process*(this: var UI) {.importcpp: "#.Process()".}
  ## Process events and update displays
  ## Call this regularly from main loop (low priority context)

proc mute*(this: var UI, shouldBeMuted: bool, queueEvents: bool = false) {.
  importcpp: "#.Mute(@)".}
  ## Mute/unmute user input processing
  ##
  ## **Parameters:**
  ## - `shouldBeMuted` - true to mute, false to unmute
  ## - `queueEvents` - If true, queue events while muted; if false, discard them

proc openPage*(this: var UI, page: var UiPage) {.importcpp: "#.OpenPage(@)".}
  ## Add page to top of page stack
  ## Page must remain alive until removed from UI

proc closePage*(this: var UI, page: var UiPage) {.importcpp: "#.ClosePage(@)".}
  ## Remove page from stack

proc getPrimaryOneBitGraphicsDisplayId*(this: var UI): uint16 {.
  importcpp: "#.GetPrimaryOneBitGraphicsDisplayId()".}
  ## Get canvas ID of primary graphics display
  ## Returns INVALID_CANVAS_ID if none configured

proc getSpecialControlIds*(this: var UI): UiSpecialControlIds {.
  importcpp: "#.GetSpecialControlIds()".}
  ## Get special control ID configuration

{.pop.}  # header pragma

# ============================================================================
# Canvas Descriptor Helpers
# ============================================================================

# Forward declare clear/flush function types
type
  CanvasClearFunc* = proc(canvas: ptr UiCanvasDescriptor) {.cdecl.}
  CanvasFlushFunc* = proc(canvas: ptr UiCanvasDescriptor) {.cdecl.}

proc createCanvasDescriptor*(id: uint8,
                             handle: pointer,
                             updateRateMs: uint32,
                             clearFunc: CanvasClearFunc = nil,
                             flushFunc: CanvasFlushFunc = nil,
                             screenSaverTimeout: uint32 = 0): UiCanvasDescriptor =
  ## Create a canvas descriptor
  ##
  ## **Parameters:**
  ## - `id` - Unique canvas ID
  ## - `handle` - Pointer to display object (cast to specific type in Draw)
  ## - `updateRateMs` - Refresh rate in milliseconds
  ## - `clearFunc` - Optional function to clear display before drawing
  ## - `flushFunc` - Optional function to flush/update display after drawing
  ## - `screenSaverTimeout` - Timeout in ms before screensaver (0=disabled)
  result.id = id
  result.handle = handle
  result.updateRateMs = updateRateMs
  result.screenSaverTimeOut = screenSaverTimeout
  result.screenSaverOn = false
  # Note: clearFunction_ and flushFunction_ are function pointers
  # They need to be set via emit or direct C++ if needed
  {.emit: [result, ".clearFunction_ = ", clearFunc, ";"].}
  {.emit: [result, ".flushFunction_ = ", flushFunc, ";"].}

# ============================================================================
# Helper Procs for Common Patterns
# ============================================================================

proc initUiWithDefaults*(eventQueue: var UiEventQueue,
                        okButton: uint16 = INVALID_BUTTON_ID,
                        cancelButton: uint16 = INVALID_BUTTON_ID,
                        upButton: uint16 = INVALID_BUTTON_ID,
                        downButton: uint16 = INVALID_BUTTON_ID): UI =
  ## Create and initialize UI with common button configuration
  ##
  ## Sets up a basic UI with optional OK, Cancel, Up, Down buttons.
  ## Other controls default to invalid IDs.
  result = initUI()
  
  var controlIds = initUiSpecialControlIds()
  controlIds.okBttnId = okButton
  controlIds.cancelBttnId = cancelButton
  controlIds.upBttnId = upButton
  controlIds.downBttnId = downButton
  
  # No canvases yet - add via init() call
  # This is just a helper to pre-configure controls

proc addButtonEvent*(eventQueue: var UiEventQueue,
                    ui: var UI,
                    buttonId: uint16,
                    isPressed: bool,
                    numPresses: uint16 = 1,
                    isRetriggering: bool = false) =
  ## Helper to add button event to queue
  ## Automatically uses correct event type based on state
  if isPressed:
    eventQueue.addButtonPressed(buttonId, numPresses, isRetriggering)
  else:
    eventQueue.addButtonReleased(buttonId)

proc addEncoderEvent*(eventQueue: var UiEventQueue,
                     encoderId: uint16,
                     increments: int16,
                     stepsPerRev: uint16 = 24) =
  ## Helper to add encoder rotation event
  eventQueue.addEncoderTurned(encoderId, increments, stepsPerRev)

proc addPotEvent*(eventQueue: var UiEventQueue,
                 potId: uint16,
                 position: cfloat) =
  ## Helper to add potentiometer movement event
  ## Position should be 0.0-1.0
  eventQueue.addPotMoved(potId, position)
