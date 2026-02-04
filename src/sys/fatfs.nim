## FatFS support for libDaisy Nim wrapper
##
## This module provides FatFS filesystem support for SD cards and USB storage
## on the Daisy Audio Platform.
##
## **Important**: The relevant hardware peripheral (SD card or USB) must be
## initialized separately before using FatFS. This module only handles the
## FatFS layer that sits on top of the hardware.
##
## Example - SD Card filesystem access:
## ```nim
## import nimphea, sys/fatfs
## 
## var daisy = initDaisy()
## var sd: SdmmcHandler
## var sdConfig = newSdmmcConfig()
## 
## # Initialize SD card hardware
## let sdResult = sd.init(sdConfig)
## if sdResult != SDMMC_OK:
##   # Handle SD card error
##   discard
## 
## # Initialize FatFS on SD card
## var fatfs: FatFSInterface
## let fsResult = fatfs.init(MEDIA_SD)
## if fsResult != FATFS_OK:
##   # Handle FatFS error
##   discard
## 
## # Now you can use standard FatFS API
## # Mount filesystem
## var fs: FATFS
## let mountResult = f_mount(fs.addr, fatfs.getSDPath(), 1)
## 
## # Open and read a file
## var file: FIL
## if f_open(file.addr, "0:/test.txt", FA_READ) == FR_OK:
##   var buffer: array[128, char]
##   var bytesRead: UINT
##   discard f_read(file.addr, buffer[0].addr, 128, bytesRead.addr)
##   discard f_close(file.addr)
## 
## # Unmount when done
## discard f_mount(nil, fatfs.getSDPath(), 0)
## ```
##
## Example - Multiple volumes (SD + USB):
## ```nim
## import nimphea, sys/fatfs
## 
## var fatfs: FatFSInterface
## 
## # Mount both SD and USB (requires _VOLUMES=2 in ffconf.h)
## let result = fatfs.init(MEDIA_SD or MEDIA_USB)
## 
## # SD card will be at "0:/"
## # USB will be at "1:/"
## 
## # Access SD card
## var sdFile: FIL
## discard f_open(sdFile.addr, "0:/file.txt", FA_READ)
## 
## # Access USB drive
## var usbFile: FIL
## discard f_open(usbFile.addr, "1:/file.txt", FA_READ)
## ```

import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(fatfs)

{.push header: "sys/fatfs.h".}

type
  FatFSInterface* {.importcpp: "daisy::FatFSInterface", bycopy.} = object
  
  FatFSConfig* {.importcpp: "daisy::FatFSInterface::Config", bycopy.} = object
    media* {.importcpp: "media".}: uint8
  
  FatFSMedia* {.importcpp: "daisy::FatFSInterface::Config::Media", size: sizeof(uint8).} = enum
    MEDIA_SD = 0x01
    MEDIA_USB = 0x02
  
  FatFSResult* {.importcpp: "daisy::FatFSInterface::Result", size: sizeof(cint).} = enum
    FATFS_OK = 0
    FATFS_ERR_TOO_MANY_VOLUMES
    FATFS_ERR_NO_MEDIA_SELECTED
    FATFS_ERR_GENERIC

# FatFS types (from ff.h) - these are opaque to Nim
type
  FATFS* {.importcpp: "FATFS", header: "ff.h".} = object
  FIL* {.importcpp: "FIL", header: "ff.h".} = object
  DIR* {.importcpp: "DIR", header: "ff.h".} = object
  FILINFO* {.importcpp: "FILINFO", header: "ff.h".} = object
  UINT* {.importcpp: "UINT", header: "ff.h".} = cuint
  DWORD* {.importcpp: "DWORD", header: "ff.h".} = culong
  FRESULT* {.importcpp: "FRESULT", header: "ff.h", size: sizeof(cint).} = enum
    FR_OK = 0
    FR_DISK_ERR
    FR_INT_ERR
    FR_NOT_READY
    FR_NO_FILE
    FR_NO_PATH
    FR_INVALID_NAME
    FR_DENIED
    FR_EXIST
    FR_INVALID_OBJECT
    FR_WRITE_PROTECTED
    FR_INVALID_DRIVE
    FR_NOT_ENABLED
    FR_NO_FILESYSTEM
    FR_MKFS_ABORTED
    FR_TIMEOUT
    FR_LOCKED
    FR_NOT_ENOUGH_CORE
    FR_TOO_MANY_OPEN_FILES
    FR_INVALID_PARAMETER

