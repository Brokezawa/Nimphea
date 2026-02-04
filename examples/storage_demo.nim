## Storage Demo - Flash and Persistent Storage
## ============================================
##
## Comprehensive demonstration of storage options on Daisy:
## - QSPI flash read/write operations
## - Persistent settings with type-safe storage
## - Factory defaults and user settings
##
## Hardware Requirements:
## - Daisy Seed (any version with QSPI flash - IS25LP064A 8MB)
## - USB connection for serial output
##
## Demo Modes (select by uncommenting one):
## - MODE_QSPI_BASIC: Basic QSPI flash read/write/verify
## - MODE_PERSISTENT: Type-safe persistent settings storage
##
## LED Indicators:
## - Steady on: Success
## - Fast blink: Init failed
## - Pattern blinks: Specific operation failed

{.define: useQSPI.}

import ../src/nimphea
import ../src/per/qspi as qspi_module  # Use qualified import to avoid ambiguity
import ../src/per/uart

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_QSPI_BASIC = true
const MODE_PERSISTENT = false

var daisy: DaisySeed

proc blinkPattern(count: int, fast: bool = false) =
  ## Blink LED a specific number of times for status indication
  let delayTime = if fast: 100 else: 300
  for i in 0..<count:
    daisy.setLed(true)
    daisy.delay(delayTime)
    daisy.setLed(false)
    daisy.delay(delayTime)
  daisy.delay(500)

# ============================================================================
# DEMO 1: BASIC QSPI FLASH OPERATIONS
# ============================================================================
## Demonstrates:
## - QSPI flash initialization
## - Sector erase operation
## - Page write operation
## - Memory-mapped read access
## - Data verification
##
## Flash Memory Notes:
## - Must erase before writing (sets all bits to 1)
## - Minimum erase unit is 4KB sector
## - Write in 256-byte pages
## - 8MB total capacity (IS25LP064A)

when MODE_QSPI_BASIC:
  const
    TEST_ADDR = 0'u32
    TEST_SIZE = 256'u32
  
  var
    qspi: qspi_module.QSPIHandle
    testData: array[256, uint8]
    readBuffer: array[256, uint8]
  
  proc fillTestPattern() =
    for i in 0..<256:
      testData[i] = uint8(i and 0xFF)
  
  proc verifyData(): bool =
    for i in 0..<256:
      if readBuffer[i] != testData[i]:
        return false
    true
  
  proc runQspiBasicDemo() =
    daisy = initDaisy()
    startLog()
    daisy.delay(100)
    
    printLine("QSPI Flash Storage Demo")
    printLine("=======================")
    
    # Initialize QSPI in indirect polling mode
    var config = QSPIConfig(
      device: QSPIDevice.IS25LP064A,
      mode: QSPIMode.INDIRECT_POLLING
    )
    
    print("Initializing QSPI...")
    if qspi.init(config) != QSPIResult.OK:
      printLine(" FAILED")
      while true:
        blinkPattern(5, fast = true)
    printLine(" OK")
    
    # Fill test pattern
    fillTestPattern()
    
    # Step 1: Erase sector
    print("Erasing sector 0...")
    if qspi.eraseSector(TEST_ADDR) != QSPIResult.OK:
      printLine(" FAILED")
      while true:
        blinkPattern(2)
    printLine(" OK")
    daisy.delay(100)
    
    # Step 2: Write test data
    print("Writing test pattern...")
    if qspi.writePage(TEST_ADDR, TEST_SIZE, testData[0].addr) != QSPIResult.OK:
      printLine(" FAILED")
      while true:
        blinkPattern(3)
    printLine(" OK")
    daisy.delay(100)
    
    # Step 3: Read data back
    print("Reading data...")
    let flashPtr = cast[ptr UncheckedArray[uint8]](qspi.getData(TEST_ADDR))
    for i in 0..<256:
      readBuffer[i] = flashPtr[i]
    printLine(" OK")
    
    # Step 4: Verify
    print("Verifying...")
    if verifyData():
      printLine(" PASSED")
      printLine("")
      printLine("All tests passed!")
      
      # Success indication
      for i in 0..2:
        daisy.setLed(true)
        daisy.delay(500)
        daisy.setLed(false)
        daisy.delay(500)
      daisy.setLed(true)
    else:
      printLine(" FAILED")
      while true:
        blinkPattern(4)
    
    while true:
      daisy.delay(1000)

