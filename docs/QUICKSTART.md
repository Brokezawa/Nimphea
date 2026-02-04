# Quick Start Guide

Get your first Nim program running on Daisy Seed in under 10 minutes!

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Daisy Seed board** with USB cable
- [ ] **Nim** installed (version 2.0 or later)
- [ ] **ARM toolchain** installed (`arm-none-eabi-gcc`)
- [ ] **dfu-util** or **ST-Link** tools for flashing
- [ ] **Terminal** or command prompt

## Step 1: Install Dependencies

### Install Nim

**macOS**:
```bash
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```

**Linux** (Ubuntu/Debian):
```bash
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```

**Windows**:
Download from [https://nim-lang.org/install.html](https://nim-lang.org/install.html)

Verify installation:
```bash
nim --version  # Should show 2.0 or later
```

### Install ARM Toolchain

**macOS**:
```bash
brew install --cask gcc-arm-embedded
```

**Linux** (Ubuntu/Debian):
```bash
sudo apt-get install gcc-arm-none-eabi binutils-arm-none-eabi
```

**Windows**:
Download from [ARM website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)

Verify installation:
```bash
arm-none-eabi-gcc --version
```

### Install Flash Tool

**For DFU (USB) flashing**:
```bash
# macOS
brew install dfu-util

# Linux
sudo apt-get install dfu-util

# Windows
# Download from https://dfu-util.sourceforge.net/
```

**For ST-Link flashing** (if you have ST-Link hardware):
```bash
# macOS
brew install stlink

# Linux
sudo apt-get install stlink-tools
```

## Step 2: Get Nimphea

Clone this wrapper with its libDaisy submodule:

```bash
# Navigate to your projects directory
cd ~/Projects  # or wherever you keep projects

# Clone with submodules
git clone --recursive https://github.com/Brokezawa/nimphea
cd nimphea

# Your structure will be:
# ~/Projects/nimphea/
# ├── libDaisy/         # Submodule
# ├── src/              # Nim wrapper
# └── examples/         # Examples
```

## Step 3: One-Time Setup

Set up the development environment (this builds libDaisy):

```bash
# In nimphea directory
nimble init_libdaisy

# This takes 2-3 minutes and:
# - Initializes git submodules
# - Builds the libDaisy C++ library
# - Verifies your ARM toolchain
```

## Step 4: Build Your First Example

```bash
# Build the blink example (simplest one)
nimble make blink

# You should see compilation output ending with binary size info
```

**Success!** You've compiled your first Nim program for Daisy!

## Step 5: Flash to Hardware

### Prepare Your Daisy

**For DFU (USB) mode:**
1. Hold the **BOOT** button on Daisy
2. While holding BOOT, press and release **RESET**
3. Release **BOOT**
4. Daisy is now in bootloader mode (LED might be dim or off)

### Flash the Program

```bash
# Flash via USB (DFU)
nimble flash blink
```

You should see:
```
Flashing build/blink.bin via DFU...
dfu-util ...
Download [=========================] 100%
File downloaded successfully
```

**Your Daisy should now be blinking its LED!**

### Alternative: ST-Link

If you have an ST-Link programmer:
```bash
nimble stlink blink
```

## Step 6: Try Other Examples

Build and flash any other example:

```bash
nimble make audio_demo
nimble flash audio_demo

# Or with ST-Link
nimble stlink audio_demo
```

Available examples include:
- `blink` - LED blink
- `gpio_demo` - Button and GPIO
- `audio_demo` - Audio I/O
- `adc_demo` - Analog input
- `pwm_demo` - PWM output
- `oled_basic` - OLED display
- `comm_demo` - I2C/SPI communication
- `midi_demo` - MIDI I/O
- `encoder` - Rotary encoder
- `pod_demo` - Daisy Pod board
- And 30+ more!

Or test all examples at once:
```bash
nimble test
```

## Step 7: Create Your Own Project

The recommended approach is to work within the nimphea examples directory or create a standalone project:

### Method 1: Add to Examples Directory

```bash
cd nimphea/examples

# Copy an example as a template
cp blink.nim my_project.nim

# Edit my_project.nim with your code

# Build and flash
nimble make my_project
nimble flash my_project
```

### Method 2: Standalone Project

Create a new directory outside nimphea:

```bash
mkdir ~/my_daisy_project
cd ~/my_daisy_project

# Create your program
cat > my_program.nim << 'EOF'
import /path/to/nimphea/src/nimphea

var hw: DaisySeed

proc main() =
  hw = initDaisy()
  
  while true:
    hw.setLed(true)
    hw.delay(500)
    hw.setLed(false)
    hw.delay(500)

when isMainModule:
  main()
EOF

# Use nimble from nimphea directory to build
cd /path/to/nimphea
nimble make my_program
nimble flash my_program
```

## Understanding the Build System

The nimble-based build system provides simple commands for all development tasks.

### Core Commands

```bash
nimble init_libdaisy           # One-time setup (builds libDaisy)
nimble make <name>             # Build example for ARM
nimble flash <name>            # Flash via USB (DFU)
nimble stlink <name>           # Flash via ST-Link
nimble test                    # Check all examples compile
nimble clear                   # Clean build artifacts
nimble docs                    # Generate API docs
```

### Build Output

After `nimble make <name>`, you'll find:
- `build/<name>.elf` - Executable with debug symbols
- `build/<name>.bin` - Binary for flashing
- `build/<name>.map` - Memory map

## Troubleshooting

### "arm-none-eabi-gcc: command not found"

ARM toolchain not installed or not in PATH.

**Fix:**
```bash
# macOS
brew install --cask gcc-arm-embedded

# Linux
sudo apt-get install gcc-arm-none-eabi

# Windows
# Download from ARM website and add to PATH
```

### "command not found: nimble"

Nim not properly installed.

**Fix:**
```bash
nim --version  # Check if Nim is installed
# If not found, install from https://nim-lang.org/install.html

# Restart terminal after installing
nimble --version  # Should work now
```

### "nimble init_libdaisy failed"

libDaisy submodule not initialized or ARM toolchain missing.

**Fix:**
```bash
# Ensure submodules are initialized
git submodule update --init

# Verify ARM toolchain
arm-none-eabi-gcc --version

# Try setup again
nimble init_libdaisy
```

### "dfu-util: Cannot open DFU device"

Daisy not in bootloader mode or USB not connected.

**Fix:**
1. Hold BOOT button
2. Press and release RESET (while holding BOOT)
3. Release BOOT
4. Try `nimble flash <name>` again

On Linux, you may need udev rules:
```bash
# Create udev rule
sudo cat > /etc/udev/rules.d/99-daisy.rules << 'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666"
EOF

sudo udevadm control --reload-rules
```

### "nimble make: command not found" or build fails

You're not in the nimphea directory.

**Fix:**
```bash
cd /path/to/nimphea  # Make sure you're in the right directory
nimble make blink   # Try again
```

### "Error: cannot open file: src/nimphea"

Import path incorrect.

**Fix:**
Make sure you're in the nimphea directory:
```bash
cd /path/to/nimphea
nimble make blink
```

Or use absolute paths in your code:
```nim
import /path/to/nimphea/src/nimphea
```

## Next Steps

Now that you have the basics working:

1. **Read the examples** - See [EXAMPLES.md](EXAMPLES.md) for detailed descriptions
2. **Learn the API** - Check [API_REFERENCE.md](API_REFERENCE.md) for all available functions
3. **Explore examples** - See [EXAMPLES.md](EXAMPLES.md) for practical demonstrations
4. **Contribute** - See [CONTRIBUTING.md](CONTRIBUTING.md) if you want to help improve the wrapper

## Quick Reference

### Basic LED Blink

```nim
import nimphea

var hw: DaisySeed

proc main() =
  hw = initDaisy()
  while true:
    hw.setLed(true)
    hw.delay(500)
    hw.setLed(false)
    hw.delay(500)

when isMainModule:
  main()
```

### Audio Passthrough

```nim
import nimphea

var hw: DaisySeed

proc audioCallback(input: ptr ptr cfloat, output: ptr ptr cfloat, 
                   size: csize_t) {.cdecl.} =
  for i in 0..<size:
    output[0][i] = input[0][i]  # Left
    output[1][i] = input[1][i]  # Right

proc main() =
  hw = initDaisy()
  hw.startAudio(audioCallback)
  while true:
    hw.delay(100)

when isMainModule:
  main()
```

### GPIO Input

```nim
import nimphea

var hw: DaisySeed

proc main() =
  hw = initDaisy()
  
  # Configure pin as input with pull-up
  var pin: GPIO
  pin.init(DPin10, MODE_INPUT, PULL_UP)
  
  while true:
    let state = pin.read()
    hw.setLed(state)  # LED follows button
    hw.delay(10)

when isMainModule:
  main()
```

## Help & Support

**Need help?**
- Check the `EXAMPLES.md` file for example explanations
- Read `API_REFERENCE.md` for function documentation
- Search GitHub issues for similar problems
- Ask on the [Electro-Smith forum](https://forum.electro-smith.com/)
- Create a GitHub issue with your question

---

**Congratulations!** You're now ready to develop Daisy Seed firmware in Nim!

For more advanced topics, continue with:
- **[EXAMPLES.md](EXAMPLES.md)** - Detailed example walkthroughs
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete API documentation
- **[EXAMPLES.md](EXAMPLES.md)** - Practical code examples

Happy coding! 🚀
