# Package

version       = "1.0.0"
author        = "Nimphea Contributors"
description   = "Nimphea - Elegant Nim bindings for libDaisy Hardware Abstraction Library (Daisy Audio Platform: Seed, Patch, Pod, Field, Petal, Versio)"
license       = "MIT"
srcDir        = "."
skipDirs      = @["examples", "examples_nim", "tests", "docs", "Drivers", "Middlewares", "core", "cmake", "ci", "resources"]
skipFiles     = @[]

# Dependencies

requires "nim >= 2.0.0"
requires "unittest2 >= 0.2.0"

# Build configuration
import os, strutils, strformat, algorithm

const
  libDaisyDir = "libDaisy"
  buildDir = "build"
  systemFilesDir = libDaisyDir / "core"
  
  # ARM toolchain
  armPrefix = "arm-none-eabi-"
  armCpu = "cortex-m7"
  armFpu = "fpv5-d16"
  
  # MCU architecture flags
  archFlags = "-mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard"
  
  # MCU defines
  defines = "-DSTM32H750xx -DCORE_CM7 -DARM_MATH_CM7 -DFILEIO_ENABLE_FATFS_READER"

proc getIncludePaths(): string =
  ## Generate all required include paths for libDaisy
  let paths = [
    libDaisyDir / "src",
    libDaisyDir / "src/sys",
    libDaisyDir / "src/usbd",
    libDaisyDir / "src/usbh",
    libDaisyDir / "core",
    libDaisyDir / "Drivers/CMSIS_5/CMSIS/Core/Include",
    libDaisyDir / "Drivers/CMSIS-Device/ST/STM32H7xx/Include",
    libDaisyDir / "Drivers/STM32H7xx_HAL_Driver/Inc",
    libDaisyDir / "Drivers/STM32H7xx_HAL_Driver/Inc/Legacy",
    libDaisyDir / "Middlewares/ST/STM32_USB_Host_Library/Core/Inc",
    libDaisyDir / "Middlewares/ST/STM32_USB_Device_Library/Core/Inc",
    libDaisyDir / "Middlewares/Third_Party/FatFs/src"
  ]
  result = ""
  for p in paths:
    result.add(" -I" & p)

proc buildCSource(srcFile, objFile: string) =
  ## Compile a C source file
  let cc = armPrefix & "gcc"
  let cflags = archFlags & " " & defines & getIncludePaths() & " -Os -Wall -fdata-sections -ffunction-sections"
  exec fmt"{cc} -c {cflags} {srcFile} -o {objFile}"

task init_libdaisy, "Initialize and build libDaisy dependency":
  ## One-time setup: clone and build libDaisy C++ library
  ##
  ## This task:
  ## - Initializes git submodules (including libDaisy)
  ## - Builds libDaisy C++ library from source
  ##
  ## Run this ONCE after cloning the repository.
  ## Required before building any examples.
  ##
  ## Usage: nimble init_libdaisy
  
  echo "=== Nimphea: libDaisy Initialization ==="
  echo ""
  
  if not dirExists(libDaisyDir):
    echo "Initializing git submodules..."
    exec "git submodule update --init --recursive"
  else:
    echo "✓ libDaisy submodule found"
  
  echo ""
  echo "Building libDaisy C++ library..."
  echo "This may take several minutes..."
  withDir libDaisyDir:
    exec "make"
  
  echo ""
  echo "✓ libDaisy initialization complete!"
  echo ""
  echo "Next steps:"
  echo "  nimble make blink       # Build an example"
  echo "  nimble test             # Quick syntax check of all examples"
  echo "  nimble flash blink      # Flash to hardware"

proc getTargetFromArgs(taskName: string): string =
  ## Extract target name from command line arguments
  var foundTaskName = false
  for i in 1..paramCount():
    let param = paramStr(i)
    if foundTaskName and not param.startsWith("-"):
      var target = param
      # Remove examples/ prefix if present
      if target.startsWith("examples/"):
        target = target[9..^1]
      # Remove .nim extension if present
      if target.endsWith(".nim"):
        target = target[0..^5]
      return target
    if param == taskName:
      foundTaskName = true
  return "blink"  # default

