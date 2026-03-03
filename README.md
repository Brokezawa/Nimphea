# Nimphea

A comprehensive, type-safe Nim wrapper for the [libDaisy](https://github.com/electro-smith/libDaisy) hardware abstraction library, enabling elegant Nim development for the Electro-Smith Daisy Seed embedded audio platform.

[![CI](https://github.com/Brokezawa/nimphea/actions/workflows/ci.yml/badge.svg)](https://github.com/Brokezawa/nimphea/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-1.1.0-blue)](https://github.com/Brokezawa/nimphea/releases/tag/v1.1.0)
[![Platform](https://img.shields.io/badge/platform-ARM%20Cortex--M7-blue)](https://www.st.com/en/microcontrollers-microprocessors/stm32h750xb.html)
[![Nim](https://img.shields.io/badge/nim-2.0%2B-orange)](https://nim-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## What is this?

This wrapper allows you to write firmware for the Daisy Seed embedded audio board using the Nim programming language instead of C++. It provides a clean, type-safe API that wraps libDaisy's hardware abstraction layer.

**Key Features:**
- Zero overhead - Direct C++ interop with no runtime cost
- Type safety - Nim's strong type system catches errors at compile time
- Clean API - Idiomatic Nim interfaces to libDaisy functionality
- Comprehensive - High coverage of libDaisy features
- Hardware Accelerated DSP - Full CMSIS-DSP support included
- Well documented - Searchable API reference and handwritten guides

## Quick Start

### Hardware Requirements
- **Daisy Seed** - STM32H750-based embedded audio board
- **USB cable** - For programming and power
- **Audio I/O** (optional) - For audio applications

### Software Requirements
- **Nim** - 2.0 or later
- **ARM Toolchain** - `arm-none-eabi-gcc` and related tools
- **dfu-util** - For uploading firmware

### Installation

1. **Install the Nimphea library**:
```bash
nimble install nimphea
```

> **Note**: This will automatically clone and build `libDaisy`. It may take a few minutes.

2. **Create a project from a template**:
Clone one of the starter templates to begin:
- [Basic Template](https://github.com/Brokezawa/nimphea-template-basic)
- [Audio Template](https://github.com/Brokezawa/nimphea-template-audio)

3. **Build and Flash**:
Navigate to your project directory and use the pre-configured nimble tasks:
```bash
nimble make
nimble flash
```

## Documentation

Comprehensive documentation is available at [https://Brokezawa.github.io/nimphea](https://Brokezawa.github.io/nimphea):

- [Installation Guide](https://Brokezawa.github.io/nimphea/guides/installation.html)
- [Getting Started](https://Brokezawa.github.io/nimphea/guides/getting-started.html)
- [CMSIS-DSP Guide](https://Brokezawa.github.io/nimphea/guides/cmsis-dsp.html)
- [API Reference](https://Brokezawa.github.io/nimphea/api/theindex.html)

## Examples

The [Nimphea Examples Repository](https://github.com/Brokezawa/nimphea-examples) contains 40+ tested examples covering:

- **Basic** - GPIO, LEDs, buttons
- **Audio** - Passthrough, synthesis, effects
- **DSP** - CMSIS-DSP accelerated math
- **Peripherals** - ADC, PWM, I2C, SPI, UART, USB, MIDI
- **Displays** - OLED (I2C/SPI), LCD character displays
- **Sensors** - IMU, gesture, touch controllers
- **Storage** - SD Card, QSPI flash, SDRAM

## License

This wrapper follows the same MIT license as libDaisy. See [LICENSE](LICENSE) file for details.

## contributing

Contributions are welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

