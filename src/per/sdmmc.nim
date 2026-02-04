## SD Card (SDIO/SDMMC) support for libDaisy Nim wrapper
##
## This module provides SD card access via SDMMC peripheral with FatFS filesystem.
## It enables reading and writing files on SD cards connected to the Daisy Seed.
##
## Basic Usage:
## ```nim
## import nimphea
## import per/sdmmc
## 
## var hw = newDaisySeed()
## var sd = newSdmmcHandler()
## var fatfs = newFatFSInterface()
## 
## proc main() =
##   hw.init()
##   
##   # Configure SDMMC
##   var sdConfig = newSdmmcConfig()
##   sdConfig.speed = SD_FAST
##   sdConfig.width = SD_BITS_4
##   
##   # Initialize SD card
##   if sd.init(sdConfig) != SD_OK:
##     return
##   
##   # Mount filesystem
##   if fatfs.init(MEDIA_SD) != FATFS_OK:
##     return
##   
##   # Now you can use FatFS functions
##   var file: FIL
##   if f_open(addr file, "test.txt", FA_READ) == FR_OK:
##     # Read file...
##     discard f_close(addr file)
##   
##   while true:
##     hw.delayMs(100)
## ```
##
## Pin Configuration (Fixed):
## - PC12: SDMMC1 Clock
## - PD2:  SDMMC1 Command
## - PC8:  SDMMC1 D0 (always required)
## - PC9:  SDMMC1 D1 (4-bit mode only)
## - PC10: SDMMC1 D2 (4-bit mode only)
## - PC11: SDMMC1 D3 (4-bit mode only)

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(sdmmc)

{.push header: "daisy_seed.h".}
{.push importcpp.}

type
  # SDMMC Handler types
  SdmmcResult* {.importcpp: "daisy::SdmmcHandler::Result", size: sizeof(cint).} = enum
    SD_OK = 0
    SD_ERROR

  SdmmcBusWidth* {.importcpp: "daisy::SdmmcHandler::BusWidth", size: sizeof(cint).} = enum
    SD_BITS_1 = 0  ## 1-bit mode (only D0 used)
    SD_BITS_4      ## 4-bit mode (D0-D3 used, faster)

  SdmmcSpeed* {.importcpp: "daisy::SdmmcHandler::Speed", size: sizeof(cint).} = enum
    SD_SLOW = 0         ## 400kHz - initialization speed
    SD_MEDIUM_SLOW      ## 12.5MHz - half of standard
    SD_STANDARD         ## 25MHz - default speed
    SD_FAST             ## 50MHz - high speed
    SD_VERY_FAST        ## 100MHz - overclocked (SDR50)

  SdmmcConfig* {.importcpp: "daisy::SdmmcHandler::Config", bycopy.} = object
    speed* {.importc: "speed".}: SdmmcSpeed
    width* {.importc: "width".}: SdmmcBusWidth
    clock_powersave* {.importc: "clock_powersave".}: bool

  SdmmcHandler* {.importcpp: "daisy::SdmmcHandler".} = object

  # FatFS Interface types
  FatFSResult* {.importcpp: "daisy::FatFSInterface::Result", size: sizeof(cint).} = enum
    FATFS_OK = 0
    FATFS_ERR_TOO_MANY_VOLUMES
    FATFS_ERR_NO_MEDIA_SELECTED
    FATFS_ERR_GENERIC

  FatFSMedia* {.importcpp: "daisy::FatFSInterface::Config::Media", size: sizeof(uint8).} = enum
    MEDIA_SD = 0x01
    MEDIA_USB = 0x02

  FatFSConfig* {.importcpp: "daisy::FatFSInterface::Config", bycopy.} = object
    media* {.importc: "media".}: uint8

  FatFSInterface* {.importcpp: "daisy::FatFSInterface".} = object

{.pop.} # importcpp
{.pop.} # header

# Low-level C++ interface - capital letter names matching libDaisy C++ API
proc Init*(this: var SdmmcHandler, cfg: SdmmcConfig): SdmmcResult 
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