proc buildExample(target: string) =
  ## Build a single example for ARM Cortex-M7
  let srcFile = "examples" / target & ".nim"
  
  if not fileExists(srcFile):
    echo fmt"Error: Example not found: {srcFile}"
    echo ""
    echo "Available examples:"
    let examplesOutput = gorgeEx("ls examples/*.nim")
    if examplesOutput.exitCode == 0:
      for line in examplesOutput.output.splitLines():
        if line.len > 0:
          let name = line.strip().split("/")[^1].replace(".nim", "")
          echo "  - " & name
    quit(1)
  
  echo fmt"=== Building {target} for ARM Cortex-M7 ==="
  echo ""
  
  # Create build directory
  mkDir(buildDir)
  
  # Compile C dependencies
  echo "Compiling C dependencies..."
  
  # FatFS unicode support
  let ccsbcsC = libDaisyDir / "Middlewares/Third_Party/FatFs/src/option/ccsbcs.c"
  let ccsbcsO = buildDir / "ccsbcs.o"
  if fileExists(ccsbcsC):
    buildCSource(ccsbcsC, ccsbcsO)
  
  # Prepare Nim compiler flags
  let includes = getIncludePaths()
  let cflags = archFlags & " " & defines & includes & " -Os -Wall -fdata-sections -ffunction-sections"
  
  let ldflags = archFlags & " " &
                "--specs=nano.specs" & " " &
                "--specs=nosys.specs" & " " &
                "-L" & libDaisyDir / "build" & " " &
                "-T" & systemFilesDir / "STM32H750IB_flash.lds" & " " &
                "-Wl,-Map=" & buildDir / target & ".map" & " " &
                "-Wl,--gc-sections" & " " &
                "-Wl,--print-memory-usage" & " " &
                "-ldaisy"
  
  let elfFile = buildDir / target & ".elf"
  let binFile = buildDir / target & ".bin"
  
  echo "Compiling Nim source..."
  
  # Build Nim compiler command
  var nimCmd = "nim cpp"
  nimCmd.add(" --clearNimblePath")
  nimCmd.add(" --nimblePath:off")
  nimCmd.add(" --skipUserCfg")
  nimCmd.add(" --skipParentCfg")
  nimCmd.add(" --path:src")  # Add src to import path so modules can find each other
  nimCmd.add(" --cpu:arm")
  nimCmd.add(" --os:standalone")
  nimCmd.add(" --mm:arc")
  nimCmd.add(" --opt:size")
  nimCmd.add(" --threads:off")
  nimCmd.add(" --exceptions:goto")
  nimCmd.add(" --panics:on")
  nimCmd.add(" --define:useMalloc")
  nimCmd.add(" --define:noSignalHandler")
  nimCmd.add(fmt" --cc:gcc")
  nimCmd.add(fmt" --gcc.exe:{armPrefix}gcc")
  nimCmd.add(fmt" --gcc.linkerexe:{armPrefix}g++")
  nimCmd.add(fmt" --gcc.cpp.exe:{armPrefix}g++")
  nimCmd.add(fmt" --gcc.cpp.linkerexe:{armPrefix}g++")
  nimCmd.add(fmt" --nimcache:{buildDir}/.nimcache")
  
  # Add C and linker flags
  for flag in cflags.split(" "):
    if flag.len > 0:
      nimCmd.add(fmt" --passC:{flag.quoteShell}")
  for flag in ldflags.split(" "):
    if flag.len > 0:
      nimCmd.add(fmt" --passL:{flag.quoteShell}")
  
  # Add C objects
  if fileExists(ccsbcsO):
    nimCmd.add(fmt" --passL:{ccsbcsO}")
  
  nimCmd.add(" --nimMainPrefix:nim_")
  nimCmd.add(fmt" -o:{elfFile}")
  nimCmd.add(fmt" {srcFile}")
  
  exec nimCmd
  
  # Convert ELF to binary
  echo ""
  echo "Creating binary file..."
  exec fmt"{armPrefix}objcopy -O binary {elfFile} {binFile}"
  
  # Show size
  echo ""
  exec fmt"{armPrefix}size {elfFile}"
  
  echo ""
  echo fmt"✓ Build complete: {binFile}"

