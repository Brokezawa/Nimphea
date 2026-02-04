## Menu System
## ===========
##
## This module wraps libDaisy's menu system for building hierarchical UI menus
## on small displays. It provides AbstractMenu as a base class and FullScreenItemMenu
## as a ready-to-use implementation for full-screen menus.
##
## **Features:**
## - Multiple menu item types (value, checkbox, callback, submenu, close)
## - Custom item support for specialized rendering
## - Flexible control schemes (buttons, encoders, potentiometers)
## - Orientation control (horizontal/vertical navigation)
## - Edit mode with step size control
## - MappedValue system for parameterized editing
##
## **Wrapped Headers:** `ui/AbstractMenu.h`, `ui/FullScreenItemMenu.h`, `util/MappedValue.h`
##
## Example - Simple menu with callback:
## ```nim
## import nimphea_menu
## import nimphea_ui_events
## 
## proc onActionTriggered(ctx: pointer) {.cdecl.} =
##   echo "Action triggered!"
## 
## var items = [
##   createCallbackItem("Do Something", onActionTriggered, nil),
##   createCloseItem("Close Menu")
## ]
## 
## var menu: FullScreenItemMenu
## menu.init(items[0].addr, 2)
## ```
##
## Example - Value editing menu:
## ```nim
## var volume = createMappedFloatValue(0.0, 1.0, 0.5, lin, "dB", 2)
## var isMuted = false
## 
## var items = [
##   createValueItem("Volume", addr volume),
##   createCheckboxItem("Mute", addr isMuted)
## ]
## 
## var menu: FullScreenItemMenu
## menu.init(items[0].addr, 2, leftRightSelectUpDownModify, true)
## ```
##
## Example - Hierarchical menu:
## ```nim
## var settingsPage: FullScreenItemMenu
## # ... configure settingsPage items ...
## 
## var mainItems = [
##   createOpenPageItem("Settings", addr settingsPage),
##   createCloseItem("Exit")
## ]
## ```

import nimphea
import nimphea_macros

# Include menu-related headers and typedefs
useNimpheaModules(menu)

{.push header: "ui/AbstractMenu.h".}

# ============================================================================
# Enums and Constants
# ============================================================================

## Menu orientation - controls which buttons navigate vs modify
type
  MenuOrientation* {.importcpp: "daisy::AbstractMenu::Orientation",
                     size: sizeof(cint).} = enum
    ## Left/Right buttons select items, Up/Down modify values
    leftRightSelectUpDownModify
    ## Up/Down buttons select items, Left/Right modify values
    upDownSelectLeftRightModify

## Menu item type enumeration
type
  MenuItemType* {.importcpp: "daisy::AbstractMenu::ItemType",
                  size: sizeof(cint).} = enum
    ## Displays text and calls callback when activated
    callbackFunctionItem
    ## Displays checkbox, toggles boolean value
    checkboxItem
    ## Displays name and editable value (MappedValue)
    valueItem
    ## Opens another UiPage (submenu)
    openUiPageItem
    ## Closes the menu when selected
    closeMenuItem
    ## Custom user-defined item
    customItem

## Arrow button type (from UI.h)
type
  ArrowButtonType* {.importcpp: "daisy::ArrowButtonType",
                     size: sizeof(cint).} = enum
    ## Left arrow button
    left = 0
    ## Right arrow button
    right
    ## Up arrow button
    up
    ## Down arrow button
    down

# ============================================================================
# UI System Types
# ============================================================================

## Canvas descriptor for UI drawing
type
  UiCanvasDescriptor* {.importcpp: "daisy::UiCanvasDescriptor",
                        header: "ui/UI.h", bycopy.} = object
    ## Canvas ID number
    id* {.importc: "id_".}: uint8
    ## Pointer to canvas handle (display object)
    handle* {.importc: "handle_".}: pointer
    ## Update rate in milliseconds
    updateRateMs* {.importc: "updateRateMs_".}: uint32
    ## Screen saver timeout (0 = disabled)
    screenSaverTimeOut* {.importc.}: uint32
    ## Screen saver active flag
    screenSaverOn* {.importc.}: bool

## Base class for UI pages
type
  UiPage* {.importcpp: "daisy::UiPage", header: "ui/UI.h", inheritable.} = object

# Forward declarations for pointers
type
  UiPagePtr* = ptr UiPage

# ============================================================================
# MappedValue System
# ============================================================================

## Mapping function type for float values
type
  MappedValueMapping* {.importcpp: "daisy::MappedFloatValue::Mapping",
                        size: sizeof(cint).} = enum
    ## Linear mapping
    lin
    ## Logarithmic mapping (min/max/default must be > 0)
    log
    ## Power-of-2 mapping
    pow2

## Base class for mapped values (abstract)
type
  MappedValue* {.importcpp: "daisy::MappedValue",
                 header: "util/MappedValue.h", inheritable.} = object

