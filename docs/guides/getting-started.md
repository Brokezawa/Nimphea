# Getting Started

[Home](../index.md) | [Installation](installation.md) | [Getting Started](getting-started.md) | [CMSIS-DSP](cmsis-dsp.md)

---

This guide will help you create and build your first Nimphea project.

## 1. Create a Project from Template

The easiest way to start is using one of the Nimphea templates.

1. Go to the [Audio Template Repository](https://github.com/Brokezawa/nimphea-template-audio).
2. Click the **"Use this template"** button.
3. Clone your new repository locally:
   ```bash
   git clone https://github.com/youruser/my-synth.git
   cd my-synth
   ```

## 2. Project Structure

- `project.nimble`: Your project configuration and build tasks.
- `src/main.nim`: Your application code.
- `build/`: Built binaries (generated).

## 3. Build the Project

Run the `make` task defined in your `.nimble` file:

```bash
nimble make
```

This will:
1. Compile your Nim code using the C++ backend.
2. Link against the pre-built `libDaisy`.
3. Generate a `build/main.bin` file.

## 4. Flash to Daisy

1. Connect your Daisy Seed via USB.
2. Enter **DFU mode**:
   - Hold the **BOOT** button.
   - Press and release the **RESET** button.
   - Release the **BOOT** button.
3. Run the flash command:
   ```bash
   nimble flash
   ```

## 5. Next Steps

- Explore the [Nimphea Examples](https://github.com/Brokezawa/nimphea-examples) for more complex use cases.
- Check the [API Reference](../theindex.html) for module documentation.
- Read the [CMSIS-DSP Guide](cmsis-dsp.html) for high-performance audio processing.
