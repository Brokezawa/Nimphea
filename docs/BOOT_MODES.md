# Boot Modes Guide

[← Home](index.md)

---

This document explains the three boot modes supported by Nimphea and how to choose the right one for your project.

## Overview

Nimphea applications can be deployed in three different ways, each with different trade-offs:

| Mode | Flash Location | Bootloader | Max Size | Best For |
|------|---|---|---|---|
| **BOOT_NONE** | Internal (0x08000000) | None | ~124KB | Development, simple projects |
| **BOOT_SRAM** | SRAM (0x20000000) | DFU required | ~512KB | Rapid iteration with bootloader |
| **BOOT_QSPI** | External (0x90040000) | DFU required | 128MB | Large applications, libraries |

## Quick Decision Tree

```
Is your application < 120KB?
├─ Yes: Can you install a bootloader?
│  ├─ No → Use BOOT_NONE (simple, fast)
│  └─ Yes: Do you need fast iteration?
│     ├─ Yes → Use BOOT_SRAM (fast reload, no reflash)
│     └─ No → Use BOOT_NONE (simpler)
└─ No: Must use bootloader + QSPI
   └─ Use BOOT_QSPI (only option for large apps)

Special case: Using CMSIS-DSP? → Always BOOT_QSPI (library is 1MB)
```

## Detailed Comparison

### BOOT_NONE (Direct Flash)

**What it is:** Application flashes directly to the Daisy's internal flash. No bootloader involved.

**Memory layout:**
- Application code: 0x08000000 to ~0x0801F000 (124KB available)
- Stack and static data: Remaining SRAM

**Advantages:**
- ✅ No bootloader required - can start fresh
- ✅ Simplest deployment - one flash operation
- ✅ Full control over memory layout
- ✅ Fastest execution (no bootloader overhead)
- ✅ Best for development and learning

**Disadvantages:**
- ❌ Limited to ~124KB of code
- ❌ Requires ST-Link or DFU mode selection each time
- ❌ No fast iteration mode

**When to use:**
- First project setup
- LED blink, serial logging, simple control
- Development and experimentation
- Total application < 100KB

**Flashing:**
```bash
nimble make
nimble stlink  # Via ST-Link (fastest)
# OR
nimble flash   # Via USB DFU (no hardware required)
```

**Configuration in project.nimble:**
```nim
const customDefines = ""  # or omit entirely
```

---

### BOOT_SRAM (Bootloader + SRAM Loading)

**What it is:** Application runs from SRAM, loaded via DFU bootloader. Once the bootloader is flashed, you can reload the application over USB without hardware.

**Memory layout:**
- Bootloader: 0x08000000 to 0x08010000 (64KB)
- Application code: 0x20000000 (loaded into SRAM at runtime)
- Heap/stack: Remaining SRAM

**Advantages:**
- ✅ Fast iteration - flash via USB without hardware
- ✅ Better size limit (~512KB available SRAM)
- ✅ No need for ST-Link after bootloader install
- ✅ Good for embedded development workflow

**Disadvantages:**
- ❌ Requires one-time bootloader installation (needs ST-Link)
- ❌ SRAM is limited (~512KB total), but application must fit
- ❌ Power cycle erases application (reboot returns to bootloader)
- ❌ SRAM applications slower than flash-resident code

**When to use:**
- Rapid development with bootloader installed
- Applications 100KB to 512KB
- Team projects where bootloader is pre-installed
- Faster iteration cycles preferred

**Setup (one-time):**
1. Install bootloader with ST-Link (contact team for bootloader binary)
2. Enter bootloader: Hold BOOT, press RESET, release BOOT
3. Run: `nimble flash` - loads to SRAM via USB

**Flashing:**
```bash
nimble make
nimble flash   # USB DFU only (bootloader required)
```

**Configuration in project.nimble:**
```nim
const customDefines = "bootSram"
```

---

### BOOT_QSPI (Bootloader + External Flash)

**What it is:** Application stored in external QSPI flash, loaded via DFU bootloader. Provides massive storage for large or feature-rich applications.

