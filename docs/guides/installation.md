# Installation Guide

[Home](../index.md) | [Installation](installation.md) | [Getting Started](getting-started.md) | [CMSIS-DSP](cmsis-dsp.md)

---

To develop with Nimphea, you need the ARM Embedded Toolchain and the Nim compiler.

## 1. Prerequisites

### ARM Toolchain
You need the `arm-none-eabi-gcc` toolchain to compile for the Daisy's Cortex-M7 processor.

- **macOS**: `brew install --cask gcc-arm-embedded`
- **Linux**: `sudo apt install gcc-arm-none-eabi libnewlib-arm-none-eabi`
- **Windows**: Download from [ARM Developer website](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain).

### DFU-Util
Required for flashing via USB.
- **macOS**: `brew install dfu-util`
- **Linux**: `sudo apt install dfu-util`

## 2. Install Nim
Nimphea requires Nim 2.0.0 or later.
Follow the instructions at [nim-lang.org](https://nim-lang.org/install.html).

## 3. Install Nimphea
Install the Nimphea library and its C++ dependencies using Nimble:

```bash
nimble install nimphea
```

> **Note**: This will automatically clone and build `libDaisy`. It may take a few minutes.

## 4. Verify Installation
Check if you can run the ARM compiler:
```bash
arm-none-eabi-gcc --version
```

Now you are ready to create your first project! See the [Getting Started](getting-started.md) guide.
