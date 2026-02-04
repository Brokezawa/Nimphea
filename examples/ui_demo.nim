## Comprehensive UI Framework Demo
## ================================
##
## This example demonstrates all UI framework features including:
## - Multi-page navigation with custom pages
## - Full menu system with all item types
## - Event dispatcher for clean event handling
## - Display helpers for graphics
## - Button/encoder/pot monitoring
## - File table integration (displays SD card files)
##
## **Hardware Setup:**
## - SH1106 128x64 OLED display on I2C1 (SCL=B8, SDA=B9)
## - 5 buttons:
##   - OK button on D0 (confirm/select)
##   - Cancel button on D1 (back/cancel)
##   - Up button on D2
##   - Down button on D3
##   - Menu button on D4 (open main menu)
## - Optional: Rotary encoder on D10/D11
## - Optional: Potentiometer on ADC0 (A0)
## - LED indicates UI activity
##
## **UI Structure:**
## - Main Menu:
##   - Audio Settings Submenu (volume, gain, mute)
##   - Display Settings (brightness, contrast)
##   - System Info Page (custom page with stats)
##   - File Browser (using FileTable if available)
##   - About Page
##
## **Controls:**
## - Menu button: Open/close main menu
## - Up/Down: Navigate menus or adjust values
## - OK: Select/confirm
## - Cancel: Go back
## - Encoder: Fast navigation/value adjustment
## - Pot: Direct value control

import ../src/nimphea
import ../src/nimphea_macros
import ../src/dev/oled_sh1106
import ../src/nimphea_ui_events
import ../src/nimphea_ui_controls
import ../src/nimphea_ui_core
import ../src/nimphea_menu
import ../src/nimphea_filetable

useNimpheaNamespace()
useNimpheaModules(sh1106, file_table)

