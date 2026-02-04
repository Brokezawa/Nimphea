## FatFS Filesystem Demonstration
##
## Demonstrates FatFS filesystem operations on SD card and USB storage.
##
## **Important**: This example shows the FatFS API layer. You must initialize
## the SD card or USB hardware separately before using FatFS.
##
## Hardware:
## - Daisy Seed (or other Daisy board with SD card support)
## - SD card inserted (formatted as FAT32)
## - Optional: USB storage device
##
## Features demonstrated:
## - FatFS initialization
## - Mounting/unmounting filesystems
## - File operations (open, read, write, close)
## - Directory operations (list, create)
## - File management (rename, delete, stat)
## - Multiple volume support (SD + USB)
##
## Compile-time modes (use -d:mode=<mode>):
## - basic: Basic file write and read (default)
## - list: List files in directory
## - copy: Copy file within SD card
## - multivolume: Use both SD and USB volumes

import nimphea
import sys/fatfs

useNimpheaNamespace()

const MODE = 
  when defined(list): "list"
  elif defined(copy): "copy"
  elif defined(multivolume): "multivolume"
  else: "basic"

when MODE == "basic":
  # ==========================================================================
  # Mode 1: Basic File Write and Read
  # ==========================================================================
  ## Demonstrates simple file creation, writing, and reading
  
  proc main() =
    var daisy = initDaisy()
    
    # NOTE: Initialize SD card hardware here
    # This is hardware-specific and would use libdaisy_sdcard or similar
    # For this example, we assume SD is already initialized
    
    # Initialize FatFS for SD card
    var fatfs: FatFSInterface
    let fsResult = fatfs.init(MEDIA_SD.uint8)
    
    if fsResult != FATFS_OK:
      # Error: blink LED rapidly
      while true:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
    
    # Mount the SD card filesystem
    let mountResult = fatfs.mount(MEDIA_SD)
    if mountResult != FR_OK:
      # Mount error: blink slowly
      while true:
        daisy.setLed(true)
        daisy.delay(500)
        daisy.setLed(false)
        daisy.delay(500)
    
    # Write a test file
    var writeFile: FIL
    if f_open(writeFile.addr, "0:/test.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
      let testData = "Hello from Daisy!\n"
      var bytesWritten: UINT
      
      discard f_write(writeFile.addr, testData.cstring, testData.len.UINT, bytesWritten.addr)
      discard f_close(writeFile.addr)
      
      # Blink once to indicate write success
      daisy.setLed(true)
      daisy.delay(200)
      daisy.setLed(false)
      daisy.delay(200)
    
    # Read the file back
    var readFile: FIL
    if f_open(readFile.addr, "0:/test.txt", FA_READ) == FR_OK:
      var buffer: array[128, char]
      var bytesRead: UINT
      
      discard f_read(readFile.addr, buffer[0].addr, 128, bytesRead.addr)
      discard f_close(readFile.addr)
      
      # File read successfully - blink twice
      for i in 0..1:
        daisy.setLed(true)
        daisy.delay(200)
        daisy.setLed(false)
        daisy.delay(200)
    
    # Unmount when done
    discard fatfs.unmount(MEDIA_SD)
    
    # Success - slow blink
    while true:
      daisy.setLed(true)
      daisy.delay(1000)
      daisy.setLed(false)
      daisy.delay(1000)

elif MODE == "list":
  # ==========================================================================
  # Mode 2: List Directory Contents
  # ==========================================================================
  ## Demonstrates directory traversal and file listing
  
  proc main() =
    var daisy = initDaisy()
    
    # Initialize and mount
    var fatfs: FatFSInterface
    if fatfs.init(MEDIA_SD.uint8) != FATFS_OK:
      while true:
        daisy.delay(100)
        return
    
    if fatfs.mount(MEDIA_SD) != FR_OK:
      while true:
        daisy.delay(100)
        return
    
    # Open root directory
    var dir: DIR
    if f_opendir(dir.addr, "0:/") == FR_OK:
      var fileInfo: FILINFO
      
      # Count files by blinking LED
      var fileCount = 0
      while f_readdir(dir.addr, fileInfo.addr) == FR_OK:
        # Check if we reached end of directory (empty fname)
        # Note: fname access would require proper FILINFO struct binding
        # For this example, we'll just count a few iterations
        fileCount.inc
        if fileCount > 10:
          break
        
        # Blink for each file found
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
      
      discard f_closedir(dir.addr)
    
    # Unmount
    discard fatfs.unmount(MEDIA_SD)
    
    # Done - stay lit
    daisy.setLed(true)
    while true:
      daisy.delay(1000)

elif MODE == "copy":
  # ==========================================================================
  # Mode 3: File Copy Operation
  # ==========================================================================
  ## Demonstrates copying a file from one location to another
  
  proc main() =
    var daisy = initDaisy()
    
    # Initialize and mount
    var fatfs: FatFSInterface
    if fatfs.init(MEDIA_SD.uint8) != FATFS_OK:
      while true:
        daisy.delay(100)
        return
    
    if fatfs.mount(MEDIA_SD) != FR_OK:
      while true:
        daisy.delay(100)
        return
    
    # Create source file
    var sourceFile: FIL
    if f_open(sourceFile.addr, "0:/source.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
      let sourceData = "This is the source file content.\n"
      var bytesWritten: UINT
      discard f_write(sourceFile.addr, sourceData.cstring, sourceData.len.UINT, bytesWritten.addr)
      discard f_close(sourceFile.addr)
    
    # Copy source to destination
    var srcFile: FIL
    var dstFile: FIL
    
    if f_open(srcFile.addr, "0:/source.txt", FA_READ) == FR_OK:
      if f_open(dstFile.addr, "0:/destination.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
        var buffer: array[64, char]
        var bytesRead: UINT
        var bytesWritten: UINT
        
        # Copy in chunks
        while f_read(srcFile.addr, buffer[0].addr, 64, bytesRead.addr) == FR_OK and bytesRead > 0:
          discard f_write(dstFile.addr, buffer[0].addr, bytesRead, bytesWritten.addr)
          
          # Blink during copy
          daisy.setLed(true)
          daisy.delay(50)
          daisy.setLed(false)
          daisy.delay(50)
        
        discard f_close(dstFile.addr)
      
      discard f_close(srcFile.addr)
    
    # Verify destination exists
    var fileInfo: FILINFO
    if f_stat("0:/destination.txt", fileInfo.addr) == FR_OK:
      # Success - rapid blink
      for i in 0..4:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
    
    # Cleanup and unmount
    discard fatfs.unmount(MEDIA_SD)
    
    # Done
    while true:
      daisy.delay(1000)

elif MODE == "multivolume":
  # ==========================================================================
  # Mode 4: Multiple Volumes (SD + USB)
  # ==========================================================================
  ## Demonstrates working with both SD card and USB storage simultaneously
  ## Requires _VOLUMES=2 in ffconf.h
  
  proc main() =
    var daisy = initDaisy()
    
    # NOTE: Initialize both SD and USB hardware here
    
    # Initialize FatFS for both volumes
    var fatfs: FatFSInterface
    let fsResult = fatfs.init((MEDIA_SD.uint8 or MEDIA_USB.uint8))
    
    if fsResult != FATFS_OK:
      while true:
        daisy.setLed(true)
        daisy.delay(100)
        daisy.setLed(false)
        daisy.delay(100)
    
    # Mount SD card (will be "0:/")
    if fatfs.mount(MEDIA_SD) != FR_OK:
      # SD mount failed
      while true:
        daisy.delay(100)
        return
    
    # Mount USB drive (will be "1:/")
    if fatfs.mount(MEDIA_USB) != FR_OK:
      # USB mount failed, but SD is OK - continue with just SD
      discard
    
    # Write to SD card
    var sdFile: FIL
    if f_open(sdFile.addr, "0:/sd_file.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
      let sdData = "File on SD card\n"
      var bytesWritten: UINT
      discard f_write(sdFile.addr, sdData.cstring, sdData.len.UINT, bytesWritten.addr)
      discard f_close(sdFile.addr)
      
      # Blink once for SD write
      daisy.setLed(true)
      daisy.delay(200)
      daisy.setLed(false)
      daisy.delay(200)
    
    # Write to USB drive
    var usbFile: FIL
    if f_open(usbFile.addr, "1:/usb_file.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
      let usbData = "File on USB drive\n"
      var bytesWritten: UINT
      discard f_write(usbFile.addr, usbData.cstring, usbData.len.UINT, bytesWritten.addr)
      discard f_close(usbFile.addr)
      
      # Blink twice for USB write
      for i in 0..1:
        daisy.setLed(true)
        daisy.delay(200)
        daisy.setLed(false)
        daisy.delay(200)
    
    # Copy file from SD to USB
    var srcFile: FIL
    var dstFile: FIL
    if f_open(srcFile.addr, "0:/sd_file.txt", FA_READ) == FR_OK:
      if f_open(dstFile.addr, "1:/copied_from_sd.txt", FA_WRITE or FA_CREATE_ALWAYS) == FR_OK:
        var buffer: array[64, char]
        var bytesRead: UINT
        var bytesWritten: UINT
        
        while f_read(srcFile.addr, buffer[0].addr, 64, bytesRead.addr) == FR_OK and bytesRead > 0:
          discard f_write(dstFile.addr, buffer[0].addr, bytesRead, bytesWritten.addr)
        
        discard f_close(dstFile.addr)
        
        # Blink three times for successful cross-volume copy
        for i in 0..2:
          daisy.setLed(true)
          daisy.delay(200)
          daisy.setLed(false)
          daisy.delay(200)
      
      discard f_close(srcFile.addr)
    
    # Unmount both volumes
    discard fatfs.unmount(MEDIA_SD)
    discard fatfs.unmount(MEDIA_USB)
    
    # Success - slow blink
    while true:
      daisy.setLed(true)
      daisy.delay(1000)
      daisy.setLed(false)
      daisy.delay(1000)

when isMainModule:
  main()
