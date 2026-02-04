## FileReader
## ==========
##
## Wrapper for libDaisy's FileReader utility.
## Provides an abstraction for reading files from FatFS.
##
## **Usage:**
## This utility wraps a FatFS `FIL` object and provides read/seek methods.
## Note that `per/sdmmc` already wraps FatFS `f_read` etc directly.
## This wrapper is provided for completeness with libDaisy API.
##
## **Example:**
## ```nim
## import nimphea_filereader
## import per/sdmmc
## 
## var file: FIL
## if f_open(addr file, "test.txt", FA_READ) == FR_OK:
##   var reader = newFileReader(addr file)
##   var buffer: array[64, uint8]
##   let bytesRead = reader.read(addr buffer, buffer.len)
##   discard f_close(addr file)
## ```

import nimphea_macros
import per/sdmmc

useNimpheaModules(file_reader)

type
  FileReader* {.importcpp: "daisy::FileReader", header: "util/FileReader.h".} = object

# Constructors
proc newFileReader*(f: ptr FIL): FileReader {.importcpp: "daisy::FileReader(@)", constructor.}
  ## Create a FileReader from an open FatFS file handle

# Methods
proc read*(this: var FileReader, dst: pointer, bytes: csize_t): csize_t {.importcpp: "#.read(@)".}
  ## Read bytes from file. Returns actual bytes read.

proc seek*(this: var FileReader, pos: uint32): bool {.importcpp: "#.seek(@)".}
  ## Seek to absolute position. Returns true on success.

proc position*(this: FileReader): uint32 {.importcpp: "#.position()".}
  ## Get current position.

proc size*(this: FileReader): uint32 {.importcpp: "#.size()".}
  ## Get total file size.
