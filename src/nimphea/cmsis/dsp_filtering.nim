## CMSIS-DSP Filtering Functions
##
## This module provides optimized filtering operations (FIR, IIR).
## Filters are designed to be stack-allocated or static-allocated
## with compile-time known sizes. Zero heap allocation is used.

import cmsis_types, cmsis_core

useCmsisModules(dsp_filtering)

# ============================================================================
# FIR Filter
# ============================================================================

type
  FirInstanceF32* {.importcpp: "arm_fir_instance_f32", header: "arm_math.h".} = object
    numTaps*: uint16
    pState*: ptr float32_t
    pCoeffs*: ptr float32_t

proc arm_fir_init_f32*(S: ptr FirInstanceF32, numTaps: uint16, pCoeffs: ptr float32_t, pState: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}
proc arm_fir_f32*(S: ptr FirInstanceF32, pSrc: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

type
  FirFilter*[NumTaps, MaxBlockSize: static int] = object
    ## A compile-time sized FIR filter.
    ## State buffer is automatically sized and zero-initialized.
    instance*: FirInstanceF32
    state*: array[NumTaps + MaxBlockSize - 1, float32_t]

proc init*[NT, MB: static int](f: var FirFilter[NT, MB], coeffs: ptr float32_t) =
  ## Initialize FIR filter with coefficients.
  ## Coeffs must point to an array of NumTaps floats.
  static: assert NT > 0, "FIR NumTaps must be > 0"
  static: assert MB > 0, "FIR MaxBlockSize must be > 0"
  f.instance.numTaps = NT.uint16
  f.instance.pCoeffs = coeffs
  f.instance.pState = addr f.state[0]
  # Zero state
  for i in 0..<f.state.len: f.state[i] = 0.0
  arm_fir_init_f32(addr f.instance, NT.uint16, coeffs, addr f.state[0], MB.uint32)

proc process*[NT, MB: static int](f: var FirFilter[NT, MB], input: openArray[float32], output: var openArray[float32]) {.inline.} =
  ## Process an audio block through the FIR filter.
  let size = min(input.len, output.len)
  if size > 0:
    arm_fir_f32(addr f.instance, cast[ptr float32_t](addr input[0]), cast[ptr float32_t](addr output[0]), size.uint32)

# ============================================================================
# Biquad (IIR) Filter (Direct Form I)
# ============================================================================

type
  BiquadInstanceF32* {.importcpp: "arm_biquad_casd_df1_inst_f32", header: "arm_math.h".} = object
    numStages*: uint8
    pState*: ptr float32_t
    pCoeffs*: ptr float32_t
    postShift*: int8

proc arm_biquad_cascade_df1_init_f32*(S: ptr BiquadInstanceF32, numStages: uint8, pCoeffs: ptr float32_t, pState: ptr float32_t) {.importc, header: "arm_math.h".}
proc arm_biquad_cascade_df1_f32*(S: ptr BiquadInstanceF32, pSrc: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

type
  BiquadFilter*[NumStages: static int] = object
    ## A compile-time sized Biquad Cascade (IIR) filter.
    ## State buffer is automatically sized and zero-initialized.
    instance*: BiquadInstanceF32
    state*: array[NumStages * 4, float32_t]

proc init*[NS: static int](f: var BiquadFilter[NS], coeffs: ptr float32_t) =
  ## Initialize Biquad filter with coefficients.
  ## Coeffs must point to [b0, b1, b2, a1, a2] * NumStages floats.
  static: assert NS > 0, "Biquad NumStages must be > 0"
  f.instance.numStages = NS.uint8
  f.instance.pCoeffs = coeffs
  f.instance.pState = addr f.state[0]
  # Zero state
  for i in 0..<f.state.len: f.state[i] = 0.0
  arm_biquad_cascade_df1_init_f32(addr f.instance, NS.uint8, coeffs, addr f.state[0])

proc process*[NS: static int](f: var BiquadFilter[NS], input: openArray[float32], output: var openArray[float32]) {.inline.} =
  ## Process an audio block through the Biquad filter.
  let size = min(input.len, output.len)
  if size > 0:
    arm_biquad_cascade_df1_f32(addr f.instance, cast[ptr float32_t](addr input[0]), cast[ptr float32_t](addr output[0]), size.uint32)
