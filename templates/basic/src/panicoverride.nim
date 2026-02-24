## Panic handler for embedded systems (template)
## This overrides Nim's default panic handler for bare metal ARM targets

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  # In embedded systems without a console, you can't reliably print.
  # A real project should implement board-specific behavior here
  # (blink LED, send over serial, etc.). This template leaves it empty.
  discard

proc panic(s: string) {.exportc: "panic", noreturn.} =
  # Halt the system - keep it simple for template projects
  while true:
    discard

{.pop.}