task make, "Build example for ARM Cortex-M7":
  ## Build a Nim example for Daisy hardware
  ##
  ## Usage: nimble make <example_name>
  ## Example: nimble make blink
  ##
  ## The built binary will be in build/<example_name>.bin
  let target = getTargetFromArgs("make")
  buildExample(target)

task test, "Quick syntax check of all examples":
  ## Quick syntax validation of all examples using 'nim check'
  ##
  ## This is FAST (~2 seconds) but only checks:
  ##   - Syntax errors
  ##   - Type checking
  ##   - Import resolution
  ##
  ## It does NOT check:
  ##   - Linking with libDaisy
  ##   - ARM cross-compilation
  ##   - Missing symbols
  ##
  ## For full validation, use: nimble test_build
  
  echo "=== Quick Syntax Check (all examples) ==="
  echo "=" .repeat(60)
  
  # Get list of examples using shell command (NimScript compatible)
  let examplesOutput = gorgeEx("ls examples/*.nim")
  if examplesOutput.exitCode != 0:
    echo "Error: Could not list examples"
    quit(1)
  
  var passed = 0
  var failed = 0
  var failedExamples: seq[string] = @[]
  
  for line in examplesOutput.output.splitLines():
    if line.len == 0:
      continue
    
    let exampleFile = line.strip()
    let name = exampleFile.split("/")[^1].replace(".nim", "")
    
    echo fmt"Checking {name:30s} ... "
    
    # Try to compile (syntax check only, no linking)
    # Add --path:src so modules can find each other
    let result = gorgeEx(fmt"nim check --path:src --hints:off {exampleFile}")
    
    if result.exitCode == 0:
      echo "  ✓ PASS"
      inc passed
    else:
      echo "  ✗ FAIL"
      inc failed
      failedExamples.add(name)
  
  echo "=" .repeat(60)
  echo "SUMMARY:"
  echo fmt"  Passed: {passed}"
  echo fmt"  Failed: {failed}"
  echo "=" .repeat(60)
  
  if failed > 0:
    echo ""
    echo "Failed examples:"
    for ex in failedExamples:
      echo fmt"  - {ex}"
    echo ""
    quit(1)
  
  echo ""
  echo "✓ All examples passed syntax check!"
  echo ""
  echo "Note: This only checks syntax. For full build validation:"
  echo "  nimble test_build    # Compile all examples with ARM toolchain"