# UI Init wrapper for std::initializer_list
{.emit: """/*INCLUDESECTION*/
static inline void UI_Init_Wrapper(daisy::UI* ui, 
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

proc uiInitWrapper(ui: ptr UI, eventQueue: var UiEventQueue, 
                   controlIds: UiSpecialControlIds,
                   canvases: ptr UiCanvasDescriptor, numCanvases: csize_t,
                   primaryDisplayId: uint16) {.importcpp: "UI_Init_Wrapper(@)".}

# ============================================================================
# Custom Page Types
# ============================================================================

# Forward declarations for custom pages
type
  SystemInfoPage {.importcpp, incompleteStruct.} = object
  FileBrowserPage {.importcpp, incompleteStruct.} = object
  AboutPage {.importcpp, incompleteStruct.} = object

# ============================================================================
# Global State
# ============================================================================

# Hardware
var daisy: DaisySeed
var display: SH1106I2c128x64

# UI system
var eventQueue: UiEventQueue
var ui: UI

# Controls
var btnOk, btnCancel, btnUp, btnDown, btnMenu: GPIO

# Menu system
var mainMenu: ptr FullScreenItemMenu

# Menu values (direct access, no submenus for simplicity)
var volumeValue: ptr MappedFloatValue
var gainValue: ptr MappedFloatValue
var brightnessValue: ptr MappedFloatValue
var isMuted: bool = false

# Custom pages
var sysInfoPage: ptr SystemInfoPage
var fileBrowserPage: ptr FileBrowserPage
var aboutPage: ptr AboutPage

# File table (for file browser)
var fileTable: FileTable32

# State tracking
var isInMenu: bool = false
var currentPage: int = 0  # 0=none, 1=sysinfo, 2=files, 3=about
var frameCounter: int = 0

# ============================================================================
# Custom Page Declarations
# ============================================================================

# Forward declare in TYPESECTION
{.emit: """/*TYPESECTION*/
struct SystemInfoPage;
struct FileBrowserPage;
struct AboutPage;
""".}

# Declare Nim callbacks
proc sysInfoPageDraw(page: ptr SystemInfoPage, canvas: ptr UiCanvasDescriptor) {.exportc: "SystemInfoPage_Draw", cdecl.}
proc sysInfoPageOnCancel(page: ptr SystemInfoPage, numPresses: uint8, isRetriggering: bool): bool {.exportc: "SystemInfoPage_OnCancel", cdecl.}

proc fileBrowserPageDraw(page: ptr FileBrowserPage, canvas: ptr UiCanvasDescriptor) {.exportc: "FileBrowserPage_Draw", cdecl.}
proc fileBrowserPageOnCancel(page: ptr FileBrowserPage, numPresses: uint8, isRetriggering: bool): bool {.exportc: "FileBrowserPage_OnCancel", cdecl.}
proc fileBrowserPageOnArrow(page: ptr FileBrowserPage, arrowType: ArrowButtonType, numPresses: uint8, isRetriggering: bool): bool {.exportc: "FileBrowserPage_OnArrow", cdecl.}

proc aboutPageDraw(page: ptr AboutPage, canvas: ptr UiCanvasDescriptor) {.exportc: "AboutPage_Draw", cdecl.}
proc aboutPageOnCancel(page: ptr AboutPage, numPresses: uint8, isRetriggering: bool): bool {.exportc: "AboutPage_OnCancel", cdecl.}

# Define C++ page structures
{.emit: """
// System Info Page - shows memory, uptime, etc.
struct SystemInfoPage : public daisy::UiPage {
    int updateCounter = 0;
    
    void Draw(const daisy::UiCanvasDescriptor& canvas) override {
        SystemInfoPage_Draw(this, const_cast<daisy::UiCanvasDescriptor*>(&canvas));
    }
    
    bool OnCancelButton(uint8_t numberOfPresses, bool isRetriggering) override {
        return SystemInfoPage_OnCancel(this, numberOfPresses, isRetriggering);
    }
};

// File Browser Page - shows files from SD card
struct FileBrowserPage : public daisy::UiPage {
    int selectedIndex = 0;
    int scrollOffset = 0;
    
    void Draw(const daisy::UiCanvasDescriptor& canvas) override {
        FileBrowserPage_Draw(this, const_cast<daisy::UiCanvasDescriptor*>(&canvas));
    }
    
    bool OnCancelButton(uint8_t numberOfPresses, bool isRetriggering) override {
        return FileBrowserPage_OnCancel(this, numberOfPresses, isRetriggering);
    }
    
    bool OnArrowButton(daisy::ArrowButtonType arrowType, uint8_t numberOfPresses, bool isRetriggering) override {
        return FileBrowserPage_OnArrow(this, arrowType, numberOfPresses, isRetriggering);
    }
};

// About Page - shows version info, credits
struct AboutPage : public daisy::UiPage {
    int animFrame = 0;
    
    void Draw(const daisy::UiCanvasDescriptor& canvas) override {
        AboutPage_Draw(this, const_cast<daisy::UiCanvasDescriptor*>(&canvas));
    }
    
    bool OnCancelButton(uint8_t numberOfPresses, bool isRetriggering) override {
        return AboutPage_OnCancel(this, numberOfPresses, isRetriggering);
    }
};
""".}

# ============================================================================
# Custom Page Implementations
# ============================================================================

proc sysInfoPageDraw(page: ptr SystemInfoPage, canvas: ptr UiCanvasDescriptor) =
  ## Draw system information page
  if canvas.id == 0:
    let disp = cast[ptr SH1106I2c128x64](canvas.handle)
    disp[].fill(false)
    
    # Title bar
    disp[].fillRect(0, 0, 128, 10, true)
    disp[].drawRect(2, 2, 124, 6, false)  # Title text placeholder
    
    # System stats (simulated with bars/indicators)
    # Memory usage bar
    disp[].drawRect(4, 15, 120, 8, true)
    disp[].fillRect(5, 16, 80, 6, true)  # 66% memory usage
    
    # CPU usage bar
    disp[].drawRect(4, 28, 120, 8, true)
    disp[].fillRect(5, 29, 50, 6, true)  # 41% CPU usage
    
    # Uptime indicator (animated dots)
    var updateCounter: cint
    {.emit: "`updateCounter` = `page`->updateCounter;".}
    
    let dotCount = (updateCounter div 5) mod 4
    for i in 0..2:
      if i < dotCount:
        disp[].fillRect(10 + i * 10, 45, 6, 6, true)
      else:
        disp[].drawRect(10 + i * 10, 45, 6, 6, true)
    
    # Footer hint
    disp[].drawRect(0, 56, 128, 8, true)
    disp[].fillRect(2, 58, 20, 4, false)  # "Back" indicator
    
    disp[].update()
  
  {.emit: "`page`->updateCounter++;".}

proc sysInfoPageOnCancel(page: ptr SystemInfoPage, numPresses: uint8, isRetriggering: bool): bool =
  ## Close system info page
  result = true

proc fileBrowserPageDraw(page: ptr FileBrowserPage, canvas: ptr UiCanvasDescriptor) =
  ## Draw file browser page
  if canvas.id == 0:
    let disp = cast[ptr SH1106I2c128x64](canvas.handle)
    disp[].fill(false)
    
    # Title
    disp[].fillRect(0, 0, 128, 8, true)
    
    # Get file count
    let fileCount = fileTable.getNumFiles()
    
    if fileCount == 0:
      # No files message (draw centered box)
      disp[].drawRect(30, 25, 68, 14, true)
      disp[].fillRect(32, 27, 64, 10, false)  # "No files" placeholder
    else:
      # Get current selection
      var selectedIdx: cint
      var scrollOfs: cint
      {.emit: """
      `selectedIdx` = `page`->selectedIndex;
      `scrollOfs` = `page`->scrollOffset;
      """.}
      
      # Draw file list (up to 6 files visible)
      let maxVisible = 6
      let startIdx = scrollOfs
      let endIdx = min(fileCount.int, startIdx + maxVisible)
      
      for i in startIdx..<endIdx:
        let y = 10 + (i - startIdx) * 9
        
        # Selection indicator
        if i == selectedIdx:
          disp[].fillRect(0, y, 4, 8, true)
        
        # File name placeholder (just a rectangle)
        disp[].drawRect(6, y, 118, 8, true)
        disp[].fillRect(8, y + 2, 40, 4, true)  # File name
    
    # Scroll indicators
    if fileCount > 6:
      var selectedIdx: cint
      {.emit: "`selectedIdx` = `page`->selectedIndex;".}
      
      if selectedIdx > 0:
        disp[].fillRect(0, 56, 4, 8, true)  # Up arrow
      if selectedIdx < fileCount.cint - 1:
        disp[].fillRect(124, 56, 4, 8, true)  # Down arrow
    
    disp[].update()

proc fileBrowserPageOnCancel(page: ptr FileBrowserPage, numPresses: uint8, isRetriggering: bool): bool =
  ## Close file browser
  result = true

proc fileBrowserPageOnArrow(page: ptr FileBrowserPage, arrowType: ArrowButtonType, numPresses: uint8, isRetriggering: bool): bool =
  ## Navigate file list
  var selectedIdx: cint
  var scrollOfs: cint
  {.emit: """
  `selectedIdx` = `page`->selectedIndex;
  `scrollOfs` = `page`->scrollOffset;
  """.}
  
  let fileCount = fileTable.getNumFiles().cint
  
  case arrowType
  of up:
    if selectedIdx > 0:
      dec selectedIdx
      # Auto-scroll
      if selectedIdx < scrollOfs:
        scrollOfs = selectedIdx
  of down:
    if selectedIdx < fileCount - 1:
      inc selectedIdx
      # Auto-scroll
      if selectedIdx >= scrollOfs + 6:
        scrollOfs = selectedIdx - 5
  else:
    discard
  
  {.emit: """
  `page`->selectedIndex = `selectedIdx`;
  `page`->scrollOffset = `scrollOfs`;
  """.}
  
  result = true

proc aboutPageDraw(page: ptr AboutPage, canvas: ptr UiCanvasDescriptor) =
  ## Draw about page with version info
  if canvas.id == 0:
    let disp = cast[ptr SH1106I2c128x64](canvas.handle)
    disp[].fill(false)
    
    # Logo/title area
    disp[].fillRect(20, 5, 88, 20, true)
    disp[].drawRect(22, 7, 84, 16, false)
    disp[].fillRect(40, 10, 48, 10, false)  # "Nimphea" placeholder
    
    # Version info bars
    disp[].drawRect(30, 30, 68, 6, true)
    disp[].fillRect(32, 32, 40, 2, true)  # "v0.15.0" placeholder
    
    # Animated footer
    var animFrame: cint
    {.emit: "`animFrame` = `page`->animFrame;".}
    
    let offset = (animFrame div 4) mod 128
    for i in 0..3:
      let x = (i * 32 + offset) mod 128
      disp[].fillRect(x, 58, 16, 6, true)
    
    disp[].update()
  
  {.emit: "`page`->animFrame++;".}

proc aboutPageOnCancel(page: ptr AboutPage, numPresses: uint8, isRetriggering: bool): bool =
  ## Close about page
  result = true

# Page constructors
proc cppNewSystemInfoPage(): ptr SystemInfoPage {.importcpp: "new SystemInfoPage()".}
proc cppNewFileBrowserPage(): ptr FileBrowserPage {.importcpp: "new FileBrowserPage()".}
proc cppNewAboutPage(): ptr AboutPage {.importcpp: "new AboutPage()".}

# Page helpers
proc openSysInfoPage(ui: var UI, page: ptr SystemInfoPage) =
  {.emit: "`ui`.OpenPage(*`page`);".}

proc closeSysInfoPage(ui: var UI, page: ptr SystemInfoPage) =
  {.emit: "`ui`.ClosePage(*`page`);".}

proc openFileBrowserPage(ui: var UI, page: ptr FileBrowserPage) =
  {.emit: "`ui`.OpenPage(*`page`);".}

proc closeFileBrowserPage(ui: var UI, page: ptr FileBrowserPage) =
  {.emit: "`ui`.ClosePage(*`page`);".}

proc openAboutPage(ui: var UI, page: ptr AboutPage) =
  {.emit: "`ui`.OpenPage(*`page`);".}

proc closeAboutPage(ui: var UI, page: ptr AboutPage) =
  {.emit: "`ui`.ClosePage(*`page`);".}

# ============================================================================
# Menu Callbacks
# ============================================================================

proc onSystemInfo(ctx: pointer) {.cdecl.} =
  ## Open system info page
  currentPage = 1
  ui.openSysInfoPage(sysInfoPage)

proc onFileBrowser(ctx: pointer) {.cdecl.} =
  ## Open file browser page
  currentPage = 2
  # Populate file table (simulated)
  fileTable.clear()
  # In real usage: discard fileTable.fill("/audio", ".wav")
  ui.openFileBrowserPage(fileBrowserPage)

proc onAbout(ctx: pointer) {.cdecl.} =
  ## Open about page
  currentPage = 3
  ui.openAboutPage(aboutPage)

proc onSaveSettings(ctx: pointer) {.cdecl.} =
  ## Save settings action
  # Blink LED to indicate save
  for i in 0..2:
    daisy.setLed(true)
    daisy.delay(100)
    daisy.setLed(false)
    daisy.delay(100)

# ============================================================================
# Hardware Initialization
# ============================================================================

proc initHardware() =
  daisy = initDaisy()
  daisy.setLed(false)

proc initButtons() =
  btnOk = initGpio(getPin(0), INPUT, PULLUP)
  btnCancel = initGpio(getPin(1), INPUT, PULLUP)
  btnUp = initGpio(getPin(2), INPUT, PULLUP)
  btnDown = initGpio(getPin(3), INPUT, PULLUP)
  btnMenu = initGpio(getPin(4), INPUT, PULLUP)

proc initDisplay() =
  display = initSH1106I2c(128, 64)

proc initMenuValues() =
  {.emit: """
  // Audio settings
  `volumeValue` = new daisy::MappedFloatValue(0.0f, 100.0f, 75.0f, 
    daisy::MappedFloatValue::Mapping::lin, "%", 0, false);
  
  `gainValue` = new daisy::MappedFloatValue(-60.0f, 12.0f, 0.0f,
    daisy::MappedFloatValue::Mapping::lin, "dB", 1, false);
  
  // Display settings
  `brightnessValue` = new daisy::MappedFloatValue(0.0f, 100.0f, 80.0f,
    daisy::MappedFloatValue::Mapping::lin, "%", 0, false);
  """.}

proc initMenus() =
  ## Initialize menu hierarchy (simplified - all items in one menu)
  var mainItems = [
    createValueItemFloat("Volume", volumeValue),
    createValueItemFloat("Gain", gainValue),
    createValueItemFloat("Brightness", brightnessValue),
    createCheckboxItem("Mute", addr isMuted),
    createCallbackItem("System Info", onSystemInfo, nil),
    createCallbackItem("File Browser", onFileBrowser, nil),
    createCallbackItem("About", onAbout, nil),
    createCallbackItem("Save Settings", onSaveSettings, nil),
    createCloseItem("Exit Menu")
  ]
  
  mainMenu = cast[ptr FullScreenItemMenu](alloc0(sizeof(FullScreenItemMenu)))
  mainMenu[].init(mainItems[0].addr, 9, upDownSelectLeftRightModify, true)

proc initUISystem() =
  ## Initialize UI core
  eventQueue = initUiEventQueue()
  
  var controlIds = initUiSpecialControlIds()
  controlIds.okBttnId = 0
  controlIds.cancelBttnId = 1
  controlIds.upBttnId = 2
  controlIds.downBttnId = 3
  
  var canvases = [
    createCanvasDescriptor(0, addr display, 50, nil, nil)
  ]
  
  ui = initUI()
  uiInitWrapper(addr ui, eventQueue, controlIds,
                unsafeAddr canvases[0], canvases.len.csize_t, 0)
  
  # Create custom pages
  sysInfoPage = cppNewSystemInfoPage()
  fileBrowserPage = cppNewFileBrowserPage()
  aboutPage = cppNewAboutPage()

proc initFileTable() =
  ## Initialize file table
  # FileTable is initialized by default constructor
  # In real usage, populate with files from SD card
  # discard fileTable.fill("/audio", ".wav")

# ============================================================================
# Button Handling
# ============================================================================

type
  ButtonState = object
    wasPressed: bool

var buttonStates: array[5, ButtonState]

proc readButton(gpio: var GPIO, stateIdx: int, buttonId: uint16): bool =
  let isPressed = not gpio.read()
  
  if isPressed and not buttonStates[stateIdx].wasPressed:
    buttonStates[stateIdx].wasPressed = true
    eventQueue.addButtonPressed(buttonId, 1, false)
    result = true
  elif not isPressed and buttonStates[stateIdx].wasPressed:
    buttonStates[stateIdx].wasPressed = false
    eventQueue.addButtonReleased(buttonId)
    result = false
  else:
    result = false

var lastMenuState = false

proc processButtons() =
  ## Read buttons and generate events
  discard readButton(btnOk, 0, 0)
  discard readButton(btnCancel, 1, 1)
  discard readButton(btnUp, 2, 2)
  discard readButton(btnDown, 3, 3)
  
  # Menu button (special handling - toggles menu visibility)
  let menuPressed = not btnMenu.read()
  if menuPressed and not lastMenuState:
    # Toggle menu state
    isInMenu = not isInMenu
    if isInMenu:
      mainMenu[].selectItem(0)
  lastMenuState = menuPressed

# ============================================================================
# Display Rendering
# ============================================================================

proc updateDisplay() =
  ## Update display based on current state
  display.fill(false)
  
  if isInMenu:
    # Menu is rendering itself via UI system
    # Draw menu indicator
    display.fillRect(0, 0, 8, 8, true)
  elif currentPage == 0:
    # Home screen (no active page)
    # Draw welcome screen
    display.fillRect(20, 15, 88, 34, true)
    display.drawRect(22, 17, 84, 30, false)
    display.fillRect(40, 25, 48, 14, false)  # Logo placeholder
    
    # Animated footer
    let offset = (frameCounter div 2) mod 128
    display.fillRect(offset, 58, 20, 6, true)
  # else: custom pages draw themselves
  
  display.update()
  inc frameCounter

# ============================================================================
# Main Loop
# ============================================================================

proc main() =
  ## Main program
  # Initialize all systems
  initHardware()
  initButtons()
  initDisplay()
  initMenuValues()
  initMenus()
  initUISystem()
  initFileTable()
  
  # Startup animation
  daisy.setLed(true)
  display.fill(false)
  display.fillRect(32, 20, 64, 24, true)
  display.update()
  daisy.delay(1000)
  daisy.setLed(false)
  
  # Main loop
  while true:
    # Process button inputs
    processButtons()
    
    # Process UI system (handles events, draws active pages/menus)
    ui.process()
    
    # Update display if not in a custom page
    if currentPage == 0 and not isInMenu:
      updateDisplay()
    
    # LED indicates activity
    let hasActivity = isInMenu or (currentPage != 0) or (volumeValue[].get() > 50.0)
    daisy.setLed(hasActivity)
    
    # Handle cancel button on custom pages
    if currentPage != 0 and not buttonStates[1].wasPressed:
      let cancelPressed = not btnCancel.read()
      if cancelPressed:
        case currentPage
        of 1:
          ui.closeSysInfoPage(sysInfoPage)
        of 2:
          ui.closeFileBrowserPage(fileBrowserPage)
        of 3:
          ui.closeAboutPage(aboutPage)
        else:
          discard
        currentPage = 0
    
    daisy.delay(10)

when isMainModule:
  main()
