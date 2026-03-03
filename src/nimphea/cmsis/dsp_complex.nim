## CMSIS-DSP Complex Math Functions
##
## This module provides optimized operations on complex number vectors.
## Complex vectors are represented as interleaved float32 arrays [re0, im0, re1, im1, ...].

import cmsis_types, cmsis_core

useCmsisModules(dsp_complex)

# ============================================================================
# Multiplication
# ============================================================================

proc arm_cmplx_mult_cmplx_f32*(pSrcA: ptr float32_t, pSrcB: ptr float32_t, pDst: ptr float32_t, numSamples: uint32) {.importc, header: "arm_math.h".}
proc arm_cmplx_mult_real_f32*(pSrcCmplx: ptr float32_t, pSrcReal: ptr float32_t, pDst: ptr float32_t, numSamples: uint32) {.importc, header: "arm_math.h".}

proc mult*(dst: var openArray[float32], a, b: openArray[float32]) {.inline.} =
  ## Complex-by-complex multiplication: dst = a * b
  let n = min([dst.len, a.len, b.len]) div 2
  if n > 0:
    arm_cmplx_mult_cmplx_f32(cast[ptr float32_t](addr a[0]), cast[ptr float32_t](addr b[0]), cast[ptr float32_t](addr dst[0]), n.uint32)

proc multReal*(dst: var openArray[float32], cmplx: openArray[float32], real: openArray[float32]) {.inline.} =
  ## Complex-by-real multiplication
  let n = min([dst.len div 2, cmplx.len div 2, real.len])
  if n > 0:
    arm_cmplx_mult_real_f32(cast[ptr float32_t](addr cmplx[0]), cast[ptr float32_t](addr real[0]), cast[ptr float32_t](addr dst[0]), n.uint32)

# ============================================================================
# Magnitude
# ============================================================================

proc arm_cmplx_mag_f32*(pSrc: ptr float32_t, pDst: ptr float32_t, numSamples: uint32) {.importc, header: "arm_math.h".}
proc arm_cmplx_mag_squared_f32*(pSrc: ptr float32_t, pDst: ptr float32_t, numSamples: uint32) {.importc, header: "arm_math.h".}

proc mag*(dst: var openArray[float32], src: openArray[float32]) {.inline.} =
  ## Complex magnitude: dst[i] = sqrt(re[i]^2 + im[i]^2)
  let n = min(dst.len, src.len div 2)
  if n > 0:
    arm_cmplx_mag_f32(cast[ptr float32_t](addr src[0]), cast[ptr float32_t](addr dst[0]), n.uint32)

proc magSquared*(dst: var openArray[float32], src: openArray[float32]) {.inline.} =
  ## Complex magnitude squared: dst[i] = re[i]^2 + im[i]^2
  let n = min(dst.len, src.len div 2)
  if n > 0:
    arm_cmplx_mag_squared_f32(cast[ptr float32_t](addr src[0]), cast[ptr float32_t](addr dst[0]), n.uint32)

# ============================================================================
# Conjugate and Dot Product
# ============================================================================

proc arm_cmplx_conj_f32*(pSrc: ptr float32_t, pDst: ptr float32_t, numSamples: uint32) {.importc, header: "arm_math.h".}
proc arm_cmplx_dot_prod_f32*(pSrcA: ptr float32_t, pSrcB: ptr float32_t, numSamples: uint32, realResult: ptr float32_t, imagResult: ptr float32_t) {.importc, header: "arm_math.h".}

proc conjugate*(dst: var openArray[float32], src: openArray[float32]) {.inline.} =
  ## Complex conjugate: dst = [re, -im]
  let n = min(dst.len div 2, src.len div 2)
  if n > 0:
    arm_cmplx_conj_f32(cast[ptr float32_t](addr src[0]), cast[ptr float32_t](addr dst[0]), n.uint32)

proc dotProduct*(a, b: openArray[float32]): tuple[real, imag: float32] =
  ## Complex dot product
  let n = min(a.len div 2, b.len div 2)
  var re: float32_t = 0.0
  var im: float32_t = 0.0
  if n > 0:
    arm_cmplx_dot_prod_f32(cast[ptr float32_t](addr a[0]), cast[ptr float32_t](addr b[0]), n.uint32, addr re, addr im)
  return (re.float32, im.float32)