task test_build, "Full compilation test of all examples":
  ## Build ALL examples with ARM cross-compilation and linking
  ##
  ## This is SLOW but validates:
  ##   - ARM cross-compilation works
  ##   - Linking with libDaisy succeeds
  ##   - All symbols resolve correctly
  ##   - Binary sizes are reasonable
  ##
  ## Requires:
  ##   - ARM toolchain installed (arm-none-eabi-gcc)
  ##   - libDaisy built (run 'nimble init_libdaisy' first)
  ##
  ## Use this before releases or when changing core build system.
  ## For quick feedback during development, use: nimble test
  
  echo "=== Full Build Test (all examples) ==="
  echo "=" .repeat(60)
  
  # Get list of examples
  let examplesOutput = gorgeEx("ls examples/*.nim")
  if examplesOutput.exitCode != 0:
    echo "Error: Could not list examples"
    quit(1)
  
  var examples: seq[string] = @[]
  for line in examplesOutput.output.splitLines():
    if line.len > 0:
      let name = line.strip().split("/")[^1].replace(".nim", "")
      examples.add(name)
  
  var passed = 0
  var failed = 0
  var failedExamples: seq[string] = @[]
  
  let startTime = gorgeEx("date +%s")
  
  for name in examples:
    echo ""
    echo fmt"[{passed + failed + 1}/{examples.len}] Building {name}..."
    echo "-" .repeat(60)
    
    # Build the example (use the buildExample proc)
    # We need to invoke it differently since we're in a task
    let buildResult = gorgeEx(fmt"nimble make {name}")
    
    if buildResult.exitCode == 0:
      echo fmt"  ✓ {name} - BUILD PASSED"
      inc passed
    else:
      echo fmt"  ✗ {name} - BUILD FAILED"
      echo "Error output:"
      echo buildResult.output
      inc failed
      failedExamples.add(name)
  
  let endTime = gorgeEx("date +%s")
  let duration = parseInt(endTime.output.strip()) - parseInt(startTime.output.strip())
  let minutes = duration div 60
  let seconds = duration mod 60
  
  echo ""
  echo "=" .repeat(60)
  echo "FULL BUILD TEST SUMMARY:"
  echo fmt"  Passed: {passed}/{examples.len}"
  echo fmt"  Failed: {failed}/{examples.len}"
  echo fmt"  Duration: {minutes}m {seconds}s"
  echo "=" .repeat(60)
  
  if failed > 0:
    echo ""
    echo "Failed examples:"
    for ex in failedExamples:
      echo fmt"  - {ex}"
    echo ""
    echo "To debug a specific failure:"
    echo "  nimble make <example_name>"
    quit(1)
  
  echo ""
  echo "✓ All examples built successfully with ARM toolchain!"
  echo ""
  echo "This confirms:"
  echo "  - ARM cross-compilation works"
  echo "  - All examples link with libDaisy"
  echo "  - No missing symbols or linker errors"

task flash, "Flash binary to connected Daisy via DFU":
  ## Flash the built binary to Daisy via DFU (USB bootloader)
  ##
  ## Usage: nimble flash <example_name>
  ## Requires: dfu-util installed and Daisy in bootloader mode
  ##
  ## To enter bootloader mode:
  ##   1. Hold BOOT button
  ##   2. Press RESET button
  ##   3. Release BOOT button
  
  let target = getTargetFromArgs("flash")
  let binFile = buildDir / target & ".bin"
  
  if not fileExists(binFile):
    echo fmt"Error: Binary not found: {binFile}"
    echo fmt"Run 'nimble make {target}' first"
    quit(1)
  
  echo fmt"=== Flashing {target} to Daisy via DFU ==="
  echo ""
  echo "Make sure Daisy is in bootloader mode:"
  echo "  1. Hold BOOT button"
  echo "  2. Press RESET button  "
  echo "  3. Release BOOT button"
  echo ""
  
  let cmd = fmt"dfu-util -a 0 -s 0x08000000:leave -D {binFile}"
  let (output, exitCode) = gorgeEx(cmd)
  
  echo output
  
  if exitCode != 0:
    echo ""
    echo "✗ Flash failed!"
    echo ""
    echo "Common issues:"
    echo "  - Daisy not in bootloader mode (hold BOOT, press RESET)"
    echo "  - USB cable not connected"
    echo "  - dfu-util not installed (brew install dfu-util)"
    echo "  - Daisy not recognized by OS (check System Information)"
    quit(1)
  
  echo ""
  echo "✓ Flash complete!"

