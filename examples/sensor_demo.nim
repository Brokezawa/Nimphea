## Sensor Demo - Motion, Environmental, Gesture, and Touch
## =======================================================
##
## Comprehensive demonstration of various sensor types:
## - ICM20948: 9-axis IMU (accel/gyro/mag) for motion control
## - DPS310 + TLV493D: Pressure and magnetic field sensing
## - APDS9960: Gesture, proximity, and color sensing
## - MPR121 + NeoTrellis: Capacitive touch and RGB buttons
##
## Hardware Requirements:
## - Daisy Seed
## - Specific sensor hardware for each mode
## - I2C connections: SCL=D11, SDA=D12
##
## Demo Modes (select by uncommenting one):
## - MODE_IMU: Motion control with ICM20948
## - MODE_ENVIRONMENTAL: Pressure and magnetic sensing
## - MODE_GESTURE: Gesture control with APDS9960
## - MODE_TOUCH_SEQ: Touch sequencer with MPR121/NeoTrellis
##
## ⚠️ Note: These demos require specific sensor hardware.

import ../src/nimphea
import ../src/per/uart
import std/math

useNimpheaNamespace()

# ============================================================================
# SELECT DEMO MODE (uncomment one)
# ============================================================================
const MODE_IMU = true
const MODE_ENVIRONMENTAL = false
const MODE_GESTURE = false
const MODE_TOUCH_SEQ = false

var daisy: DaisySeed

# ============================================================================
# DEMO 1: ICM20948 IMU - Motion Control
# ============================================================================
## Maps motion to audio filter parameters:
## - Accelerometer tilt → Filter cutoff
## - Gyroscope rotation → Resonance
## - Magnetometer heading → Dry/wet mix
## - LED blinks on motion detection

