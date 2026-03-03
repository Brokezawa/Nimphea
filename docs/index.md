# Nimphea

A comprehensive, type-safe [Nim](https://nim-lang.org/) wrapper for the
[libDaisy](https://github.com/electro-smith/libDaisy) hardware abstraction
library — enabling elegant Nim development for the Electro-Smith Daisy Seed
embedded audio platform (ARM Cortex-M7 / STM32H750).



## Getting Started

- [Installation Guide](guides/installation.html) — Set up the ARM toolchain, Nim, and Nimphea
- [Getting Started](guides/getting-started.html) — Create your first project and flash it
- [CMSIS-DSP Guide](guides/cmsis-dsp.html) — Hardware-accelerated DSP: filters, FFT, matrix math

## API Reference

- [Module Index](theindex.html) — Complete searchable index of all 85+ modules
- [API Reference Overview](API_REFERENCE.html) — All modules listed by category

### Key Modules

**Peripherals:** [ADC](adc.html), [DAC](dac.html), [I2C](i2c.html),
[SPI](spi.html), [UART](uart.html), [PWM](pwm.html)

**HID:** [Switch](switch.html), [Encoder/Ctrl](ctrl.html),
[LED](led.html), [RGB LED](rgb_led.html), [MIDI](midi.html)

**DSP:** [Basic Math](dsp_basic.html), [FFT](dsp_transforms.html),
[Filters](dsp_filtering.html)

**System:** [DMA](dma.html), [SDRAM](sdram.html), [FatFS](fatfs.html)

## Project Templates

- [Basic Template](https://github.com/Brokezawa/nimphea-template-basic) — Minimal LED blink and serial logging
- [Audio Template](https://github.com/Brokezawa/nimphea-template-audio) — Pre-configured stereo audio callback

## Examples

The [Nimphea Examples Repository](https://github.com/Brokezawa/nimphea-examples)
contains 40+ tested examples covering GPIO, audio, DSP, peripherals, displays,
sensors, and storage.

## Additional Documentation

- [Build System Reference](BUILD_SYSTEM.html)
- [Flashing Guide](FLASH_GUIDE.html) — DFU and ST-Link methods
- [Boot Modes](BOOT_MODES.html)
- [Nim Features](NIM_FEATURES.html)
- [Contributing](CONTRIBUTING.html)