proc Init*(this: var FatFSInterface, cfg: FatFSConfig): FatFSResult 
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

proc Init*(this: var FatFSInterface, media: uint8): FatFSResult 
  {.importcpp: "#.Init(@)", header: "daisy_seed.h".}

{.push header: "daisy_seed.h".}
{.push importcpp.}

# FatFS Interface methods
proc DeInit*(this: var FatFSInterface): FatFSResult 
  {.importcpp: "#.DeInit()", header: "daisy_seed.h".}
proc Initialized*(this: FatFSInterface): bool 
  {.importcpp: "#.Initialized()", header: "daisy_seed.h".}

proc GetConfig*(this: FatFSInterface): FatFSConfig 
  {.importcpp: "#.GetConfig()", header: "daisy_seed.h".}

proc GetSDPath*(this: FatFSInterface): cstring 
  {.importcpp: "#.GetSDPath()", header: "daisy_seed.h".}

proc GetUSBPath*(this: FatFSInterface): cstring 
  {.importcpp: "#.GetUSBPath()", header: "daisy_seed.h".}

{.pop.} # importcpp
{.pop.} # header

# Import FatFS C library functions
{.push header: "ff.h".}

type
  # FatFS result codes
  FRESULT* {.importc: "FRESULT", size: sizeof(cint).} = enum
    FR_OK = 0                ## Succeeded
    FR_DISK_ERR              ## A hard error occurred in the low level disk I/O layer
    FR_INT_ERR               ## Assertion failed
    FR_NOT_READY             ## The physical drive cannot work
    FR_NO_FILE               ## Could not find the file
    FR_NO_PATH               ## Could not find the path
    FR_INVALID_NAME          ## The path name format is invalid
    FR_DENIED                ## Access denied due to prohibited access or directory full
    FR_EXIST                 ## Access denied due to prohibited access
    FR_INVALID_OBJECT        ## The file/directory object is invalid
    FR_WRITE_PROTECTED       ## The physical drive is write protected
    FR_INVALID_DRIVE         ## The logical drive number is invalid
    FR_NOT_ENABLED           ## The volume has no work area
    FR_NO_FILESYSTEM         ## There is no valid FAT volume
    FR_MKFS_ABORTED          ## The f_mkfs() aborted due to any problem
    FR_TIMEOUT               ## Could not get a grant to access the volume within defined period
    FR_LOCKED                ## The operation is rejected according to the file sharing policy
    FR_NOT_ENOUGH_CORE       ## LFN working buffer could not be allocated
    FR_TOO_MANY_OPEN_FILES   ## Number of open files > FF_FS_LOCK
    FR_INVALID_PARAMETER     ## Given parameter is invalid

# File access mode flags
const
  FA_READ* = 0x01'u8           ## Read access
  FA_WRITE* = 0x02'u8          ## Write access
  FA_OPEN_EXISTING* = 0x00'u8  ## Open existing file
  FA_CREATE_NEW* = 0x04'u8     ## Create new file
  FA_CREATE_ALWAYS* = 0x08'u8  ## Create new file, overwrite existing
  FA_OPEN_ALWAYS* = 0x10'u8    ## Open existing or create new
  FA_OPEN_APPEND* = 0x30'u8    ## Open existing and seek to end

type
  # File object
  FIL* {.importc: "FIL", bycopy.} = object
  
  # Directory object
  DIR* {.importc: "DIR", bycopy.} = object
  
  # File information
  FILINFO* {.importc: "FILINFO", bycopy.} = object
    fsize* {.importc: "fsize".}: uint32     ## File size
    fdate* {.importc: "fdate".}: uint16     ## Modified date
    ftime* {.importc: "ftime".}: uint16     ## Modified time
    fattrib* {.importc: "fattrib".}: uint8  ## File attributes
    fname* {.importc: "fname".}: array[256, char]  ## File name
  
  # Filesystem object
  FATFS* {.importc: "FATFS", bycopy.} = object

  # Seek origin
  FSIZE_t* = uint32
  UINT* = cuint
  BYTE* = uint8

