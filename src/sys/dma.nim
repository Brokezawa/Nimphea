## DMA Cache Management
## ====================
##
## Direct Memory Access (DMA) cache coherency functions for Daisy hardware.
##
## This module provides functions to maintain cache coherency when using DMA
## (Direct Memory Access) peripherals on the STM32H750 microcontroller.
##
## Cache Coherency Problem
## -----------------------
##
## The STM32H750 has data caches (D-cache) that sit between the CPU and SRAM.
## When using DMA:
##
## 1. **CPU accesses cache**, but **DMA accesses SRAM directly**
## 2. Cache and SRAM can become **out of sync**
## 3. This causes **data corruption** in DMA transfers
##
## **Example Problem:**
##
## .. code-block:: nim
##    var buffer = [1'u8, 2, 3, 4]
##    # CPU writes to cache, but not yet to SRAM
##    # DMA reads from SRAM → gets old/garbage data!
##
## Solutions
## ---------
##
## **Option 1: Disable cache for DMA buffers** (Recommended)
##
## Place DMA buffers in D2 memory domain with cache disabled:
##
## .. code-block:: nim
##    var buffer {.emit: "DMA_BUFFER_MEM_SECTION".}: array[256, uint8]
##
## This is the cleanest solution - no manual cache management needed.
##
## **Option 2: Manual cache management** (When Option 1 is not possible)
##
## Use the functions in this module:
##
## .. code-block:: nim
##    var buffer: array[256, uint8]
##    
##    # Before DMA transmit (write)
##    dmaClearCache(buffer)  # Flush cache to SRAM
##    startDmaTransmit(buffer)
##    
##    # After DMA receive (read)
##    waitForDmaComplete()
##    dmaInvalidateCache(buffer)  # Reload cache from SRAM
##    # Now buffer contains DMA-received data
##
## When to Use Each Function
## --------------------------
##
## **Use `dmaClearCache()` before DMA transmit (TX)**:
## - CPU wrote data to buffer
## - About to transmit via DMA (SPI, I2C, UART, etc.)
## - Need to flush CPU cache changes to SRAM
##
## **Use `dmaInvalidateCache()` after DMA receive (RX)**:
## - DMA wrote data to buffer
## - Need to read the data with CPU
## - Need to discard stale cache and reload from SRAM
##
## Complete Example
## ----------------
##
## SPI transmit with DMA:
##
## .. code-block:: nim
##    var txBuffer: array[128, uint8]
##    
##    # CPU prepares data
##    for i in 0..<128:
##      txBuffer[i] = uint8(i)
##    
##    # Flush cache before DMA reads from SRAM
##    dmaClearCache(txBuffer)
##    
##    # Start DMA transfer
##    spi.dmaTransmit(txBuffer.addr, 128)
##    
##    # Wait for completion
##    while spi.isBusy(): discard
##
## SPI receive with DMA:
##
## .. code-block:: nim
##    var rxBuffer: array[128, uint8]
##    
##    # Start DMA transfer
##    spi.dmaReceive(rxBuffer.addr, 128)
##    
##    # Wait for completion
##    while spi.isBusy(): discard
##    
##    # Invalidate cache before CPU reads from buffer
##    dmaInvalidateCache(rxBuffer)
##    
##    # Now safe to read
##    echo "First byte: ", rxBuffer[0]
##
## Performance Notes
## -----------------
##
## - Cache operations are **relatively expensive** (microseconds)
## - **Prefer Option 1** (DMA_BUFFER_MEM_SECTION) when possible
## - Only use manual cache management when necessary
## - Call cache functions **as close as possible** to DMA operations
##
## See Also
## --------
## - `sys/system <system.html>`_ - System initialization and cache config
## - `per/spi <spi.html>`_ - SPI with DMA support
## - `per/i2c <i2c.html>`_ - I2C with DMA support
## - `examples/system_control.nim` - DMA usage examples

import nimphea
import nimphea_macros

useNimpheaModules(dma)

{.push header: "sys/dma.h".}

# ============================================================================
# C Function Wrappers (Low-Level)
# ============================================================================

