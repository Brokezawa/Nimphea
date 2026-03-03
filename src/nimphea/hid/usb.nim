## libDaisy USB - Nim wrapper for USB functionality
## 
## This module provides Nim bindings for USB Device (CDC) and USB Host functionality
## in libDaisy. It supports USB CDC (Communication Device Class) for serial communication
## over USB, USB MIDI transport, and USB Host for Mass Storage Devices.
##
## USB Device (CDC) Example:
## ```nim
## import nimphea/hid/usb
## 
## var usb = newUsbHandle()
## 
## proc usbReceiveCallback(buffer: ptr uint8, len: ptr uint32) {.cdecl.} =
##   echo "Received ", len[], " bytes"
## 
## usb.init(FS_INTERNAL)
## usb.setReceiveCallback(usbReceiveCallback, FS_INTERNAL)
## 
## var data = "Hello USB\n"
## discard usb.transmitInternal(cast[ptr uint8](addr data[0]), data.len.csize_t)
## ```
##
## USB MIDI Transport Example:
## ```nim
## import nimphea/hid/usb
## 
## var midiUsb = newMidiUsbTransport()
## var config = MidiUsbTransportConfig()
## config.periph = MIDI_USB_INTERNAL
## config.txRetryCount = 3
## 
## proc midiRxCallback(data: ptr uint8, size: csize_t, context: pointer) {.cdecl.} =
##   echo "Received MIDI data: ", size, " bytes"
## 
## midiUsb.init(config)
## midiUsb.startRx(midiRxCallback, nil)
## ```
##
## USB Host Example:
## ```nim
## import nimphea/hid/usb
## 
## var usbHost = newUSBHostHandle()
## var config = USBHostConfig()
## 
## proc onConnect(data: pointer) {.cdecl.} =
##   echo "USB device connected"
## 
## proc onDisconnect(data: pointer) {.cdecl.} =
##   echo "USB device disconnected"
## 
## proc onClassActive(data: pointer) {.cdecl.} =
##   echo "USB class initialized"
## 
## config.connectCallback = onConnect
## config.disconnectCallback = onDisconnect
## config.classActiveCallback = onClassActive
## 
## discard usbHost.init(config)
## 
## while true:
##   discard usbHost.process()
##   if usbHost.getReady():
##     echo "USB Host ready: ", usbHost.getProductName()
## ```

import nimphea/nimphea_macros

useNimpheaModules(usb, usb_midi, usb_host)

{.push header: "hid/usb.h".}

type
  # USB Device (CDC) types

  UsbResult* {.importcpp: "daisy::UsbHandle::Result", size: sizeof(cint).} = enum
    USB_OK = 0
    USB_ERR
  
  UsbPeriph* {.importcpp: "daisy::UsbHandle::UsbPeriph", size: sizeof(cint).} = enum
    FS_INTERNAL = 0  ## Internal USB pin
    FS_EXTERNAL      ## External USB pins (D+ on Pin 38/GPIO32, D- on Pin 37/GPIO31)
    FS_BOTH          ## Both internal and external
  
  UsbReceiveCallback* = proc(buff: ptr uint8, len: ptr uint32) {.cdecl.}
  
  UsbHandle* {.importcpp: "daisy::UsbHandle".} = object

# UsbHandle methods
proc init*(this: var UsbHandle, dev: UsbPeriph) {.importcpp: "#.Init(@)", header: "hid/usb.h".}
proc deInit*(this: var UsbHandle, dev: UsbPeriph) {.importcpp: "#.DeInit(@)", header: "hid/usb.h".}
proc transmitInternal*(this: var UsbHandle, buff: ptr uint8, size: csize_t): UsbResult {.importcpp: "#.TransmitInternal(@)", header: "hid/usb.h".}
proc transmitExternal*(this: var UsbHandle, buff: ptr uint8, size: csize_t): UsbResult {.importcpp: "#.TransmitExternal(@)", header: "hid/usb.h".}
proc setReceiveCallback*(this: var UsbHandle, cb: UsbReceiveCallback, dev: UsbPeriph) {.importcpp: "#.SetReceiveCallback(@)", header: "hid/usb.h".}

{.pop.} # header

# USB MIDI Transport
{.push header: "hid/usb_midi.h".}

type
  MidiUsbPeriph* {.importcpp: "daisy::MidiUsbTransport::Config::Periph", size: sizeof(cint).} = enum
    MIDI_USB_INTERNAL = 0
    MIDI_USB_EXTERNAL
    MIDI_USB_HOST
  
  MidiRxParseCallback* = proc(data: ptr uint8, size: csize_t, context: pointer) {.cdecl.}
  
  MidiUsbTransportConfig* {.importcpp: "daisy::MidiUsbTransport::Config".} = object
    periph* {.importc: "periph".}: MidiUsbPeriph
    txRetryCount* {.importc: "tx_retry_count".}: uint8
  
  MidiUsbTransport* {.importcpp: "daisy::MidiUsbTransport".} = object

# MidiUsbTransport methods
proc init*(this: var MidiUsbTransport, config: MidiUsbTransportConfig) {.importcpp: "#.Init(@)", header: "hid/usb_midi.h".}
proc startRx*(this: var MidiUsbTransport, callback: MidiRxParseCallback, context: pointer) {.importcpp: "#.StartRx(@)", header: "hid/usb_midi.h".}
proc rxActive*(this: var MidiUsbTransport): bool {.importcpp: "#.RxActive()", header: "hid/usb_midi.h".}
proc flushRx*(this: var MidiUsbTransport) {.importcpp: "#.FlushRx()", header: "hid/usb_midi.h".}
proc tx*(this: var MidiUsbTransport, buffer: ptr uint8, size: csize_t) {.importcpp: "#.Tx(@)", header: "hid/usb_midi.h".}

