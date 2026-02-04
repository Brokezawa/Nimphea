## Communication Demo - SPI and I2C Peripherals
## =============================================
##
## Comprehensive demonstration of communication interfaces:
## - Basic SPI read/write/transfer
## - Multi-slave SPI with chip select handling
## - I2C bus scanning and device detection
##
## Hardware Requirements:
## - Daisy Seed
## - For SPI: External SPI device or loopback for testing
## - For I2C: External I2C devices (OLED, sensor, etc.)
##
## Demo Modes (select by uncommenting one):
## - MODE_SPI_BASIC: Basic SPI read/write/transfer operations
## - MODE_SPI_MULTISLAVE: Multiple SPI devices on one bus
## - MODE_I2C_SCANNER: Scan I2C bus for connected devices
##
## Pin Assignments:
## - SPI: D7 (SCK), D8 (MISO), D9 (MOSI), D10-D12 (CS)
## - I2C: D11 (SCL), D12 (SDA)

import ../src/nimphea
import ../src/per/uart

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_SPI_BASIC = true
const MODE_SPI_MULTISLAVE = false
const MODE_I2C_SCANNER = false

var daisy: DaisySeed

# ============================================================================
# DEMO 1: BASIC SPI OPERATIONS
# ============================================================================
## Demonstrates:
## - SPI initialization with pin configuration
## - Write operation (transmit only)
## - Read operation (receive only)
## - Full-duplex transfer (simultaneous TX/RX)