when MODE_IMU:
  import ../src/per/i2c
  import ../src/dev/icm20948
  
  var
    imu: Icm20948I2C
    cutoff = 1000.0'f32
    mix = 0.5'f32
    filterStateL, filterStateR = 0.0'f32
    lastAccelMag = 0.0'f32
  
  proc mapRange(value, inMin, inMax, outMin, outMax: float32): float32 {.inline.} =
    result = outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
    result = clamp(result, outMin, outMax)
  
  proc onePoleFilter(input, freq: float32, state: var float32): float32 {.inline.} =
    const sampleRate = 48000.0'f32
    let rc = 1.0'f32 / (2.0'f32 * PI * freq)
    let alpha = (1.0'f32 / sampleRate) / (rc + 1.0'f32 / sampleRate)
    state = state + alpha * (input - state)
    return state
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      let filtL = onePoleFilter(input[0][i], cutoff, filterStateL)
      let filtR = onePoleFilter(input[1][i], cutoff, filterStateR)
      output[0][i] = input[0][i] * (1.0'f32 - mix) + filtL * mix
      output[1][i] = input[1][i] * (1.0'f32 - mix) + filtR * mix
  
  proc runImuDemo() =
    daisy = initDaisy()
    
    var imuConfig: Icm20948I2CConfig
    imuConfig.transport_config.periph = I2C_1
    imuConfig.transport_config.speed = I2C_400KHZ
    imuConfig.transport_config.scl = D11()
    imuConfig.transport_config.sda = D12()
    imuConfig.transport_config.address = ICM20948_I2CADDR_DEFAULT
    
    startLog()
    printLine("ICM20948 IMU Motion Control")
    printLine("===========================")
    
    if imu.init(imuConfig) != ICM20948_OK:
      printLine("ERROR: IMU init failed!")
      while true:
        daisy.setLed(true); daisy.delay(100)
        daisy.setLed(false); daisy.delay(100)
    
    printLine("IMU initialized")
    discard imu.setupMag()
    printLine("Tilt→Cutoff, Rotation→Res, Heading→Mix")
    printLine("")
    
    daisy.setSampleRate(SAI_48KHZ)
    daisy.setBlockSize(48)
    daisy.startAudio(audioCallback)
    
    var loopCount = 0'u32
    
    while true:
      imu.process()
      
      let accel = imu.getAccelVect()
      let accelMag = sqrt(accel.x * accel.x + accel.y * accel.y)
      cutoff = mapRange(accelMag, 0.0'f32, 2.0'f32, 100.0'f32, 10000.0'f32)
      
      let mag = imu.getMagVect()
      let heading = arctan2(mag.y, mag.x) * 180.0'f32 / PI
      mix = mapRange(heading, -180.0'f32, 180.0'f32, 0.0'f32, 1.0'f32)
      
      # Motion detection LED
      let motionDelta = abs(accelMag - lastAccelMag)
      lastAccelMag = accelMag
      daisy.setLed(motionDelta > 0.1'f32)
      
      inc loopCount
      if loopCount mod 100 == 0:
        print("Cutoff: "); print(cutoff.int)
        print("Hz Mix: "); print((mix * 100).int)
        printLine("%")
      
      daisy.delay(10)

# ============================================================================
# DEMO 2: DPS310 + TLV493D - Environmental Sensing
# ============================================================================
## Monitors environmental conditions:
## - Barometric pressure and altitude
## - Temperature
## - 3D magnetic field

when MODE_ENVIRONMENTAL:
  import ../src/per/i2c
  import ../src/dev/dps310
  import ../src/dev/tlv493d
  
  const SEA_LEVEL_PRESSURE = 1013.25'f32
  
  var
    pressureSensor: Dps310I2C
    magSensor: Tlv493dI2C
  
  proc calculateAltitude(pressure: float32): float32 =
    44330.0'f32 * (1.0'f32 - pow(pressure / SEA_LEVEL_PRESSURE, 0.1903'f32))
  
  proc runEnvironmentalDemo() =
    daisy = initDaisy()
    
    startLog()
    printLine("Environmental Monitoring")
    printLine("========================")
    
    # DPS310 pressure sensor
    var pressureConfig: Dps310I2CConfig
    pressureConfig.transport_config.periph = I2C_1
    pressureConfig.transport_config.speed = I2C_400KHZ
    pressureConfig.transport_config.scl = D11()
    pressureConfig.transport_config.sda = D12()
    pressureConfig.transport_config.address = DPS310_I2CADDR_DEFAULT
    
    let pressureOk = pressureSensor.init(pressureConfig) == DPS310_OK
    if pressureOk:
      printLine("DPS310 initialized")
      pressureSensor.configurePressure(DPS310_8HZ, DPS310_64SAMPLES)
      pressureSensor.configureTemperature(DPS310_8HZ, DPS310_64SAMPLES)
    else:
      printLine("DPS310 FAILED")
    
    # TLV493D magnetic sensor
    var magConfig: Tlv493dConfig
    magConfig.transport_config.periph = I2C_1
    magConfig.transport_config.speed = I2C_400KHZ
    magConfig.transport_config.scl = D11()
    magConfig.transport_config.sda = D12()
    magConfig.transport_config.address = TLV493D_ADDRESS1
    
    let magOk = magSensor.init(magConfig) == TLV493D_OK
    if magOk:
      printLine("TLV493D initialized")
      magSensor.setAccessMode(FASTMODE)
    else:
      printLine("TLV493D FAILED")
    
    printLine("")
    
    var loopCount = 0'u32
    var ledState = false
    
    while true:
      if pressureOk:
        pressureSensor.process()
      if magOk:
        magSensor.updateData()
      
      inc loopCount
      if loopCount mod 100 == 0:
        printLine("--- Readings ---")
        
        if pressureOk:
          let p = pressureSensor.getPressure()
          let t = pressureSensor.getTemperature()
          print("Pressure: "); print(p.float); printLine(" hPa")
          print("Altitude: "); print(calculateAltitude(p).float); printLine(" m")
          print("Temp: "); print(t.float); printLine(" C")
        
        if magOk:
          let mx = magSensor.getX()
          let my = magSensor.getY()
          let mz = magSensor.getZ()
          let mag = sqrt(mx*mx + my*my + mz*mz)
          print("Mag field: "); print(mag.float); printLine(" mT")
        
        printLine("")
        ledState = not ledState
        daisy.setLed(ledState)
      
      daisy.delay(10)

# ============================================================================
# DEMO 3: APDS9960 - Gesture Control
# ============================================================================
## Maps gestures to audio effects:
## - UP/DOWN: Adjust filter cutoff
## - LEFT/RIGHT: Adjust dry/wet mix
## - Proximity: Modulation depth

when MODE_GESTURE:
  import ../src/per/i2c
  import ../src/dev/apds9960
  
  var
    sensor: Apds9960I2C
    cutoff = 1000.0'f32
    mix = 0.5'f32
    modDepth = 0.0'f32
    filterStateL, filterStateR = 0.0'f32
  
  proc onePoleFilter(input, freq: float32, state: var float32): float32 {.inline.} =
    const sampleRate = 48000.0'f32
    let rc = 1.0'f32 / (2.0'f32 * PI * freq)
    let alpha = (1.0'f32 / sampleRate) / (rc + 1.0'f32 / sampleRate)
    state = state + alpha * (input - state)
    return state
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    for i in 0..<size:
      let modCutoff = cutoff * (1.0'f32 + modDepth * 0.5'f32)
      let filtL = onePoleFilter(input[0][i], modCutoff, filterStateL)
      let filtR = onePoleFilter(input[1][i], modCutoff, filterStateR)
      output[0][i] = input[0][i] * (1.0'f32 - mix) + filtL * mix
      output[1][i] = input[1][i] * (1.0'f32 - mix) + filtR * mix
  
  proc runGestureDemo() =
    daisy = initDaisy()
    
    var config: Apds9960Config
    config.transport_config.periph = I2C_1
    config.transport_config.speed = I2C_400KHZ
    config.transport_config.scl = D11()
    config.transport_config.sda = D12()
    config.gesture_mode = true
    config.prox_mode = true
    config.color_mode = true
    
    startLog()
    printLine("APDS9960 Gesture Control")
    printLine("========================")
    
    if sensor.init(config) != APDS9960_OK:
      printLine("ERROR: Sensor init failed!")
      while true:
        daisy.setLed(true); daisy.delay(100)
        daisy.setLed(false); daisy.delay(100)
    
    printLine("Sensor initialized")
    printLine("UP/DOWN→Cutoff, LEFT/RIGHT→Mix")
    printLine("Proximity→Modulation")
    printLine("")
    
    daisy.setSampleRate(SAI_48KHZ)
    daisy.setBlockSize(48)
    daisy.startAudio(audioCallback)
    
    var loopCount = 0'u32
    
    while true:
      let gesture = sensor.readGesture()
      var detected = false
      
      case gesture
      of APDS9960_UP:
        cutoff = clamp(cutoff + 500.0'f32, 100.0'f32, 10000.0'f32)
        printLine("UP → Cutoff+")
        detected = true
      of APDS9960_DOWN:
        cutoff = clamp(cutoff - 500.0'f32, 100.0'f32, 10000.0'f32)
        printLine("DOWN → Cutoff-")
        detected = true
      of APDS9960_LEFT:
        mix = clamp(mix - 0.1'f32, 0.0'f32, 1.0'f32)
        printLine("LEFT → Mix-")
        detected = true
      of APDS9960_RIGHT:
        mix = clamp(mix + 0.1'f32, 0.0'f32, 1.0'f32)
        printLine("RIGHT → Mix+")
        detected = true
      else: discard
      
      let proximity = sensor.readProximity()
      modDepth = proximity.float32 / 255.0'f32
      
      if detected:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
      
      inc loopCount
      if loopCount mod 50 == 0:
        print("Cutoff: "); print(cutoff.int)
        print(" Mix: "); print((mix * 100).int)
        print("% Prox: "); print(proximity.int)
        printLine("")
      
      daisy.delay(10)

# ============================================================================
# DEMO 4: MPR121 + NeoTrellis - Touch Sequencer
# ============================================================================
## Interactive step sequencer:
## - 12-key touch keyboard for note selection
## - 16-step visual sequencer grid
## - RGB LED feedback

when MODE_TOUCH_SEQ:
  import ../src/per/i2c
  import ../src/dev/mpr121
  import ../src/dev/neotrellis
  
  const NUM_STEPS = 16
  const NUM_NOTES = 12
  
  var
    touchSensor: Mpr121I2C
    trellis: NeoTrellisI2C
    currentStep = 0
    stepDelay = 125  # ~120 BPM
    pattern: array[NUM_STEPS, array[NUM_NOTES, bool]]
    lastTouched: uint16 = 0
    phase = 0.0'f32
    frequency = 440.0'f32
    envelope = 0.0'f32
    touchOk, trellisOk: bool
  
  const noteFreqs: array[12, float32] = [
    261.63'f32, 277.18'f32, 293.66'f32, 311.13'f32,
    329.63'f32, 349.23'f32, 369.99'f32, 392.00'f32,
    415.30'f32, 440.00'f32, 466.16'f32, 493.88'f32
  ]
  
  proc triggerNote(noteIndex: int) =
    if noteIndex >= 0 and noteIndex < 12:
      frequency = noteFreqs[noteIndex]
      envelope = 1.0'f32
  
  proc updateDisplay() =
    if not trellisOk: return
    for step in 0..<16:
      var hasNote = false
      for note in 0..<12:
        if pattern[step][note]:
          hasNote = true
          break
      
      var r, g, b: uint8
      if step == currentStep:
        r = 255; g = 255; b = 255
      elif hasNote:
        r = 0; g = 50; b = 0
      else:
        r = 0; g = 0; b = 10
      
      trellis.pixels.setPixelColor(step.uint16, r, g, b)
    trellis.pixels.show()
  
  proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
    const sampleRate = 48000.0'f32
    for i in 0..<size:
      let sample = sin(phase * 2.0'f32 * PI) * 0.3'f32 * envelope
      output[0][i] = sample
      output[1][i] = sample
      phase += frequency / sampleRate
      if phase >= 1.0'f32: phase -= 1.0'f32
      envelope *= 0.9995'f32
  
  proc runTouchSeqDemo() =
    daisy = initDaisy()
    
    startLog()
    printLine("Touch Sequencer")
    printLine("===============")
    
    # MPR121 touch sensor
    var touchConfig: Mpr121Config
    touchConfig.transport_config.periph = I2C_1
    touchConfig.transport_config.speed = I2C_400KHZ
    touchConfig.transport_config.scl = D11()
    touchConfig.transport_config.sda = D12()
    
    touchOk = touchSensor.init(touchConfig) == MPR121_OK
    if touchOk:
      printLine("MPR121 initialized")
      touchSensor.setThresholds(12, 6)
    else:
      printLine("MPR121 FAILED")
    
    # NeoTrellis button pad
    var trellisConfig: NeoTrellisConfig
    trellisConfig.transport_config.periph = I2C_1
    trellisConfig.transport_config.speed = I2C_400KHZ
    trellisConfig.transport_config.scl = D11()
    trellisConfig.transport_config.sda = D12()
    trellisConfig.transport_config.address = NEO_TRELLIS_ADDR
    
    trellisOk = trellis.init(trellisConfig) == NEOTRELLIS_OK
    if trellisOk:
      printLine("NeoTrellis initialized")
      let edges = (NEO_TRELLIS_RISING.uint8 or NEO_TRELLIS_FALLING.uint8)
      for row in 0'u8..<4'u8:
        for col in 0'u8..<4'u8:
          trellis.activateKey(col, row, edges, true)
    else:
      printLine("NeoTrellis FAILED")
    
    printLine("Touch pads 0-11 to play/toggle")
    printLine("")
    
    # Clear pattern
    for step in 0..<NUM_STEPS:
      for note in 0..<NUM_NOTES:
        pattern[step][note] = false
    
    daisy.setSampleRate(SAI_48KHZ)
    daisy.setBlockSize(48)
    daisy.startAudio(audioCallback)
    
    updateDisplay()
    
    var loopCounter = 0'u32
    var lastStepTime = 0'u32
    var ledState = false
    
    while true:
      inc loopCounter
      
      # Handle touch input
      if touchOk:
        let touched = touchSensor.touched()
        for i in 0..<12:
          let mask = 1'u16 shl i
          if (touched and mask) != 0 and (lastTouched and mask) == 0:
            triggerNote(i)
            pattern[currentStep][i] = not pattern[currentStep][i]
            updateDisplay()
        lastTouched = touched
      
      # Handle trellis buttons
      if trellisOk:
        trellis.process()
        for i in 0'u8..<16'u8:
          if trellis.getRising(i):
            currentStep = i.int
            updateDisplay()
      
      # Advance sequencer
      if loopCounter - lastStepTime >= stepDelay.uint32:
        lastStepTime = loopCounter
        for note in 0..<NUM_NOTES:
          if pattern[currentStep][note]:
            triggerNote(note)
        currentStep = (currentStep + 1) mod NUM_STEPS
        updateDisplay()
        ledState = not ledState
        daisy.setLed(ledState)
      
      daisy.delay(1)

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

proc main() =
  when MODE_IMU:
    runImuDemo()
  elif MODE_ENVIRONMENTAL:
    runEnvironmentalDemo()
  elif MODE_GESTURE:
    runGestureDemo()
  elif MODE_TOUCH_SEQ:
    runTouchSeqDemo()
  else:
    daisy = initDaisy()
    while true:
      daisy.setLed(true)
      daisy.delay(100)
      daisy.setLed(false)
      daisy.delay(100)

when isMainModule:
  main()
