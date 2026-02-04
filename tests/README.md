# Nimphea Unit Tests

This directory contains unit tests for Nimphea's testable modules. These tests run on your **host computer** (no Daisy Seed hardware required) and verify the logic of pure data structures and utility functions.

## Overview

Nimphea uses a **two-tier testing approach**:

### Tier 1: Unit Tests (This Directory)
- **What**: Pure logic testing for data structures and utilities
- **Where**: Runs on your host computer (Linux/macOS/Windows)
- **How**: `nimble test_unit`
- **Purpose**: Catch logic bugs, enable TDD, support CI/CD
- **Framework**: [nim-unittest2](https://github.com/status-im/nim-unittest2)

### Tier 2: Integration Tests (examples/)
- **What**: Full functionality testing on real hardware
- **Where**: Runs on Daisy Seed hardware
- **How**: Flash and test examples (see `EXAMPLES.md` and `TESTING_GUIDE.md`)
- **Purpose**: Verify hardware integration and real-world usage
- **Framework**: Manual testing with documented examples

## Running Unit Tests

```bash
# Run all unit tests
nimble test_unit

# Install test dependencies (if needed)
nimble install -y unittest2
```

## Test Coverage

### Modules with Unit Tests

| Module | Test File | Status | Test Count |
|--------|-----------|--------|------------|
| `nimphea_fixedstr.nim` | `test_fixedstr.nim` | Complete | 22 tests |
| `nimphea_fifo.nim` | `test_fifo.nim` | Complete | 29 tests |
| `nimphea_stack.nim` | `test_stack.nim` | Complete | 27 tests |
| `nimphea_ringbuffer.nim` | `test_ringbuffer.nim` | Complete | 37 tests |
| `nimphea_mapped_value.nim` | `test_mapped_value.nim` | Complete | 40 tests |

**Total: 133 tests, 5/5 testable modules complete (100% of pure Nim modules)**

### Modules NOT Testable (C++ Wrappers)

The following modules use C++ headers via `{.importcpp.}` and cannot be unit tested without hardware. They are tested via integration tests (44 hardware examples in `examples/` directory):

- `nimphea_color.nim` - Requires `util/color.h`
- `nimphea_cpuload.nim` - Requires C++ headers
- `nimphea_voct_calibration.nim` - Requires C++ headers  
- `nimphea_shift_register.nim` - Requires C++ headers
- `nimphea_wavformat.nim` - Requires C++ headers (WAV file parsing)

### Modules Requiring Hardware Testing (Integration Tests Only)

These modules require Daisy Seed hardware and are tested via integration tests (examples):

- `nimphea_adc.nim`, `nimphea_dac.nim` - Analog I/O
- `nimphea_gpio.nim` - Digital I/O
- `nimphea_audio.nim` - Audio processing
- `nimphea_i2c.nim`, `nimphea_spi.nim` - Communication protocols
- Device drivers (OLED, encoders, switches, LEDs, etc.)
- Board support packages (Daisy Seed, Patch, Field, etc.)
- All C++ wrapper modules (see above)

## Writing Unit Tests

### Test File Structure

Each testable module gets its own test file:

```nim
# tests/test_modulename.nim
import unittest2
import ../src/nimphea_modulename

suite "ModuleName: Basic Functionality":
  test "should create default instance":
    var obj = initModuleName()
    check obj.someProperty == expectedValue

  test "should handle edge case":
    var obj = initModuleName()
    check obj.someMethod() == expectedResult
```

### Guidelines

1. **File Naming**: `test_<modulename>.nim` (e.g., `test_fifo.nim`)
2. **Suite Organization**: Group related tests into suites
3. **Test Naming**: Use descriptive names starting with "should..."
4. **Edge Cases**: Test boundary conditions, empty states, full states
5. **Practical Usage**: Include real-world usage patterns
6. **Import Test Module**: Add to `all_tests.nim` after creating

### Adding a New Test File

1. Create `tests/test_newmodule.nim`
2. Write your test suites
3. Add `import test_newmodule` to `all_tests.nim`
4. Run `nimble test_unit` to verify

## Design Philosophy

Nimphea's unit tests mirror **libDaisy's googletest approach**:

- **UNIT_TEST Macro**: Tests compile with `-d:UNIT_TEST` to enable mock implementations
- **Host Compilation**: Tests run on your development machine (x86/ARM host, not Cortex-M7)
- **Pure Logic**: Only modules without hardware dependencies are tested
- **Comprehensive Coverage**: Multiple test suites per module (basics, edge cases, practical usage)

See libDaisy's unit testing guide:
`libDaisy/doc/md/_b1_Development-Unit-Testing.md`

## Configuration

### `nim.cfg`
- Defines `UNIT_TEST` macro
- Sets up include paths
- Enables debug flags for better error messages

### `config.nims`
- NimScript configuration
- Adds `src/` directory to paths

## CI/CD Integration

Unit tests are designed to run in continuous integration:

```yaml
# Example GitHub Actions workflow
- name: Install dependencies
  run: nimble install -y unittest2

- name: Run unit tests
  run: nimble test_unit
```

## Test Output

When you run `nimble test_unit`, you'll see output like:

```
[Suite] FixedStr: Basic Functionality
  [OK] should start empty
  [OK] should report correct capacity
  [OK] should handle append operations
...
Success: All tests passed (40/40)
```

## Contributing

When adding new testable functionality to Nimphea:

1. Write unit tests for pure logic modules
2. Follow the existing test structure
3. Aim for comprehensive coverage (basics, edge cases, practical usage)
4. Update this README with new test files
5. Ensure `nimble test_unit` passes before submitting PR

For more information, see:
- `docs/CONTRIBUTING.md` - Contribution guidelines
- `docs/TESTING_GUIDE.md` - Integration testing guide
- `EXAMPLES.md` - Example programs and their test status

## Questions?

- **"Why can't I test hardware modules?"** - They require physical Daisy Seed hardware. Use integration tests (examples) instead.
- **"How do I test my custom audio callback?"** - Flash it to hardware and test manually. Unit tests are for pure logic only.
- **"Should I write unit tests or integration tests?"** - Both! Unit tests catch logic bugs early. Integration tests verify hardware behavior.

---

**Next Steps**: Run `nimble test_unit` to verify your test setup works!