## Float value with mapping function
type
  MappedFloatValue* {.importcpp: "daisy::MappedFloatValue",
                      header: "util/MappedValue.h".} = object of MappedValue

# MappedFloatValue constructor
proc initMappedFloatValue*(minVal, maxVal, defaultVal: cfloat,
                          mapping: MappedValueMapping = lin,
                          unitStr: cstring = "",
                          numDecimals: uint8 = 1,
                          forceSign: bool = false): MappedFloatValue {.
  importcpp: "daisy::MappedFloatValue(@)", constructor.}

# MappedFloatValue methods
proc get*(this: var MappedFloatValue): cfloat {.importcpp: "#.Get()".}
  ## Get current value

proc set*(this: var MappedFloatValue, newValue: cfloat) {.importcpp: "#.Set(@)".}
  ## Set value (clamped to valid range)

proc getAs0to1*(this: var MappedFloatValue): cfloat {.importcpp: "#.GetAs0to1()".}
  ## Get normalized value (0.0-1.0)

proc setFrom0to1*(this: var MappedFloatValue, normalizedValue: cfloat) {.
  importcpp: "#.SetFrom0to1(@)".}
  ## Set from normalized value (0.0-1.0)

proc step*(this: var MappedFloatValue, numStepsUp: int16, useCoarseStep: bool) {.
  importcpp: "#.Step(@)".}
  ## Step value up/down by increments

proc resetToDefault*(this: var MappedFloatValue) {.importcpp: "#.ResetToDefault()".}
  ## Reset to default value

# Helper for Nim ergonomics
proc createMappedFloatValue*(minVal, maxVal, defaultVal: float,
                            mapping: MappedValueMapping = lin,
                            unitStr: string = "",
                            numDecimals: int = 1,
                            forceSign: bool = false): MappedFloatValue =
  ## Create a MappedFloatValue with Nim-friendly types
  initMappedFloatValue(minVal.cfloat, maxVal.cfloat, defaultVal.cfloat,
                       mapping, unitStr.cstring, numDecimals.uint8, forceSign)

# ============================================================================
# Menu Item Configuration
# ============================================================================

## Menu item configuration (union type)
type
  MenuItemConfig* {.importcpp: "daisy::AbstractMenu::ItemConfig",
                    bycopy.} = object
    ## Item type
    `type`* {.importc.}: MenuItemType
    ## Display text/name
    text* {.importc.}: cstring

# Note: The union fields are accessed through helper procs below
# C++ uses anonymous unions which Nim can't directly represent

# Helper procs to create MenuItemConfig for different types
proc createCallbackItem*(text: cstring,
                        callback: proc(ctx: pointer) {.cdecl.},
                        context: pointer = nil): MenuItemConfig {.importcpp: """
  [&]() {
    daisy::AbstractMenu::ItemConfig item;
    item.type = daisy::AbstractMenu::ItemType::callbackFunctionItem;
    item.text = #;
    item.asCallbackFunctionItem.callbackFunction = #;
    item.asCallbackFunctionItem.context = #;
    return item;
  }()
""".}
  ## Create a callback function menu item

proc createCheckboxItem*(text: cstring, valuePtr: ptr bool): MenuItemConfig {.importcpp: """
  [&]() {
    daisy::AbstractMenu::ItemConfig item;
    item.type = daisy::AbstractMenu::ItemType::checkboxItem;
    item.text = #;
    item.asCheckboxItem.valueToModify = #;
    return item;
  }()
""".}
  ## Create a checkbox menu item

proc createValueItem*(text: cstring, valuePtr: ptr MappedValue): MenuItemConfig {.importcpp: """
  [&]() {
    daisy::AbstractMenu::ItemConfig item;
    item.type = daisy::AbstractMenu::ItemType::valueItem;
    item.text = #;
    item.asMappedValueItem.valueToModify = #;
    return item;
  }()
""".}
  ## Create a value editing menu item

proc createOpenPageItem*(text: cstring, pagePtr: UiPagePtr): MenuItemConfig {.importcpp: """
  [&]() {
    daisy::AbstractMenu::ItemConfig item;
    item.type = daisy::AbstractMenu::ItemType::openUiPageItem;
    item.text = #;
    item.asOpenUiPageItem.pageToOpen = #;
    return item;
  }()
""".}
  ## Create a submenu/page opening item

proc createCloseItem*(text: cstring): MenuItemConfig {.importcpp: """
  [&]() {
    daisy::AbstractMenu::ItemConfig item;
    item.type = daisy::AbstractMenu::ItemType::closeMenuItem;
    item.text = #;
    return item;
  }()
""".}
  ## Create a menu close item

# ============================================================================
# Custom Menu Item Base Class
# ============================================================================

## Base class for custom menu items
type
  CustomMenuItem* {.importcpp: "daisy::AbstractMenu::CustomItem",
                    header: "ui/AbstractMenu.h".} = object