proc dsy_dma_init*() {.importc: "dsy_dma_init".}
  ## Initialize DMA peripheral (low-level).
  ##
  ## This is called automatically by `System.init()`.
  ## You rarely need to call this directly.
  ##
  ## Initializes DMA controllers used by libDaisy peripherals
  ## (SPI, I2C, UART, SAI, etc.).

proc dsy_dma_deinit*() {.importc: "dsy_dma_deinit".}
  ## Deinitialize DMA peripheral (low-level).
  ##
  ## This is called automatically by `System.deInit()`.
  ## You rarely need to call this directly.

proc dsy_dma_clear_cache_for_buffer*(buffer: ptr uint8, size: csize_t) {.
  importc: "dsy_dma_clear_cache_for_buffer".}
  ## Clear (flush) CPU cache to SRAM for a buffer (low-level).
  ##
  ## **Use before DMA transmit** to ensure SRAM has latest data.
  ##
  ## **Parameters:**
  ## - `buffer` - Pointer to buffer start
  ## - `size` - Buffer size in bytes
  ##
  ## **Note**: Prefer the type-safe `dmaClearCache[T]()` template.
  ##
  ## **Example:**
  ## ```nim
  ## var data: array[64, uint8]
  ## dsy_dma_clear_cache_for_buffer(cast[ptr uint8](data[0].addr), 64)
  ## ```

proc dsy_dma_invalidate_cache_for_buffer*(buffer: ptr uint8, size: csize_t) {.
  importc: "dsy_dma_invalidate_cache_for_buffer".}
  ## Invalidate CPU cache for a buffer, reload from SRAM (low-level).
  ##
  ## **Use after DMA receive** to ensure CPU reads latest data.
  ##
  ## **Parameters:**
  ## - `buffer` - Pointer to buffer start
  ## - `size` - Buffer size in bytes
  ##
  ## **Note**: Prefer the type-safe `dmaInvalidateCache[T]()` template.
  ##
  ## **Example:**
  ## ```nim
  ## var data: array[64, uint8]
  ## dsy_dma_invalidate_cache_for_buffer(cast[ptr uint8](data[0].addr), 64)
  ## ```

{.pop.} # header

# ============================================================================
# Nim Helper Functions (High-Level, Type-Safe)
# ============================================================================

proc dmaInit*() =
  ## Initialize DMA peripheral.
  ##
  ## Nim wrapper for `dsy_dma_init()`. Same functionality, more Nim-friendly name.
  ##
  ## **Note**: Usually called automatically by `System.init()`.
  dsy_dma_init()

proc dmaDeInit*() =
  ## Deinitialize DMA peripheral.
  ##
  ## Nim wrapper for `dsy_dma_deinit()`. Same functionality, more Nim-friendly name.
  ##
  ## **Note**: Usually called automatically by `System.deInit()`.
  dsy_dma_deinit()

template dmaClearCache*[T](buffer: var openArray[T]) =
  ## Clear (flush) CPU cache to SRAM before DMA transmit.
  ##
  ## Type-safe template that automatically calculates buffer size.
  ##
  ## **When to use**:
  ## - CPU wrote data to buffer
  ## - About to transmit via DMA
  ## - Need cache changes written to SRAM
  ##
  ## **Parameters:**
  ## - `buffer` - Array or openArray to flush
  ##
  ## **Example:**
  ## ```nim
  ## var txData: array[256, uint8]
  ## for i in 0..<256: txData[i] = uint8(i)
  ## 
  ## dmaClearCache(txData)  # Flush cache
  ## spi.dmaTransmit(txData.addr, 256)
  ## ```
  ##
  ## **Generic types supported**:
  ## ```nim
  ## var byteArray: array[128, uint8]
  ## var wordArray: array[64, uint16]
  ## var floatArray: array[32, float32]
  ## 
  ## dmaClearCache(byteArray)   # Works
  ## dmaClearCache(wordArray)   # Works
  ## dmaClearCache(floatArray)  # Works
  ## ```
  when buffer.len > 0:
    dsy_dma_clear_cache_for_buffer(
      cast[ptr uint8](buffer[0].addr),
      csize_t(buffer.len * sizeof(T))
    )

