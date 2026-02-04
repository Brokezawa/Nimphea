# AGENTS.md - Guide for AI Coding Agents

**Nimphea** v1.0.0 - Nim wrapper for libDaisy embedded audio platform (ARM Cortex-M7 / STM32H750).

## Build & Test Commands

```bash
# One-time setup (clone submodules, build libDaisy)
nimble init_libdaisy

# Build for ARM (outputs: build/*.elf, build/*.bin)
nimble make blink              # Build single example
nimble make examples/audio_demo  # Can use full path

# Flash to hardware
nimble flash blink              # Via DFU bootloader (USB)
nimble stlink blink             # Via ST-Link/OpenOCD (faster)

# Testing
nimble test                     # Test all 43 examples (syntax check)
nim check examples/blink.nim    # Fast syntax check for single file
nimble make blink               # Full compile test with linking

# Other
nimble clear                    # Remove build/ directory and artifacts
nimble docs                     # Generate API docs → docs/api/*.html
```

**Requirements**: Nim ≥2.0.0, arm-none-eabi-gcc, libDaisy (submodule)

## Code Style

### Naming Conventions

```nim
type DaisySeed* = object          # Types: PascalCase*
proc setLed*(x: var T)            # Procs: camelCase*
const SAMPLE_RATE* = 48000        # Constants: UPPER_SNAKE_CASE
type Mode* = enum INPUT, OUTPUT   # Enums: PascalCase type, values match C++
var ledState = false              # Vars: camelCase (not exported)
```

### Module Structure

```nim
## Module Title - Short description
## 
## Detailed description with usage examples.

import std/math                 # Standard imports first
import nimphea, nimphea_macros  # Local imports
import per/adc, hid/switch      # Category-based organization

useNimpheaNamespace()           # For examples (REQUIRED)
useNimpheaModules(adc)          # For wrappers (after imports!)

type MyType* = object
  field*: cint

proc myProc*() = discard
```

### C++ Interop Patterns

```nim
# Import C++ type
type
  DaisySeed* {.importcpp: "daisy::DaisySeed", header: "daisy_seed.h".} = object

# C++ methods (# = this pointer, @ = subsequent args)
proc init*(this: var DaisySeed) {.importcpp: "#.Init()".}
proc setLed*(this: var DaisySeed, state: bool) {.importcpp: "#.SetLed(#)".}
proc delay*(this: var DaisySeed, ms: csize_t) {.importcpp: "#.DelayMs(@)".}

# C++ constructor
proc newPin*(port: GPIOPort, pin: uint8): Pin 
  {.importcpp: "daisy::Pin(@)", constructor, header: "daisy_seed.h".}

# Type mappings: int→cint, float→cfloat, uint16→uint16, size_t→csize_t
# T*→ptr T, T&→var T, const T&→T
```

### Documentation Style

```nim
proc process*(input, output: AudioBuffer, size: int) =
  ## Process audio in real-time callback
  ## 
  ## **Parameters:**
  ## - `input` - Input [channel][sample]
  ## - `output` - Output [channel][sample]
  ## 
  ## **Example:**
  ## ```nim
  ## for i in 0..<size:
  ##   output[0][i] = input[0][i] * 0.5
  ## ```
```

## Directory Structure

```
src/
├── nimphea.nim           # Core API (DaisySeed, GPIO, Audio)
├── nimphea_macros.nim    # C++ interop macro system
├── boards/               # Board support (pod, patch, field, etc. - 8 boards)
├── per/                  # Peripherals (adc, dac, spi, i2c, uart - 12 modules)
├── hid/                  # Human interface (switch, led, midi, usb)
│   └── disp/             # Display drivers
├── dev/                  # Device drivers (sensors, codecs, displays - 20+ devices)
├── sys/                  # System (dma, sdram, fatfs, system)
└── ui/                   # UI framework (menu, events)
examples/                 # 43 tested examples
libDaisy/                 # C++ library (submodule)
```

## Macro System (CRITICAL)

**Always use macros for C++ headers. NO raw emit!**

```nim
# CORRECT: CORRECT - For examples
import nimphea
useNimpheaNamespace()

# CORRECT: CORRECT - For wrapper modules
import nimphea_macros
useNimpheaModules(spi, i2c)

# WRONG: WRONG
{.emit: """#include "per/spi.h"
using namespace daisy;""".}
```

**Raw emit allowed ONLY for:**
1. C++ operators (can't define in Nim)
2. `std::initializer_list` workarounds
3. Custom C++ helpers (rare, document why)

### Adding New Module

1. Find C++ header in `libDaisy/src/`
2. Edit `nimphea_macros.nim`:
   ```nim
   const myTypedefs* = ["MyClass::Result MyResult"]
   # Add to getModuleHeaders() and useNimpheaModules()
   ```
3. Create wrapper in `src/per/mymodule.nim`
4. Test with `nimble test`

## Common Pitfalls

```nim
# WRONG: Missing # for this pointer
proc init*(x: var T) {.importcpp: "Init()".}

# CORRECT: Correct
proc init*(x: var T) {.importcpp: "#.Init()".}

# WRONG: Not exported, wrong type
proc getValue(): int

# CORRECT: Exported, C type
proc getValue*(): cint

# WRONG: Macro before imports
useNimpheaModules(adc)
import per/adc

# CORRECT: Imports first
import per/adc
useNimpheaModules(adc)
```

## Embedded Constraints

- **CPU**: ARM Cortex-M7 @ 400-480MHz
- **RAM**: 512KB SRAM (+ optional 64MB SDRAM)
- **Bare metal**: No OS, no dynamic allocation by default
- **Real-time audio**: ~1ms callbacks (48 samples @ 48kHz)
- **Stack over heap**: Prefer `array` over `seq` in audio callbacks
- **No exceptions in hot paths**: Use `{.push raises: [].}`

### Memory Management

```nim
# CORRECT: GOOD - Static allocation
var buffer: array[1024, float32]

# CAUTION: AVOID in callbacks - Dynamic allocation
var buffer = newSeq[float32](1024)

# CORRECT: GOOD - Pre-allocate outside callback
var phase = 0.0
proc audioCallback(...) {.cdecl, raises: [].} =
  phase += phaseIncrement
```

## Formatting

- **Indentation**: 2 spaces (NO tabs)
- **Line length**: 80-100 chars max
- **Blank lines**: 1 between procs
- **No automated formatter**: Manual (maintain consistency)

## References

- **nimphea.nimble** - Build system
- **docs/API_REFERENCE.md** - Complete API (85 modules)
- **examples/** - 43 examples
- **libDaisy docs** - https://electro-smith.github.io/libDaisy
