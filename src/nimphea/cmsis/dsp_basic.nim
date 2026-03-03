## CMSIS-DSP Basic Math Functions
##
## This module provides optimized vector math operations.
## All operations are in-place or write to a user-provided destination buffer.
## Zero heap allocation is used.

import cmsis_types, cmsis_core

useCmsisModules(dsp_basic)

# ============================================================================
# Addition
# ============================================================================

proc arm_add_f32*(pSrcA, pSrcB: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc add*(dst: var openArray[float32], a, b: openArray[float32]) {.inline.} =
  ## Vector addition: dst = a + b
  let n = min([dst.len, a.len, b.len])
  if n > 0:
    arm_add_f32(addr a[0], addr b[0], addr dst[0], n.uint32)

# ============================================================================
# Subtraction
# ============================================================================

proc arm_sub_f32*(pSrcA, pSrcB: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc sub*(dst: var openArray[float32], a, b: openArray[float32]) {.inline.} =
  ## Vector subtraction: dst = a - b
  let n = min([dst.len, a.len, b.len])
  if n > 0:
    arm_sub_f32(addr a[0], addr b[0], addr dst[0], n.uint32)

# ============================================================================
# Multiplication
# ============================================================================

proc arm_mult_f32*(pSrcA, pSrcB: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc mult*(dst: var openArray[float32], a, b: openArray[float32]) {.inline.} =
  ## Vector multiplication: dst = a * b
  let n = min([dst.len, a.len, b.len])
  if n > 0:
    arm_mult_f32(addr a[0], addr b[0], addr dst[0], n.uint32)

# ============================================================================
# Scaling
# ============================================================================

proc arm_scale_f32*(pSrc: ptr float32_t, scale: float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc scale*(dst: var openArray[float32], src: openArray[float32], scale: float32) {.inline.} =
  ## Vector scaling: dst = src * scale
  let n = min(dst.len, src.len)
  if n > 0:
    arm_scale_f32(addr src[0], scale.float32_t, addr dst[0], n.uint32)

proc scale*(dst: var openArray[float32], scale: float32) {.inline.} =
  ## In-place vector scaling: dst = dst * scale
  if dst.len > 0:
    arm_scale_f32(addr dst[0], scale.float32_t, addr dst[0], dst.len.uint32)

# ============================================================================
# Dot Product
# ============================================================================

proc arm_dot_prod_f32*(pSrcA, pSrcB: ptr float32_t, blockSize: uint32, result: ptr float32_t) {.importc, header: "arm_math.h".}

proc dotProduct*(a, b: openArray[float32]): float32 =
  ## Vector dot product: sum(a[i] * b[i])
  let n = min(a.len, b.len)
  var res: float32_t = 0.0
  if n > 0:
    arm_dot_prod_f32(addr a[0], addr b[0], n.uint32, addr res)
  return res.float32

# ============================================================================
# Negation
# ============================================================================

proc arm_negate_f32*(pSrc: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc negate*(dst: var openArray[float32], src: openArray[float32]) {.inline.} =
  ## Vector negation: dst = -src
  let n = min(dst.len, src.len)
  if n > 0:
    arm_negate_f32(addr src[0], addr dst[0], n.uint32)

# ============================================================================
# Absolute Value
# ============================================================================

proc arm_abs_f32*(pSrc: ptr float32_t, pDst: ptr float32_t, blockSize: uint32) {.importc, header: "arm_math.h".}

proc abs*(dst: var openArray[float32], src: openArray[float32]) {.inline.} =
  ## Vector absolute value: dst = abs(src)
  let n = min(dst.len, src.len)
  if n > 0:
    arm_abs_f32(addr src[0], addr dst[0], n.uint32)
