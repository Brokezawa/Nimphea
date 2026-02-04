## MIDI support for libDaisy Nim wrapper
##
## This module provides MIDI functionality for the Daisy Audio Platform.
##
## Example - USB MIDI input:
## ```nim
## import nimphea, hid/midi, per/uart
## 
## var daisy = initDaisy()
## var midi: MidiUsbHandler
## initMidiUsb(midi)
## 
## startLog()
## printLine("MIDI Input Started")
## 
## while true:
##   midi.listen()
##   
##   while midi.hasEvents:
##     let event = midi.popEvent()
##     
##     case event.messageType
##     of NoteOn:
##       let note = event.note
##       print("Note On: ")
##       print(note.number)
##       print(" Vel: ")
##       printLine(note.velocity)
##     
##     of NoteOff:
##       let note = event.note
##       print("Note Off: ")
##       printLine(note.number)
##     
##     of ControlChange:
##       let cc = event.controlChange
##       print("CC ")
##       print(cc.number)
##       print(": ")
##       printLine(cc.value)
##     
##     else: discard
##   
##   daisy.delay(1)
## ```
##
## Example - UART MIDI with output (TRS/DIN MIDI):
## ```nim
## import nimphea, hid/midi
## 
## var daisy = initDaisy()
## var midi: MidiUartHandler
## var config = newMidiUartConfig()
## config.transport_config.periph = USART_1
## config.transport_config.rx = initPin(PIN_PORTB, 7)
## config.transport_config.tx = initPin(PIN_PORTB, 6)
## initMidiUart(midi, config)
## 
## # Send a note on message
## var noteOn = [0x90'u8, 60, 100]  # Channel 1, note C4, velocity 100
## midi.sendMessage(noteOn[0].addr, 3)
## 
## # Receive and echo messages
## while true:
##   midi.listen()
##   while midi.hasEvents:
##     let event = midi.popEvent()
##     # Process or echo the event
## ```

# Import libdaisy which provides the macro system
import nimphea

# Use the macro system for this module's compilation unit
useNimpheaModules(midi)

{.push header: "hid/midi.h".}

type
  MidiEvent* {.importcpp: "daisy::MidiEvent", bycopy.} = object
    mType* {.importcpp: "type".}: MidiMessageType
    channel* {.importcpp: "channel".}: cint
    data* {.importcpp: "data".}: array[2, uint8]
  
  MidiMessageType* {.importcpp: "daisy::MidiMessageType", size: sizeof(cint).} = enum
    NoteOff
    NoteOn
    PolyphonicKeyPressure
    ControlChange
    ProgramChange
    ChannelPressure
    PitchBend
    SystemCommon
    SystemRealTime

  # USB MIDI Transport
  MidiUsbTransport* {.importcpp: "daisy::MidiUsbTransport".} = object
  MidiUsbHandler* {.importcpp: "daisy::MidiHandler<daisy::MidiUsbTransport>".} = object
  MidiUsbHandlerConfig* {.importcpp: "daisy::MidiHandler<daisy::MidiUsbTransport>::Config", bycopy.} = object

  # UART MIDI Transport (for TRS/DIN MIDI)
  MidiUartTransport* {.importcpp: "daisy::MidiUartTransport".} = object
  MidiUartHandler* {.importcpp: "daisy::MidiUartHandler".} = object
  MidiUartHandlerConfig* {.importcpp: "daisy::MidiUartHandler::Config", bycopy.} = object
    transport_config* {.importcpp: "transport_config".}: MidiUartTransportConfig
  
  MidiUartTransportConfig* {.importcpp: "daisy::MidiUartTransport::Config", bycopy.} = object
    periph* {.importcpp: "periph".}: UartPeriph
    rx* {.importcpp: "rx".}: Pin
    tx* {.importcpp: "tx".}: Pin
    rx_buffer* {.importcpp: "rx_buffer".}: ptr uint8
    rx_buffer_size* {.importcpp: "rx_buffer_size".}: csize_t
  
  # UART types (from per/uart.h)
  UartPeriph* {.importcpp: "daisy::UartHandler::Config::Peripheral", size: sizeof(cint).} = enum
    USART_1
    USART_2
    USART_3
    UART_4
    UART_5
    USART_6
    UART_7
    UART_8
    LPUART_1
  
  # Pin and GPIO types (from daisy_core.h)
  GPIOPort* {.importcpp: "daisy::GPIOPort", size: sizeof(cint).} = enum
    PORTA = 0
    PORTB = 1
    PORTC = 2
    PORTD = 3
    PORTE = 4
    PORTF = 5
    PORTG = 6
    PORTH = 7
    PORTI = 8
    PORTJ = 9
    PORTK = 10
    PORTX = 255  # Invalid port
  
  Pin* {.importcpp: "daisy::Pin", bycopy.} = object
    port* {.importcpp: "port".}: GPIOPort
    pin* {.importcpp: "pin".}: uint8

