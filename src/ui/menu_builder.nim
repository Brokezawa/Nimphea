## Menu Builder DSL
## ================
##
## Nim-friendly, zero-allocation DSL for building menus declaratively.
##
## This module provides a compile-time macro `defineMenu` that generates
## a fully initialized `BuiltMenu` with static storage, ensuring memory safety
## and adhering to the project's zero-heap-allocation policy.
##
## **Features**:
## - Zero heap allocation (uses static arrays)
## - Compile-time validation
## - Type-safe integration with variables
## - Automatic C++ pointer handling
##
## **Example**:
## ```nim
## var volume: cfloat = 50.0
## var mute: bool = false
##
## # Generates 'mainMenu' variable in current scope
## defineMenu mainMenu:
##   value "Volume", volume, 0.0, 100.0
##   checkbox "Mute", mute
##   action "Save", saveSettings
##   submenu "Advanced", advancedMenu
##   close "Back"
## ```
##
## **Usage**:
## Pass `mainMenu` (or `mainMenu.menu`) to `ui.openPage()`.

import ../nimphea_menu
import ../nimphea_macros
import macros

useNimpheaModules(menu)

type
  BuiltMenu*[N: static int] = object
    ## Static container for menu and its items
    menu*: FullScreenItemMenu
    items*: array[N, MenuItemConfig]

# Converter allows passing BuiltMenu directly to procs expecting FullScreenItemMenu
converter toMenu*[N](bm: var BuiltMenu[N]): var FullScreenItemMenu = bm.menu
converter toMenuPtr*[N](bm: var BuiltMenu[N]): ptr FullScreenItemMenu = addr bm.menu

# ============================================================================
# DSL Macro
# ============================================================================

macro defineMenu*(varName: untyped, body: untyped): untyped =
  ## Define a statically allocated menu.
  ##
  ## **Parameters:**
  ## - `varName`: Name of the variable to declare
  ## - `body`: DSL block defining menu items
  ##
  ## **Generates:**
  ## - `var varName: BuiltMenu[N]`
  ## - Initialization code
  
  var initStmts = newStmtList()
  var count = 0
  
  # Create a temporary symbol for the items array access
  # We will generate assignments like: varName.items[0] = ...
  
  for stmt in body:
    if stmt.kind == nnkCall or stmt.kind == nnkCommand:
      let itemType = stmt[0].strVal
      let idx = newLit(count)
      
      case itemType
      of "action":
        # action "Text", callback
        let text = stmt[1]
        let cb = stmt[2]
        initStmts.add quote do:
          `varName`.items[`idx`] = createCallbackItem(`text`.cstring, `cb`, nil)
        count.inc
        
      of "checkbox":
        # checkbox "Text", boolVar
        let text = stmt[1]
        let val = stmt[2]
        initStmts.add quote do:
          `varName`.items[`idx`] = createCheckboxItem(`text`.cstring, addr `val`)
        count.inc
        
      of "value":
        # value "Text", mappedValue
        # value "Text", var, min, max (helper)
        let text = stmt[1]
        let val = stmt[2]
        
        # Check if using simplified range syntax or MappedValue object
        if stmt.len == 3:
          # Standard: value "Text", mappedValueObject
          initStmts.add quote do:
            `varName`.items[`idx`] = createValueItem(`text`.cstring, cast[ptr MappedValue](addr `val`))
        else:
          # Simplified: value "Text", floatVar, min, max
          # This requires creating a MappedValue helper? 
          # For zero-alloc, MappedValue must exist. 
          # We'll support only the MappedValue object form for v0.15.0 safety.
          error("Usage: value \"Text\", mappedValueVar")
        count.inc
        
      of "submenu":
        # submenu "Text", subMenuVar
        let text = stmt[1]
        let sub = stmt[2]
        initStmts.add quote do:
          `varName`.items[`idx`] = createOpenPageItem(`text`.cstring, cast[UiPagePtr](addr `sub`.menu))
        count.inc
        
      of "close", "back":
        # close "Text" or just close
        let text = if stmt.len > 1: stmt[1] else: newLit("Back")
        initStmts.add quote do:
          `varName`.items[`idx`] = createCloseItem(`text`.cstring)
        count.inc
        
      else:
        warning("Unknown menu item type: " & itemType)
  
  # Generate final code
  # var varName: BuiltMenu[N]
  # ... assignments ...
  # varName.menu.init(addr varName.items[0], N)
  
  let N = newLit(count)
  
  result = newStmtList()
  result.add quote do:
    var `varName`: BuiltMenu[`N`]
  
  result.add(initStmts)
  
  result.add quote do:
    `varName`.menu.init(addr `varName`.items[0], `N`.uint16)

# ============================================================================
# Value Helpers (Run-time / Setup-time)
# ============================================================================
# These return MappedFloatValue which can be assigned to a var

template linear*(min, max, initial: cfloat, unit: string = ""): MappedFloatValue =
  initMappedFloatValue(min, max, initial, lin, unit.cstring, 2.uint8, false)

template logarithmic*(min, max, initial: cfloat, unit: string = ""): MappedFloatValue =
  initMappedFloatValue(min, max, initial, log, unit.cstring, 2.uint8, false)
