## FileTable
## =========
##
## File index and metadata management for FAT filesystems on Daisy hardware.
##
## This module provides a utility for creating an indexed table of files from
## a directory, with support for filtering, sorting, and metadata access.
## Commonly used for managing audio sample libraries (.wav files) on SD cards.
##
## What is FileTable?
## ------------------
##
## **FileTable** scans a directory on an SD card or QSPI flash, builds an
## in-memory index of files, and provides fast access to file names and sizes.
##
## **Typical use cases:**
## - Loading .wav sample libraries
## - Managing preset/patch files
## - Building a file browser UI
## - Batch file operations
##
## **Key features:**
## - Alphabetical sorting (case-insensitive)
## - File extension filtering (e.g., only ".wav" files)
## - Fixed-size table (compile-time capacity)
## - Metadata access (file name, size)
## - Log file generation for debugging
##
## Basic Usage
## -----------
##
## **Step 1: Define table capacity**
##
## .. code-block:: nim
##    # Create table for up to 64 files
##    type SampleTable = FileTable[64]
##    
##    var samples: SampleTable
##
## **Step 2: Scan directory**
##
## .. code-block:: nim
##    # Load all .wav files from /samples/ directory
##    if samples.fill("/samples", ".wav"):
##      echo "Found ", samples.getNumFiles(), " .wav files"
##    else:
##      echo "Error scanning directory"
##
## **Step 3: Access file info**
##
## .. code-block:: nim
##    for i in 0..<samples.getNumFiles():
##      let name = samples.getFileName(i)
##      let size = samples.getFileSize(i)
##      echo i, ": ", name, " (", size, " bytes)"
##
## Complete Example
## ----------------
##
## Sample player with SD card library:
##
## .. code-block:: nim
##    import nimphea_filetable
##    import per/sdmmc
##    
##    type SampleLibrary = FileTable[128]
##    
##    var samples: SampleLibrary
##    var sd: SdmmcHandler
##    
##    proc loadSampleLibrary() =
##      # Initialize SD card
##      sd.init()
##      
##      if not samples.fill("/samples", ".wav"):
##        echo "Error: Could not scan samples directory"
##        return
##      
##      echo "Sample Library:"
##      echo "---------------"
##      
##      for i in 0..<samples.getNumFiles():
##        if samples.isFileInSlot(i):
##          let name = samples.getFileName(i)
##          let size = samples.getFileSize(i)
##          echo i + 1, ". ", name, " (", size, " bytes)"
##      
##      # Optional: Write log file to SD card
##      if samples.writeLog("/samples_index.txt"):
##        echo "Index written to samples_index.txt"
##
## Filtering Files
## ---------------
##
## **Example 1: Load only .wav files**
##
## .. code-block:: nim
##    samples.fill("/audio", ".wav")
##
## **Example 2: Load only .txt files**
##
## .. code-block:: nim
##    presets.fill("/presets", ".txt")
##
## **Example 3: Load all files (no filter)**
##
## .. code-block:: nim
##    allFiles.fill("/data", nil)  # nil = no extension filter
##
## File Access Patterns
## --------------------
##
## **Pattern 1: Iterate all files**
##
## .. code-block:: nim
##    for i in 0..<samples.getNumFiles():
##      let filename = samples.getFileName(i)
##      processSample(filename)
##
## **Pattern 2: Check if slot has file**
##
## .. code-block:: nim
##    if samples.isFileInSlot(5):
##      let name = samples.getFileName(5)
##      echo "Slot 5: ", name
##    else:
##      echo "Slot 5 is empty"
##
## **Pattern 3: Find file by name**
##
## .. code-block:: nim
##    proc findFile(table: var SampleTable, searchName: cstring): int =
##      for i in 0..<table.getNumFiles():
##        if table.getFileName(i) == searchName:
##          return i
##      return -1
##    
##    let idx = findFile(samples, "kick.wav")
##    if idx >= 0:
##      echo "Found at index ", idx
##
## Load/Save State Management
## ---------------------------
##
## FileTable includes optional flags for coordinating file I/O operations:
##
## **Save workflow:**
##
## .. code-block:: nim
##    # User presses "Save" button
##    samples.setSavePending(3)  # Mark slot 3 for saving
##    
##    # In main loop
##    if samples.isSavePending():
##      let slot = samples.getSlotForSaveLoad()
##      let filename = samples.getFileName(slot)
##      saveDataToFile(filename)
##      samples.clearSavePending()
##
## **Load workflow:**
##
## .. code-block:: nim
##    # User selects file 7
##    samples.setLoadPending(7)
##    
##    # In main loop
##    if samples.isLoadPending():
##      let slot = samples.getSlotForSaveLoad()
##      let filename = samples.getFileName(slot)
##      loadDataFromFile(filename)
##      samples.clearLoadPending()
##
## Log File Generation
## -------------------
##
## Generate a text file listing all indexed files (useful for debugging):
##
## .. code-block:: nim
##    samples.fill("/samples", ".wav")
##    samples.writeLog("/samples_log.txt")
##
## **Example log file output:**
##
## .. code-block::
##    1:  kick.wav    45632 bytes
##    2:  snare.wav   38912 bytes
##    3:  hihat.wav   12048 bytes
##
## Capacity and Limitations
## -------------------------
##
## **Compile-time capacity:**
##
## The table size is fixed at compile time via the template parameter:
##
## .. code-block:: nim
##    type
##      SmallTable = FileTable[16]   # Max 16 files
##      MediumTable = FileTable[64]  # Max 64 files
##      LargeTable = FileTable[256]  # Max 256 files
##
## **Memory usage:**
##
## Each slot uses ~260 bytes (255 chars for filename + size field).
##
## .. code-block::
##    FileTable[16]:  ~4KB RAM
##    FileTable[64]:  ~16KB RAM
##    FileTable[256]: ~64KB RAM
##
## **Filename length:**
##
## Maximum filename length is 255 characters (FAT long filename support).
##
## **What happens when table is full?**
##
## `fill()` stops after loading `max_slots` files. Remaining files are ignored.
## Use a larger table size if needed.
##
## Sorting Behavior
## ----------------
##
## Files are automatically sorted alphabetically (case-insensitive) after loading:
##
## .. code-block::
##    Directory contents:    Sorted in table:
##    - snare.wav            1. bass.wav
##    - kick.wav             2. hihat.wav
##    - Bass.wav             3. kick.wav
##    - HiHat.wav            4. snare.wav
##
## **Case-insensitive:** "Bass.wav" and "bass.wav" are treated equally.
##
## Error Handling
## --------------
##
## **Check return values:**
##
## .. code-block:: nim
##    if not samples.fill("/samples", ".wav"):
##      echo "ERROR: Could not scan directory"
##      echo "Possible causes:"
##      echo "- SD card not mounted"
##      echo "- Directory does not exist"
##      echo "- Filesystem error"
##      return
##    
##    if samples.getNumFiles() == 0:
##      echo "WARNING: No .wav files found in /samples/"
##
## Performance Notes
## -----------------
##
## - **Scanning is relatively slow** (depends on number of files)
## - Call `fill()` once during initialization, not in main loop
## - Accessing file metadata (name, size) is instant (in-memory lookup)
## - Sorting adds minimal overhead (insertion sort, ~O(n²) but n is small)
##
## See Also
## --------
## - `per/sdmmc <per/sdmmc.html>`_ - SD card access
## - `per/qspi <qspi.html>`_ - QSPI flash access
## - FatFs documentation - Underlying filesystem library