# Helper constructor for Pin
proc initPin*(port: GPIOPort, pin: uint8): Pin {.importcpp: "daisy::Pin(@)", constructor.}

# Low-level C++ interface - USB MIDI
proc Listen(this: var MidiUsbHandler) {.importcpp: "#.Listen()".}
proc HasEvents(this: var MidiUsbHandler): bool {.importcpp: "#.HasEvents()".}
proc PopEvent(this: var MidiUsbHandler): MidiEvent {.importcpp: "#.PopEvent()".}
proc Init(this: var MidiUsbHandler, config: MidiUsbHandlerConfig) {.importcpp: "#.Init(@)".}
proc StartReceive(this: var MidiUsbHandler) {.importcpp: "#.StartReceive()".}
proc SendMessage(this: var MidiUsbHandler, bytes: ptr uint8, size: csize_t) {.importcpp: "#.SendMessage(@)".}

# Low-level C++ interface - UART MIDI
proc Listen(this: var MidiUartHandler) {.importcpp: "#.Listen()".}
proc HasEvents(this: var MidiUartHandler): bool {.importcpp: "#.HasEvents()".}
proc PopEvent(this: var MidiUartHandler): MidiEvent {.importcpp: "#.PopEvent()".}
proc Init(this: var MidiUartHandler, config: MidiUartHandlerConfig) {.importcpp: "#.Init(@)".}
proc StartReceive(this: var MidiUartHandler) {.importcpp: "#.StartReceive()".}
proc SendMessage(this: var MidiUartHandler, bytes: ptr uint8, size: csize_t) {.importcpp: "#.SendMessage(@)".}

# C++ constructors
proc newMidiUsbConfig*(): MidiUsbHandlerConfig {.importcpp: "daisy::MidiHandler<daisy::MidiUsbTransport>::Config()", constructor.}
proc newMidiUartConfig*(): MidiUartHandlerConfig {.importcpp: "daisy::MidiUartHandler::Config()", constructor.}
proc newMidiUartTransportConfig*(): MidiUartTransportConfig {.importcpp: "daisy::MidiUartTransport::Config()", constructor.}

{.pop.} # header

# Create alias for backward compatibility
type MidiHandler* = MidiUsbHandler

# =============================================================================
# High-Level Nim-Friendly API
# =============================================================================

type
  NoteEvent* = object
    number*: uint8
    velocity*: uint8
  
  ControlChangeEvent* = object
    number*: uint8
    value*: uint8

# =============================================================================
# USB MIDI API
# =============================================================================

proc initMidiUsb*(midi: var MidiUsbHandler) =
  ## Initialize MIDI handler for USB MIDI
  ## 
  ## Usage:
  ## ```nim
  ## var midi: MidiUsbHandler
  ## initMidiUsb(midi)
  ## ```
  var cfg: MidiUsbHandlerConfig  # Default constructor
  midi.Init(cfg)
  midi.StartReceive()

proc initMidi*(midi: var MidiUsbHandler) =
  ## Backward-compatible alias for initMidiUsb
  ## 
  ## **Deprecated**: Use `initMidiUsb()` for clarity
  initMidiUsb(midi)

