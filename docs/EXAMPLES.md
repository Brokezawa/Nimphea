# Nimphea Examples - Quick Reference

This document provides a quick reference for all examples in Nimphea. For detailed hardware testing procedures, see [TESTING_GUIDE.md](TESTING_GUIDE.md).

## Table of Contents

- [How to Use This Guide](#how-to-use-this-guide)
- [Quick Start](#quick-start)
- [Example Testing Matrix](#example-testing-matrix)
- [Hardware Requirements](#hardware-requirements)
- [Common Patterns](#common-patterns)
- [Troubleshooting](#troubleshooting)

## How to Use This Guide

### For Testing

1. **Build and flash** the example to your Daisy Seed
2. **Observe behavior** against the "Expected Behavior" column
3. **Mark status** in your test report:
   - PASS: **PASS** - Behaves exactly as expected
   - PARTIAL: **PARTIAL** - Works but with minor differences
   - FAIL: **FAIL** - Does not work or crashes
   - SKIP: **SKIP** - Hardware not available

4. **Document differences** if behavior doesn't match exactly

### Reporting Issues

If you find a discrepancy:

1. Check the "Common Issues" column first
2. Verify your hardware setup matches requirements
3. If still failing, open a GitHub issue with:
   - Example name
   - Expected vs actual behavior
   - Hardware setup
   - Test results from working examples

---

## Quick Start

### Building Examples

```bash
# Build specific example
nimble make blink

# Flash to Daisy Seed (USB DFU mode)
nimble flash blink

# Run tests
nimble test
```

### Entering DFU Mode

1. Hold BOOT button on Daisy Seed
2. Press and release RESET button
3. Release BOOT button
4. LED should be off (DFU mode active)
5. Run `nimble flash <example>`

---

## Example Testing Matrix

### Basic Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **blink.nim** | Basic | None (onboard LED) | Onboard LED blinks at ~2Hz (500ms on, 500ms off). Should continue indefinitely. | None - simplest example | SKIP: |
| **gpio_demo.nim** | GPIO | Button on D0, LED on D7 | Consolidated GPIO demo with compile-time modes: **BUTTON_LED** - LED mirrors button state with instant response; **GPIO_INPUT** - Reads digital input, logs state changes; **OUTPUT_TOGGLE** - Cycles through LED patterns. | If inverted, check button wiring (needs pull-up) | SKIP: |

### Audio Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **audio_demo.nim** | Audio | Audio input/output | Consolidated audio demo with compile-time modes: **PASSTHROUGH** - Clean audio passthrough with minimal latency (<3ms); **SINE_WAVE** - Generates clean 440Hz sine wave (A4 note); **DISTORTION** - Warm overdrive distortion when activated, LED indicates effect state. | Silence = check connections; Clicking = buffer issue; Wrong pitch = sample rate mismatch | SKIP: |

### Audio Codec Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **codec_comparison.nim** | Audio Codec | None (onboard codec) | Detects Daisy Seed hardware version and initializes appropriate codec (AK4556/WM8731/PCM3060). LED blinks to indicate successful codec initialization. Console output shows detected version. | No LED blink = codec init failed; Check board version detection | SKIP: |

### ADC (Analog Input) Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **adc_demo.nim** | ADC | Potentiometer(s) on A0-A3 | Consolidated ADC demo with compile-time modes: **SIMPLE** - Single channel read (A0), LED brightness reflects pot position; **MULTICHANNEL** - Reads 3 channels (A0-A2) simultaneously, console shows all values; **MULTIPLEXED** - External mux chip support with sequential scanning; **CONFIG** - Custom ADC configuration demo (resolution, speed, oversampling); **ANALOG_KNOBS** - Real-world 4-knob control with smoothing/filtering. | Noisy readings = add capacitor; Inverted = check wiring; Crosstalk = ADC config issue | SKIP: |

### PWM Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **pwm_demo.nim** | PWM | LED/RGB LED/Servo on D0-D2 | Consolidated PWM demo with compile-time modes: **LED_FADE** - Single LED fades smoothly 0-100% brightness, no flickering; **RGB_RAINBOW** - RGB LED cycles rainbow colors (R→Y→G→C→B→M→R), ~5s per cycle; **SERVO_SWEEP** - Servo motor sweeps 0°-180° continuously, standard 50Hz signal. | Flickering = PWM freq too low; Servo jitter = power supply issue; Wrong colors = check LED pinout | SKIP: |

### Display Examples (OLED)

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **oled_basic.nim** | OLED/I2C | SSD1306 I2C OLED (128x64) | Display initializes and shows text "Hello Daisy!". Text should be crisp and readable. May show demo pattern or counter. | Blank screen = check I2C address (0x3C or 0x3D) | SKIP: |
| **oled_graphics.nim** | OLED/I2C | SSD1306 I2C OLED | Draws shapes (rectangles, circles, lines). Shapes should be clean with no artifacts. May animate or update periodically. | Corrupted graphics = timing issue; Partial = buffer problem | SKIP: |
| **oled_spi.nim** | OLED/SPI | SSD1306 SPI OLED | Same as oled_basic but using SPI interface. Faster updates than I2C version. Text or graphics displayed clearly. | Blank = check CS/DC pins; Shifted = clock issue | SKIP: |
| **oled_visualizer.nim** | OLED/Audio | SSD1306 + Audio input | Real-time audio level meter or waveform display. Bars or scope trace react to audio input. 10-30 FPS typical. | No movement = audio not connected; Slow = optimize drawing | SKIP: |

### Display Examples (Advanced OLED)

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **ui_demo.nim** | UI/Comprehensive | SH1106 OLED + 5 buttons | Complete UI framework showcase: menu system (Volume/Gain/Brightness/Mute), custom pages (System Info/File Browser/About), event dispatcher, FileTable integration. Menu button opens main menu. All UI features demonstrated. | Menu not opening = check menu button; Pages blank = check page init; LED activity indicates state | SKIP: |
| **display_gallery.nim** | OLED/SPI | Any OLED (SSD1351 default) | Comprehensive demo cycling through 4 modes: (1) Test pattern with shapes, (2) Performance test with random lines, (3) Rectangle API demo, (4) Color gradients. Modes change every 3 seconds. | Edit imports to change display type; Compile for your specific display | SKIP: |
| **menu_dsl_demo.nim** | UI/DSL | SH1106 OLED (default) | Menu Builder DSL demo. Creates a settings menu (Volume/Frequency/Mute) using declarative syntax. Zero heap allocation. Demonstrates static menu generation. | Menu not rendering = check display type; Compile error = macro expansion issue | SKIP: |

### Display Examples (LCD)

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **lcd_menu.nim** | LCD/Encoder | HD44780 16x2 LCD + Encoder | Character LCD displays 3-parameter menu (Volume %, Frequency Hz, Waveform name). Encoder rotation changes values, button press cycles menu items. Display updates in real-time. | Garbled text = timing/wiring issue; No encoder response = check encoder pins | SKIP: |

### Communication Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **comm_demo.nim** | Communication | I2C/SPI devices | Consolidated communication demo with compile-time modes: **I2C_SCANNER** - Scans addresses 0x03-0x77, reports found devices via console/LED; **SPI_BASIC** - Sends/receives SPI data with verification; **MULTI_SPI** - Shares SPI bus between 3 devices with individual chip selects. | False positives = pull-up resistor issue; No response = check MISO/MOSI; CS pins swapped = wrong device | SKIP: |
| **usb_serial.nim** | USB | USB cable to computer | Creates virtual serial port. Text typed in terminal echoes back. Baud rate doesn't matter (USB CDC). | Not detected = enter DFU mode first; No echo = driver issue | SKIP: |
| **midi_demo.nim** | MIDI | MIDI controller (USB/UART) | Comprehensive MIDI I/O demo: receives and transmits MIDI via USB and UART. Echoes received messages, generates test notes. Demonstrates NoteOn/NoteOff, channel handling, and bidirectional communication. | No response = check MIDI mode (USB vs UART); Echo not working = check MIDI output connection | SKIP: |

### Control Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **encoder.nim** | Encoder | Rotary encoder on D0,D1,D2 | Turning encoder changes value (displayed on LED/console). Button press may reset. Detents should feel accurate (no skips). | Skips = debounce issue; Reversed = swap A/B pins | SKIP: |
| **lcd_menu.nim** | LCD/Encoder | HD44780 LCD + Encoder | See "Display Examples (LCD)" section above for details | See LCD section | SKIP: |

### Storage Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **sdram_test.nim** | SDRAM | External SDRAM chip | Writes test pattern to SDRAM, reads back and verifies. LED blinks on success, stays on for failure. May test full 64MB. | Fails = check SDRAM soldering/power | SKIP: |
| **storage_demo.nim** | Storage | Built-in QSPI flash | Consolidated storage demo with compile-time modes: **FLASH_STORAGE** - Erases sector, writes test data, reads back, tests INDIRECT and MEMORY_MAPPED modes; **QSPI_STORAGE** - Low-level QSPI flash operations; **SETTINGS_MANAGER** - Persistent settings with dirty detection, state transitions (UNKNOWN→FACTORY→USER), restore defaults. | Verify fails = flash defective; Settings lost = flash write failure; State = UNKNOWN = init() not called | SKIP: |

### DAC Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **dac_simple.nim** | DAC | Voltmeter or scope on DAC pins | Outputs ramping voltage on DAC channel 1. Voltage sweeps from 0V to 3.3V continuously. ~1V per second typical. | Flat line = DAC not enabled; Wrong range = 12-bit config | SKIP: |

### Board-Specific Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **pod_demo.nim** | Pod Board | Daisy Pod | Consolidated Pod demo with compile-time modes: **SIMPLE** - LED/knob/button test, rainbow LED, encoder controls; **SYNTH** - Monophonic synthesizer with waveform selection, filter, and pitch control; **EFFECT** - Multi-effect audio processor (Delay/Tremolo/Distortion/Bitcrusher) with bypass. | LEDs dim = check power supply; No audio = check connections; Effect not changing = encoder issue | SKIP: |
| **patch_demo.nim** | Patch Board | Daisy Patch | Consolidated Patch demo with compile-time modes: **SIMPLE** - Initializes hardware, tests controls, OLED display, audio passthrough; **EFFECT** - Multi-effect with CV modulation, encoder selects effects; **CV_PROCESSOR** - CV utilities (quantizer, slew limiter, sample&hold, gate generator). | Controls not working = check board variant; No CV = ADC not started; Gate not working = check voltage | SKIP: |
| **patch_sm_demo.nim** | Patch SM Board | Daisy Patch SM | Consolidated Patch SM demo with compile-time modes: **CV_PROCESSOR** - CV summing/mixing with 12 inputs and 3 outputs; **QUANTIZER** - Musical CV quantizer with sample & hold, 12-TET chromatic scale, embedded-safe rounding. | No CV output = check DAC init; Wrong notes = check quantization scale | SKIP: |
| **field_demo.nim** | Field Board | Daisy Field | Consolidated Field demo with compile-time modes: **KEYBOARD** - 16-key touch keyboard synthesizer with polyphonic detection; **MODULAR** - CV/Gate sequencer with step programming via keyboard. | Keys not responding = keyboard not initialized; Sequence not advancing = gate not detected | SKIP: |
| **petal_demo.nim** | Petal Board | Daisy Petal | Consolidated Petal demo with compile-time modes: **SIMPLE** - LED control with 6 knobs, 7 footswitches, encoder brightness; **OVERDRIVE** - Guitar overdrive effect with VU meter on RGB ring LEDs. | LEDs not responding = I2C issue; Harsh distortion = reduce gain | SKIP: |
| **versio_demo.nim** | Versio Board | Daisy Versio | Consolidated Versio demo with compile-time modes: **SIMPLE** - LED/control demo with 7 knobs, 3-position switches, gate flash; **REVERB** - Schroeder reverb (4 comb + 2 allpass filters) with freeze, 217KB SRAM buffers. | LEDs dim = check PWM frequency; No reverb = check mix knob | SKIP: |
| **legio_demo.nim** | Legio Board | Daisy Legio | Consolidated Legio demo with compile-time modes: **SIMPLE** - Control/LED demo with encoder, CV inputs, switches, gate flash; **CV_METER** - CV meter with audio passthrough, gain control, stereo/mono routing. | Encoder not responding = check init; Meter not updating = check mode | SKIP: |

### Peripherals Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **peripherals_basic.nim** | RNG/Timer/LED | LED on D7 | Random LED blink patterns using hardware TRNG. Brightness varies randomly (0.0-1.0). Timer measures actual delay duration. Console prints timing stats every 5th loop. | LED stays on/off = update() not called; No randomness = RNG not ready | SKIP: |
| **eurorack_basics.nim** | GateIn/Switch3 | Gates on D0,D1; Switch on D2,D3 | Gate inputs detect rising edges (triggers). Switch reads 3 positions: UP/CENTER/DOWN. Console shows trigger counts and current states. Status printed every 500ms. | No triggers = check gate voltage (>2V); Switch stuck = check wiring | SKIP: |
| **led_control.nim** | RgbLed/Color | RGB LED on D10,D11,D12 | RGB LED cycles through: Primary colors (R,G,B) → Mixed colors (Purple,Cyan,Orange,White) → Red-to-Blue blend → Rainbow cycle (3 loops). ~20 seconds total sequence. | Wrong colors = check RGB pin order; Dim = check current limiting | SKIP: |
| **timer_advanced.nim** | Timer | None (uses serial) | Coordinates 3 timers: TIM2 (free-running counter), TIM3 (periodic callback), TIM5 (faster callback). Runs for 20 seconds showing callback counts and tick measurements. | Callbacks = 0 = IRQ not enabled; Tick overflow = period too short | SKIP: |

### Data Structures & Utilities Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **data_structures.nim** | Data Structures | Audio input/output | Demonstrates FIFO queue, Stack, RingBuffer, and FixedStr. Audio delay effect using RingBuffer (300ms delay). Serial output shows FIFO/Stack operations. OLED-style string formatting examples. | No delay = RingBuffer size too small; Distorted = buffer overflow | SKIP: |
| **control_mapping.nim** | Parameter Mapping | Serial output | Shows Parameter curves (linear/exp/log/cubic) and MappedValue quantization. Simulates synth controls: frequency (exp curve), filter (linear), resonance (log), steps (quantized). Prints mapped values. | Values out of range = curve misconfiguration | SKIP: |
| **system_info.nim** | System Monitoring | Serial output | Displays STM32 unique device ID (96-bit hex). Real-time CPU load monitoring showing average and peak usage. Performance tips based on CPU load thresholds. Runs indefinitely. | CPU = 0% = CpuLoad not measuring; ID all zeros = chip issue | SKIP: |

### Sensor Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **sensor_demo.nim** | Sensors | I2C sensors on D11/D12 | Consolidated sensor demo with compile-time modes: **IMU** - ICM20948 9-axis motion tracking (accel/gyro/mag), requires libDaisy patch; **GESTURE** - APDS9960 gesture/proximity/color sensing; **ENVIRONMENTAL** - DPS310 pressure/altitude + TLV493D magnetic field; **TOUCH** - MPR121 capacitive touch + NeoTrellis 4x4 RGB matrix for 16-step sequencer. | No magnetometer = patch not applied; No gestures = check orientation; Touch not detected = adjust sensitivity | SKIP: |

**Hardware Notes for Sensor Examples:**
- All sensor modes use I2C on pins D11 (SCL) and D12 (SDA)
- I2C pull-up resistors (4.7kΩ typical) required on SCL and SDA lines
- Power sensors from 3.3V output (most sensors are 3.3V only)
- ICM20948 mode requires applying libDaisy patch before compilation
- Sensor addresses: ICM20948 (0x68/0x69), APDS9960 (0x39), DPS310 (0x77), TLV493D (0x5E), MPR121 (0x5A), NeoTrellis (0x2E)

### System Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **system_demo.nim** | System | None (onboard LED + USB serial) | Consolidated system demo with compile-time modes: **SYSTEM_CONTROL** - Prints system clock frequencies (CPU, AHB, APB1, APB2), LED blinks at 1Hz, heartbeat every 10s with uptime/memory info; **SYSTEM_INFO** - Displays STM32 unique device ID, real-time CPU load monitoring; **ADVANCED_LOGGING** - Performance profiling with microsecond timing, structured logging patterns. | No serial = USB not connected; LED not blinking = check init; CPU = 0% = not measuring | SKIP: |

### LED Drivers & I/O Expansion Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **led_drivers.nim** | LED Driver/PWM | PCA9685 16-ch PWM driver on I2C (D11=SCL, D12=SDA), 16 LEDs, optional OE pin on D10 | Smooth wave pattern across 16 LEDs. Each LED brightness controlled independently via PCA9685 PWM driver. Sine wave animation creates traveling wave effect. Updates at 10Hz. Uses DMA for efficient I2C transfers with gamma correction. | No LEDs = check I2C address (default 0x40); Flickering = DMA buffer issue; All LEDs same brightness = channel addressing wrong | SKIP: |
| **io_expander_demo.nim** | GPIO/I2C/SPI | Various I/O expanders | Consolidated I/O expansion demo with compile-time modes: **IO_EXPANSION** - MCP23017 16-bit I/O expander, reads 8 buttons mirrors to 8 LEDs; **SHIFT_REGISTER** - Button matrix reading via shift registers; **CV_EXPANDER** - MAX11300 PIXI for Eurorack CV pass-through (±5V). | No response = check I2C address; Inverted LEDs = check wiring; No CV output = check SPI | SKIP: |
| **vu_meter.nim** | Audio/LED | APA102/SK9822 DotStar LED strip (16 LEDs) on SPI (D7=MOSI, D9=SCK), audio input | Stereo VU meter with RGB LEDs. Left channel (LEDs 0-7) shows green-to-red gradient, right channel (LEDs 8-15) shows blue-to-red gradient. Peak detection with smooth decay. Audio passthrough. Updates at 50Hz. 8 levels per channel. | LEDs wrong color = check color_order (GRB/RGB); No response to audio = verify audio input; Too bright = reduce global brightness | SKIP: |

**Hardware Notes for LED/IO Examples:**
- LED driver and GPIO expansion use I2C on pins D11 (SCL) and D12 (SDA)
- I2C pull-up resistors (4.7kΩ typical) required on SCL and SDA lines
- DotStar and MAX11300 use SPI interface (faster than I2C for high-bandwidth data)
- PCA9685 supports up to 62 devices on same I2C bus (different addresses)
- DotStar strips can be chained (up to 64 pixels per driver recommended)
- All examples compile successfully (100% pass rate)

### Special Examples

| Example | Category | Hardware Required | Expected Behavior | Common Issues | Status |
|---------|----------|-------------------|-------------------|---------------|--------|
| **panicoverride.nim** | System | None | Demonstrates custom panic handler. Intentionally crashes to show LED blink pattern on panic. LED blinks rapidly (SOS pattern). | Normal - this example is supposed to crash! | SKIP: |

---

## Hardware Requirements

### Minimal Setup (No External Hardware)

These examples work with Daisy Seed alone:
- **blink.nim** - Onboard LED only
- **codec_comparison.nim** - Onboard codec detection
- **panicoverride.nim** - Onboard LED only
- **timer_advanced.nim** - Serial output only
- **control_mapping.nim** - Serial output only
- **system_demo.nim** - Serial output + LED, compile-time modes for system_info/system_control/advanced_logging

### Board-Specific Examples (Require Daisy Boards)

These examples require complete board platforms:
- **pod_demo.nim** - Daisy Pod required (modes: SIMPLE/SYNTH/EFFECT)
- **patch_demo.nim** - Daisy Patch required (modes: SIMPLE/EFFECT/CV_PROCESSOR)
- **field_demo.nim** - Daisy Field required (modes: KEYBOARD/MODULAR)
- **patch_sm_demo.nim** - Daisy Patch SM required (modes: CV_PROCESSOR/QUANTIZER)
- **petal_demo.nim** - Daisy Petal required (modes: SIMPLE/OVERDRIVE)
- **versio_demo.nim** - Daisy Versio required (modes: SIMPLE/REVERB)
- **legio_demo.nim** - Daisy Legio required (modes: SIMPLE/CV_METER)

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed wiring and setup instructions.

---

## Common Patterns

### Standard Initialization

All examples follow this pattern:

```nim
import nimphea

useNimpheaNamespace()  # Macro for C++ includes

var hw: DaisySeed  # Global hardware object

proc main() =
  hw = initDaisy()  # Initialize hardware
  
  # Your setup code here
  
  while true:
    # Main loop
    hw.delay(100)

when isMainModule:
  main()
```

### Audio Callback Structure

```nim
proc audioCallback(input: ptr ptr cfloat, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
  ## Real-time audio processing
  ## RULES:
  ## - No allocations (no seq, no string)
  ## - No printing/logging
  ## - No delays or blocking calls
  ## - Keep processing fast and deterministic
  
  for i in 0..<size:
    # Process left channel
    output[0][i] = processLeft(input[0][i])
    # Process right channel
    output[1][i] = processRight(input[1][i])

proc main() =
  hw = initDaisy()
  hw.startAudio(audioCallback)  # Register callback
  
  while true:
    # Main loop runs independently from audio
    hw.delay(10)
```

### GPIO Pattern

```nim
var pin: GPIO

proc main() =
  hw = initDaisy()
  
  pin.init(DPin0, MODE_INPUT, PULL_UP)
  
  while true:
    let state = pin.read()
    hw.setLed(state)
    hw.delay(10)
```

### I2C Pattern

```nim
var i2c: I2CHandle

proc main() =
  hw = initDaisy()
  
  var cfg = createI2CConfig()
  cfg.periph = I2C_PERIPH_1
  cfg.speed = I2C_SPEED_400KHZ
  cfg.pin_config.scl = DPin11
  cfg.pin_config.sda = DPin12
  
  discard i2c.init(cfg)
  
  # Write to device
  discard i2c.transmitBlocking(0x3C, addr data, 1, 1000)
```

---

## Troubleshooting

### Compilation Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `Error: cannot open file 'nimphea.nim'` | Wrong directory | Import from correct path or install via nimble |
| `undefined reference to daisy::DaisySeed` | libDaisy not built | `cd libDaisy && make` |
| `arm-none-eabi-gcc: command not found` | Toolchain not installed | Install ARM embedded toolchain |
| `Error: undeclared identifier` | Missing import | Add required `import nimphea/module` |

### Flashing Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `dfu-util: Cannot open DFU device` | Not in DFU mode | Hold BOOT, press RESET, release BOOT |
| `No DFU capable USB device available` | Driver issue (Windows) | Install Zadig drivers for DFU device |
| `Lost device after RESET` | Normal | Device rebooted - not an error |
| `Error during download` | Corrupted binary | `nimble make <example>` again |

### Runtime Issues

#### No LED Activity

1. Check hardware initialization: `hw.init()`
2. Try `blink.nim` (simplest example)
3. Verify power supply (USB or external 3.3-5V)
4. Check for panic crash (LED might blink SOS pattern)

#### No Audio Output

1. Verify audio callback registered: `hw.startAudio(callback)`
2. Check audio cable connections (input and output)
3. Test with `audio_demo.nim` SINE_WAVE mode (doesn't need input)
4. Verify sample rate matches hardware (48kHz default)
5. Check volume level on amp/headphones

#### Peripheral Not Working

**I2C:**
- Run `comm_demo.nim` I2C_SCANNER mode to detect devices
- Check pull-up resistors (4.7kΩ to 3.3V)
- Verify device address (7-bit: 0x3C, not 8-bit: 0x78)
- Check power supply to peripheral (3.3V or 5V)

**SPI:**
- Verify MOSI/MISO not swapped
- Check clock polarity/phase settings
- Confirm CS pin actively driven
- Scope the signals if available

**ADC:**
- Ensure voltage range 0-3.3V (exceeding may damage chip!)
- Check pot wiring (wiper to ADC pin, ends to GND/3.3V)
- Add 100nF capacitor for noise filtering
- Verify ADC pin supports analog input (A0-A11)

**PWM:**
- Confirm pin supports PWM (not all GPIO pins do)
- Check PWM frequency (visible flicker = too low)
- Verify duty cycle range (0-100%)
- Test with different pins if issue persists

### Performance Issues

**Audio Glitches/Clicks:**
- Audio callback taking too long
- Remove logging/printing from callback
- Reduce buffer processing complexity
- Increase audio buffer size (tradeoff: more latency)

**Slow Display Updates:**
- I2C speed too low (use 400kHz)
- Drawing too much per frame
- Use partial updates instead of full clears
- SPI faster than I2C for displays

**Controls Feel Sluggish:**
- Main loop has delays too large
- Reduce `hw.delay()` duration
- Use hardware timers for precise timing
- Check update rate in control library

---

## Resources

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Detailed hardware testing procedures
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete API documentation
- **[BUILD_SYSTEM.md](BUILD_SYSTEM.md)** - Build configuration and system details
- **[libDaisy Docs](https://github.com/electro-smith/DaisyWiki/wiki)** - Hardware documentation
- **[Nim Manual](https://nim-lang.org/docs/manual.html)** - Nim language reference

---

**Questions?** Open a GitHub discussion or issue!