# FatFS file access mode flags
const
  FA_READ* = 0x01'u8
  FA_WRITE* = 0x02'u8
  FA_OPEN_EXISTING* = 0x00'u8
  FA_CREATE_NEW* = 0x04'u8
  FA_CREATE_ALWAYS* = 0x08'u8
  FA_OPEN_ALWAYS* = 0x10'u8
  FA_OPEN_APPEND* = 0x30'u8

# Low-level C++ interface - FatFSInterface
proc Init(this: var FatFSInterface, config: FatFSConfig): FatFSResult {.importcpp: "#.Init(@)".}
proc Init(this: var FatFSInterface, media: uint8): FatFSResult {.importcpp: "#.Init(@)".}
proc DeInit(this: var FatFSInterface): FatFSResult {.importcpp: "#.DeInit()".}
proc Initialized(this: FatFSInterface): bool {.importcpp: "#.Initialized()".}
proc GetConfig(this: FatFSInterface): FatFSConfig {.importcpp: "#.GetConfig()".}
proc GetSDPath(this: FatFSInterface): cstring {.importcpp: "#.GetSDPath()".}
proc GetUSBPath(this: FatFSInterface): cstring {.importcpp: "#.GetUSBPath()".}
proc GetSDFileSystem(this: var FatFSInterface): var FATFS {.importcpp: "#.GetSDFileSystem()".}
proc GetUSBFileSystem(this: var FatFSInterface): var FATFS {.importcpp: "#.GetUSBFileSystem()".}

# FatFS standard API (from ff.h)
proc f_mount*(fs: ptr FATFS, path: cstring, opt: cint): FRESULT {.importcpp: "f_mount(@)", header: "ff.h".}
proc f_open*(fp: ptr FIL, path: cstring, mode: uint8): FRESULT {.importcpp: "f_open(@)", header: "ff.h".}
proc f_close*(fp: ptr FIL): FRESULT {.importcpp: "f_close(@)", header: "ff.h".}
proc f_read*(fp: ptr FIL, buff: pointer, btr: UINT, br: ptr UINT): FRESULT {.importcpp: "f_read(@)", header: "ff.h".}
proc f_write*(fp: ptr FIL, buff: pointer, btw: UINT, bw: ptr UINT): FRESULT {.importcpp: "f_write(@)", header: "ff.h".}
proc f_lseek*(fp: ptr FIL, ofs: DWORD): FRESULT {.importcpp: "f_lseek(@)", header: "ff.h".}
proc f_sync*(fp: ptr FIL): FRESULT {.importcpp: "f_sync(@)", header: "ff.h".}
proc f_opendir*(dp: ptr DIR, path: cstring): FRESULT {.importcpp: "f_opendir(@)", header: "ff.h".}
proc f_closedir*(dp: ptr DIR): FRESULT {.importcpp: "f_closedir(@)", header: "ff.h".}
proc f_readdir*(dp: ptr DIR, fno: ptr FILINFO): FRESULT {.importcpp: "f_readdir(@)", header: "ff.h".}
proc f_mkdir*(path: cstring): FRESULT {.importcpp: "f_mkdir(@)", header: "ff.h".}
proc f_unlink*(path: cstring): FRESULT {.importcpp: "f_unlink(@)", header: "ff.h".}
proc f_rename*(oldPath: cstring, newPath: cstring): FRESULT {.importcpp: "f_rename(@)", header: "ff.h".}
proc f_stat*(path: cstring, fno: ptr FILINFO): FRESULT {.importcpp: "f_stat(@)", header: "ff.h".}
proc f_getfree*(path: cstring, nclst: ptr DWORD, fatfs: ptr ptr FATFS): FRESULT {.importcpp: "f_getfree(@)", header: "ff.h".}

# Constructors
proc newFatFSConfig*(): FatFSConfig {.importcpp: "daisy::FatFSInterface::Config()", constructor.}

{.pop.} # header

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc init*(fatfs: var FatFSInterface, config: FatFSConfig): FatFSResult {.inline.} =
  ## Initialize FatFS with the given configuration.
  ##
  ## Parameters:
  ##   fatfs: The FatFS interface to initialize
  ##   config: Configuration specifying which media to use
  ##
  ## Returns:
  ##   FATFS_OK on success, error code on failure
  ##
  ## Example:
  ## ```nim
  ## var fatfs: FatFSInterface
  ## var config = newFatFSConfig()
  ## config.media = MEDIA_SD
  ## let result = fatfs.init(config)
  ## ```
  result = fatfs.Init(config)