# FatFS C API functions
proc f_open*(fp: ptr FIL, path: cstring, mode: uint8): FRESULT {.importc: "f_open".}
proc f_close*(fp: ptr FIL): FRESULT {.importc: "f_close".}
proc f_read*(fp: ptr FIL, buff: pointer, btr: UINT, br: ptr UINT): FRESULT {.importc: "f_read".}
proc f_write*(fp: ptr FIL, buff: pointer, btw: UINT, bw: ptr UINT): FRESULT {.importc: "f_write".}
proc f_lseek*(fp: ptr FIL, ofs: FSIZE_t): FRESULT {.importc: "f_lseek".}
proc f_sync*(fp: ptr FIL): FRESULT {.importc: "f_sync".}
proc f_tell*(fp: ptr FIL): FSIZE_t {.importc: "f_tell".}
proc f_size*(fp: ptr FIL): FSIZE_t {.importc: "f_size".}
proc f_eof*(fp: ptr FIL): cint {.importc: "f_eof".}

proc f_opendir*(dp: ptr DIR, path: cstring): FRESULT {.importc: "f_opendir".}
proc f_closedir*(dp: ptr DIR): FRESULT {.importc: "f_closedir".}
proc f_readdir*(dp: ptr DIR, fno: ptr FILINFO): FRESULT {.importc: "f_readdir".}

proc f_mkdir*(path: cstring): FRESULT {.importc: "f_mkdir".}
proc f_unlink*(path: cstring): FRESULT {.importc: "f_unlink".}
proc f_rename*(oldname: cstring, newname: cstring): FRESULT {.importc: "f_rename".}
proc f_stat*(path: cstring, fno: ptr FILINFO): FRESULT {.importc: "f_stat".}
proc f_chmod*(path: cstring, attr: BYTE, mask: BYTE): FRESULT {.importc: "f_chmod".}

proc f_mount*(fs: ptr FATFS, path: cstring, opt: BYTE): FRESULT {.importc: "f_mount".}
proc f_unmount*(path: cstring): FRESULT {.importc: "f_unmount".}

{.pop.} # header

# Nim-friendly constructors
proc newSdmmcHandler*(): SdmmcHandler {.importcpp: "daisy::SdmmcHandler()", constructor, header: "daisy_seed.h".}
proc newFatFSInterface*(): FatFSInterface {.importcpp: "daisy::FatFSInterface()", constructor, header: "daisy_seed.h".}

proc newSdmmcConfig*(): SdmmcConfig =
  ## Creates a new SDMMC configuration with default values
  result.speed = SD_FAST
  result.width = SD_BITS_4
  result.clock_powersave = false

proc newFatFSConfig*(): FatFSConfig =
  ## Creates a new FatFS configuration
  result.media = uint8(MEDIA_SD)

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

proc init*(sdmmc: var SdmmcHandler, cfg: SdmmcConfig): SdmmcResult =
  ## Initialize SDMMC handler with configuration
  sdmmc.Init(cfg)

proc init*(fatfs: var FatFSInterface, cfg: FatFSConfig): FatFSResult =
  ## Initialize FatFS interface with configuration
  fatfs.Init(cfg)

proc init*(fatfs: var FatFSInterface, media: FatFSMedia): FatFSResult =
  ## Initialize FatFS interface with media type (convenience)
  fatfs.Init(uint8(media))

proc deInit*(fatfs: var FatFSInterface): FatFSResult =
  ## Deinitialize FatFS interface
  fatfs.DeInit()

proc initialized*(fatfs: FatFSInterface): bool =
  ## Check if FatFS is initialized
  fatfs.Initialized()

proc getConfig*(fatfs: FatFSInterface): FatFSConfig =
  ## Get FatFS configuration
  fatfs.GetConfig()

proc getSDPath*(fatfs: FatFSInterface): cstring =
  ## Get SD card mount path
  fatfs.GetSDPath()

proc getUSBPath*(fatfs: FatFSInterface): cstring =
  ## Get USB mount path
  fatfs.GetUSBPath()

