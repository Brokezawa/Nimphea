## MIDI Demonstration
##
## Demonstrates MIDI input and output functionality:
## - USB MIDI input and output
## - UART MIDI (TRS/DIN) input and output  
## - MIDI message parsing and creation
## - MIDI echo and transformation
##
## Hardware:
## - Daisy Seed
## - USB cable for USB MIDI
## - Optional: TRS MIDI adapter or 5-pin DIN MIDI
##   - UART1 TX (PB6) → MIDI OUT
##   - UART1 RX (PB7) → MIDI IN
##
## Features demonstrated:
## - USB MIDI receive and transmit
## - UART MIDI receive and transmit
## - MIDI message parsing (Note, CC, Program Change, Pitch Bend)
## - MIDI message creation helpers
## - MIDI echo and transformation
##
## Compile-time modes (use -d:mode=<mode>):
## - usb: USB MIDI echo (default)
## - uart: UART MIDI echo
## - usbOut: USB MIDI output test (sends notes)
## - uartOut: UART MIDI output test (sends notes)
## - transform: USB MIDI to UART MIDI transposer

import nimphea
import hid/midi

useNimpheaNamespace()

const MODE = 
  when defined(uart): "uart"
  elif defined(usbOut): "usbOut"
  elif defined(uartOut): "uartOut"
  elif defined(transform): "transform"
  else: "usb"

when MODE == "usb":
  # ==========================================================================
  # Mode 1: USB MIDI Echo
  # ==========================================================================
  ## Echoes received USB MIDI messages back to USB
  ## Demonstrates: USB MIDI input, parsing, and output
  
  proc main() =
    var daisy = initDaisy()
    var midi: MidiUsbHandler
    initMidiUsb(midi)
    
    while true:
      midi.listen()
      
      while midi.hasEvents():
        var event = midi.popEvent()
        
        case event.messageType
        of NoteOn:
          let note = event.note
          # Echo note on back
          let msg = makeMidiNoteOn(event.channel.uint8, note.number, note.velocity)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        of NoteOff:
          let note = event.note
          # Echo note off back
          let msg = makeMidiNoteOff(event.channel.uint8, note.number, note.velocity)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        of ControlChange:
          let cc = event.controlChange
          # Echo CC back
          let msg = makeMidiControlChange(event.channel.uint8, cc.number, cc.value)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        of ProgramChange:
          let program = event.programChange
          # Echo program change back
          let msg = makeMidiProgramChange(event.channel.uint8, program)
          midi.sendMessage(msg[0].unsafeAddr, 2)
        
        of PitchBend:
          let bend = event.pitchBend
          # Echo pitch bend back
          let msg = makeMidiPitchBend(event.channel.uint8, bend)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        else:
          discard
      
      daisy.delay(1)

elif MODE == "uart":
  # ==========================================================================
  # Mode 2: UART MIDI Echo
  # ==========================================================================
  ## Echoes received UART MIDI messages back to UART
  ## Demonstrates: UART MIDI input, parsing, and output
  
  proc main() =
    var daisy = initDaisy()
    var midi: MidiUartHandler
    var config = newMidiUartConfig()
    
    # Configure UART1 pins for MIDI (standard Daisy MIDI pinout)
    config.transport_config.periph = USART_1
    config.transport_config.rx = initPin(PORTB, 7)
    config.transport_config.tx = initPin(PORTB, 6)
    
    initMidiUart(midi, config)
    
    while true:
      midi.listen()
      
      while midi.hasEvents():
        var event = midi.popEvent()
        
        case event.messageType
        of NoteOn:
          let note = event.note
          let msg = makeMidiNoteOn(event.channel.uint8, note.number, note.velocity)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        of NoteOff:
          let note = event.note
          let msg = makeMidiNoteOff(event.channel.uint8, note.number, note.velocity)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        of ControlChange:
          let cc = event.controlChange
          let msg = makeMidiControlChange(event.channel.uint8, cc.number, cc.value)
          midi.sendMessage(msg[0].unsafeAddr, 3)
        
        else:
          discard
      
      daisy.delay(1)

