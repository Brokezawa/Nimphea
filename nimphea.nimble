# Package

version       = "1.1.0"
author        = "Brokezawa"
description   = "Nimphea - Elegant Nim bindings for libDaisy Hardware Abstraction Library (Daisy Audio Platform: Seed, Patch, Pod, Field, Petal, Versio)"
license       = "MIT"
srcDir        = "src"
installDirs   = @[]
installFiles  = @[]
skipDirs      = @["tests", "docs", "nimphea-examples", "templates", "cmake", "ci", "resources", ".github", "libDaisy"]
skipFiles     = @[]

# Dependencies

requires "nim >= 2.0.0"

dev:
  requires "unittest2 >= 0.2.0"

# Build configuration
import os, strutils, strformat, algorithm

after install:
  let libDaisyUrl = "https://github.com/electro-smith/libDaisy.git"

  if not dirExists("libDaisy"):
    echo "--- Post-install: Cloning libDaisy ---"
    exec "git clone --recurse-submodules " & libDaisyUrl & " libDaisy"
  else:
    echo "--- Post-install: libDaisy already present ---"

  if fileExists("libDaisy/Makefile"):
    echo "--- Post-install: Building libDaisy ---"
    withDir "libDaisy":
      exec "make"
    echo "--- libDaisy build complete ---"
  else:
    echo "Warning: libDaisy/Makefile not found. Build skipped."

const
  libDaisyDir = "libDaisy"
  buildDir = "build"

task init_libdaisy, "Initialize and build libDaisy dependency":
  ## One-time setup: clone and build libDaisy C++ library
  let libDaisyUrl = "https://github.com/electro-smith/libDaisy.git"

  echo "=== Nimphea: libDaisy Initialization ==="
  echo ""

  if not dirExists(libDaisyDir):
    if dirExists(".git"):
      echo "Initializing git submodules..."
      exec "git submodule update --init --recursive"
    else:
      echo "Cloning libDaisy (not a git repo, using direct clone)..."
      exec "git clone --recurse-submodules " & libDaisyUrl & " " & libDaisyDir
  else:
    echo "libDaisy already present"

  echo ""
  echo "Building libDaisy C++ library..."
  echo "This may take several minutes..."
  withDir libDaisyDir:
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

task test, "Run all tests":
  ## Master test task - runs unit tests.
  exec "nimble test_unit"

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