**Memory layout:**
- Bootloader: 0x08000000 to 0x08010000 (64KB internal)
- Application code: 0x90040000 (in QSPI, mapped to execution address)
- Heap/stack: SRAM (reusable, doesn't count toward app size)

**Advantages:**
- ✅ Unlimited code space (128MB QSPI available)
- ✅ Required for large libraries (CMSIS-DSP ~1MB)
- ✅ Fast iteration - reload over USB
- ✅ Persistent across power cycles

**Disadvantages:**
- ❌ Requires bootloader + QSPI support (one-time setup)
- ❌ Bootloader must support QSPI (not all do)
- ❌ QSPI access slightly slower than internal flash
- ❌ More complex memory layout

**When to use:**
- Applications > 120KB (especially > 300KB)
- Using CMSIS-DSP library (always required)
- Complex audio processing, filters, FFT
- Full-featured applications with UI framework

**Setup (one-time):**
1. Install QSPI-capable bootloader with ST-Link (contact team)
2. Enter bootloader: Hold BOOT, press RESET, release BOOT
3. First flash may take longer (programming QSPI)

**Flashing:**
```bash
nimble make
nimble flash   # USB DFU only (bootloader required)
```

**Configuration in project.nimble:**
```nim
const customDefines = "bootQspi"
```

**Example: CMSIS-DSP (always BOOT_QSPI):**
```nim
const customDefines = "bootQspi useCMSIS"
```

---

## Common Scenarios

### Scenario 1: Brand New Project

**Goal:** Get something working on Daisy

**Steps:**
1. Use BOOT_NONE (no extra setup)
2. Flash with ST-Link or USB DFU
3. Start simple - blink, serial logging
4. Only switch modes if you hit size limit

**Example:**
```bash
# Create from template
git clone https://github.com/Brokezawa/nimphea-template-basic myproject
cd myproject

# Build and flash
nimble make
nimble stlink  # or: nimble flash
```

### Scenario 2: Growing Beyond 120KB

**Goal:** Application is hitting size limit in BOOT_NONE

**Steps:**
1. Decide: Do you have a bootloader?
   - **No bootloader?** → Install one (one-time, needs ST-Link)
   - **Have bootloader?** → Continue
2. Choose BOOT_SRAM or BOOT_QSPI based on size
3. Update `customDefines` in project.nimble
4. Flash via `nimble flash`

**Decision:**
- Application < 512KB? → BOOT_SRAM (simpler)
- Application > 512KB? → BOOT_QSPI (required)
- Using CMSIS-DSP? → Always BOOT_QSPI

### Scenario 3: Using CMSIS-DSP for FFT

**Goal:** Fast Fourier Transform for spectral analysis

**Requirements:**
- CMSIS-DSP library is ~1MB (won't fit in internal flash)
- Must use BOOT_QSPI boot mode
- Must install QSPI-capable bootloader first

**Configuration:**
```nim
# project.nimble
const customDefines = "bootQspi useCMSIS"
```

**Build and flash:**
```bash
nimble make      # Will link CMSIS-DSP library
nimble flash     # Over USB with bootloader (2-3 seconds)
```

### Scenario 4: Team Project with Bootloader Pre-Installed

**Goal:** New developer joining project that already has bootloader

**Setup (one-time):**
1. No setup needed - bootloader already on device
2. Enter bootloader: Hold BOOT, press RESET, release BOOT
3. Run `nimble flash` - loads via USB

**Daily workflow:**
```bash
nimble make
nimble flash    # Fast USB update, no hardware required
```

---

## Changing Boot Modes

### From BOOT_NONE to BOOT_SRAM

```nim
# project.nimble - Change this line:
const customDefines = ""        # was: BOOT_NONE
# to:
const customDefines = "bootSram"
```

Then:
```bash
nimble make
nimble flash  # Must have bootloader installed
```

### From BOOT_SRAM to BOOT_QSPI

```nim
# project.nimble
const customDefines = "bootQspi"  # was: "bootSram"
```

Then:
```bash
nimble make
nimble flash
```

### Reverting to BOOT_NONE

**Requires ST-Link** (bootloader can't reflash itself)

```bash
# Remove boot mode defines
const customDefines = ""

nimble make
nimble stlink   # Via ST-Link only
```

---

## Troubleshooting

### "stlink task requires BOOT_NONE mode"

**Problem:** Tried `nimble stlink` with bootloaded application

**Solution:**
- Bootloaded modes (BOOT_SRAM, BOOT_QSPI) must use `nimble flash` (DFU)
- Direct flash (BOOT_NONE) can use `nimble stlink` (ST-Link)

**Fix:**
```bash
# If bootloader installed, use DFU
nimble flash

# If no bootloader, revert to BOOT_NONE
nimble stlink
```

### Application Size Error

**Problem:** "Binary too large for internal flash"

**Solutions:**
1. Enable size optimization: check `-Os` flag in config.nims
2. Switch to BOOT_QSPI: enables external 128MB QSPI storage
3. Add CMSIS-DSP if needed: requires BOOT_QSPI anyway

### Bootloader Entry Not Working

**Problem:** Device won't enter bootloader (Hold BOOT + press RESET)

**Possible causes:**
1. Application is interfering (e.g., GPIO remapping)
2. Bootloader not installed correctly
3. Wrong button combination for your board

**Solution:**
- Contact team for bootloader support and installation
- Try flashing with ST-Link in BOOT_NONE mode first

---

## Technical Details

### Memory Maps

**BOOT_NONE:**
```
0x08000000 ┌─────────────────────┐
           │  Application Code   │  ~124KB available
           │  (direct flash)     │
0x0801F000 └─────────────────────┘
0x20000000 ┌─────────────────────┐
           │  Stack + Heap       │  ~512KB SRAM
0x20080000 └─────────────────────┘
```

**BOOT_SRAM:**
```
0x08000000 ┌─────────────────────┐
           │  DFU Bootloader     │  64KB (pre-installed)
0x08010000 └─────────────────────┘
0x20000000 ┌─────────────────────┐
           │  Application Code   │  ~512KB (runs here)
0x20080000 └─────────────────────┘  Stack/Heap above app
```

**BOOT_QSPI:**
```
0x08000000 ┌─────────────────────┐
           │  DFU Bootloader     │  64KB (pre-installed)
0x08010000 └─────────────────────┘
0x90040000 ┌─────────────────────┐
           │  Application Code   │  128MB available
0x98000000 └─────────────────────┘  (QSPI external flash)
0x20000000 ┌─────────────────────┐
           │  Stack + Heap       │  Full SRAM available
0x20080000 └─────────────────────┘  (not counted toward app size)
```

### Performance Notes

- **BOOT_NONE**: Fastest - code executes directly from flash
- **BOOT_SRAM**: Code in SRAM is slightly faster than QSPI, but slower than internal flash
- **BOOT_QSPI**: QSPI access has latency (~20-30 cycles), but for most code this is negligible

---

## References

- [Build System](./BUILD_SYSTEM.md) - Compiler configuration details
- [Flashing Guide](./FLASH_GUIDE.md) - Flashing methods and tools
- Templates: [Basic](https://github.com/Brokezawa/nimphea-template-basic) | [Audio](https://github.com/Brokezawa/nimphea-template-audio)