# ============================================================================
# DEMO 2: PERSISTENT SETTINGS STORAGE
# ============================================================================
## Demonstrates:
## - Type-safe settings storage
## - Factory defaults
## - Dirty detection (only writes when changed)
## - Settings state tracking (UNKNOWN/FACTORY/USER)
## - Factory reset functionality
##
## Settings Pattern:
## - Define POD struct with {.bycopy, exportc.}
## - Provide C++ comparison operators
## - Initialize with factory defaults
## - Load/save as needed

when MODE_PERSISTENT:
  import ../src/nimphea_persistent_storage
  
  type
    SynthSettings {.bycopy, exportc: "SynthSettings".} = object
      ## POD settings structure for synthesizer
      gain {.exportc.}: cfloat        ## Output gain (0.0 - 1.0)
      frequency {.exportc.}: cfloat   ## Base frequency in Hz
      waveform {.exportc.}: uint8     ## Waveform type (0-3)
  
  # C++ comparison operators required for PersistentStorage dirty detection
  {.emit: """
  inline bool operator==(const SynthSettings& a, const SynthSettings& b) {
    return a.gain == b.gain && 
           a.frequency == b.frequency && 
           a.waveform == b.waveform;
  }
  inline bool operator!=(const SynthSettings& a, const SynthSettings& b) {
    return !(a == b);
  }
  """.}
  
  var
    qspi: qspi_module.QSPIHandle
  
  proc runPersistentDemo() =
    daisy = initDaisy()
    startLog()
    daisy.delay(100)
    
    printLine("Persistent Settings Demo")
    printLine("========================")
    
    # Initialize QSPI in memory-mapped mode for persistent storage
    var config = QSPIConfig(
      device: QSPIDevice.IS25LP064A,
      mode: QSPIMode.MEMORY_MAPPED
    )
    
    print("Initializing QSPI...")
    if qspi.init(config) != QSPIResult.OK:
      printLine(" FAILED")
      while true:
        blinkPattern(5, fast = true)
    printLine(" OK")
    
    # Create persistent storage
    var storage = newPersistentStorage[SynthSettings](qspi)
    
    # Factory defaults
    let defaults = SynthSettings(
      gain: 0.5,
      frequency: 440.0,
      waveform: 0
    )
    
    print("Initializing storage...")
    storage.init(defaults, address_offset = 0)
    printLine(" OK")
    
    # Check state
    let state = storage.getState()
    print("State: ")
    case state
    of UNKNOWN: printLine("UNKNOWN (first boot or corrupted)")
    of FACTORY: printLine("FACTORY (using defaults)")
    of USER: printLine("USER (saved settings loaded)")
    
    # Show current settings
    var settings = storage.getSettings()
    printLine("")
    printLine("Current Settings:")
    print("  Gain: ")
    printLine(settings.gain)
    print("  Frequency: ")
    printLine(settings.frequency)
    print("  Waveform: ")
    printLine(settings.waveform.int)
    
    # Modify settings
    printLine("")
    printLine("Modifying settings...")
    settings.gain = 0.8
    settings.frequency = 880.0
    settings.waveform = 2
    
    # Save (only writes if changed)
    print("Saving...")
    storage.save()
    printLine(" Done")
    
    # Show updated settings
    printLine("")
    printLine("Updated Settings:")
    let saved = storage.getSettings()
    print("  Gain: ")
    printLine(saved.gain)
    print("  Frequency: ")
    printLine(saved.frequency)
    print("  Waveform: ")
    printLine(saved.waveform.int)
    
    # Demonstrate restore defaults
    printLine("")
    print("Restoring factory defaults...")
    storage.restoreDefaults()
    printLine(" Done")
    
    let restored = storage.getSettings()
    print("  Gain: ")
    printLine(restored.gain)
    
    printLine("")
    printLine("Demo complete! Reboot to see saved state.")
    daisy.setLed(true)
    
    while true:
      daisy.delay(1000)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_QSPI_BASIC:
    runQspiBasicDemo()
  elif MODE_PERSISTENT:
    runPersistentDemo()
  else:
    daisy = initDaisy()
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)

when isMainModule:
  main()