task stlink, "Flash binary to connected Daisy via ST-Link":
  ## Flash the built binary to Daisy via ST-Link/OpenOCD
  ##
  ## Usage: nimble stlink <example_name>
  ## Requires: openocd installed and ST-Link connected to Daisy
  ##
  ## ST-Link Connection:
  ##   - SWDIO -> Daisy SWDIO
  ##   - SWCLK -> Daisy SWCLK
  ##   - GND   -> Daisy GND
  ##   - 3V3   -> Daisy 3V3 (optional, for power)
  ##
  ## This method is faster than DFU and doesn't require bootloader mode.
  
  let target = getTargetFromArgs("stlink")
  let elfFile = buildDir / target & ".elf"
  
  if not fileExists(elfFile):
    echo fmt"Error: ELF file not found: {elfFile}"
    echo fmt"Run 'nimble make {target}' first"
    quit(1)
  
  echo fmt"=== Flashing {target} to Daisy via ST-Link ==="
  echo ""
  
  # Use OpenOCD with ST-Link interface
  let cmd = "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg -c \"program " & elfFile & " verify reset exit\""
  let (output, exitCode) = gorgeEx(cmd)
  
  echo output
  
  if exitCode != 0:
    echo ""
    echo "✗ Flash failed!"
    echo ""
    echo "Common issues:"
    echo "  - ST-Link not connected to Daisy"
    echo "  - Wrong wiring (check SWDIO, SWCLK, GND connections)"
    echo "  - OpenOCD not installed (brew install openocd)"
    echo "  - USB cable issue or ST-Link driver problem"
    echo "  - Power issue (ensure Daisy has power)"
    quit(1)
  
  echo ""
  echo "✓ Flash complete!"

when defined(nimbleClean):
  task clean, "Remove build artifacts":
    ## Clean all generated files
    ##
    ## Removes the build/ directory and all artifacts.

    echo "Cleaning build artifacts..."
    
    exec "/bin/rm -rf build"
    echo "✓ Removed build/"

task clear, "Remove all build artifacts":
  ## Fully clean all generated files including build/ directory.
  ##
  ## This is an alternative to 'nimble clean' which only removes
  ## nimcache/. Use this to remove build artifacts and test outputs.

  echo "Cleaning build artifacts..."
  exec "/bin/rm -rf build"
  echo "✓ Removed build/"
  
  # Clean up unit test artifacts
  if dirExists("tests/.nimcache"):
    echo "Cleaning unit test cache..."
    exec "/bin/rm -rf tests/.nimcache"
    echo "✓ Removed tests/.nimcache/"
  
  # Remove compiled test binary if it exists
  if fileExists("tests/all_tests"):
    echo "Cleaning unit test binary..."
    exec "/bin/rm -f tests/all_tests"
    echo "✓ Removed tests/all_tests"
  
  # Remove debug symbols for test binary if they exist
  if dirExists("tests/all_tests.dSYM"):
    echo "Cleaning unit test debug symbols..."
    exec "/bin/rm -rf tests/all_tests.dSYM"
    echo "✓ Removed tests/all_tests.dSYM"

