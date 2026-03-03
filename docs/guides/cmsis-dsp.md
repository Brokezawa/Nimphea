# CMSIS-DSP Guide

[Home](../index.md) | [Installation](installation.md) | [Getting Started](getting-started.md) | [CMSIS-DSP](cmsis-dsp.md)

---

Nimphea includes a comprehensive wrapper for ARM's **CMSIS-DSP** library, providing hardware-accelerated math functions optimized for the Cortex-M7 processor.

## Features

- **Fast Math**: Optimized sine, cosine, and square root functions.
- **Vector Operations**: Element-wise addition, multiplication, and scaling.
- **Filtering**: FIR and Biquad (IIR) filters with zero heap allocation.
- **Transforms**: Real and Complex FFT (up to 4096 points).
- **Matrix**: High-performance matrix arithmetic.

## Basic Usage

All CMSIS functions are designed to be **real-time safe** (no heap allocations).

### Fast Math
```nim
import nimphea/cmsis/dsp_fastmath

let s = fastSin(PI / 2.0)
let root = fastSqrt(16.0)
```

### Vector Operations
```nim
import nimphea/cmsis/dsp_basic

var v1 = [1.0'f32, 2.0, 3.0, 4.0]
var v2 = [10.0'f32, 20.0, 30.0, 40.0]
var res: array[4, float32]

add(res, v1, v2) # res = [11, 22, 33, 44]
```

## Advanced DSP

### FIR Filtering
Filters use compile-time sizing for maximum efficiency.

```nim
import nimphea/cmsis/dsp_filtering

const coeffs: array[3, float32] = [0.5, 0.5, 0.5]
var filter: FirFilter[3, 48] # 3 taps, max block size 48
filter.init(addr coeffs[0])

proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  filter.process(input[0], output[0])
```

### Fast Fourier Transform (FFT)
```nim
import nimphea/cmsis/dsp_transforms

var fft: FftInstance[256] # 256-point complex FFT
fft.init()

var data: array[512, float32] # Interleaved [re, im, re, im, ...]
fft.forward(data) # In-place FFT
```

## Performance Tips

1. **Use static arrays**: Avoid `seq` in your audio path.
2. **Pre-initialize**: Initialize filters and FFT instances in your `main()` or setup code, not inside the audio callback.
3. **Use the right type**: Prefer `float32` (f32) for most audio tasks as it is hardware-accelerated by the FPU.
