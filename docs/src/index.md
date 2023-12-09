# Asciicast.jl

```@index
```

## Simple example

```@example
using Asciicast
cast"""
    using Pkg
    Pkg.status()
    1 + 1
    """0.5
```

## `record_output` example

```@example
using Asciicast
record_output() do
    @info "Hello!"
    println("That was a logging statement, but this is printing.")
    x = 1
    x + 1 # does not print anything-- no output!
    @info "here's `x`" x
    println("Now I'll wait a second")
    sleep(1)
    println("ok, done!")
end
```

## Manual example

```@example
using Asciicast
using Asciicast: Header
cast = Cast(IOBuffer(), Header(; height=5))
write_event!(cast, OutputEvent, "hello\n")
write_event!(cast, OutputEvent, "Let us wait...")
sleep(.5)
write_event!(cast, OutputEvent, "\nDone!")
cast
```

## API Reference

```@autodocs
Modules = [Asciicast]
```