# CustomMenuItem virtual methods (advanced usage)
# Users can implement these in C++ and wrap as needed

# ============================================================================
# AbstractMenu Base Class
# ============================================================================

## Abstract base class for menu pages
type
  AbstractMenu* {.importcpp: "daisy::AbstractMenu",
                  header: "ui/AbstractMenu.h".} = object of UiPage

# AbstractMenu query methods
proc getNumItems*(this: var AbstractMenu): uint16 {.importcpp: "#.GetNumItems()".}
  ## Get total number of items in menu

proc getItem*(this: var AbstractMenu, itemIdx: uint16): MenuItemConfig {.
  importcpp: "#.GetItem(@)".}
  ## Get item configuration by index

proc selectItem*(this: var AbstractMenu, itemIdx: uint16) {.importcpp: "#.SelectItem(@)".}
  ## Select a specific item by index

proc getSelectedItemIdx*(this: var AbstractMenu): int16 {.
  importcpp: "#.GetSelectedItemIdx()".}
  ## Get currently selected item index (-1 if none)

# AbstractMenu event handlers (inherited from UiPage)
proc onOkayButton*(this: var AbstractMenu, numPresses: uint8,
                  isRetriggering: bool): bool {.importcpp: "#.OnOkayButton(@)".}
  ## Handle OK button press

proc onCancelButton*(this: var AbstractMenu, numPresses: uint8,
                    isRetriggering: bool): bool {.importcpp: "#.OnCancelButton(@)".}
  ## Handle cancel button press

proc onArrowButton*(this: var AbstractMenu, arrowType: ArrowButtonType,
                   numPresses: uint8, isRetriggering: bool): bool {.
  importcpp: "#.OnArrowButton(@)".}
  ## Handle arrow button press

proc onFunctionButton*(this: var AbstractMenu, numPresses: uint8,
                      isRetriggering: bool): bool {.importcpp: "#.OnFunctionButton(@)".}
  ## Handle function button press (for coarse stepping)

proc onMenuEncoderTurned*(this: var AbstractMenu, turns: int16,
                         stepsPerRev: uint16): bool {.
  importcpp: "#.OnMenuEncoderTurned(@)".}
  ## Handle menu encoder rotation

proc onValueEncoderTurned*(this: var AbstractMenu, turns: int16,
                          stepsPerRev: uint16): bool {.
  importcpp: "#.OnValueEncoderTurned(@)".}
  ## Handle value encoder rotation

proc onValuePotMoved*(this: var AbstractMenu, newPosition: cfloat): bool {.
  importcpp: "#.OnValuePotMoved(@)".}
  ## Handle value potentiometer movement

proc onShow*(this: var AbstractMenu) {.importcpp: "#.OnShow()".}
  ## Called when page is shown

# ============================================================================
# FullScreenItemMenu Implementation
# ============================================================================

## Full-screen menu implementation for small displays
type
  FullScreenItemMenu* {.importcpp: "daisy::FullScreenItemMenu",
                        header: "ui/FullScreenItemMenu.h".} = object of AbstractMenu

# FullScreenItemMenu initialization
proc init*(this: var FullScreenItemMenu,
          items: ptr MenuItemConfig,
          numItems: uint16,
          orientation: MenuOrientation = leftRightSelectUpDownModify,
          allowEntering: bool = true) {.importcpp: "#.Init(@)".}
  ## Initialize menu with items array
  ##
  ## **Parameters:**
  ## - `items` - Array of MenuItemConfig
  ## - `numItems` - Number of items in array
  ## - `orientation` - Button mapping (select vs modify)
  ## - `allowEntering` - Allow OK button to enter edit mode

proc setOneBitGraphicsDisplayToDrawTo*(this: var FullScreenItemMenu,
                                       canvasId: uint16) {.
  importcpp: "#.SetOneBitGraphicsDisplayToDrawTo(@)".}
  ## Set which canvas this menu draws to (default: primary display)

proc draw*(this: var FullScreenItemMenu, canvas: UiCanvasDescriptor) {.
  importcpp: "#.Draw(@)".}
  ## Draw menu to canvas (called by UI system)

{.pop.}  # header pragma

# ============================================================================
# Nim Helper Functions
# ============================================================================

proc createValueItemFloat*(text: string, valuePtr: ptr MappedFloatValue): MenuItemConfig =
  ## Nim-friendly wrapper for creating float value items
  createValueItem(text.cstring, cast[ptr MappedValue](valuePtr))

proc initFullScreenMenu*(items: var openArray[MenuItemConfig],
                        orientation: MenuOrientation = leftRightSelectUpDownModify,
                        allowEntering: bool = true): FullScreenItemMenu =
  ## Create and initialize a full-screen menu from array
  result.init(items[0].addr, items.len.uint16, orientation, allowEntering)
