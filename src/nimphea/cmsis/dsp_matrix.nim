## CMSIS-DSP Matrix Functions
##
## This module provides optimized matrix operations.
## Matrix instances are designed to be static-allocated with compile-time 
## known dimensions. Zero heap allocation is used.

import cmsis_types, cmsis_core

useCmsisModules(dsp_matrix)

# ============================================================================
# Matrix Instance
# ============================================================================

type
  MatrixInstanceF32* {.importcpp: "arm_matrix_instance_f32", header: "arm_math.h".} = object
    numRows*: uint16
    numCols*: uint16
    pData*: ptr float32_t

proc arm_mat_init_f32*(S: ptr MatrixInstanceF32, nRows: uint16, nCols: uint16, pData: ptr float32_t) {.importc, header: "arm_math.h".}

type
  Matrix*[Rows, Cols: static int] = object
    ## A compile-time sized Matrix.
    instance*: MatrixInstanceF32
    data*: array[Rows * Cols, float32_t]

proc init*[R, C: static int](m: var Matrix[R, C]) =
  ## Initialize matrix instance.
  arm_mat_init_f32(addr m.instance, R.uint16, C.uint16, addr m.data[0])

proc `[]`*[R, C: static int](m: Matrix[R, C], row, col: int): float32 {.inline.} =
  ## Get element at row, col.
  m.data[row * C + col].float32

proc `[]=`*[R, C: static int](m: var Matrix[R, C], row, col: int, val: float32) {.inline.} =
  ## Set element at row, col.
  m.data[row * C + col] = val.float32_t

# ============================================================================
# Matrix Operations
# ============================================================================

proc arm_mat_add_f32*(pSrcA: ptr MatrixInstanceF32, pSrcB: ptr MatrixInstanceF32, pDst: ptr MatrixInstanceF32): ArmStatus {.importc, header: "arm_math.h".}
proc arm_mat_sub_f32*(pSrcA: ptr MatrixInstanceF32, pSrcB: ptr MatrixInstanceF32, pDst: ptr MatrixInstanceF32): ArmStatus {.importc, header: "arm_math.h".}
proc arm_mat_mult_f32*(pSrcA: ptr MatrixInstanceF32, pSrcB: ptr MatrixInstanceF32, pDst: ptr MatrixInstanceF32): ArmStatus {.importc, header: "arm_math.h".}
proc arm_mat_inverse_f32*(pSrc: ptr MatrixInstanceF32, pDst: ptr MatrixInstanceF32): ArmStatus {.importc, header: "arm_math.h".}
proc arm_mat_trans_f32*(pSrc: ptr MatrixInstanceF32, pDst: ptr MatrixInstanceF32): ArmStatus {.importc, header: "arm_math.h".}

proc add*[R, C: static int](dst: var Matrix[R, C], a, b: Matrix[R, C]): ArmStatus {.inline.} =
  ## Add two matrices: dst = a + b
  ##
  ## **Returns:** ArmStatus indicating success or error
  ## - ARM_MATH_SUCCESS: Operation completed successfully
  ## - ARM_MATH_SIZE_MISMATCH: Dimension mismatch
  arm_mat_add_f32(addr a.instance, addr b.instance, addr dst.instance)

proc sub*[R, C: static int](dst: var Matrix[R, C], a, b: Matrix[R, C]): ArmStatus {.inline.} =
  ## Subtract two matrices: dst = a - b
  ##
  ## **Returns:** ArmStatus indicating success or error
  ## - ARM_MATH_SUCCESS: Operation completed successfully
  ## - ARM_MATH_SIZE_MISMATCH: Dimension mismatch
  arm_mat_sub_f32(addr a.instance, addr b.instance, addr dst.instance)

proc mult*[R1, C1, C2: static int](dst: var Matrix[R1, C2], a: Matrix[R1, C1], b: Matrix[C1, C2]): ArmStatus {.inline.} =
  ## Multiply two matrices: dst = a * b
  ##
  ## **Returns:** ArmStatus indicating success or error
  ## - ARM_MATH_SUCCESS: Operation completed successfully
  ## - ARM_MATH_SIZE_MISMATCH: Dimension mismatch
  arm_mat_mult_f32(addr a.instance, addr b.instance, addr dst.instance)

proc inverse*[N: static int](dst: var Matrix[N, N], src: Matrix[N, N]): ArmStatus {.inline.} =
  ## Compute matrix inverse: dst = src^(-1)
  ##
  ## **Returns:** ArmStatus indicating success or error
  ## - ARM_MATH_SUCCESS: Operation completed successfully
  ## - ARM_MATH_SINGULAR: Matrix is singular and cannot be inverted
  arm_mat_inverse_f32(addr src.instance, addr dst.instance)

proc transpose*[R, C: static int](dst: var Matrix[C, R], src: Matrix[R, C]): ArmStatus {.inline.} =
  ## Transpose a matrix: dst = src^T
  ##
  ## **Returns:** ArmStatus indicating success or error
  ## - ARM_MATH_SUCCESS: Operation completed successfully
  arm_mat_trans_f32(addr src.instance, addr dst.instance)
