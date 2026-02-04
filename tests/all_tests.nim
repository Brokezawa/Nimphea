## Master test runner for Nimphea unit tests
##
## This file imports and runs all unit test files.
## Add new test files here as they are created.
##
## Usage:
##   nimble test_unit
##
## See tests/README.md for more information.

import unittest2

# Import all test modules
# Phase 1: FixedStr (string utilities)
import test_fixedstr

# Phase 2: Data structures
import test_fifo
import test_stack
import test_ringbuffer

# Phase 3: Utility modules (pure Nim only)
import test_mapped_value

# Note: The following modules use C++ headers and cannot be unit tested:
# - color, cpuload, voct_calibration, shift_register, wavformat
# These are tested via integration tests (44 hardware examples)