proc init*(fatfs: var FatFSInterface, media: uint8): FatFSResult {.inline.} =
  ## Initialize FatFS with the specified media (simplified API).
  ##
  ## Parameters:
  ##   fatfs: The FatFS interface to initialize
  ##   media: Media flags (MEDIA_SD, MEDIA_USB, or both OR'd together)
  ##
  ## Returns:
  ##   FATFS_OK on success, error code on failure
  ##
  ## Example:
  ## ```nim
  ## var fatfs: FatFSInterface
  ## let result = fatfs.init(MEDIA_SD)
  ## # Or for multiple volumes:
  ## # let result = fatfs.init(MEDIA_SD or MEDIA_USB)
  ## ```
  result = fatfs.Init(media)

proc deinit*(fatfs: var FatFSInterface): FatFSResult {.inline.} =
  ## Deinitialize FatFS and unlink from configured media.
  ##
  ## Returns:
  ##   FATFS_OK on success, error code on failure
  result = fatfs.DeInit()

proc isInitialized*(fatfs: FatFSInterface): bool {.inline.} =
  ## Check if FatFS is initialized.
  ##
  ## Returns:
  ##   true if initialized, false otherwise
  result = fatfs.Initialized()

proc getConfig*(fatfs: FatFSInterface): FatFSConfig {.inline.} =
  ## Get the current FatFS configuration.
  ##
  ## Returns:
  ##   Current configuration
  result = fatfs.GetConfig()

proc getSDPath*(fatfs: FatFSInterface): cstring {.inline.} =
  ## Get the path to the SD card volume for use with f_mount.
  ##
  ## Returns:
  ##   Path string (typically "0:/")
  result = fatfs.GetSDPath()

proc getUSBPath*(fatfs: FatFSInterface): cstring {.inline.} =
  ## Get the path to the USB volume for use with f_mount.
  ##
  ## Returns:
  ##   Path string (typically "1:/" when SD is also mounted)
  result = fatfs.GetUSBPath()

proc getSDFileSystem*(fatfs: var FatFSInterface): var FATFS {.inline.} =
  ## Get a reference to the SD card filesystem object.
  ##
  ## Returns:
  ##   Reference to FATFS object for SD card
  result = fatfs.GetSDFileSystem()

proc getUSBFileSystem*(fatfs: var FatFSInterface): var FATFS {.inline.} =
  ## Get a reference to the USB filesystem object.
  ##
  ## Returns:
  ##   Reference to FATFS object for USB
  result = fatfs.GetUSBFileSystem()

# =============================================================================
# Helper Procedures
# =============================================================================

proc mount*(fatfs: var FatFSInterface, media: FatFSMedia): FRESULT =
  ## Mount a filesystem on the specified media.
  ##
  ## This is a convenience wrapper around f_mount.
  ##
  ## Parameters:
  ##   fatfs: Initialized FatFS interface
  ##   media: Media to mount (MEDIA_SD or MEDIA_USB)
  ##
  ## Returns:
  ##   FR_OK on success, FatFS error code on failure
  ##
  ## Example:
  ## ```nim
  ## var fatfs: FatFSInterface
  ## discard fatfs.init(MEDIA_SD)
  ## let result = fatfs.mount(MEDIA_SD)
  ## ```
  case media
  of MEDIA_SD:
    result = f_mount(fatfs.getSDFileSystem().addr, fatfs.getSDPath(), 1)
  of MEDIA_USB:
    result = f_mount(fatfs.getUSBFileSystem().addr, fatfs.getUSBPath(), 1)

proc unmount*(fatfs: FatFSInterface, media: FatFSMedia): FRESULT =
  ## Unmount a filesystem from the specified media.
  ##
  ## Note: FatFS unmounts by calling f_mount with NULL filesystem pointer.
  ##
  ## Parameters:
  ##   fatfs: Initialized FatFS interface
  ##   media: Media to unmount (MEDIA_SD or MEDIA_USB)
  ##
  ## Returns:
  ##   FR_OK on success, FatFS error code on failure
  case media
  of MEDIA_SD:
    result = f_mount(nil, fatfs.getSDPath(), 0)
  of MEDIA_USB:
    result = f_mount(nil, fatfs.getUSBPath(), 0)

when isMainModule:
  echo "libDaisy FatFS wrapper - Filesystem support for SD card and USB"
