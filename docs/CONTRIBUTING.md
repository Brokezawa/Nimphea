# Contributing to Nimphea

[← Home](index.md)

---

## Development Setup

### 1. Prerequisites
- Nim 2.0 or later.
- ARM Toolchain (arm-none-eabi-gcc).
- libDaisy built and working.

### 2. Fork and Clone
```bash
git clone --recursive https://github.com/Brokezawa/nimphea
cd nimphea
```

### 3. Initialize libDaisy
```bash
nimble init_libdaisy
```

## Repository Structure

- `src/nimphea/`: Core library source code.
- `docs/`: Documentation and guides.
- `tests/`: Unit tests for pure Nim logic.

## Contribution Workflow

### 1. Library Improvements
- All core wrapper logic belongs in `src/nimphea/`.
- Ensure changes are namespaced correctly (e.g., `nimphea/per/adc`).
- Add unit tests in `tests/` for any new logic.

### 2. New Examples
- Examples are hosted in a separate repository: [nimphea-examples](https://github.com/Brokezawa/nimphea-examples).
- To contribute an example, create a standalone directory with its own `.nimble` file and submit a PR to that repo.

## Code Standards

- **Naming**: PascalCase for types, camelCase for procedures and variables.
- **Embedded Constraints**: No heap allocations in real-time callbacks.
- **Safety**: Use `addr` instead of the deprecated `unsafeAddr`.
- **Documentation**: Use `##` comments for all public symbols.



## Wrapper Development Guide

### Understanding the Pattern

All wrappers follow this structure:

**1. Type Definitions** (in module)

```nim
type
  MyPeripheral* {.importcpp: "daisy::MyPeripheral", 
                  header: "per/myperipheral.h".} = object
    ## Brief description
    
  MyConfig* {.importcpp: "daisy::MyPeripheral::Config".} = object
    ## Configuration structure
    field1*: cint
    field2*: bool
```

**2. Constants and Enums**

```nim
type
  MyMode* = enum
    MODE_A = 0
    MODE_B = 1
    MODE_C = 2
```

**3. Procedures**

```nim
proc init*(this: var MyPeripheral, config: MyConfig): bool 
  {.importcpp: "#.Init(#)".} =
  ## Initialize the peripheral
  ## 
  ## **Parameters:**
  ## - `config` - Configuration structure
  ## 
  ## **Returns:** true on success
  discard

proc read*(this: var MyPeripheral): cint 
  {.importcpp: "#.Read()".} =
  ## Read from peripheral
  ## 
  ## **Returns:** Read value
  discard
```

**4. Macro for Includes**

In `nimphea_macros.nim`, add:

```nim
macro emitMyPeripheralIncludes*(): untyped =
  when defined(useMyPeripheral):
    result = quote do:
      {.emit: """
      #include "per/myperipheral.h"
      """.}
  else:
    result = newStmtList()
```

**5. Module Setup**

At top of your module file:

```nim
import nimphea_macros

{.define: useMyPeripheral.}
emitMyPeripheralIncludes()
```

### Step-by-Step: Adding a New Peripheral

Let's wrap the DAC as an example:

**Step 1: Study the C++ Interface**

Look at `libDaisy/src/per/dac.h`:

```cpp
namespace daisy {
class DacHandle {
public:
    enum Channel { CHN_1, CHN_2, CHN_BOTH };
    
    struct Config {
        Channel chn;
        Mode mode;
    };
    
    void Init(Config config);
    void WriteValue(Channel channel, uint16_t value);
};
}
```

**Step 2: Create Nim Types**

```nim
# In src/per/dac.nim
import nimphea_macros

type
  DacChannel* = enum
    DAC_CHN_1 = 0
    DAC_CHN_2 = 1
    DAC_CHN_BOTH = 2
  
  DacHandle* {.importcpp: "daisy::DacHandle",
                header: "per/dac.h".} = object
  
  DacConfig* {.importcpp: "daisy::DacHandle::Config".} = object
    chn*: DacChannel
```

**Step 3: Add Procedures**

```nim
proc init*(this: var DacHandle, config: DacConfig) 
  {.importcpp: "#.Init(#)".} =
  ## Initialize DAC
  discard

proc writeValue*(this: var DacHandle, channel: DacChannel, value: uint16) 
  {.importcpp: "#.WriteValue(#, #)".} =
  ## Write value to DAC channel
  discard
```

**Step 4: Add Macro**

In `src/nimphea_macros.nim`:

```nim
macro emitDacIncludes*(): untyped =
  when defined(useDAC):
    result = quote do:
      {.emit: """
      #include "per/dac.h"
      """.}
  else:
    result = newStmtList()
```

**Step 5: Use Macro in Module**

At top of `per/dac.nim`:

```nim
{.define: useDAC.}
emitDacIncludes()
```

**Step 6: Create Example**

Create `examples/dac_simple.nim`:

```nim
import ../src/nimphea
import ../src/per/dac

var hw = newDaisySeed()
var dac: DacHandle

proc main() =
  hw.init()
  
  var dacCfg: DacConfig
  dacCfg.chn = DAC_CHN_1
  dac.init(dacCfg)
  
  var value: uint16 = 0
  while true:
    dac.writeValue(DAC_CHN_1, value)
    value = (value + 100) mod 4096
    hw.delayMs(10)

when isMainModule:
  main()
```

**Step 7: Test**

```bash
cd nimphea

# Syntax check your new wrapper
nimble test

# Build your new wrapper example for ARM
nimble make dac_simple

# Flash to hardware (requires Daisy in bootloader mode)
nimble flash dac_simple
```

**Expected output**:
- `nimble test` shows dac_simple passes
- `nimble make dac_simple` produces `build/dac_simple.bin`
- `nimble flash dac_simple` displays " Flash complete!"

**Step 8: Document**

Add to `API_REFERENCE.md`:

```markdown
### DAC (per/dac.nim)

Digital to Analog Converter for CV outputs.

**Types:**
- `DacHandle` - DAC controller
- `DacChannel` - Channel selection (CHN_1, CHN_2, CHN_BOTH)
- `DacConfig` - Configuration structure

**Functions:**
- `init(dac, config)` - Initialize DAC
- `writeValue(dac, channel, value)` - Write 12-bit value (0-4095)

**Example:** See `examples/dac_simple.nim`
```

### Common Pitfalls

**1. Forgetting the Macro**

If you forget `emitDacIncludes()`, you'll get:
```
Error: undeclared identifier: 'DacHandle'
```

**Solution:** Add the macro call at module top.

**2. Wrong C++ Signature**

If the `importcpp` pattern is wrong:
```nim
# WRONG
proc init*(this: var DacHandle) {.importcpp: "Init".}

# RIGHT
proc init*(this: var DacHandle) {.importcpp: "#.Init()".}
```

The `#` is crucial - it represents the object.

**3. Type Mismatches**

Ensure Nim types match C++ types:
- `cint` → `int`
- `cfloat` → `float`
- `uint16` → `uint16_t`
- `bool` → `bool`

**4. Missing Exports**

Remember the `*` for public symbols:
```nim
# WRONG (not exported)
proc init(this: var DacHandle)

# RIGHT (exported)
proc init*(this: var DacHandle)
```

## Testing Requirements

Nimphea uses a **two-tier testing approach**:

### Tier 1: Unit Tests (Host Computer)

**What:** Pure logic testing for data structures and utilities  
**Where:** Runs on your development computer (no hardware required)  
**Framework:** nim-unittest2  

```bash
# Run all unit tests
nimble test_unit

# Expected output:
# [Suite] FixedStr - Basics ...... (0.00s)
# [Suite] FixedStr - Edge Cases .... (0.00s)
# [Summary] 22 tests run (0.00s): 22 OK, 0 FAILED, 0 SKIPPED
#  All unit tests passed!
```

**When to write unit tests:**
- Adding or modifying pure logic modules (FIFO, Stack, FixedStr, etc.)
- Implementing utility functions (value mapping, color conversion, etc.)
- Working with file format parsers (WAV, JSON, etc.)

**When NOT to write unit tests:**
- Hardware-dependent code (ADC, DAC, GPIO, I2C, SPI, etc.)
- Board-specific functionality
- Audio processing that requires real-time behavior

For detailed unit testing information, see `tests/README.md`.

### Tier 2: Integration Tests (Hardware)

**What:** Full functionality testing on real Daisy Seed hardware  
**Where:** Runs on physical Daisy boards  
**Framework:** Manual testing with documented examples  

#### Compilation Tests

All examples must pass compilation checks. We use a **two-tier testing approach**:

**Tier 1: Quick Syntax Check** (required for all PRs)
```bash
# Fast (~7 seconds) - checks syntax and types only
nimble test
```

What it checks:
-  Syntax errors
-  Type checking  
-  Import resolution
- ❌ Does NOT link with libDaisy
- ❌ Does NOT cross-compile for ARM
- ❌ Does NOT catch linker errors

**Tier 2: Full Build Test** (required before releases)
```bash
# Slow (~45 minutes) - builds all examples with ARM toolchain
nimble test_build
```

What it checks:
-  ARM cross-compilation
-  Linking with libDaisy
-  All symbols resolve
-  Binary sizes are reasonable

**For Contributors:**
- **During development**: Use `nimble test` for fast feedback
- **Before submitting PR**: Ensure `nimble test` passes
- **For major changes**: Run `nimble test_build` to catch linker issues
- **Maintainers**: Will run `nimble test_build` before merges/releases

**Expected output from `nimble test`**:
```
=== Quick Syntax Check (all examples) ===
============================================================
Checking blink                           ...  PASS
Checking audio_demo                      ...  PASS
Checking pod_demo                        ...  PASS
...
============================================================
SUMMARY:
  Passed: 43
  Failed: 0
============================================================

 All examples passed syntax check!

Note: This only checks syntax. For full build validation:
  nimble test_build    # Compile all examples with ARM toolchain
```

#### Hardware Tests

If you have hardware, test your feature:

1. **Does it compile?**
2. **Does it upload?**
3. **Does it work as expected?**
4. **Are there any errors or warnings?**

Document test results in your PR.

#### Regression Tests

Ensure you haven't broken existing functionality:

```bash
# Quick syntax check (required)
nimble test

# Run unit tests (required if you modified testable modules)
nimble test_unit

# For major changes: full build validation (optional but recommended)
nimble test_build

# Build and test 2-3 existing examples on hardware (if available)
nimble make blink
nimble flash blink

# Try another example
nimble make audio_demo
nimble flash audio_demo
```

**All existing examples should**:
- Pass `nimble test` (syntax check) - **REQUIRED**
- Pass `nimble test_unit` (unit tests) - **REQUIRED**
- Pass `nimble test_build` (full build) - **RECOMMENDED** for major changes
- Build successfully with `nimble make` - **REQUIRED** for changed examples
- Flash successfully with `nimble flash` - **OPTIONAL** (hardware dependent)
- Run correctly on hardware - **OPTIONAL** (hardware dependent)

### Writing Unit Tests

When adding testable modules, create corresponding unit tests:

**1. Create test file:** `tests/test_yourmodule.nim`

```nim
import unittest2
import ../src/nimphea_yourmodule

suite "YourModule: Basic Functionality":
  test "should initialize correctly":
    var obj = initYourModule()
    check obj.someProperty == expectedValue

suite "YourModule: Edge Cases":
  test "should handle empty state":
    var obj = initYourModule()
    check obj.isEmpty() == true
```

**2. Add to master runner:** In `tests/all_tests.nim`:

```nim
import test_yourmodule
```

**3. Run tests:**

```bash
nimble test_unit
```

**Test Organization:**
- Group related tests into suites
- Use descriptive test names ("should do X when Y")
- Test basics, edge cases, and practical usage
- Mirror libDaisy's googletest structure when applicable

See `tests/test_fixedstr.nim` for a comprehensive example.

## Hardware Testing

Community hardware testing is essential to validate examples on different Daisy boards and peripherals.

### Quick Overview

**Testing Levels:**

1. **Compilation Testing** (Required for all PRs)
    ```bash
    cd /path/to/nimphea
    nimble test
    ```
    Fast syntax checking without ARM compilation. All 40+ examples must pass.

2. **Basic Hardware Testing**
    ```bash
    nimble make blink
    nimble flash blink
    ```
    LED, GPIO, Audio, SDRAM, USB, RNG, Timers

3. **Extended Hardware Testing** (Community - peripherals needed)
   - Displays (OLED, LCD)
   - Sensors (IMU, touch, gesture)
   - I/O expansion (shift registers, I2C expanders)
   - LED strips (NeoPixel, DotStar)

4. **Board-Specific Testing** (Community - critical!)
   - Daisy Pod, Field, PatchSM, Petal, Versio, Legio
   - Full feature validation per board

**How to Help:**
- Check GitHub issues with `needs-hardware-testing` label
- Test examples on your hardware and report results
- Get credited in release notes!

See the testing section in [Contributing Guide](CONTRIBUTING.md) for detailed testing procedures.

## Code Style Guidelines

### Naming Conventions

```nim
# Types: PascalCase with * for export
type DaisySeed* = object

# Enums: PascalCase (use descriptive names)
type PinMode* = enum
  INPUT
  OUTPUT
  ANALOG

# Procedures: camelCase with * for export
proc setLed*(hw: var DaisySeed, state: bool)

# Constants: UPPER_SNAKE_CASE
const MAX_BUFFER_SIZE* = 1024

# Variables: camelCase
var myValue = 42
```

### Module Structure

**File Structure:**

```nim
## Module documentation
## 
## Detailed description of what this module does.
## Explains what C++ functionality it wraps.

# 1. Imports
import nimphea_macros

# 2. Type definitions
type
  MyType* = object

# 3. Constants
const MY_CONST* = 42

# 4. Macro calls
{.define: useMyFeature.}
emitMyFeatureIncludes()

# 5. Procedures
proc myProc*() = discard
```

**Location Convention:**
- Core wrapper modules: `src/`
- Peripherals (ADC, DAC, SPI, I2C, etc.): `src/per/`
- Human interface (buttons, MIDI, controls): `src/hid/`
- System modules (DMA, SDRAM, timers): `src/sys/`
- Device drivers (sensors, displays, codecs): `src/dev/`
- Board support (Patch, Pod, Field): `src/boards/`
- UI framework: `src/ui/`

### Documentation Comments

Use `##` for documentation:

```nim
proc importantFunction*(param: int): bool =
  ## Brief one-line description
  ## 
  ## More detailed explanation if needed.
  ## Multiple paragraphs okay.
  ## 
  ## **Parameters:**
  ## - `param` - Description of parameter
  ## 
  ## **Returns:** Description of return value
  ## 
  ## **Example:**
  ## ```nim
  ## if importantFunction(42):
  ##   echo "Success!"
  ## ```
  result = true
```

### Formatting

- **Indentation:** 2 spaces (Nim standard)
- **Line length:** 80-100 characters preferred (soft limit)
- **Blank lines:** One between procedures, two between sections
- **Imports:** Group by: stdlib → external → local, with blank lines between groups

```nim
# Good
import std/strutils
import std/sequtils

import nimphea_macros

import per/adc
import per/gpio

# Procedures with one blank line between them
proc foo*() =
  let x = 42
  echo x

proc bar*() =
  let y = 24
  echo y


# Section separator (two blank lines before major sections)
const CONSTANT = 1
```

## Documentation Standards

### What to Document

**1. Module-Level**

Every `.nim` file should start with:

```nim
## ModuleName
## ==========
## 
## Brief one-line description of what this module provides.
##
## Detailed explanation of what C++ functionality it wraps,
## and how to use it. Include any important constraints or
## performance considerations.
## 
## **Example:**
## ```nim
## import src/per/dac
## 
## var dac: DacHandle
## var cfg: DacConfig
## cfg.chn = DAC_CHN_1
## dac.init(cfg)
## dac.writeValue(DAC_CHN_1, 2048)
## ```
```

**2. Type Definitions**

```nim
type
  MyType* = object
    ## Description of what this type represents
    ##
    ## **Fields:**
    ## - `field1` - Description
    field1*: int
```

**3. Procedures**

All public procs need documentation (see above).

**4. Examples**

Every new peripheral wrapper needs a corresponding example in `examples/`:

- Name: `<peripheral>_*.nim` or `<feature>_demo.nim`
- Should be self-contained (minimal dependencies)
- Include comments explaining key operations
- Example: `examples/dac_simple.nim`, `examples/audio_effects_demo.nim`

**5. API Reference**

Add entry to `docs/API_REFERENCE.md` for new modules/features:

```markdown
### DAC (per/dac.nim)

Digital to Analog Converter for CV outputs.

**Types:**
- `DacHandle` - DAC controller
- `DacChannel` - Channel selection (CHN_1, CHN_2, CHN_BOTH)
- `DacConfig` - Configuration structure

**Functions:**
- `init(dac, config)` - Initialize DAC
- `writeValue(dac, channel, value)` - Write 12-bit value (0-4095)

**Example:** See `examples/dac_simple.nim`

**Performance:** Negligible overhead (~1% of audio callback)
```

## Performance Guidelines

### Performance Target: ≤5-10% overhead vs C++ libDaisy

The Nim wrapper should have minimal performance overhead. For audio code, this is critical.

**Measurement Areas:**
- Audio callback execution time (per-sample operations)
- DMA transfer rates
- File I/O throughput
- UI rendering speed (framerate)

**Best Practices:**

1. **Use `{.inline.}` pragma** for hot-path functions
   ```nim
   proc getValue*(buffer: Buffer, index: int): float32 {.inline.} =
     result = buffer.data[index]
   ```

2. **Avoid heap allocation** in real-time audio code
   ```nim
   # BAD - allocates on heap every call
   proc process*(data: seq[float32]) =
     let temp = newSeq[float32](data.len)
   
   # GOOD - use stack or pre-allocated buffers
   proc process*(data: var openArray[float32]) =
     # Process in-place
   ```

3. **Minimize branching** in audio callback
   ```nim
   # AVOID - branch prediction misses hurt performance
   for sample in audio:
     if someCondition:
       sample = process1()
     else:
       sample = process2()
   
   # BETTER - loop unrolling or SIMD-friendly code
   ```

4. **Profile before optimizing** - use actual measurements
   ```bash
   # Build with performance monitoring enabled
   nimble make myexample
   
   # Check flash and RAM usage
   arm-none-eabi-size build/myexample.elf
   ```

### Safety vs Performance

Provide both checked and unchecked variants when appropriate:

```nim
# Safe version (bounds checked)
proc get*(buffer: var Buffer, index: int): float32 =
  assert index >= 0 and index < buffer.len
  result = buffer.data[index]

# Fast version (no checks)
proc getUnchecked*(buffer: var Buffer, index: int): float32 {.inline.} =
  result = buffer.data[index]

# Unsafe version (for extreme performance needs)
proc getUnsafe*(buffer: var Buffer, index: int): float32 {.inline.} =
  {.emit: "return ((float*)#1)[#2];".}
```

### Acceptable Tradeoffs

- Sacrifice up to 5-10% performance for safety/usability features
- Document the tradeoff in code comments
- Provide unsafe alternative if needed for performance-critical code
- Aim for "zero-cost abstraction" where possible

## Breaking Changes Policy

### Current Status: Feature Complete (v1.0.0)

At v1.0.0 and beyond:
-  **Feature Complete** - All major functionality implemented
-  **Use at Your Own Risk** - Requires community testing
-  **No breaking changes** in minor/patch releases (1.x.y)
-  **Semantic versioning**: Major.Minor.Patch
-  **Deprecation period**: Minimum 2 releases (6 months) before removal
-  **Stability guarantee**: Public APIs remain stable

**Breaking Change Requirements** (if necessary for major version):

When breaking changes are absolutely necessary:

1. **Provide comprehensive migration guide**
   - Clear before/after examples
   - Step-by-step migration instructions
   - Automated migration tools if possible

2. **Justify the change thoroughly**
   - Why the current API is problematic
   - How the new API improves things
   - Why it couldn't be done with deprecation

3. **Long deprecation period**
   - Announce in 2-3 releases before breaking change
   - Mark old API with `{.deprecated: "Use newApi instead".}`
   - Provide clear error messages directing to new API

**Example Breaking Change** (v2.0.0 hypothetically):

```markdown
### Breaking Changes in v2.0.0

**per/adc.nim:**
- `initAdc()` → `init()` (renamed for API consistency)
- Old: `initAdc(hw, pin, channel)`
- New: `var adc: AdcHandle; adc.init(pin, channel)`
- Migration: see the migration notes below for step-by-step guidance

**Migration path:**
- v1.8.0: Old API marked `{.deprecated.}`, new API available
- v1.9.0: Deprecation warnings shown
- v2.0.0: Old API removed entirely
```

## Submitting Changes

### Before Submitting

Checklist:

- Code compiles without errors.
- New feature has a working example.
- Code is documented with ## comments.
- Commits are clear and descriptive.

### Commit Messages

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add DAC wrapper with example"
git commit -m "Fix I2C timeout handling"
git commit -m "Update SPI documentation"

# Bad  
git commit -m "stuff"
git commit -m "wip"
git commit -m "fix"
```

Format:
```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what changed and why.

- Bullet points okay
- For multiple changes

Fixes #123  # Reference issue if applicable
```

### Pull Request Process

1. **Push to your fork**
```bash
git push origin feature/my-new-feature
```

2. **Create PR on GitHub**
- Go to [github.com/Brokezawa/nimphea](https://github.com/Brokezawa/nimphea)
- Click "New Pull Request"
- Select your fork and branch as source, main as target
- Fill in description using the template below

3. **PR Description Template**

```markdown
## Description
Brief description of what this PR does and why.

## Type of Change
- New feature (peripheral wrapper, board support, etc.)
- Bug fix (compilation, runtime, logic error)
- Documentation (README, API_REFERENCE, guides)
- Performance improvement
- Refactoring (no functional change)
- Other (describe)

## Related Issues
Fixes #123 (if applicable)
Relates to #456 (if applicable)

## Changes Made
- Bullet point describing each change
- Second change
- Third change

## Testing Done
- All examples compile.
- New example works and follows conventions.
- Tested on hardware.
- Ran nimble clear and rebuilt from scratch.

## Checklist
- Code follows Nim style guidelines.
- Code is documented with ## comments.
- New public APIs added to API_REFERENCE.md.
- No breaking changes to existing API.
- Commits are clean and descriptive.
- No hardcoded paths or personal configurations.

## Additional Notes
Any additional context or notes for reviewers...
```

4. **Respond to Reviews**
- Be open to constructive feedback
- Ask questions if anything is unclear
- Make requested changes in new commits (don't force push)
- Push to same branch - PR auto-updates

5. **After Approval**
- Maintainer will rebase/squash and merge
- Your contribution is now part of Nimphea!
- You'll be listed in release notes

## Areas Needing Help

Current needs include:

**1. Hardware Testing**
- Test examples on Daisy Pod, Patch, Field, Patch SM, Petal, Versio, Legio
- Report bugs and compatibility issues
- Create board-specific example improvements

**2. More Examples**
- Complex audio processing examples
- Multi-peripheral integration examples
- Real-world applications
- Board-specific examples

**3. Documentation**
- Tutorials and guides
- API reference expansion
- Example explanations and walkthroughs
- Video tutorials

**4. Bug Fixes & Improvements**
- Optimize existing modules
- Improve error handling
- Enhance performance
- Add missing features

## Getting Help

**Questions about contributing?**
- Open a GitHub Discussion: [github.com/Brokezawa/nimphea/discussions](https://github.com/Brokezawa/nimphea/discussions)
- Comment on relevant issue with context
- Ask in Electro-Smith forum: https://forum.electro-smith.com/

**Stuck implementing a feature?**
- Look at similar existing wrappers (e.g., look at DAC for ADC patterns)
- Check API_REFERENCE.md for complete API documentation
- Review corresponding libDaisy C++ headers for behavior
- Ask in a GitHub Discussion - maintainers are helpful!

**Found a Bug?**
- Check existing issues first (might be known)
- Open an issue with:
  - Clear title and description
  - Steps to reproduce
  - Expected vs actual behavior
  - Your setup: OS, Nim version (`nim --version`), ARM toolchain version, hardware
  - Relevant code snippet or example
  - Build output/error log

## Recognition

Contributors will be:
- Listed in project documentation
- Credited in release notes
- Part of the community!

Thank you for contributing to Nimphea!