proc listen*(midi: var MidiUsbHandler) {.inline.} =
  ## Process incoming USB MIDI data (call this regularly in your loop)
  midi.Listen()

proc hasEvents*(midi: var MidiUsbHandler): bool {.inline.} =
  ## Check if there are any USB MIDI events waiting
  result = midi.HasEvents()

proc popEvent*(midi: var MidiUsbHandler): MidiEvent {.inline.} =
  ## Get the next USB MIDI event from the queue
  result = midi.PopEvent()

proc sendMessage*(midi: var MidiUsbHandler, bytes: ptr uint8, size: int) {.inline.} =
  ## Send raw MIDI bytes over USB
  ##
  ## Parameters:
  ##   bytes: Pointer to MIDI message bytes
  ##   size: Number of bytes to send
  ##
  ## Example:
  ## ```nim
  ## # Send note on: channel 1, note 60 (C4), velocity 100
  ## var noteOn = [0x90'u8, 60, 100]
  ## midi.sendMessage(noteOn[0].addr, 3)
  ## 
  ## # Send note off
  ## var noteOff = [0x80'u8, 60, 0]
  ## midi.sendMessage(noteOff[0].addr, 3)
  ## ```
  midi.SendMessage(bytes, size.csize_t)

# =============================================================================
# UART MIDI API (for TRS/DIN MIDI)
# =============================================================================

proc initMidiUart*(midi: var MidiUartHandler, config: MidiUartHandlerConfig) =
  ## Initialize MIDI handler for UART (TRS/DIN) MIDI
  ## 
  ## Usage:
  ## ```nim
  ## var midi: MidiUartHandler
  ## var config = newMidiUartConfig()
  ## 
  ## # Configure UART pins (example for USART1)
  ## config.transport_config.periph = USART_1
  ## config.transport_config.rx = initPin(PIN_PORTB, 7)
  ## config.transport_config.tx = initPin(PIN_PORTB, 6)
  ## 
  ## initMidiUart(midi, config)
  ## ```
  midi.Init(config)
  midi.StartReceive()

proc listen*(midi: var MidiUartHandler) {.inline.} =
  ## Process incoming UART MIDI data (call this regularly in your loop)
  ## 
  ## Note: This also handles UART error recovery
  midi.Listen()

proc hasEvents*(midi: var MidiUartHandler): bool {.inline.} =
  ## Check if there are any UART MIDI events waiting
  result = midi.HasEvents()

proc popEvent*(midi: var MidiUartHandler): MidiEvent {.inline.} =
  ## Get the next UART MIDI event from the queue
  result = midi.PopEvent()

proc sendMessage*(midi: var MidiUartHandler, bytes: ptr uint8, size: int) {.inline.} =
  ## Send raw MIDI bytes over UART (TRS/DIN MIDI)
  ##
  ## Parameters:
  ##   bytes: Pointer to MIDI message bytes
  ##   size: Number of bytes to send
  ##
  ## Example:
  ## ```nim
  ## # Send note on: channel 1, note 60 (C4), velocity 100
  ## var noteOn = [0x90'u8, 60, 100]
  ## midi.sendMessage(noteOn[0].addr, 3)
  ## 
  ## # Send control change: channel 1, CC 7 (volume), value 127
  ## var cc = [0xB0'u8, 7, 127]
  ## midi.sendMessage(cc[0].addr, 3)
  ## ```
  midi.SendMessage(bytes, size.csize_t)

# =============================================================================
# Common Helper Functions (work with both USB and UART)
# =============================================================================

# MidiEvent helper properties - access C++ fields directly
proc messageType*(event: MidiEvent): MidiMessageType {.importcpp: "#.type", nodecl.}
proc channel*(event: MidiEvent): cint {.importcpp: "#.channel", nodecl.}

proc note*(event: var MidiEvent): NoteEvent {.inline.} =
  ## Parse as note event (for NoteOn/NoteOff messages)
  result.number = event.data[0]
  result.velocity = event.data[1]