elif MODE == "usbOut":
  # ==========================================================================
  # Mode 3: USB MIDI Output Test
  # ==========================================================================
  ## Sends a sequence of MIDI notes over USB
  ## Demonstrates: USB MIDI output, message creation
  
  proc main() =
    var daisy = initDaisy()
    var midi: MidiUsbHandler
    initMidiUsb(midi)
    
    const notes = [60'u8, 62, 64, 65, 67, 69, 71, 72]  # C major scale
    var noteIdx = 0
    var counter = 0
    
    while true:
      # Send a note every 500ms
      if counter mod 500 == 0:
        # Note off for previous note
        if noteIdx > 0:
          let prevNote = notes[noteIdx - 1]
          let noteOff = makeMidiNoteOff(0, prevNote, 0)
          midi.sendMessage(noteOff[0].unsafeAddr, 3)
        
        # Note on for current note
        let currentNote = notes[noteIdx]
        let noteOn = makeMidiNoteOn(0, currentNote, 100)
        midi.sendMessage(noteOn[0].unsafeAddr, 3)
        
        noteIdx = (noteIdx + 1) mod notes.len
      
      inc counter
      daisy.delay(1)

elif MODE == "uartOut":
  # ==========================================================================
  # Mode 4: UART MIDI Output Test
  # ==========================================================================
  ## Sends a sequence of MIDI notes over UART
  ## Demonstrates: UART MIDI output, message creation
  
  proc main() =
    var daisy = initDaisy()
    var midi: MidiUartHandler
    var config = newMidiUartConfig()
    
    config.transport_config.periph = USART_1
    config.transport_config.rx = initPin(PORTB, 7)
    config.transport_config.tx = initPin(PORTB, 6)
    
    initMidiUart(midi, config)
    
    const notes = [60'u8, 62, 64, 65, 67, 69, 71, 72]  # C major scale
    var noteIdx = 0
    var counter = 0
    
    while true:
      # Send a note every 500ms
      if counter mod 500 == 0:
        # Note off for previous note
        if noteIdx > 0:
          let prevNote = notes[noteIdx - 1]
          let noteOff = makeMidiNoteOff(0, prevNote, 0)
          midi.sendMessage(noteOff[0].unsafeAddr, 3)
        
        # Note on for current note
        let currentNote = notes[noteIdx]
        let noteOn = makeMidiNoteOn(0, currentNote, 100)
        midi.sendMessage(noteOn[0].unsafeAddr, 3)
        
        noteIdx = (noteIdx + 1) mod notes.len
      
      inc counter
      daisy.delay(1)

elif MODE == "transform":
  # ==========================================================================
  # Mode 5: USB to UART MIDI Transposer
  # ==========================================================================
  ## Receives MIDI from USB, transposes notes, and sends to UART
  ## Demonstrates: Dual MIDI handlers, message transformation
  
  proc main() =
    var daisy = initDaisy()
    
    # USB MIDI for input
    var usbMidi: MidiUsbHandler
    initMidiUsb(usbMidi)
    
    # UART MIDI for output
    var uartMidi: MidiUartHandler
    var uartConfig = newMidiUartConfig()
    uartConfig.transport_config.periph = USART_1
    uartConfig.transport_config.rx = initPin(PORTB, 7)
    uartConfig.transport_config.tx = initPin(PORTB, 6)
    initMidiUart(uartMidi, uartConfig)
    
    const TRANSPOSE = 12  # Transpose up one octave
    
    while true:
      usbMidi.listen()
      uartMidi.listen()
      
      while usbMidi.hasEvents():
        var event = usbMidi.popEvent()
        
        case event.messageType
        of NoteOn:
          let note = event.note
          # Transpose note up one octave
          let transposedNote = min(note.number + TRANSPOSE, 127)
          let msg = makeMidiNoteOn(event.channel.uint8, transposedNote.uint8, note.velocity)
          uartMidi.sendMessage(msg[0].unsafeAddr, 3)
        
        of NoteOff:
          let note = event.note
          # Transpose note up one octave
          let transposedNote = min(note.number + TRANSPOSE, 127)
          let msg = makeMidiNoteOff(event.channel.uint8, transposedNote.uint8, note.velocity)
          uartMidi.sendMessage(msg[0].unsafeAddr, 3)
        
        of ControlChange:
          # Pass through control changes unchanged
          let cc = event.controlChange
          let msg = makeMidiControlChange(event.channel.uint8, cc.number, cc.value)
          uartMidi.sendMessage(msg[0].unsafeAddr, 3)
        
        else:
          discard
      
      daisy.delay(1)

when isMainModule:
  main()
