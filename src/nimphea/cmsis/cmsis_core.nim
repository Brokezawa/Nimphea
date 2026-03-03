## CMSIS Core Macro System
##
## This module provides the infrastructure for including CMSIS-DSP headers
## and setting up the C++ environment.
##
## **Implementation Note:**
## The `useCmsisModules` macro uses raw `{.emit.}` pragmas to inject C++ `#include`
## directives. This approach is necessary because:
##
## 1. CMSIS-DSP headers must be available at C++ compile time before any
##    function declarations are processed by the Nim C++ backend
## 2. Nim's standard `{.header.}` pragma cannot be used directly on `importc`
##    procedures that reference CMSIS types/functions
## 3. The `emit` pragma allows precise control over the order and placement of
##    includes in the generated C++ code
##
## Per AGENTS.md guidelines, raw `emit` is justified here because:
## - This is infrastructure code (not application logic)
## - The mechanism is well-documented and its purpose is clear
## - Standard alternatives (header pragma) don't work for CMSIS integration

import macros

# ============================================================================
# C++ Header Includes for CMSIS
# ============================================================================

proc getCmsisHeaders*(moduleName: string): string =
  ## Returns the C++ header includes needed for a specific CMSIS module
  case moduleName
  of "dsp_basic": "#include \"dsp/basic_math_functions.h\"\n"
  of "dsp_filtering": "#include \"dsp/filtering_functions.h\"\n"
  of "dsp_transforms": "#include \"dsp/transform_functions.h\"\n"
  of "dsp_statistics": "#include \"dsp/statistics_functions.h\"\n"
  of "dsp_fastmath": "#include \"dsp/fast_math_functions.h\"\n"
  of "dsp_support": "#include \"dsp/support_functions.h\"\n"
  of "dsp_complex": "#include \"dsp/complex_math_functions.h\"\n"
  of "dsp_matrix": "#include \"dsp/matrix_functions.h\"\n"
  of "dsp_controller": "#include \"dsp/controller_functions.h\"\n"
  of "dsp_interpolation": "#include \"dsp/interpolation_functions.h\"\n"
  of "dsp_distance": "#include \"dsp/distance_functions.h\"\n"
  of "dsp_ml": "#include \"dsp/svm_functions.h\"\n#include \"dsp/bayes_functions.h\"\n"
  of "dsp_quaternion": "#include \"dsp/quaternion_math_functions.h\"\n"
  else: ""

macro useCmsisModules*(modules: varargs[untyped]): untyped =
  ## Selective inclusion of CMSIS-DSP modules.
  ##
  ## Injects the required #include statements.
  
  result = newStmtList()
  
  var headersStr = ""
  headersStr.add("#include \"arm_math.h\"\n")
  
  for module in modules:
    headersStr.add(getCmsisHeaders($module))
  
  let includesEmit = newNimNode(nnkPragma)
  includesEmit.add(
    newNimNode(nnkExprColonExpr).add(
      newIdentNode("emit"),
      newLit("/*INCLUDESECTION*/\n" & headersStr)
    )
  )
  result.add(includesEmit)
