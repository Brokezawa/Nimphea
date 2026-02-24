# Package

version       = "1.1.0"
author        = "Brokezawa"
description   = "Nimphea - Elegant Nim bindings for libDaisy Hardware Abstraction Library (Daisy Audio Platform: Seed, Patch, Pod, Field, Petal, Versio)"
license       = "MIT"
srcDir        = "src"
# Ensure Nim sources are included when the package is installed so
# downstream examples can `import nimphea` after `nimble install`.
installDirs   = @["src", "libDaisy"]
installFiles  = @[]
skipDirs      = @["tests", "docs", "nimphea-examples", "templates", "cmake", "ci", "resources"]
skipFiles     = @[]

# Dependencies

requires "nim >= 2.0.0"

# Build configuration
import os, strutils, strformat, algorithm

proc programExists(cmd: string): bool =
  ## Cross-platform check for an executable in PATH. Try `which` then `where`.
  let w = gorge("which " & cmd).strip()
  if w.len > 0: return true
  let w2 = gorge("where " & cmd).strip()
  if w2.len > 0: return true
  return false

after install:
  ## Post-install: print instructions and prepare for manual init_libdaisy
  ## We avoid forcing a network build in restricted environments. The user
  ## can run `nimble init_libdaisy` in the printed path to finish the one-time
  ## setup. This keeps `nimble install` robust across platforms.
  echo "--- Post-install: nimphea installed ---"
  let nimpheaPath = getCurrentDir()
  echo fmt"Nimphea package path: {nimpheaPath}"
  echo "To initialize libDaisy (one-time), run the following inside that path:"
  echo fmt"  cd {nimpheaPath}"
  echo "  nimble init_libdaisy"
  echo "This will clone libDaisy submodules and build the C++ library (requires ARM toolchain)."
  echo "If you want automatic initialization during install, set the environment variable NIMPHEA_AUTO_INIT=1 and re-run nimble install."
  # If user asked for auto init via env var, attempt it (best-effort)
  let envAuto = getEnv("NIMPHEA_AUTO_INIT")
  if envAuto == "1" or envAuto == "true" or envAuto == "on":
    echo "Detected NIMPHEA_AUTO_INIT; attempting automatic libDaisy initialization (best-effort)"
    # Check for git and make availability
    let hasGit = programExists("git")
    let hasMake = programExists("make")
    if not hasGit:
      echo "Warning: 'git' not found in PATH; cannot clone libDaisy. Install git and run 'nimble init_libdaisy' manually."
    elif not hasMake:
      echo "Warning: 'make' not found in PATH; cannot build libDaisy. Install make and run 'nimble init_libdaisy' manually."
    else:
      # Attempt to initialize (best-effort). Keep errors non-fatal.
      try:
        if not dirExists("libDaisy"):
          echo "Cloning libDaisy (recursive)..."
          exec "git clone --recursive https://github.com/electro-smith/libDaisy.git"
        else:
          if not dirExists(joinPath("libDaisy", ".git")):
            echo "libDaisy directory exists but has no .git; re-cloning to initialize submodules"
            exec "rm -rf libDaisy"
            exec "git clone --recursive https://github.com/electro-smith/libDaisy.git"
        # Initialize submodules
        withDir "libDaisy":
          echo "Updating libDaisy submodules..."
          exec "git submodule update --init --recursive"
          # Build libDaisy
          if not fileExists("build/libdaisy.a"):
            echo "Building libDaisy (this may take a few minutes)..."
            exec "make"
      except OSError as e:
        echo fmt"Automatic libDaisy init failed: {e}" 
        echo "Please run 'nimble init_libdaisy' inside the nimphea package directory."

const
  libDaisyDir = "libDaisy"
  buildDir = "build"

task init_libdaisy, "Initialize and build libDaisy dependency":
  ## One-time setup: clone and build libDaisy C++ library
  
  echo "=== Nimphea: libDaisy Initialization ==="
  echo ""
  
  if not dirExists(libDaisyDir):
    echo "Cloning libDaisy (recursive)..."
    exec "git clone --recursive https://github.com/electro-smith/libDaisy.git"
  else:
    echo "libDaisy directory found"

  echo ""
  echo "Building libDaisy C++ library..."
  echo "This may take several minutes..."
  # Verify required tools
  if not programExists("git"):
    echo "Error: 'git' not found in PATH. Install git and retry."
    quit(1)
  # Recommend toolchain version
  echo "Note: Recommended ARM toolchain: GCC Arm Embedded v10.3-2021.10 or later"
  echo "See: https://daisy.audio/tutorials/cpp-dev-env/"
  if not programExists("arm-none-eabi-gcc"):
    echo "Warning: 'arm-none-eabi-gcc' not found in PATH. Building libDaisy may fail."
  withDir libDaisyDir:
    exec "git submodule update --init --recursive"
    if not fileExists("build/libdaisy.a"):
      exec "make"
  
  echo ""
  echo "libDaisy initialization complete!"

task clear, "Remove all build artifacts":
  ## Fully clean all generated files including build/ directory.

  echo "Cleaning build artifacts..."
  if dirExists(buildDir):
    rmDir(buildDir)
  
  # Clean up unit test artifacts
  if dirExists("tests/.nimcache"):
    rmDir("tests/.nimcache")
  
  # Remove compiled test binary if it exists
  if fileExists("tests/all_tests"):
    rmFile("tests/all_tests")
  
  if dirExists("tests/all_tests.dSYM"):
    rmDir("tests/all_tests.dSYM")

task docs, "Generate API documentation":
  ## Generate HTML documentation for all modules with comprehensive index
  
  echo "=== Generating API documentation ==="
  echo ""
  
  # Clean up any old files
  echo "Cleaning old documentation files..."
  if dirExists("docs/api"):
    rmDir("docs/api")
  mkDir("docs/api")
  
  # GitHub repository URL for source links
  let gitUrl = "https://github.com/Brokezawa/nimphea"
  let gitCommit = "main"
  
  # Get all Nim modules
  let modulesOutput = gorgeEx("find src/nimphea -name '*.nim' -type f")
  if modulesOutput.exitCode != 0:
    echo "Error: Could not list modules"
    quit(1)
  
  var allModules: seq[string] = @["src/nimphea.nim"]
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
  echo "Stage 2: Generating HTML documentation..."
  var htmlCount = 0
  for modulePath in allModules:
    let moduleName = modulePath.splitFile.name
    
    var cmd = "nim doc"
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
    echo "Index built successfully"
  else:
    echo "Warning: Failed to build index"
    echo idxOutput
  
  echo ""
  echo "Documentation generated successfully"

task test_unit, "Run unit tests on host computer":
  ## Run unit tests for Nimphea wrapper logic
  
  echo "=== Running Nimphea Unit Tests ==="
  echo ""
  
  if not dirExists("tests"):
    echo "Error: tests/ directory not found"
    quit(1)
  
  # Run all unit tests
  exec "nim c -r tests/all_tests.nim"
  
  echo ""
  echo "All unit tests passed!"
