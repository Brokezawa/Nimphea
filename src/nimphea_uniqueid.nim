## Unique Device ID Module
## 
## This module provides access to the STM32 microcontroller's 96-bit unique identifier.
## Each STM32 chip has a unique ID programmed during manufacturing, useful for:
## - Device identification and registration
## - License/authentication systems
## - Generating unique serial numbers
## - Hardware-based encryption keys
##
## **Key Features:**
## - Read 96-bit unique ID as three 32-bit words
## - Convert to hexadecimal string representation
## - Guaranteed unique per chip (factory programmed)
## - Read-only hardware register (cannot be modified)
##
## **Usage Example:**
## 
## .. code-block:: nim
##   import nimphea_uniqueid
##   
##   # Get unique ID as three 32-bit values
##   var uid = getUniqueId()
##   echo "Device ID: ", uid.w0.toHex(8), "-", uid.w1.toHex(8), "-", uid.w2.toHex(8)
##   
##   # Get as formatted hex string
##   let serialNumber = getUniqueIdString()
##   echo "Serial: ", serialNumber  # e.g. "1A2B3C4D-5E6F7890-ABCDEF01"
##
## **Technical Details:**
## - Unique ID is stored in read-only memory at factory
## - Location: STM32H7 UID base address (0x1FF1E800)
## - Format: 96 bits = 3 x 32-bit words
## - Guaranteed unique across all STM32 devices

import nimphea_macros

useNimpheaModules(unique_id)

# Simple toHex implementation for embedded (no heap allocation)
proc toHexImpl(value: uint32, width: int): string =
  const hexChars = "0123456789ABCDEF"
  result = newString(width)
  var val = value
  for i in countdown(width - 1, 0):
    result[i] = hexChars[val and 0xF]
    val = val shr 4

type
  UniqueId* = object
    ## 96-bit unique identifier split into three 32-bit words.
    ## 
    ## **Fields:**
    ## - w0: First 32-bit word (bits 0-31)
    ## - w1: Second 32-bit word (bits 32-63)
    ## - w2: Third 32-bit word (bits 64-95)
    w0*: uint32
    w1*: uint32
    w2*: uint32

proc dsy_get_unique_id(w0: ptr uint32, w1: ptr uint32, w2: ptr uint32)
  {.importc: "dsy_get_unique_id", header: "util/unique_id.h".}

proc getUniqueId*(): UniqueId =
  ## Read the 96-bit unique ID from the microcontroller.
  ## 
  ## **Returns:**
  ## UniqueId object containing three 32-bit words
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let uid = getUniqueId()
  ##   echo "Word 0: 0x", uid.w0.toHex(8)
  ##   echo "Word 1: 0x", uid.w1.toHex(8)
  ##   echo "Word 2: 0x", uid.w2.toHex(8)
  dsy_get_unique_id(addr result.w0, addr result.w1, addr result.w2)

proc getUniqueIdString*(): string =
  ## Read the unique ID and format as hyphen-separated hex string.
  ## 
  ## **Returns:**
  ## String in format "XXXXXXXX-XXXXXXXX-XXXXXXXX" (24 hex digits + 2 hyphens)
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let serial = getUniqueIdString()
  ##   echo "Device Serial Number: ", serial
  ##   # Output: Device Serial Number: 1A2B3C4D-5E6F7890-ABCDEF01
  let uid = getUniqueId()
  result = toHexImpl(uid.w0, 8) & "-" & toHexImpl(uid.w1, 8) & "-" & toHexImpl(uid.w2, 8)

proc `$`*(uid: UniqueId): string =
  ## Convert UniqueId to string representation.
  ## 
  ## **Parameters:**
  ## - uid: The UniqueId object
  ## 
  ## **Returns:**
  ## String in format "UniqueId(0xXXXXXXXX-0xXXXXXXXX-0xXXXXXXXX)"
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let uid = getUniqueId()
  ##   echo uid  # UniqueId(0x1A2B3C4D-0x5E6F7890-0xABCDEF01)
  result = "UniqueId(0x" & toHexImpl(uid.w0, 8) & "-0x" & toHexImpl(uid.w1, 8) & "-0x" & toHexImpl(uid.w2, 8) & ")"

proc `==`*(a, b: UniqueId): bool {.inline.} =
  ## Compare two UniqueId objects for equality.
  ## 
  ## **Parameters:**
  ## - a: First UniqueId
  ## - b: Second UniqueId
  ## 
  ## **Returns:**
  ## true if all three words match, false otherwise
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   let uid1 = getUniqueId()
  ##   let uid2 = getUniqueId()
  ##   assert uid1 == uid2  # Same device always returns same ID
  result = (a.w0 == b.w0) and (a.w1 == b.w1) and (a.w2 == b.w2)
