# Package
version       = "0.1.0"
author        = "Your Name"
description   = "A basic Nimphea project"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]

# Dependencies
requires "nim >= 2.0.0"
requires "nimphea >= 1.0.0"

# Build configuration (copied from nimphea for standalone use)
import os, strutils, strformat

task make, "Build for ARM Cortex-M7":
  ## Simplified cross-platform build that integrates with nimphea installed
  var pkgPath = ""
  let rawPaths = gorge("nimble path nimphea")
  for ln in rawPaths.splitLines():
    let p = ln.strip()
    if p.len > 0 and dirExists(p):
      pkgPath = p
      break
  if pkgPath == "":
    echo "Error: nimphea package not found. Run 'nimble install nimphea' and then 'nimble init_libdaisy' inside the package path."
    quit(1)

  var nimCmd = "nim cpp"
  nimCmd.add(" --cc:gcc --gcc.exe:arm-none-eabi-gcc --gcc.cpp.exe:arm-none-eabi-g++ --gcc.linkerexe:arm-none-eabi-g++")
  nimCmd.add(" --cpu:arm --os:standalone --mm:arc --opt:size --exceptions:goto")
  nimCmd.add(" --define:useMalloc --define:noSignalHandler")
  nimCmd.add(" --path:src")
  nimCmd.add(" --path:" & pkgPath & "/src")
  nimCmd.add(" --passL:-L" & pkgPath & "/libDaisy/build")
  nimCmd.add(" --passL:-ldaisy")
  nimCmd.add(" --passC:-I" & pkgPath & "/libDaisy/src")
  nimCmd.add(" --passC:-DSTM32H750xx")

  let target = "main"
  mkDir("build")
  nimCmd.add(" -o:build/" & target & ".elf")
  nimCmd.add(" src/" & target & ".nim")
  exec nimCmd
  exec "arm-none-eabi-objcopy -O binary build/" & target & ".elf build/" & target & ".bin"
  exec "arm-none-eabi-size build/" & target & ".elf"

task flash, "Flash via DFU":
  exec "dfu-util -a 0 -s 0x08000000:leave -D build/main.bin"

task stlink, "Flash via ST-Link":
  exec "openocd -f interface/stlink.cfg -f target/stm32h7x.cfg -c \"program build/main.elf verify reset exit\""
