# Build System Documentation

**Nimphea** uses a pure **nimble-based** build system for cross-compiling Nim code to ARM Cortex-M7 (Daisy Seed hardware).

This document explains how to build, test, and flash examples using the nimble make system.

---

## Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Nimble Tasks](#nimble-tasks)
- [Build Process Details](#build-process-details)
- [Flashing to Hardware](#flashing-to-hardware)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

---

## Requirements

### Software Requirements

1. **Nim Compiler** (≥ 2.0.0)
   ```bash
   nim --version  # Check version
   ```

2. **ARM GNU Toolchain** (arm-none-eabi-gcc)
   ```bash
   arm-none-eabi-gcc --version
   ```
   
   Installation:
   - **macOS**: `brew install --cask gcc-arm-embedded`
   - **Linux**: `sudo apt-get install gcc-arm-none-eabi`
   - **Windows**: Download from [ARM Developer](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm)

3. **dfu-util** (for flashing via USB)
   ```bash
   dfu-util --version
   ```
   
   Installation:
   - **macOS**: `brew install dfu-util`
   - **Linux**: `sudo apt-get install dfu-util`
   - **Windows**: Download from [dfu-util.org](http://dfu-util.sourceforge.net/)

4. **Git** (for submodules)
   ```bash
   git --version
   ```

### Hardware Requirements

- **Daisy Seed** board (or Daisy Pod/Patch/Field/etc.)
- **USB cable** (for programming and power)

---

## Quick Start

### 1. Clone and Setup

```bash
# Clone repository with submodules
git clone --recursive https://github.com/Brokezawa/nimphea.git
cd nimphea

# Setup development environment (builds libDaisy C++ library)
nimble init_libdaisy
```

**What `nimble init_libdaisy` does:**
- Initializes git submodules (`libDaisy`)
- Builds the libDaisy C++ library
- Takes ~2-5 minutes on first run

### 2. Build an Example

```bash
# Build the blink example (default)
nimble make blink

# Build any other example
nimble make audio_demo
nimble make pod_demo
```

**Output**: Binary files in `build/` directory
- `build/blink.elf` - ELF executable with debug symbols
- `build/blink.bin` - Raw binary for flashing
- `build/blink.map` - Memory map file

### 3. Flash to Hardware

```bash
# Put Daisy in bootloader mode:
#   1. Hold BOOT button
#   2. Press RESET button
#   3. Release BOOT button

# Flash the binary
nimble flash blink
```

---

## Nimble Tasks

### `nimble init_libdaisy`

**Description**: One-time setup of development environment

**What it does**:
- Clones libDaisy submodule if not present
- Compiles libDaisy C++ library
- Verifies ARM toolchain is available

**Usage**:
```bash
nimble init_libdaisy
```

**When to run**:
- After first clone
- After pulling updates that change libDaisy version
- If libDaisy build artifacts are deleted

---

### `nimble make <example>`

**Description**: Cross-compile a Nim example for ARM Cortex-M7

**Usage**:
```bash
nimble make <example_name>
```

**Examples**:
```bash
nimble make blink
nimble make audio_demo
nimble make pod_demo
nimble make system_demo
```

**What it does**:
1. Compiles FatFS C dependencies
2. Compiles Nim source to C++
3. Links with libDaisy C++ library
4. Generates ELF and BIN files
5. Shows binary size statistics

**Output**:
```
build/
├── <example>.elf      # Executable with debug symbols
├── <example>.bin      # Raw binary for flashing
├── <example>.map      # Memory map
└── .nimcache/         # Nim compiler cache
```

**Compiler Settings**:
- CPU: ARM Cortex-M7
- FPU: FPv5-D16 (hard float)
- Memory Management: ARC (Automatic Reference Counting)
- Optimization: Size (-Os)
- No heap allocation in audio callbacks
- No exceptions (goto-based error handling)

---

### `nimble test`

**Description**: Quick syntax check of all examples

**Usage**:
```bash
nimble test
```

**What it does**:
- Runs `nim check` on all 43 examples
- Verifies syntax and type correctness
- **Fast**: ~7 seconds for all examples
- **Does NOT**:
  - Link with libDaisy
  - Cross-compile for ARM
  - Catch linker errors or missing symbols

**Example Output**:
```
=== Quick Syntax Check (all examples) ===
============================================================
Checking blink                           ... ✓ PASS
Checking audio_demo                      ... ✓ PASS
Checking pod_demo                        ... ✓ PASS
...
============================================================
SUMMARY:
  Passed: 43
  Failed: 0
============================================================

✓ All examples passed syntax check!

Note: This only checks syntax. For full build validation:
  nimble test_build    # Compile all examples with ARM toolchain
```

**Use cases**:
- Development workflow (quick feedback)
- Pre-commit checks
- Continuous integration (fast CI)
- Ensuring all examples stay up-to-date

**Limitations**:
This is a **fast syntax check** only. It will NOT catch:
- Missing symbols in libDaisy
- Linker errors
- ARM-specific compilation issues
- Binary size problems

For complete validation, use `nimble test_build`.

---

### `nimble test_build`

**Description**: Full compilation test with ARM cross-compilation and linking

**Usage**:
```bash
nimble test_build
```

**What it does**:
- Builds ALL 43 examples with ARM toolchain
- Links each example with libDaisy
- Verifies all symbols resolve correctly
- Checks binary sizes
- **Slow**

**Example Output**:
```
=== Full Build Test (all examples) ===
============================================================

[1/43] Building blink...
------------------------------------------------------------
  ✓ blink - BUILD PASSED

[2/43] Building audio_demo...
------------------------------------------------------------
  ✓ audio_demo - BUILD PASSED

...

============================================================
FULL BUILD TEST SUMMARY:
  Passed: 43/43
  Failed: 0/43
  Duration: 42m 15s
============================================================

✓ All examples built successfully with ARM toolchain!

This confirms:
  - ARM cross-compilation works
  - All examples link with libDaisy
  - No missing symbols or linker errors
```

**Use cases**:
- Before releases
- After libDaisy updates
- After changing core build system
- Final validation before merging PRs
- Ensuring no linker errors exist

**Requirements**:
- ARM toolchain installed (`arm-none-eabi-gcc`)
- libDaisy built (`nimble init_libdaisy` completed)
- Sufficient disk space (~500MB for all binaries)

**When to use**:
- Use `nimble test` for **daily development** (fast)
- Use `nimble test_build` for **pre-release validation** (thorough)

---

### `nimble flash <example>`

**Description**: Flash binary to Daisy hardware via DFU

**Usage**:
```bash
nimble flash <example_name>
```

**Prerequisites**:
1. Daisy must be in **bootloader mode**:
   - Hold **BOOT** button
   - Press **RESET** button
   - Release **BOOT** button
   
2. Binary must be built first:
   ```bash
   nimble make blink    # Build first
   nimble flash blink    # Then flash
   ```

**What it does**:
- Verifies binary exists
- Uses `dfu-util` to flash via USB
- Automatically resets Daisy after flashing

**Troubleshooting**:
- **"No DFU capable USB device found"**: Daisy not in bootloader mode
- **"Binary not found"**: Run `nimble make` first
- **Permission denied (Linux)**: Add udev rules or use `sudo`

---

### `nimble clear`

**Description**: Remove all build artifacts

**Usage**:
```bash
nimble clear
```

**What it removes**:
- `build/` directory and all contents
- Compiled binaries (.elf, .bin, .map)
- Nim compiler cache

**When to use**:
- Before rebuilding from scratch
- After changing compiler flags
- To free disk space
- When troubleshooting build issues

**Note**: Use `nimble clear` instead of `nimble clean`. The built-in `nimble clean` only removes nimcache but not the `build/` directory.

---

### `nimble docs`

**Description**: Generate HTML API documentation for all Nimphea modules

**Usage**:
```bash
nimble docs
```

**What it does**:
- Generates documentation for all 85+ modules in `src/`
- Creates index files for each module
- Builds a comprehensive searchable index
- Includes GitHub source links for each definition
- Takes ~2-3 minutes to complete

**Output**:
```
docs/api/
├── theindex.html              # Main searchable index (start here!)
├── nimphea.html               # Core module documentation
├── nimphea_macros.html        # Macro system documentation
├── boards/
│   ├── daisy_seed.html
│   ├── daisy_pod.html
│   └── ...
├── per/
│   ├── adc.html
│   ├── dac.html
│   ├── spi.html
│   └── ...
├── hid/
│   ├── switch.html
│   ├── led.html
│   └── ...
├── dev/
│   ├── oled.html
│   ├── ws2812.html
│   └── ...
├── dochack.js                 # Search functionality
└── nimdoc.out.css             # Documentation styling
```

**View documentation**:

**Recommended - Start with the searchable index**:
```bash
# Serve documentation locally (recommended)
python3 -m http.server 7029 --directory docs/api

# Open in browser
# macOS: open http://localhost:7029/theindex.html
# Linux: xdg-open http://localhost:7029/theindex.html
# Windows: start http://localhost:7029/theindex.html
```

**Alternative - Direct file access** (search won't work):
```bash
# macOS
open docs/api/theindex.html

# Linux
xdg-open docs/api/theindex.html

# Windows
start docs/api/theindex.html
```

**Features**:
- **85+ modules** fully documented
- **Search functionality** (requires HTTP server)
- **Cross-referenced** type definitions and procedures
- **GitHub source links** - Click "See source" to view implementation
- **Code examples** - Documented with `##` comments
- **Type annotations** - Full type signatures for all procedures

**Important Notes**:
- Search feature **requires HTTP server** (won't work with `file://`)
- Documentation reflects current state of `src/` directory
- Source links point to main branch on GitHub
- Generated files should **not** be committed (regenerate before releases)

**When to generate docs**:
- Before each release
- After significant API changes
- When updating module documentation comments
- To share with team members

---

## Build Process Details

### Cross-Compilation Settings

The build system configures Nim for ARM Cortex-M7 cross-compilation:

```nim
--cpu:arm                    # ARM architecture
--os:standalone              # No OS (bare metal)
--mm:arc                     # ARC memory management
--opt:size                   # Optimize for size
--threads:off                # No threading
--exceptions:goto            # Goto-based exceptions (no unwinding)
--panics:on                  # Enable panics
--define:useMalloc           # Use C malloc
--define:noSignalHandler     # No signal handlers
```

### ARM Compiler Flags

**Architecture**:
```
-mcpu=cortex-m7              # Cortex-M7 CPU
-mthumb                      # Thumb-2 instruction set
-mfpu=fpv5-d16               # Hardware FPU
-mfloat-abi=hard             # Hard-float ABI
```

**Optimization**:
```
-Os                          # Optimize for size
-fdata-sections              # Separate data sections
-ffunction-sections          # Separate function sections
-Wl,--gc-sections            # Garbage collect unused sections
```

### Memory Layout

**Linker Script**: `libDaisy/core/STM32H750IB_flash.lds`

**Memory Regions**:
- **FLASH**: 128KB (0x08000000)
- **DTCMRAM**: 128KB (0x20000000) - Data tightly coupled memory
- **RAM_D1**: 512KB (0x24000000) - AXI SRAM
- **RAM_D2**: 288KB (0x30000000) - AHB SRAM
- **RAM_D3**: 64KB (0x38000000) - AHB SRAM
- **ITCMRAM**: 64KB (0x00000000) - Instruction tightly coupled memory
- **SDRAM**: 64MB (0xC0000000) - External SDRAM (if populated)

### Binary Size

Typical sizes for different example types:

| Example Type | Flash Usage | RAM Usage |
|--------------|-------------|-----------|
| Blink (minimal) | ~10KB | ~5KB |
| Audio Basic | ~25KB | ~10KB |
| Audio + DSP | ~40KB | ~20KB |
| Full Board (Pod/Patch) | ~50-80KB | ~30-50KB |
| Maximum (all features) | ~120KB | ~100KB |

**Note**: Nim's ARC + size optimization produces compact binaries comparable to C++.

---

## Flashing to Hardware

### Bootloader Mode

**Enter DFU bootloader**:
1. Hold **BOOT** button
2. Press and release **RESET** button
3. Release **BOOT** button
4. LED should be dim/off (not blinking)

**Exit bootloader** (return to normal mode):
- Press **RESET** button
- Or disconnect/reconnect power

### DFU Flashing

**Via nimble**:
```bash
nimble flash blink
```

**Manual dfu-util**:
```bash
dfu-util -a 0 -s 0x08000000:leave -D build/blink.bin
```

**Parameters**:
- `-a 0`: Alt setting 0 (internal flash)
- `-s 0x08000000:leave`: Flash address + reset after
- `-D <file>`: Binary file to flash

### Alternative: ST-Link

If you have an ST-Link programmer:

```bash
st-flash write build/blink.bin 0x8000000
```

---

## Troubleshooting

### Compilation Errors

#### "arm-none-eabi-gcc: command not found"

**Problem**: ARM toolchain not installed or not in PATH

**Solution**:
```bash
# macOS
brew install --cask gcc-arm-embedded

# Linux
sudo apt-get install gcc-arm-none-eabi

# Verify
arm-none-eabi-gcc --version
```

#### "libdaisy.a: No such file"

**Problem**: libDaisy not compiled

**Solution**:
```bash
nimble init_libdaisy
```

#### "Error: undeclared identifier"

**Problem**: Missing import or API change

**Solution**:
- Check example uses correct imports
- Verify you're using compatible Nimphea version
- Check API_REFERENCE.md for correct usage

### Flashing Errors

#### "No DFU capable USB device found"

**Problem**: Daisy not in bootloader mode

**Solution**:
1. Put Daisy in bootloader mode (see above)
2. Verify USB connection
3. Check `lsusb` (Linux/macOS) or Device Manager (Windows)
4. Should see "STM32 BOOTLOADER" device

#### "dfu-util: command not found"

**Problem**: dfu-util not installed

**Solution**:
```bash
# macOS
brew install dfu-util

# Linux
sudo apt-get install dfu-util
```

#### "Cannot open DFU device" (Linux)

**Problem**: Permission denied (USB access)

**Solution 1 - Add udev rule** (recommended):
```bash
# Create udev rule
sudo nano /etc/udev/rules.d/50-daisy.rules

# Add this line:
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666"

# Reload rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reconnect Daisy
```

**Solution 2 - Use sudo** (temporary):
```bash
sudo nimble flash blink
```

### Runtime Issues

#### LED not blinking / No output

**Possible causes**:
1. **Not flashed**: Verify flash succeeded
2. **Wrong binary**: Built for different board
3. **Hardware issue**: Check power, connections
4. **Panic/crash**: LED blinks SOS pattern (... --- ...)

**Debug steps**:
```bash
# Rebuild from scratch
nimble clear
nimble make blink
nimble flash blink

# Try simplest example
nimble make blink
nimble flash blink
```

#### Audio not working

**Check**:
1. Audio connections (input/output cables)
2. Volume levels
3. Correct board variant (Seed vs Pod vs Patch)
4. Sample rate configuration

#### USB serial not appearing

**Check**:
1. Correct example (usb_serial.nim)
2. USB cable supports data (not just power)
3. Driver installed (Windows may need STM32 VCP driver)
4. Not in bootloader mode (bootloader blocks normal USB)

---

## Advanced Usage

### Custom Build Configuration

Create a `config.nims` file in your project root:

```nim
# Custom optimization flags
switch("opt", "speed")  # Optimize for speed instead of size

# Custom defines
switch("define", "CUSTOM_FEATURE")

# Debug builds
switch("define", "debug")
switch("debugger", "native")
```

### Building for Different Boards

Examples automatically detect board type from filename:
- `pod_*.nim` → Daisy Pod
- `patch_*.nim` → Daisy Patch
- `field_*.nim` → Daisy Field
- Default → Daisy Seed

### Memory Profiling

Check memory usage after build:

```bash
nimble make myexample
arm-none-eabi-size build/myexample.elf
```

Output:
```
   text    data     bss     dec     hex filename
  25684     124    5240   31048    7948 build/myexample.elf
```

- **text**: Flash usage (code + const data)
- **data**: Initialized RAM
- **bss**: Uninitialized RAM
- **dec/hex**: Total size

### Disassembly

View generated assembly:

```bash
arm-none-eabi-objdump -d build/myexample.elf > myexample.asm
```

### Build Artifacts

After a successful build:

```
build/
├── <example>.elf          # ELF executable (for debugging)
├── <example>.bin          # Raw binary (for flashing)
├── <example>.map          # Memory map (symbol addresses)
├── ccsbcs.o               # FatFS C object
└── .nimcache/             # Nim compiler cache
    ├── *.c / *.cpp        # Generated C/C++ code
    ├── *.h                # Generated headers
    └── *.o                # Object files
```

---

## Resources

- **API Reference**: [API_REFERENCE.md](API_REFERENCE.md)
- **Examples**: [EXAMPLES.md](EXAMPLES.md)
- **libDaisy Docs**: https://github.com/electro-smith/DaisyWiki/wiki
- **Nim Manual**: https://nim-lang.org/docs/manual.html

---

## Questions?

Open an issue or discussion on GitHub!