task docs, "Generate API documentation":
  ## Generate HTML documentation for all modules with comprehensive index
  ##
  ## Output: docs/api/ directory with HTML files and theindex.html
  ##
  ## Uses a two-stage process:
  ##   1. Generate .idx files for all modules
  ##   2. Generate HTML docs and build unified index
  
  echo "=== Generating API documentation ==="
  echo ""
  
  # Clean up any old files
  echo "Cleaning old documentation files..."
  discard gorgeEx("rm -rf docs/api 2>/dev/null || true")
  mkDir("docs/api")
  
  # GitHub repository URL for source links
  let gitUrl = "https://github.com/Brokezawa/nimphea"
  let gitCommit = "main"
  
  # Get all Nim modules
  let modulesOutput = gorgeEx("find src -name '*.nim' -type f")
  if modulesOutput.exitCode != 0:
    echo "Error: Could not list modules"
    quit(1)
  
  var allModules: seq[string] = @[]
  for line in modulesOutput.output.splitLines():
    if line.len > 0 and line.endsWith(".nim"):
      allModules.add(line.strip())
  
  echo fmt"Found {allModules.len} modules to document"
  echo ""
  
  # Stage 1: Generate .idx files for all modules
  echo "Stage 1: Generating index files..."
  var idxCount = 0
  for modulePath in allModules:
    let moduleName = modulePath.splitFile.name
    
    var cmd = "nim doc --index:only"
    cmd.add(" --backend:cpp")
    cmd.add(" --doccmd:skip")
    cmd.add(" --path:src")
    cmd.add(fmt" --git.url:{gitUrl}")
    cmd.add(fmt" --git.commit:{gitCommit}")
    cmd.add(" --hints:off")
    cmd.add(" --warnings:off")
    cmd.add(" --outdir:docs/api")
    cmd.add(fmt" {modulePath}")
    
    let (output, exitCode) = gorgeEx(cmd)
    if exitCode == 0:
      inc idxCount
    else:
      echo fmt"  Warning: Failed to generate index for {moduleName}"
  
  echo fmt"  Generated {idxCount} index files"
  echo ""
  
  # Stage 2: Generate HTML documentation
  # Note: --index:on on first module automatically copies dochack.js and nimdoc.out.css
  echo "Stage 2: Generating HTML documentation..."
  var htmlCount = 0
  for modulePath in allModules:
    let moduleName = modulePath.splitFile.name
    
    var cmd = "nim doc"
    # Add --index:on to first module to copy support files (dochack.js, nimdoc.out.css)
    if htmlCount == 0:
      cmd.add(" --index:on")
    cmd.add(" --backend:cpp")
    cmd.add(" --doccmd:skip")
    cmd.add(" --path:src")
    cmd.add(fmt" --git.url:{gitUrl}")
    cmd.add(fmt" --git.commit:{gitCommit}")
    cmd.add(" --hints:off")
    cmd.add(" --warnings:off")
    cmd.add(" --outdir:docs/api")
    cmd.add(fmt" {modulePath}")
    
    let (output, exitCode) = gorgeEx(cmd)
    if exitCode == 0:
      inc htmlCount
    else:
      echo fmt"  Warning: Failed to generate docs for {moduleName}"
  
  echo fmt"  Generated {htmlCount} HTML files"
  echo ""
  
  # Stage 3: Build comprehensive index
  echo "Stage 3: Building comprehensive index..."
  let buildIdxCmd = "nim buildIndex -o:docs/api/theindex.html docs/api"
  let (idxOutput, idxExitCode) = gorgeEx(buildIdxCmd)
  
  if idxExitCode == 0:
    echo "  ✓ Index built successfully"
  else:
    echo "  Warning: Failed to build index"
    echo idxOutput
  
  echo ""
  echo "✓ Documentation generated successfully"
  echo ""
  echo "📂 Output:"
  echo "  - docs/api/theindex.html (comprehensive index with search)"
  echo fmt"  - docs/api/*.html ({htmlCount} module documentation files)"
  echo "  - docs/api/dochack.js (search functionality)"
  echo "  - docs/api/nimdoc.out.css (styling)"
  echo "  - All modules include 'See source' links to GitHub"
  echo ""
  echo "🌐 To view locally:"
  echo "   python3 -m http.server 7029 --directory docs/api"
  echo "   then open: http://localhost:7029/theindex.html"
  echo "🔍 Search works best via HTTP server (not file://)"
  echo "📖 For structured guide: see docs/API_REFERENCE.md"

task test_unit, "Run unit tests on host computer":
  ## Run unit tests for Nimphea wrapper logic
  ##
  ## These tests run on your development machine (no hardware required).
  ## Tests cover pure logic modules: data structures, utilities, calculations.
  ##
  ## Usage: nimble test_unit
  ##
  ## Test categories:
  ##   - Data structures (FIFO, Stack, RingBuffer, FixedStr)
  ##   - Utilities (MappedValue, Color, VoctCalibration)
  ##   - File formats (WAV parsing, headers)
  ##
  ## Note: Hardware-dependent modules (I2C, SPI, ADC, etc.) are tested
  ## via the 44 integration test examples (see 'nimble test').
  
  echo "=== Running Nimphea Unit Tests ==="
  echo ""
  
  if not dirExists("tests"):
    echo "Error: tests/ directory not found"
    echo "Unit tests have not been set up yet."
    quit(1)
  
  # Run all unit tests
  exec "nim c -r tests/all_tests.nim"
  
  echo ""
  echo "✓ All unit tests passed!"