import nimphea
import nimphea_macros

useNimpheaModules(file_table)

{.push header: "util/FileTable.h".}

# ============================================================================
# Type Definitions
# ============================================================================

type
  FileTable*[max_slots: static int] {.
    importcpp: "daisy::FileTable<'0>".} = object
    ## File index table for FAT filesystem directories.
    ##
    ## **Template parameter:**
    ## - `max_slots` - Maximum number of files to index (compile-time constant)
    ##
    ## **Example:**
    ## ```nim
    ## type SampleTable = FileTable[64]
    ## var samples: SampleTable
    ## ```
    ##
    ## **Internal state:**
    ## - Array of file metadata (name + size)
    ## - Number of files found
    ## - Load/save pending flags (optional state management)

{.pop.} # header

# ============================================================================
# Compatibility Aliases (Standard Sizes)
# ============================================================================

type
  FileTable8* = FileTable[8]
  FileTable16* = FileTable[16]
  FileTable32* = FileTable[32]
  FileTable64* = FileTable[64]
  FileTable128* = FileTable[128]

# ============================================================================
# C++ Method Wrappers
# ============================================================================

proc clear*[N: static int](this: var FileTable[N]) {.importcpp: "#.Clear()".}
  ## Reset table to empty state.
  ##
  ## Clears all file entries and resets file count to zero.
  ##
  ## **Example:**
  ## ```nim
  ## samples.fill("/samples", ".wav")
  ## # ... use table ...
  ## samples.clear()  # Erase all entries
  ## samples.fill("/drums", ".wav")  # Reload with different directory
  ## ```