when MODE_SPI_BASIC:
  import ../src/per/spi
  
  proc runSpiBasicDemo() =
    daisy = initDaisy()
    
    # Initialize SPI on SPI1: D8 (SCK), D9 (MISO), D10 (MOSI)
    var spi = initSPI(SPI_1, D8(), D9(), D10())
    
    startLog()
    daisy.delay(100)
    
    printLine("SPI Basic Communication Demo")
    printLine("============================")
    printLine("")
    printLine("Pins: D8=SCK, D9=MISO, D10=MOSI")
    printLine("")
    
    var cycleCount = 0
    
    while true:
      cycleCount += 1
      print("--- Cycle ")
      print(cycleCount)
      printLine(" ---")
      
      # Write operation
      let writeResult = spi.write([0x01'u8, 0x02, 0x03, 0x04])
      if writeResult == SPI_OK:
        printLine("Write [01 02 03 04]: OK")
      else:
        printLine("Write: ERROR")
      
      # Read operation
      var readBuffer: array[4, uint8]
      let readResult = spi.read(readBuffer)
      if readResult == SPI_OK:
        print("Read: ")
        for b in readBuffer:
          print(int(b))
          print(" ")
        printLine("")
      else:
        printLine("Read: ERROR")
      
      # Full-duplex transfer
      var rxData: array[4, uint8]
      let xferResult = spi.transfer([0xAA'u8, 0xBB, 0xCC, 0xDD], rxData)
      if xferResult == SPI_OK:
        print("Transfer TX[AA BB CC DD] RX: ")
        for b in rxData:
          print(int(b))
          print(" ")
        printLine("")
      else:
        printLine("Transfer: ERROR")
      
      printLine("")
      
      # LED heartbeat
      daisy.setLed(cycleCount mod 2 == 0)
      daisy.delay(1000)

# ============================================================================
# DEMO 2: MULTI-SLAVE SPI
# ============================================================================
## Demonstrates:
## - Multiple SPI devices on a single bus
## - Individual chip select control
## - Configurable SPI parameters (polarity, phase, speed)
##
## Useful for: Multiple DACs, multiple sensors, display + storage

when MODE_SPI_MULTISLAVE:
  import ../src/per/spi
  import ../src/per/spi_multislave
  
  proc runSpiMultislaveDemo() =
    daisy = initDaisy()
    startLog()
    daisy.delay(100)
    
    printLine("Multi-Slave SPI Demo")
    printLine("====================")
    printLine("")
    printLine("Bus: D7=SCK, D8=MISO, D9=MOSI")
    printLine("CS:  D10=Dev0, D11=Dev1, D12=Dev2")
    printLine("")
    
    # Configure multi-slave SPI
    var config = MultiSlaveSpiConfig(
      periph: SPI_1,
      direction: SPI_TWO_LINES,
      datasize: 8,
      clock_polarity: SPI_CLOCK_POL_LOW,
      clock_phase: SPI_CLOCK_PHASE_1,
      baud_prescaler: SPI_PS_16,
      num_devices: 3
    )
    
    # Configure pins
    config.pin_config.sclk = D7()
    config.pin_config.miso = D8()
    config.pin_config.mosi = D9()
    config.pin_config.nss[0] = D10()  # Device 0
    config.pin_config.nss[1] = D11()  # Device 1
    config.pin_config.nss[2] = D12()  # Device 2
    
    # Initialize
    var spi = initMultiSlaveSpi()
    print("Initializing multi-slave SPI...")
    
    if spi.init(config) != SPI_OK:
      printLine(" FAILED")
      while true:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
    
    printLine(" OK")
    printLine("")
    
    # Test data for each device
    let deviceData: array[3, array[3, uint8]] = [
      [0x01'u8, 0x02, 0x03],  # Device 0
      [0xAA'u8, 0xBB, 0xCC],  # Device 1
      [0xFF'u8, 0x00, 0xFF]   # Device 2
    ]
    
    printLine("Sending data to each device:")
    
    for dev in 0..2:
      var txData = deviceData[dev]
      print("  Device ")
      print(dev)
      print(": [")
      print(int(txData[0]))
      print(" ")
      print(int(txData[1]))
      print(" ")
      print(int(txData[2]))
      print("]...")
      
      if spi.blockingTransmit(dev.cint, txData) == SPI_OK:
        printLine(" OK")
      else:
        printLine(" FAILED")
    
    printLine("")
    printLine("Multi-slave demo complete!")
    printLine("Each device received unique data")
    
    daisy.setLed(true)
    while true:
      daisy.delay(1000)

# ============================================================================
# DEMO 3: I2C BUS SCANNER
# ============================================================================
## Demonstrates:
## - I2C initialization with configurable speed
## - Bus scanning for connected devices
## - Device identification by address
##
## Common I2C addresses:
## - 0x3C/0x3D: SSD1306 OLED
## - 0x68: MPU6050 IMU / DS3231 RTC
## - 0x76/0x77: BMP280 Sensor
## - 0x20: PCF8574 / MCP23017 I/O Expander
## - 0x48: ADS1115 ADC
## - 0x50: AT24C32 EEPROM

when MODE_I2C_SCANNER:
  import ../src/per/i2c
  
  proc printHex(val: uint8) =
    const hexChars = "0123456789ABCDEF"
    let high = hexChars[(val shr 4) and 0x0F]
    let low = hexChars[val and 0x0F]
    print("0x")
    print($high)
    print($low)
  
  proc getDeviceName(address: uint8): string =
    ## Return human-readable device name for known I2C addresses
    case address
    of I2C_ADDR_SSD1306, I2C_ADDR_SSD1306_ALT:
      "SSD1306 OLED"
    of I2C_ADDR_MPU6050:
      "MPU6050 IMU / DS3231 RTC"
    of I2C_ADDR_BMP280, I2C_ADDR_BMP280_ALT:
      "BMP280 Sensor"
    of I2C_ADDR_PCF8574:
      "PCF8574 / MCP23017 I/O"
    of I2C_ADDR_ADS1115:
      "ADS1115 ADC"
    of I2C_ADDR_AT24C32:
      "AT24C32 EEPROM"
    else:
      ""
  
  proc runI2cScannerDemo() =
    daisy = initDaisy()
    
    # Initialize I2C on D11 (SCL), D12 (SDA) at 400kHz
    var i2c = initI2C(I2C_1, D11(), D12(), I2C_400KHZ)
    
    startLog()
    daisy.delay(100)
    
    printLine("I2C Bus Scanner Demo")
    printLine("====================")
    printLine("")
    printLine("Pins: D11=SCL, D12=SDA")
    printLine("Speed: 400 kHz")
    printLine("")
    printLine("Scanning for devices...")
    printLine("")
    
    var foundDevices: array[112, uint8]  # Max 112 addresses (0x08-0x77)
    var scanCount = 0
    
    while true:
      scanCount += 1
      print("--- Scan #")
      print(scanCount)
      printLine(" ---")
      
      let deviceCount = i2c.scan(foundDevices)
      
      if deviceCount == 0:
        printLine("No I2C devices found")
        printLine("Check wiring and power")
      else:
        print("Found ")
        print(deviceCount)
        printLine(" device(s):")
        printLine("")
        
        for i in 0..<deviceCount:
          print("  ")
          printHex(foundDevices[i])
          
          let name = getDeviceName(foundDevices[i])
          if name.len > 0:
            print(" - ")
            print(cstring(name))
          
          printLine("")
      
      printLine("")
      
      # LED indicates scan activity
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      
      # Scan every 5 seconds
      daisy.delay(4900)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_SPI_BASIC:
    runSpiBasicDemo()
  elif MODE_SPI_MULTISLAVE:
    runSpiMultislaveDemo()
  elif MODE_I2C_SCANNER:
    runI2cScannerDemo()
  else:
    daisy = initDaisy()
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)

when isMainModule:
  main()
