# Build System Documentation

[← Home](index.md)


Nimphea uses a pure Nimble-based build system for cross-compiling Nim code to ARM Cortex-M7 (Daisy Seed hardware). This approach eliminates the need for complex Makefiles in your projects.

## Requirements

### Software Requirements

1. **Nim Compiler** (>= 2.0.0)
2. **ARM GNU Toolchain** (arm-none-eabi-gcc)
3. **dfu-util** (for flashing via USB)
4. **OpenOCD** (optional, for flashing via ST-Link)

## Workflow

### 1. Install Nimphea

The Nimphea library is installed as a standard Nimble package:

```bash
nimble install nimphea
```

During installation, Nimble will automatically clone the required version of libDaisy and build it for ARM. This ensures that you have a consistent, pre-compiled hardware abstraction layer ready to link against.

### 2. Create a Project

We recommend starting from a template:
- [Basic Template](https://github.com/Brokezawa/nimphea-template-basic) - LED blink and serial logging.
- [Audio Template](https://github.com/Brokezawa/nimphea-template-audio) - Real-time stereo audio processing.

### 3. Build Tasks

Standard projects provide three primary Nimble tasks:

#### nimble make
Compiles your Nim code using the C++ backend, cross-compiles it for ARM Cortex-M7, and links it against the pre-built libDaisy library. 

The output is generated in the `build/` directory:
- `main.elf`: Executable with debug symbols.
- `main.bin`: Raw binary for flashing.

#### nimble flash
Flashes the `main.bin` file to your Daisy Seed via USB using `dfu-util`. You must enter DFU mode first (hold BOOT, press and release RESET).

#### nimble stlink
Flashes the `main.elf` file via an ST-Link probe using `openocd`. This method is faster and does not require manual button presses on the board.

## Boot Modes and Optional Features

Nimphea supports three boot modes for deploying applications. See [BOOT_MODES](./BOOT_MODES.md) for a comprehensive decision tree and guide.

### Boot Modes

1. **BOOT_NONE (Default)**
   - Direct flash to internal flash (0x08000000)
   - No bootloader required
   - Best for development and simple projects
   - Use with `nimble stlink` (ST-Link) or `nimble flash` (DFU)

2. **BOOT_SRAM**
   - Application runs from SRAM (0x20000000), loaded by DFU bootloader
   - Requires pre-installed DFU bootloader on device
   - Allows iterative development without re-flashing bootloader
   - Limited to ~512KB (SRAM size)
   - Configuration: Add `-d:bootSram` to `customDefines` in project.nimble
   - Flash with `nimble flash` (DFU only)

3. **BOOT_QSPI**
   - Application stored in QSPI flash (0x90040000)
   - Requires DFU bootloader with QSPI support
   - Provides 128MB additional storage for large applications
   - Essential for applications with large libraries (e.g., CMSIS-DSP at 1MB)
   - Configuration: Add `-d:bootQspi` to `customDefines` in project.nimble
   - Flash with `nimble flash` (DFU only)

### CMSIS-DSP Library

Optional ARM optimized math and signal processing library:
- ~1MB library - requires BOOT_QSPI mode due to size
- Add `-d:useCMSIS` to `customDefines` in project.nimble
- Includes FFT, filtering, matrix operations, and more
- See example: `cmsis_demo`

### FatFs Long Filename Support

For projects using SD card file operations with long filenames, add the `-d:useFatFsLFN` flag in `customDefines`:

```nim
# In project.nimble
const customDefines = "useFatFsLFN"
```

This automatically links the `libfatfs_ccsbcs.a` library for UTF-8/Unicode filename support.

## Optimization and Safety

Projects are configured with the following defaults:
- **Optimization**: Size (-Os) to fit within the Daisy's internal flash.
- **Memory Management**: ARC (Automatic Reference Counting) for deterministic performance.
- **Panic Handling**: Custom panic handler that halts the system (avoiding OS dependencies).
- **Audio Safety**: Zero heap allocations allowed in audio callbacks.
