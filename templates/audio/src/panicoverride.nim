## Panic handler for embedded audio projects (template)

{.push stack_trace: off, profiler:off.}

proc rawoutput(s: string) =
  # Template panic override: intentionally minimal.
  discard

proc panic(s: string) {.exportc: "panic", noreturn.} =
  while true:
    discard

{.pop.}