{.pop.} # header

# USB Host
{.push header: "hid/usb_host.h".}

type
  USBHostResult* {.importcpp: "daisy::USBHostHandle::Result", size: sizeof(cint).} = enum
    USBH_OK = 0
    USBH_BUSY
    USBH_FAIL
    USBH_NOT_SUPPORTED
    USBH_UNRECOVERED_ERROR
    USBH_ERROR_SPEED_UNKNOWN
  
  USBHostConnectCallback* = proc(data: pointer) {.cdecl.}
  USBHostDisconnectCallback* = proc(data: pointer) {.cdecl.}
  USBHostClassActiveCallback* = proc(userdata: pointer) {.cdecl.}
  USBHostErrorCallback* = proc(data: pointer) {.cdecl.}
  
  USBHostConfig* {.importcpp: "daisy::USBHostHandle::Config".} = object
    connectCallback* {.importc: "connect_callback".}: USBHostConnectCallback
    disconnectCallback* {.importc: "disconnect_callback".}: USBHostDisconnectCallback
    classActiveCallback* {.importc: "class_active_callback".}: USBHostClassActiveCallback
    errorCallback* {.importc: "error_callback".}: USBHostErrorCallback
    userdata* {.importc: "userdata".}: pointer
  
  USBHostHandle* {.importcpp: "daisy::USBHostHandle".} = object
  
  # Forward declaration for USB class typedef (opaque)
  USBHClassTypeDef* {.importcpp: "USBH_ClassTypeDef".} = object

# USBHostHandle methods
proc init*(this: var USBHostHandle, config: var USBHostConfig): USBHostResult {.importcpp: "#.Init(@)", header: "hid/usb_host.h".}
proc deinit*(this: var USBHostHandle): USBHostResult {.importcpp: "#.Deinit()", header: "hid/usb_host.h".}
proc registerClass*(this: var USBHostHandle, pClass: ptr USBHClassTypeDef): USBHostResult {.importcpp: "#.RegisterClass(@)", header: "hid/usb_host.h".}
proc isActiveClass*(this: var USBHostHandle, usbClass: ptr USBHClassTypeDef): bool {.importcpp: "#.IsActiveClass(@)", header: "hid/usb_host.h".}
proc process*(this: var USBHostHandle): USBHostResult {.importcpp: "#.Process()", header: "hid/usb_host.h".}
proc reEnumerate*(this: var USBHostHandle): USBHostResult {.importcpp: "#.ReEnumerate()", header: "hid/usb_host.h".}
proc getReady*(this: var USBHostHandle): bool {.importcpp: "#.GetReady()", header: "hid/usb_host.h".}
proc getPresent*(this: var USBHostHandle): bool {.importcpp: "#.GetPresent()", header: "hid/usb_host.h".}
proc getProductName*(this: var USBHostHandle): cstring {.importcpp: "#.GetProductName()", header: "hid/usb_host.h".}
proc isPortEnabled*(this: var USBHostHandle): bool {.importcpp: "#.IsPortEnabled()", header: "hid/usb_host.h".}
proc isDeviceConnected*(this: var USBHostHandle): bool {.importcpp: "#.IsDeviceConnected()", header: "hid/usb_host.h".}

{.pop.} # header

# Nim-friendly constructors
proc newUsbHandle*(): UsbHandle {.importcpp: "daisy::UsbHandle()", constructor, header: "hid/usb.h".}
proc newMidiUsbTransport*(): MidiUsbTransport {.importcpp: "daisy::MidiUsbTransport()", constructor, header: "hid/usb_midi.h".}
proc newUSBHostHandle*(): USBHostHandle {.importcpp: "daisy::USBHostHandle()", constructor, header: "hid/usb_host.h".}

# Helper procs for MidiUsbTransportConfig initialization
proc newMidiUsbTransportConfig*(): MidiUsbTransportConfig {.importcpp: "daisy::MidiUsbTransport::Config()", constructor, header: "hid/usb_midi.h".}

# Helper procs for USBHostConfig initialization
proc newUSBHostConfig*(): USBHostConfig {.importcpp: "daisy::USBHostHandle::Config()", constructor, header: "hid/usb_host.h".}

# Convenience procs for transmitting data
proc transmitInternal*(this: var UsbHandle, data: cstring): UsbResult =
  ## Transmit a C string via internal USB
  result = this.transmitInternal(cast[ptr uint8](data), data.len.csize_t)

proc transmitExternal*(this: var UsbHandle, data: cstring): UsbResult =
  ## Transmit a C string via external USB
  result = this.transmitExternal(cast[ptr uint8](data), data.len.csize_t)

proc transmitInternal*(this: var UsbHandle, data: openArray[byte]): UsbResult =
  ## Transmit a byte array via internal USB
  if data.len == 0:
    return USB_OK
  result = this.transmitInternal(cast[ptr uint8](addr data[0]), data.len.csize_t)

proc transmitExternal*(this: var UsbHandle, data: openArray[byte]): UsbResult =
  ## Transmit a byte array via external USB
  if data.len == 0:
    return USB_OK
  result = this.transmitExternal(cast[ptr uint8](addr data[0]), data.len.csize_t)

proc tx*(this: var MidiUsbTransport, buffer: openArray[byte]) =
  ## Transmit MIDI data from a byte array
  if buffer.len == 0:
    return
  this.tx(cast[ptr uint8](addr buffer[0]), buffer.len.csize_t)

when isMainModule:
  echo "libDaisy USB wrapper"
  echo "Supports:"
  echo "  - USB Device CDC (Communication Device Class)"
  echo "  - USB MIDI Transport"
  echo "  - USB Host (Mass Storage, MIDI)"
  echo ""
  echo "Import this module to use USB functionality with Daisy"