proc fill*[N: static int](this: var FileTable[N], path: cstring,
                               endswith: cstring = nil): bool {.
  importcpp: "#.Fill(@)".}
  ## Scan directory and fill table with matching files.
  ##
  ## **Parameters:**
  ## - `path` - Directory path (e.g., "/samples")
  ## - `endswith` - File extension filter (e.g., ".wav"), or nil for all files
  ##
  ## **Returns:** True if scan succeeded, false on error
  ##
  ## **Behavior:**
  ## - Scans directory recursively (one level)
  ## - Filters by extension if provided
  ## - Skips hidden files, directories, and system files
  ## - Sorts results alphabetically (case-insensitive)
  ## - Stops after `max_slots` files
  ##
  ## **Example:**
  ## ```nim
  ## # Load only .wav files
  ## if samples.fill("/audio", ".wav"):
  ##   echo "Loaded ", samples.getNumFiles(), " samples"
  ## 
  ## # Load all files
  ## if allFiles.fill("/data", nil):
  ##   echo "Loaded ", allFiles.getNumFiles(), " files"
  ## ```

proc writeLog*[N: static int](this: var FileTable[N],
                                   log_file_name: cstring): bool {.
  importcpp: "#.WriteLog(@)".}
  ## Write a log file listing all indexed files.
  ##
  ## **Parameters:**
  ## - `log_file_name` - Path to log file (e.g., "/index.txt")
  ##
  ## **Returns:** True if log written successfully, false on error
  ##
  ## **Log format:**
  ## ```
  ## 1:  filename1.wav  12345 bytes
  ## 2:  filename2.wav  67890 bytes
  ## ```
  ##
  ## **Example:**
  ## ```nim
  ## samples.fill("/samples", ".wav")
  ## if samples.writeLog("/samples_index.txt"):
  ##   echo "Index written successfully"
  ## ```

proc isFileInSlot*[N: static int](this: FileTable[N], idx: csize_t): bool {.
  importcpp: "#.IsFileInSlot(@)".}
  ## Check if a file exists at the given index.
  ##
  ## **Parameters:**
  ## - `idx` - Slot index (0 to max_slots-1)
  ##
  ## **Returns:** True if slot contains a file, false if empty
  ##
  ## **Example:**
  ## ```nim
  ## if samples.isFileInSlot(3):
  ##   echo "Slot 3: ", samples.getFileName(3)
  ## else:
  ##   echo "Slot 3 is empty"
  ## ```

proc getFileSize*[N: static int](this: FileTable[N], idx: csize_t): csize_t {.
  importcpp: "#.GetFileSize(@)".}
  ## Get file size in bytes for the file at the given index.
  ##
  ## **Parameters:**
  ## - `idx` - File index (0 to numFiles-1)
  ##
  ## **Returns:** File size in bytes, or 0 if slot is empty
  ##
  ## **Example:**
  ## ```nim
  ## let size = samples.getFileSize(0)
  ## echo "First file is ", size, " bytes"
  ## ```

proc getFileName*[N: static int](this: FileTable[N], idx: csize_t): cstring {.
  importcpp: "#.GetFileName(@)".}
  ## Get filename for the file at the given index.
  ##
  ## **Parameters:**
  ## - `idx` - File index (0 to numFiles-1)
  ##
  ## **Returns:** Filename as C-string (pointer to internal buffer)
  ##
  ## **Warning:** Do not modify the returned string. It points to internal storage.
  ##
  ## **Example:**
  ## ```nim
  ## for i in 0..<samples.getNumFiles():
  ##   echo i, ": ", samples.getFileName(i)
  ## ```

proc getNumFiles*[N: static int](this: FileTable[N]): csize_t {.
  importcpp: "#.GetNumFiles()".}
  ## Get the number of files found in the table.
  ##
  ## **Returns:** Number of files (0 to max_slots)
  ##
  ## **Example:**
  ## ```nim
  ## samples.fill("/samples", ".wav")
  ## echo "Found ", samples.getNumFiles(), " files"
  ## ```

# ============================================================================
# Load/Save State Management
# ============================================================================

proc isLoadPending*[N: static int](this: FileTable[N]): bool {.
  importcpp: "#.IsLoadPending()".}
  ## Check if a load operation is pending.
  ##
  ## **Returns:** True if load pending, false otherwise
  ##
  ## **Example:**
  ## ```nim
  ## if samples.isLoadPending():
  ##   let slot = samples.getSlotForSaveLoad()
  ##   loadFile(samples.getFileName(slot))
  ##   samples.clearLoadPending()
  ## ```

