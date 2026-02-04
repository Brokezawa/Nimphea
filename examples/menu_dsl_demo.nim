## Menu Builder DSL Demo
## =====================
##
## Demonstrates the zero-allocation menu builder DSL.
## This example creates a settings menu with Volume, Frequency, and Mute controls.
##
## **Hardware:**
## - Daisy Seed (or any board with OLED)
## - SH1106 OLED (default) or SSD1306
## - 5 Buttons (OK, Cancel, Up, Down, Function)
##
## **Concepts:**
## - `defineMenu` macro for static menu generation
## - `linear`/`logarithmic` value helpers
## - Binding variables to menu items

import ../src/nimphea
import ../src/nimphea_macros
import ../src/per/i2c
import ../src/dev/oled_sh1106
import ../src/nimphea_ui_core
import ../src/nimphea_ui_events
import ../src/nimphea_ui_controls
import ../src/nimphea_menu as menu_mod
import ../src/ui/menu_builder

useNimpheaNamespace()
useNimpheaModules(sh1106, ui_core, ui, menu)

# ============================================================================
# Hardware & Globals
# ============================================================================

var hw: DaisySeed
var display: SH1106I2c128x64
var uiSystem: UI
var eventQueue: UiEventQueue
var controlIds: UiSpecialControlIds

# ============================================================================
# C++ Helper for UI Init
# ============================================================================
# Workaround: Define UI_Init_Helper locally because it's not exported via header
{.emit: """/*INCLUDESECTION*/
static inline void UI_Init_Helper(daisy::UI* ui, 
                           daisy::UiEventQueue& eventQueue,
                           const daisy::UI::SpecialControlIds& controlIds,
                           const daisy::UiCanvasDescriptor* canvases,
                           size_t numCanvases,
                           uint16_t primaryDisplayId) {
    switch(numCanvases) {
        case 0: ui->Init(eventQueue, controlIds, {}, primaryDisplayId); break;
        case 1: ui->Init(eventQueue, controlIds, {canvases[0]}, primaryDisplayId); break;
        case 2: ui->Init(eventQueue, controlIds, {canvases[0], canvases[1]}, primaryDisplayId); break;
        default: break;
    }
}
""".}

# Menu Variables
var volume = linear(0.0, 100.0, 50.0, "%")
var freq = logarithmic(20.0, 20000.0, 440.0, "Hz")
var isMuted = false

# Callback
proc onSave(ctx: pointer) {.cdecl.} =
  # Simulate saving
  discard

# ============================================================================
# Menu Definition (Zero Allocation)
# ============================================================================

defineMenu mainMenu:
  value "Volume", volume
  value "Frequency", freq
  checkbox "Mute", isMuted
  action "Save Settings", onSave
  close "Exit"

# ============================================================================
# Main Loop
# ============================================================================

proc main() =
  hw = initDaisy()
  
  # Initialize Display (uses default I2C1 pins: SCL=PB8, SDA=PB9)
  display = initSH1106I2c(128, 64)
  
  # Initialize UI
  eventQueue = initUiEventQueue()
  controlIds = initUiSpecialControlIds()
  # Map buttons (D0=OK, D1=Cancel, D2=Up, D3=Down)
  controlIds.okBttnId = 0
  controlIds.cancelBttnId = 1
  controlIds.upBttnId = 2
  controlIds.downBttnId = 3
  
  var canvas = createCanvasDescriptor(0, addr display, 50) # 50Hz refresh
  
  # Initialize UI System (using the workaround helper for std::initializer_list)
  cppUiInitHelper(addr uiSystem, eventQueue, controlIds, addr canvas, 1, 0)
  
  # Open the menu
  uiSystem.openPage(mainMenu.menu)
  
  while true:
    # process inputs/events would go here
    uiSystem.process()
    hw.delay(10)

when isMainModule:
  main()
