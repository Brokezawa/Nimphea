# Package
version       = "0.1.0"
author        = "Nimphea Contributors"
description   = "Nimphea Example: blink"
license       = "MIT"
srcDir        = "src"
bin           = @["blink"]

# Dependencies
requires "nim >= 2.0.0"
requires "nimphea >= 1.1.0"
# Ensure panicoverride from nimphea is used when building examples installed via nimble

# Build configuration
import os, strutils, strformat

task make, "Build for ARM Cortex-M7":
  ## Simple, cross-platform example build that expects nimphea to be installed
  ## via nimble and libDaisy to be initialized (see nimphea.nimble after-install
  ## instructions). This task works on macOS/Linux/Windows (MSYS/WSL) as long
  ## as the ARM toolchain is available in PATH.

  var pkgPath = ""
  let rawPaths = gorge("nimble path nimphea")
  for ln in rawPaths.splitLines():
    let p = ln.strip()
    if p.len > 0 and dirExists(p):
      pkgPath = p
      break
  if pkgPath == "" and dirExists("../nimphea"):
    var p = "../nimphea"
    normalizePath(p)
    pkgPath = p
  if pkgPath == "":
    echo "Error: nimphea package not found. Run 'nimble install nimphea' and 'nimble init_libdaisy' as described in the nimphea README."
    quit(1)
  echo fmt"Using nimphea path: {pkgPath}"

  var nimCmd = "nim cpp"
  # Force the gcc backend and point to ARM cross-toolchain
  nimCmd.add(" --cc:gcc")
  nimCmd.add(" --gcc.exe:arm-none-eabi-gcc")
  nimCmd.add(" --gcc.cpp.exe:arm-none-eabi-g++")
  nimCmd.add(" --gcc.linkerexe:arm-none-eabi-g++")
  nimCmd.add(" --cpu:arm --os:standalone --mm:arc --opt:size --exceptions:goto")
  nimCmd.add(" --define:useMalloc --define:noSignalHandler")

  # Ensure example src and nimphea src are on the search path
  nimCmd.add(" --path:src")
  nimCmd.add(" --path:" & pkgPath & "/src")

  # Link with libDaisy (must be built by nimble init_libdaisy)
  nimCmd.add(" --passL:-L" & pkgPath & "/libDaisy/build")
  nimCmd.add(" --passL:-ldaisy")

  # Include libDaisy headers
  nimCmd.add(" --passC:-I" & pkgPath & "/libDaisy/src")
  nimCmd.add(" --passC:-I" & pkgPath & "/libDaisy")
  nimCmd.add(" --passC:-DSTM32H750xx")
  nimCmd.add(" --passC:-DFILEIO_ENABLE_FATFS_READER")

  # Ensure panicoverride in this example is used (it's in src/)
  let target = "blink"
  mkDir("build")
  nimCmd.add(" -o:build/" & target & ".elf")
  nimCmd.add(" src/" & target & ".nim")

  echo "Running: " & nimCmd
  exec nimCmd
  exec "arm-none-eabi-objcopy -O binary build/" & target & ".elf build/" & target & ".bin"
  exec "arm-none-eabi-size build/" & target & ".elf"

task flash, "Flash via DFU":
  exec "dfu-util -a 0 -s 0x08000000:leave -D build/blink.bin"

task stlink, "Flash via ST-Link":
  exec "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg -c \"program build/blink.elf verify reset exit\""