# Higher-level convenience functions

proc readFile*(path: cstring, buffer: var openArray[uint8], 
               bytesRead: var int): FRESULT =
  ## Read file into provided buffer (safe for embedded)
  ## Returns number of bytes actually read in bytesRead parameter
  var file: FIL
  result = f_open(addr file, path, FA_READ)
  
  if result != FR_OK:
    bytesRead = 0
    return
  
  let fileSize = f_size(addr file)
  let toRead = min(fileSize, FSIZE_t(buffer.len))
  
  var br: UINT = 0
  result = f_read(addr file, addr buffer[0], UINT(toRead), addr br)
  bytesRead = int(br)
  
  discard f_close(addr file)
  
  if br != toRead:
    result = FR_DISK_ERR

proc writeFile*(path: cstring, data: openArray[uint8]): FRESULT =
  ## Write data to file (creates or overwrites)
  var file: FIL
  result = f_open(addr file, path, FA_WRITE or FA_CREATE_ALWAYS)
  
  if result != FR_OK:
    return
  
  var bytesWritten: UINT = 0
  result = f_write(addr file, addr data[0], UINT(len(data)), addr bytesWritten)
  
  discard f_sync(addr file)
  discard f_close(addr file)
  
  if bytesWritten != UINT(len(data)):
    result = FR_DISK_ERR

proc appendFile*(path: cstring, data: openArray[uint8]): FRESULT =
  ## Append data to file (creates if doesn't exist)
  var file: FIL
  result = f_open(addr file, path, FA_WRITE or FA_OPEN_APPEND)
  
  if result != FR_OK:
    return
  
  var bytesWritten: UINT = 0
  result = f_write(addr file, addr data[0], UINT(len(data)), addr bytesWritten)
  
  discard f_sync(addr file)
  discard f_close(addr file)

proc fileExists*(path: cstring): bool =
  ## Check if file exists
  var info: FILINFO
  result = f_stat(path, addr info) == FR_OK

proc getFileSize*(path: cstring): int =
  ## Get file size in bytes, returns -1 on error
  var info: FILINFO
  if f_stat(path, addr info) == FR_OK:
    result = int(info.fsize)
  else:
    result = -1

proc listDirectory*(path: cstring, filenames: var openArray[array[256, char]], 
                    maxFiles: int): tuple[result: FRESULT, count: int] =
  ## List files in directory into provided buffer
  ## filenames: buffer for storing filenames (each up to 256 chars)
  ## maxFiles: maximum number of files to read (should be <= filenames.len)
  ## Returns: result code and number of files found
  var dir: DIR
  result.result = f_opendir(addr dir, path)
  result.count = 0
  
  if result.result != FR_OK:
    return
  
  let limit = min(maxFiles, filenames.len)
  
  while result.count < limit:
    var info: FILINFO
    let res = f_readdir(addr dir, addr info)
    
    if res != FR_OK or info.fname[0] == '\0':
      break
    
    # Copy filename to buffer
    var i = 0
    while i < 255 and info.fname[i] != '\0':
      filenames[result.count][i] = info.fname[i]
      inc i
    filenames[result.count][i] = '\0'
    inc result.count
  
  discard f_closedir(addr dir)

proc deleteFile*(path: cstring): FRESULT =
  ## Delete a file
  result = f_unlink(path)

proc renameFile*(oldPath: cstring, newPath: cstring): FRESULT =
  ## Rename or move a file
  result = f_rename(oldPath, newPath)

proc createDirectory*(path: cstring): FRESULT =
  ## Create a directory
  result = f_mkdir(path)

# File attributes
const
  AM_RDO* = 0x01'u8  ## Read only
  AM_HID* = 0x02'u8  ## Hidden
  AM_SYS* = 0x04'u8  ## System
  AM_DIR* = 0x10'u8  ## Directory
  AM_ARC* = 0x20'u8  ## Archive

when isMainModule:
  echo "libDaisy SD Card (SDMMC) wrapper"
  echo "Supports SD card access via SDMMC with FatFS"