template dmaInvalidateCache*[T](buffer: var openArray[T]) =
  ## Invalidate CPU cache after DMA receive, reload from SRAM.
  ##
  ## Type-safe template that automatically calculates buffer size.
  ##
  ## **When to use**:
  ## - DMA wrote data to buffer
  ## - Need to read data with CPU
  ## - Need to discard stale cache
  ##
  ## **Parameters:**
  ## - `buffer` - Array or openArray to invalidate
  ##
  ## **Example:**
  ## ```nim
  ## var rxData: array[256, uint8]
  ## 
  ## spi.dmaReceive(rxData.addr, 256)
  ## while spi.isBusy(): discard
  ## 
  ## dmaInvalidateCache(rxData)  # Reload from SRAM
  ## echo "Received: ", rxData[0]
  ## ```
  ##
  ## **Generic types supported**:
  ## ```nim
  ## var byteArray: array[128, uint8]
  ## var wordArray: array[64, uint16]
  ## var floatArray: array[32, float32]
  ## 
  ## dmaInvalidateCache(byteArray)   # Works
  ## dmaInvalidateCache(wordArray)   # Works
  ## dmaInvalidateCache(floatArray)  # Works
  ## ```
  when buffer.len > 0:
    dsy_dma_invalidate_cache_for_buffer(
      cast[ptr uint8](buffer[0].addr),
      csize_t(buffer.len * sizeof(T))
    )

proc dmaClearCacheFor*(p: pointer, size: int) =
  ## Clear (flush) cache for arbitrary memory region.
  ##
  ## Use when you need fine-grained control over cache operations.
  ##
  ## **Parameters:**
  ## - `p` - Pointer to memory region
  ## - `size` - Size in bytes
  ##
  ## **Example:**
  ## ```nim
  ## type MyStruct = object
  ##   field1: uint32
  ##   field2: array[16, uint8]
  ## 
  ## var data: MyStruct
  ## dmaClearCacheFor(data.addr, sizeof(MyStruct))
  ## ```
  if size > 0:
    dsy_dma_clear_cache_for_buffer(cast[ptr uint8](p), csize_t(size))

proc dmaInvalidateCacheFor*(p: pointer, size: int) =
  ## Invalidate cache for arbitrary memory region.
  ##
  ## Use when you need fine-grained control over cache operations.
  ##
  ## **Parameters:**
  ## - `p` - Pointer to memory region
  ## - `size` - Size in bytes
  ##
  ## **Example:**
  ## ```nim
  ## type MyStruct = object
  ##   field1: uint32
  ##   field2: array[16, uint8]
  ## 
  ## var data: MyStruct
  ## # After DMA receive
  ## dmaInvalidateCacheFor(data.addr, sizeof(MyStruct))
  ## ```
  if size > 0:
    dsy_dma_invalidate_cache_for_buffer(cast[ptr uint8](p), csize_t(size))

# ============================================================================
# Usage Examples
# ============================================================================

when isMainModule:
  ## Compile-time examples (not executable without hardware)
  
  # Example 1: SPI transmit with cache management
  block:
    var txBuffer: array[128, uint8]
    for i in 0..<128:
      txBuffer[i] = uint8(i)
    
    dmaClearCache(txBuffer)  # Flush before DMA reads
    # spi.dmaTransmit(txBuffer.addr, 128)
  
  # Example 2: SPI receive with cache management
  block:
    var rxBuffer: array[128, uint8]
    # spi.dmaReceive(rxBuffer.addr, 128)
    # while spi.isBusy(): discard
    
    dmaInvalidateCache(rxBuffer)  # Reload after DMA writes
    # echo "Data: ", rxBuffer[0]
  
  # Example 3: Different data types
  block:
    var floatData: array[32, float32]
    var wordData: array[64, uint16]
    
    dmaClearCache(floatData)       # Works with float32
    dmaInvalidateCache(wordData)   # Works with uint16
  
  # Example 4: Low-level pointer access
  block:
    type CustomStruct = object
      id: uint32
      values: array[16, uint8]
    
    var data: CustomStruct
    dmaClearCacheFor(data.addr, sizeof(CustomStruct))