proc controlChange*(event: var MidiEvent): ControlChangeEvent {.inline.} =
  ## Parse as control change event
  result.number = event.data[0]
  result.value = event.data[1]

proc pitchBend*(event: var MidiEvent): int16 {.inline.} =
  ## Parse as pitch bend (-8192 to +8191)
  let lsb = event.data[0]
  let msb = event.data[1]
  result = ((msb.int16 shl 7) or lsb.int16) - 8192

proc programChange*(event: var MidiEvent): uint8 {.inline.} =
  ## Parse as program change (0-127)
  result = event.data[0]

proc channelPressure*(event: var MidiEvent): uint8 {.inline.} =
  ## Parse as channel pressure (0-127)
  result = event.data[0]

# =============================================================================
# MIDI Message Builder Helpers
# =============================================================================

proc makeMidiNoteOn*(channel: uint8, note: uint8, velocity: uint8): array[3, uint8] {.inline.} =
  ## Create a MIDI Note On message
  ##
  ## Parameters:
  ##   channel: MIDI channel (0-15, where 0 = channel 1)
  ##   note: Note number (0-127, where 60 = C4)
  ##   velocity: Note velocity (1-127, 0 is treated as note off)
  ##
  ## Returns:
  ##   3-byte array containing the MIDI message
  ##
  ## Example:
  ## ```nim
  ## let noteOn = makeMidiNoteOn(0, 60, 100)  # Channel 1, C4, velocity 100
  ## midi.sendMessage(noteOn[0].unsafeAddr, 3)
  ## ```
  result[0] = 0x90 or (channel and 0x0F)
  result[1] = note and 0x7F
  result[2] = velocity and 0x7F

proc makeMidiNoteOff*(channel: uint8, note: uint8, velocity: uint8 = 0): array[3, uint8] {.inline.} =
  ## Create a MIDI Note Off message
  ##
  ## Parameters:
  ##   channel: MIDI channel (0-15, where 0 = channel 1)
  ##   note: Note number (0-127)
  ##   velocity: Release velocity (0-127, default 0)
  ##
  ## Returns:
  ##   3-byte array containing the MIDI message
  result[0] = 0x80 or (channel and 0x0F)
  result[1] = note and 0x7F
  result[2] = velocity and 0x7F

proc makeMidiControlChange*(channel: uint8, ccNumber: uint8, value: uint8): array[3, uint8] {.inline.} =
  ## Create a MIDI Control Change message
  ##
  ## Parameters:
  ##   channel: MIDI channel (0-15, where 0 = channel 1)
  ##   ccNumber: Controller number (0-127)
  ##   value: Controller value (0-127)
  ##
  ## Returns:
  ##   3-byte array containing the MIDI message
  result[0] = 0xB0 or (channel and 0x0F)
  result[1] = ccNumber and 0x7F
  result[2] = value and 0x7F

proc makeMidiProgramChange*(channel: uint8, program: uint8): array[2, uint8] {.inline.} =
  ## Create a MIDI Program Change message
  ##
  ## Parameters:
  ##   channel: MIDI channel (0-15, where 0 = channel 1)
  ##   program: Program number (0-127)
  ##
  ## Returns:
  ##   2-byte array containing the MIDI message
  result[0] = 0xC0 or (channel and 0x0F)
  result[1] = program and 0x7F

proc makeMidiPitchBend*(channel: uint8, value: int16): array[3, uint8] {.inline.} =
  ## Create a MIDI Pitch Bend message
  ##
  ## Parameters:
  ##   channel: MIDI channel (0-15, where 0 = channel 1)
  ##   value: Pitch bend value (-8192 to +8191, where 0 is center)
  ##
  ## Returns:
  ##   3-byte array containing the MIDI message
  let unsigned = (value + 8192).uint16  # Convert to 0-16383 range
  result[0] = 0xE0 or (channel and 0x0F)
  result[1] = (unsigned and 0x7F).uint8  # LSB
  result[2] = ((unsigned shr 7) and 0x7F).uint8  # MSB

when isMainModule:
  echo "libDaisy MIDI wrapper - USB and UART MIDI with output support"
