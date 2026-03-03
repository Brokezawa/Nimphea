# Nimphea Examples

This repository contains a collection of examples for the Nimphea Nim wrapper for the Daisy Audio Platform.

> **Requires Nimphea v1.1.0 or later.**

## Structure

Each example is a standalone Nim project located in the `examples/` directory.

## How to Build and Flash

To build and flash an example, you should have Nimphea installed via Nimble:

```bash
nimble install nimphea
```

Then, navigate to the example directory:

```bash
cd examples/blink
nimble make
nimble flash # Via USB DFU
# OR
nimble stlink # Via ST-Link probe
```

## Hardware Testing

For detailed instructions on how to set up your hardware for these examples, please refer to the [Hardware Testing Guide](TESTING_GUIDE.md).

## List of Examples

### Basic
- **blink**: The classic LED blink example.
- **cmsis_demo**: Demonstrates optimized ARM math functions.

### Audio
- **audio_demo**: Stereo passthrough, sine wave, and distortion.
- **codec_comparison**: Automatic codec detection for different hardware versions.

### Controls and Peripherals
- **adc_demo**: Reading potentiometers and multiplexers.
- **gpio_demo**: Button and LED interactions.
- **pwm_demo**: LED fading, RGB rainbow, and servo control.
- **encoder**: Rotary encoder reading.

### Communication
- **comm_demo**: I2C scanner and SPI communication.
- **usb_serial**: Virtual serial port over USB.
- **midi_demo**: MIDI I/O via USB and UART.

### Display
- **oled_basic**: Text display on SSD1306.
- **oled_graphics**: Drawing shapes.
- **oled_spi**: SPI-based OLED communication.
- **oled_visualizer**: Real-time audio waveform/metering.
- **ui_demo**: Full UI framework showcase.

### Storage and System
- **sdram_test**: External memory verification.
- **storage_demo**: QSPI flash and settings management.
- **system_demo**: System clock info and logging.
- **panicoverride**: Rapid LED blink on system crash.