proc clearLoadPending*[N: static int](this: var FileTable[N]) {.
  importcpp: "#.ClearLoadPending()".}
  ## Clear the load pending flag.

proc setLoadPending*[N: static int](this: var FileTable[N], slot: cint) {.
  importcpp: "#.SetLoadPending(@)".}
  ## Mark a slot for loading.
  ##
  ## **Parameters:**
  ## - `slot` - Slot index to load
  ##
  ## **Example:**
  ## ```nim
  ## # User selects file 5
  ## samples.setLoadPending(5)
  ## ```

proc isSavePending*[N: static int](this: FileTable[N]): bool {.
  importcpp: "#.IsSavePending()".}
  ## Check if a save operation is pending.
  ##
  ## **Returns:** True if save pending, false otherwise

proc clearSavePending*[N: static int](this: var FileTable[N]) {.
  importcpp: "#.ClearSavePending()".}
  ## Clear the save pending flag.

proc setSavePending*[N: static int](this: var FileTable[N], slot: cint) {.
  importcpp: "#.SetSavePending(@)".}
  ## Mark a slot for saving.
  ##
  ## **Parameters:**
  ## - `slot` - Slot index to save

proc getSlotForSaveLoad*[N: static int](this: FileTable[N]): cint {.
  importcpp: "#.GetSlotForSaveLoad()".}
  ## Get the slot index marked for save/load.
  ##
  ## **Returns:** Slot index, or -1 if none pending
  ##
  ## **Example:**
  ## ```nim
  ## if samples.isLoadPending():
  ##   let slot = samples.getSlotForSaveLoad()
  ##   let filename = samples.getFileName(csize_t(slot))
  ##   loadFile(filename)
  ## ```

# ============================================================================
# Nim Helper Functions
# ============================================================================

iterator items*[N: static int](table: FileTable[N]): tuple[idx: int, name: cstring, size: int] =
  ## Iterate over all files in the table.
  ##
  ## **Yields:** Tuple of (index, filename, size)
  ##
  ## **Example:**
  ## ```nim
  ## for (idx, name, size) in samples.items():
  ##   echo idx, ": ", name, " (", size, " bytes)"
  ## ```
  let numFiles = int(table.getNumFiles())
  for i in 0..<numFiles:
    yield (idx: i, name: table.getFileName(csize_t(i)), size: int(table.getFileSize(csize_t(i))))

proc printTable*[N: static int](table: FileTable[N]) =
  ## Print all files in the table to stdout.
  ##
  ## **Example:**
  ## ```nim
  ## samples.fill("/samples", ".wav")
  ## samples.printTable()
  ## # Output:
  ## # 0: kick.wav (45632 bytes)
  ## # 1: snare.wav (38912 bytes)
  ## ```
  for (idx, name, size) in table.items():
    echo idx, ": ", name, " (", size, " bytes)"

proc findByName*[N: static int](table: FileTable[N], searchName: cstring): int =
  ## Find a file by name (exact match, case-sensitive).
  ##
  ## **Parameters:**
  ## - `searchName` - Filename to search for
  ##
  ## **Returns:** File index, or -1 if not found
  ##
  ## **Example:**
  ## ```nim
  ## let idx = samples.findByName("kick.wav")
  ## if idx >= 0:
  ##   echo "Found kick.wav at index ", idx
  ## else:
  ##   echo "kick.wav not found"
  ## ```
  for (idx, name, _) in table.items():
    if name == searchName:
      return idx
  return -1

# ============================================================================
# Usage Examples
# ============================================================================

when isMainModule:
  ## Compile-time examples (not executable without hardware)
  ## All examples use discard to avoid compile errors in test mode
  
  # Example 1: Basic usage
  discard """
  block:
    type SampleTable = FileTable[64]
    var samples: SampleTable
    
    if samples.fill("/samples", ".wav"):
      echo "Loaded ", samples.getNumFiles(), " samples"
  """
  
  # Example 2: Using iterator
  discard """
  block:
    type SampleTable = FileTable[64]
    var samples: SampleTable
    discard samples.fill("/samples", ".wav")
    
    for (idx, name, size) in samples.items():
      echo idx, ": ", name, " (", size, " bytes)"
  """
  
  # Example 3: Find file by name
  discard """
  block:
    type SampleTable = FileTable[64]
    var samples: SampleTable
    discard samples.fill("/samples", ".wav")
    
    let idx = samples.findByName("kick.wav")
    if idx >= 0:
      echo "Found at index ", idx
  """
