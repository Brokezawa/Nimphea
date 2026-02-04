# Nim-Specific Features in Nimphea

This document highlights features and advantages unique to the Nim wrapper that go beyond a simple C++ binding.

## Table of Contents

- [Memory Safety](#memory-safety)
- [Nim-Native Data Structures](#nim-native-data-structures)
- [Language Features](#language-features)
- [Developer Experience](#developer-experience)
- [Type Safety](#type-safety)
- [Performance Characteristics](#performance-characteristics)

---

## Memory Safety

### Zero Heap Allocation in Realtime Paths

All critical data structures are designed for stack allocation with **guaranteed zero heap usage** in audio callbacks and other realtime paths.

**C++ libDaisy:**
```cpp
// Risk of heap allocation with STL
std::vector<float> buffer;  // May allocate
std::string name;           // Allocates

// Safe but verbose
float buffer[256];          // Stack allocated
```

**Nimphea:**
```nim
# All containers are stack-allocated by default
var buffer: array[256, float]   # Stack allocated
var fifo: FIFO[float, 128]      # Stack allocated
var str: FixedStr[32]           # Stack allocated - no heap!

# Compile-time enforcement
when defined(danger):
  # --gc:arc ensures deterministic behavior
  # No GC pauses in embedded targets
```

**Benefits:**
- **Deterministic**: No surprise allocations in audio callbacks
- **Fast**: Stack allocation is instant
- **Safe**: Compiler enforces size limits at compile time
- **Predictable**: No memory fragmentation

---

### ARC Memory Management

Nim's **Automatic Reference Counting (ARC)** provides deterministic memory management without garbage collection.

**Key Advantages:**

1. **No GC Pauses**: ARC has predictable, bounded overhead
2. **Deterministic Destruction**: Resources freed immediately when last reference goes out of scope
3. **Move Semantics**: Efficient ownership transfer without copying
4. **Cycle Collection**: Optional cycle collector for rare cases (disabled in embedded targets)

**Example:**
```nim
type
  AudioBuffer = object
    data: seq[float32]
    
proc createBuffer(size: int): AudioBuffer =
  result.data = newSeq[float32](size)
  # Automatically freed when result goes out of scope

# In embedded code, use stack allocation instead:
proc audioCallback(input, output: AudioBuffer, size: int) {.cdecl.} =
  # No heap allocation in callback - compile-time guaranteed
  var temp: array[256, float32]  # Stack only
  # Process audio...
```

**Compile-Time Safety:**
```nim
# Nim can detect some heap allocations at compile time:
proc badAudioCallback(input, output: ptr ptr cfloat, size: int) {.cdecl.} =
  var list = @[1, 2, 3]  # Can cause compile warnings in analysis mode
  # The seq type is marked as potentially allocating

# Best practice: Explicitly use stack-allocated types
proc goodAudioCallback(input, output: ptr ptr cfloat, size: int) {.cdecl.} =
  var buffer: array[256, float32]  # Stack allocated - guaranteed safe
  # Array types are explicitly stack-based
```

**Note:** Nim's type system makes it easy to choose safe types, but detecting all heap allocations requires careful use of stack-allocated containers and type restrictions. This is similar to using `alloca()` or stack containers in C++.

---

## Nim-Native Data Structures

Instead of wrapping C++ STL templates, Nimphea provides **pure Nim implementations** designed specifically for embedded use.

### Why Nim-Native?

| Aspect | C++ Wrappers | Nim-Native |
|--------|--------------|------------|
| **Type Safety** | Limited (C++ templates are opaque) | Full Nim type checking |
| **Error Messages** | Cryptic template errors | Clear, helpful messages |
| **Overhead** | FFI boundary crossings | Zero-cost abstractions |
| **Control** | Limited to C++ API | Full control over memory layout |
| **Integration** | Foreign types | Native Nim semantics |

### FIFO (First-In-First-Out Queue)

**C++ libDaisy:**
```cpp
#include "util/fifo.h"

daisy::FIFO<float, 128> fifo;  // Template instantiation
fifo.PushBack(42.0f);          // C++ naming
float val;
fifo.PopFront(&val);           // Pointer-based API
```

**Nimphea:**
```nim
import src/util/fifo

var fifo: FIFO[float, 128]  # Generic, type-safe
fifo.write(42.0)            # Nim naming conventions
let val = fifo.read()       # Value-based API (safer)

# Check before operations
if not fifo.isFull():
  fifo.write(3.14)
  
if not fifo.isEmpty():
  echo "Got: ", fifo.read()
```

**Benefits:**
- Compile-time size checking
- No heap allocation
- Native Nim error handling
- Clearer API naming

### FixedStr (Fixed-Size Strings)

A **zero-allocation** string type for embedded systems.

**The Problem:**
```nim
# Standard Nim strings allocate on heap:
var name = "Daisy"  # Heap allocated - NOT safe in audio callbacks!
```

**The Solution:**
```nim
import src/util/fixedstr

var name: FixedStr[32]  # Stack allocated, max 32 chars
name = "Daisy Seed"     # No heap allocation!
name.add(" Audio")      # Still no heap!

echo name              # "Daisy Seed Audio"
echo name.len          # 16
echo name.capacity     # 32
```

**Features:**
- **Zero heap allocation**: Completely stack-based
- **Familiar API**: Similar to Nim's `string` type
- **Compile-time capacity**: Size checked at compile time
- **Safe truncation**: Automatic bounds checking
- **Efficient**: No copying, minimal overhead

**Use Cases:**
```nim
# Display text without heap allocation
var display: OledDisplay
var msg: FixedStr[20]
msg = "Volume: "
msg.add($volumeLevel)  # String conversion, still no heap!
display.writeString(0, 0, msg.cstring, Font_7x10, true)

# Debug logging in realtime code
var log: FixedStr[64]
log = "Sample rate: "
log.add($sampleRate)
usbLogger.print(log)
```

### RingBuffer

**Optimized for audio applications:**

```nim
import src/util/ringbuffer

# Lock-free, single-producer single-consumer
var rb: RingBuffer[AudioSample, 1024]

# Producer (audio callback)
proc audioCallback(input, output: ptr ptr cfloat, size: int) {.cdecl.} =
  for i in 0..<size:
    if not rb.isFull():
      rb.write(input[0][i])

# Consumer (main thread)
while not rb.isEmpty():
  let sample = rb.read()
  processAudioData(sample)
```

**Features:**
- Lock-free for single producer/consumer
- Optimal cache locality
- Zero allocation after initialization
- Suitable for realtime audio processing

### Stack

**Type-safe, bounded stack:**

```nim
import src/util/stack

var history: Stack[MidiNote, 16]  # Max 16 notes

# Push note
if not history.isFull():
  history.push(MidiNote(note: 60, velocity: 100))

# Pop note
if not history.isEmpty():
  let lastNote = history.pop()
  echo "Last note: ", lastNote.note
```

---

## Language Features

### Macros: Compile-Time Code Generation

Nim's **powerful macro system** enables code generation at compile time, reducing boilerplate and improving safety.

#### useDaisyNamespace Macro

**Problem:** C++ uses namespaces, Nim uses modules.

**Solution:** The `useDaisyNamespace()` macro imports and re-exports all common types automatically.

```nim
import nimphea
useDaisyNamespace()  # Macro expands to import all needed types

# Now you can use Daisy types directly:
var hw: DaisySeed
var led: Led
var sw: Switch
# No need for: libdaisy.DaisySeed, libdaisy.Led, etc.
```

**Generated code** (what the macro expands to):
```nim
# Auto-imports and re-exports:
import nimphea
export DaisyGPIO, Pin, PinMode, Pull

import hid/ctrl
export Switch, Encoder, Led, RgbLed

# ... and many more modules
```

**Benefits:**
- **Convenience**: One line imports everything
- **Flexibility**: Can still import selectively if needed
- **Zero overhead**: Resolved at compile time
- **Type-safe**: Full compiler checking

#### useDaisyModules Macro

**Selective imports** for advanced users:

```nim
import nimphea_macros
useDaisyModules(gpio, controls, audio)  # Import only what you need

# Now have: DaisyGPIO, Switch, Encoder, AudioCallback
# But not: OLED types, MIDI types, etc.
```

**Benefits:**
- Faster compile times
- Clearer dependencies
- Reduced namespace pollution

#### defineMenu DSL

**Declarative menu construction:**

```nim
import src/ui/menu_builder

var volume = linear(0.0, 100.0, 50.0, "%")
var mute = false

# Define menu using DSL
defineMenu mainMenu:
  value "Volume", volume
  checkbox "Mute", mute
  action "Save", saveSettings
  close "Exit"

# Generated at compile-time:
# - Menu structure
# - Item array
# - Type-safe bindings
```

**Expanded code** (what macro generates):
```nim
var mainMenu: BuiltMenu[4]
mainMenu.items[0] = valueItem("Volume", addr volume)
mainMenu.items[1] = checkboxItem("Mute", addr mute)
mainMenu.items[2] = actionItem("Save", saveSettings)
mainMenu.items[3] = closeItem("Exit")
mainMenu.menu = initFullScreenItemMenu(mainMenu.items)
```

---

### Templates: Zero-Cost Abstractions

Nim **templates** are hygienic macros that expand inline at compile time - **zero runtime overhead**.

#### Example: Safe Buffer Access

```nim
template withBounds[T](buffer: openArray[T], index: int, body: untyped) =
  if index >= 0 and index < buffer.len:
    body
  else:
    # Compile-time error or runtime assertion
    {.error: "Index out of bounds".}

# Usage
var samples: array[256, float]
withBounds(samples, idx):
  samples[idx] = 0.5  # Checked access, zero overhead
```

#### Example: Audio Processing DSL

```nim
template stereoProcess(input, output: AudioBuffer, size: int, 
                       processBody: untyped) =
  for i in 0..<size:
    let left {.inject.} = input[0][i]
    let right {.inject.} = input[1][i]
    
    processBody  # User code injected here
    
    output[0][i] = left
    output[1][i] = right

# Use the template
proc audioCallback(input, output: ptr ptr cfloat, size: int) {.cdecl.} =
  stereoProcess(input, output, size):
    # 'left' and 'right' variables are automatically available
    left = left * 0.5   # Apply gain
    right = right * 0.5
```

**Benefits:**
- No function call overhead
- Compile-time expansion
- Code reuse without performance cost
- Hygienic (no variable capture issues)

---

### Generics vs C++ Templates

Nim generics are **fully type-checked** at definition time. C++ templates traditionally use duck typing, but C++20 added **concepts** for similar checking.

**C++ Templates (traditional, duck typing):**
```cpp
template<typename T>
void process(T& value) {
    value.start();      // Error only when instantiated
    value.unknown();    // Cryptic template instantiation error
}
```

**C++ with Concepts (C++20, type-checked):**
```cpp
template<typename T>
concept Startable = requires(T t) {
    t.start();          // Explicit requirements
};

template<Startable T>
void process(T& value) {
    value.start();      // Type-checked at definition
    value.unknown();    // ERROR: Clear error at definition time
}
```

**Nim Generics (type-checked):**
```nim
type
  Startable = concept c
    c.start()  # Explicit constraints

proc process[T: Startable](value: var T) =
  value.start()   # Type-checked at definition
  value.unknown() # ERROR: Clear message at definition time
```

**Comparison:**
| Aspect | C++ Templates | C++20 Concepts | Nim Generics |
|--------|--------------|----------------|--------------|
| **Type checking** | Duck typing (at instantiation) | Explicit (at definition) | Explicit (at definition) |
| **Error messages** | Cryptic, instantiation-related | Clear, requirement-focused | Clear, requirement-focused |
| **Availability** | All versions | C++20+ only | All Nim versions |
| **Constraint syntax** | Implicit (code attempts) | Explicit `requires` | Explicit `concept` |

**Benefits:**
- **Earlier error detection**: Errors caught at definition, not use
- **Better error messages**: Clear, helpful messages
- **Explicit constraints**: Document requirements
- **Faster compilation**: Reduced instantiation explosion (Nim & C++20 concepts)

---

## Developer Experience

### Clearer Syntax

**C++ libDaisy:**
```cpp
#include "daisy_seed.h"

daisy::DaisySeed hw;

void AudioCallback(AudioHandle::InputBuffer in,
                   AudioHandle::OutputBuffer out,
                   size_t size) {
    for(size_t i = 0; i < size; i++) {
        out[0][i] = in[0][i];
        out[1][i] = in[1][i];
    }
}

int main() {
    hw.Init();
    hw.StartAudio(AudioCallback);
    while(1) {}
}
```

**Nimphea:**
```nim
import nimphea
useDaisyNamespace()

proc audioCallback(input, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
  for i in 0..<size:
    output[0][i] = input[0][i]
    output[1][i] = input[1][i]

proc main() =
  var hw = initDaisy()
  hw.startAudio(audioCallback)
  while true:
    discard

when isMainModule:
  main()
```

**Improvements:**
- No manual `#include` management
- Lowercase naming (Nim convention)
- `while true` instead of `while(1)`
- Built-in module system
- No semicolons

---

### Better Error Messages

**C++ Template Error (can be 100+ lines):**
```
error: no matching function for call to 'FIFO<float, 128>::PushBack(int)'
  fifo.PushBack(42);
       ^~~~~~~~
note: candidate: void daisy::FIFO<T, capacity>::PushBack(const T&) [with T = float; long unsigned int capacity = 128]
... 50 more lines of template instantiation context ...
```

**Nim Error (clear and concise):**
```
Error: type mismatch: got <int> but expected 'float'
  fifo.write(42)
         ^
Hint: convert with 42.0 or 42.cfloat
```

---

### Uniform Function Call Syntax (UFCS)

Method-like calls on any type:

```nim
# Traditional function call
echo repeat("*", 10)

# UFCS - call as method
"*".repeat(10).echo()

# Chain operations
let result = "hello"
  .toUpper()
  .repeat(3)
  .split("E")

# Works with Daisy types too:
var hw = initDaisy()
hw.setLed(true)      # Method syntax
setLed(hw, true)     # Function syntax - both work!
```

---

### Compile-Time Function Execution (CTFE)

**Run code at compile time** to generate lookup tables, validate configurations, etc.

**Nim:**
```nim
import math

# Generate sine table at compile time
const WaveTableSize = 256

proc generateSineTable(): array[WaveTableSize, float] =
  for i in 0..<WaveTableSize:
    result[i] = sin(2.0 * PI * i.float / WaveTableSize.float)

# Executed at compile time - zero runtime cost!
const SineTable = generateSineTable()

# Use in audio callback - just a memory lookup
proc audioCallback(input, output: ptr ptr cfloat, size: csize_t) {.cdecl.} =
  var phase = 0
  for i in 0..<size:
    output[0][i] = SineTable[phase]
    phase = (phase + 1) mod WaveTableSize
```

**C++ Equivalent (constexpr):**
```cpp
#include <cmath>
#include <array>

constexpr std::array<float, 256> generateSineTable() {
    std::array<float, 256> result{};
    for (int i = 0; i < 256; i++) {
        result[i] = std::sin(2.0f * M_PI * i / 256.0f);
    }
    return result;
}

// Executed at compile time - equivalent to Nim's approach
constexpr auto SineTable = generateSineTable();

void audioCallback(float** input, float** output, size_t size) {
    static int phase = 0;
    for (size_t i = 0; i < size; i++) {
        output[0][i] = SineTable[phase];
        phase = (phase + 1) % 256;
    }
}
```

**Comparison:**
| Aspect | Nim CTFE | C++ constexpr |
|--------|----------|---------------|
| **Syntax** | Implicit with `const` | Explicit `constexpr` keyword |
| **Flexibility** | Works with any function | Limited to certain operations |
| **Runtime cost** | Zero | Zero |
| **Compile time impact** | Can be slow for large tables | Generally faster |

**Benefits (Both Languages):**
- No initialization code at runtime
- Perfect for embedded systems
- Validate configurations at compile time
- Generate optimal code

**Note:** Modern C++ (C++20+) supports most compile-time code generation via constexpr. Nim's CTFE is more general and flexible, but both achieve the goal of zero-cost initialization.

---

## Type Safety

### Distinct Types

Create incompatible types from the same base type to **prevent mixing values**:

```nim
type
  Hertz = distinct float
  Seconds = distinct float
  Decibels = distinct float

proc setFrequency(freq: Hertz) = discard
proc setDelay(time: Seconds) = discard

let freq: Hertz = 440.0.Hertz
let time: Seconds = 0.5.Seconds

setFrequency(freq)  # OK
setFrequency(time)  # ERROR: Type mismatch - prevented at compile time!
```

### Enum Variants

Safe enum handling without undefined values:

```nim
type
  SampleRate = enum
    SR_8KHZ = 8000
    SR_16KHZ = 16000
    SR_44_1KHZ = 44100
    SR_48KHZ = 48000
    SR_96KHZ = 96000

proc configureSampleRate(sr: SampleRate) =
  # Compiler ensures all cases are handled
  case sr
  of SR_8KHZ: echo "8kHz"
  of SR_16KHZ: echo "16kHz"
  of SR_44_1KHZ: echo "44.1kHz"
  of SR_48KHZ: echo "48kHz"
  # Missing SR_96KHZ - COMPILER ERROR!
```

### Option Types

Safe handling of optional values without null pointers:

```nim
import std/options

type
  MidiMessage = object
    note: int
    velocity: int

proc getNextMidiEvent(): Option[MidiMessage] =
  if hasEvent():
    some(MidiMessage(note: 60, velocity: 100))
  else:
    none(MidiMessage)

# Safe usage
let maybeEvent = getNextMidiEvent()
if maybeEvent.isSome:
  let event = maybeEvent.get
  echo "Note: ", event.note
# No null pointer crashes!
```

---

## Performance Characteristics

### Inline Functions

Explicit control over inlining:

```nim
proc readGPIO(pin: DaisyGPIO): bool {.inline.} =
  # Always inlined - zero function call overhead
  pin.read()

proc complexCalculation(): float {.noinline.} =
  # Never inlined - saves code size
  # ... complex code ...
```

### Emit C/C++

When you need **maximum performance**, directly emit C++ code:

```nim
proc fastCopy(dest, src: pointer, size: int) {.importc: "memcpy", header: "<string.h>".}

# Or emit inline C++:
proc atomicIncrement(p: ptr int): int =
  {.emit: """
  return __atomic_fetch_add(`p`, 1, __ATOMIC_SEQ_CST);
  """.}
```

### No Virtual Function Overhead

Nim uses **static dispatch by default** - no vtable lookups:

```nim
# Static dispatch - resolved at compile time
proc process(sw: var Switch) = discard
proc process(enc: var Encoder) = discard

# Method syntax, but static dispatch:
sw.process()   # No virtual call overhead
enc.process()  # Direct function call
```

### Compile-Time Polymorphism

Generic specialization at compile time:

```nim
proc process[T](control: var T) =
  when T is Switch:
    # Specialized code for Switch
    control.debounce()
  elif T is Encoder:
    # Specialized code for Encoder
    control.update()
  
  # Code specialized for each type - no runtime checks!
```

---

## Conclusion

Nimphea leverages Nim's unique features to provide:

1. **Memory Safety**: ARC, zero-heap data structures, compile-time guarantees
2. **Nim-Native Design**: Purpose-built data structures, not just wrappers
3. **Powerful Metaprogramming**: Macros, templates, CTFE for clean, efficient code
4. **Better DX**: Clearer syntax, better errors, UFCS, module system
5. **Type Safety**: Distinct types, exhaustive case checking, Option types
6. **Performance**: Inline, static dispatch, compile-time polymorphism

These features combine to create a **safer, more expressive, and equally performant** alternative to C++ for embedded audio development on the Daisy platform.

### Note on C++ Comparisons

This document highlights Nim's strengths. Modern C++ (especially C++20+) has evolved significantly and now provides many similar features (concepts, constexpr, structured bindings, etc.). The advantage of Nimphea is **consistent availability across all versions** and **simpler syntax** for these features, not necessarily unique capabilities. Both languages are capable for embedded audio work—Nim simply prioritizes these patterns as first-class features.

---

**Next Steps:**

- See [API_REFERENCE.md](API_REFERENCE.md) for complete API documentation
- See [EXAMPLES.md](EXAMPLES.md) for practical usage examples
- See [BUILD_SYSTEM.md](BUILD_SYSTEM.md) for build instructions
