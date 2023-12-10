## Creating casts

### the `@cast_str` macro

The string macro [`@cast_str`](@ref) provides a convenient API to construct a [`Cast`](@ref) object:

```@example
using Asciicast
cast"""
    using Pkg
    Pkg.status()
    1 + 1
    """0.5
```

The `Cast` objects have a `show` method defined for HTML, allowing rich display with a local [asciinema-player](https://github.com/asciinema/asciinema-player), in Documenter, Pluto, jupyter, etc. For convenient use with Documenter in particular, see the `@cast` syntax in [Documenter usage](@ref). Note that this player needs the asciinema-player javascript and CSS assets to be loaded.

They can be saved to a `.cast` file using [`Asciicast.save`](@ref) or saved to a gif using [`Asciicast.save_gif`](@ref). See also [Markdown usage](@ref) for easier integration into READMEs and other documents.

```@docs
@cast_str
```

### `record_output`

Here only the *outputs* can be captured, as [`record_output`](@ref) is a function, not a macro.

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

This likewise produces a `Cast` object. You can provide a filename to have it save the results directly to that file.

```@docs
Asciicast.record_output
```

### `Cast` objects and a manual example

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

See also: [Cast files](@ref).

```@docs
Cast
write_event!
```
### Saving outputs

[`Cast`](@ref) objects (whether created via [`@cast_str`](@ref), [`record_output`](@ref), or manual construction with [`Cast`](@ref) and [`write_event!`](@ref)) can be saved to `.cast` files with [`Asciicast.save`](@ref) or to gifs with [`Asciicast.save_gif`](@ref). Additionally, [`Asciicast.save_code_gif`](@ref) provides a shortcut to create a `Cast` object from code and save it to a gif in one go.

```@docs
Asciicast.save
Asciicast.save_gif
Asciicast.save_code_gif
```
