# Asciicast.jl

## Simple example

The string macro [`@cast_str`](@ref) provides a convenient API to construct a [`Cast`](@ref) object:

```@example
using Asciicast
cast"""
    using Pkg
    Pkg.status()
    1 + 1
    """0.5
```

The `Cast` objects have a `show` method defined for HTML, allowing rich display with a local [asciinema player](https://github.com/asciinema/asciinema-player), in Documenter, Pluto, jupyter, etc. For convenient use with Documenter in particular, see the `@cast` syntax in [Documenter usage](@ref).

## `record_output` example

Here only the *outputs* can be captured, as `record_output` is a function, not a macro.

```@example
using Asciicast
record_output(; height=10) do
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

## `Cast` objects and a manual example

Asciicast provides a type [`Cast`](@ref) which can be used for constructing asciicast v2 files. The most low-level interface is to use manual [`write_event!`](@ref) calls as follows:

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

Such a `Cast` can be saved to a `.cast` file using [`Asciicast.save`](@ref). These files are JSON lines files, which can be read with `JSON3.read` with the `jsonlines=true` keyword argument. They can also be parsed with [`Asciicast.parse_cast`](@ref). They can be played in the terminal or uploaded to <asciinema.org> with [asciinema](https://github.com/asciinema/asciinema), and converted to gifs with [agg](https://github.com/asciinema/agg). Note that Asciicast.jl does not upload or embed any casts, using a local player instead.

## API Reference

```@index
```

```@autodocs
Modules = [Asciicast]
```
