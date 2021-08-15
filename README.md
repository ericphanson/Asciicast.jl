# Asciicast

Asciicast.jl is a Julia package for recording Julia sessions into the `asciicast` v2 file format, <https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md>.

Asciicast provides a type `Cast` which can be used for constructing asciicast v2 files, for example:
```julia
using Asciicast
cast = Cast("example.cast")
write_event!(cast, OutputEvent, "hello\n")
write_event!(cast, OutputEvent, "Let us wait...")
sleep(.5)
write_event!(cast, OutputEvent, "\nDone!")
```
This produces the file [example.cast](./example.cast).
These `.cast` files can be used a couple different ways.

They can rendered into ".gif"s via [asciicast2gif](https://github.com/asciinema/asciicast2gif). For example,
this simple example becomes:

![](example.gif)

This is useful for READMEs in GitHub since fancier web technologies like Javascript is not supported. In a richer environment, an
[asciinema-player](https://github.com/asciinema/asciinema-player) can be embedded to play the cast.

Asciicast.jl also provides an `@gif` block for Documenter.jl, which can be used like
an `@repl` block, except instead of printing the output after each line, it collects the output and generates
an asciicast file. Then it produces an inline HTML player via
asciinema-player.

This feature requires the necessary JS and CSS files are added to `assets` in `makedocs`. See [docs/make.jl](docs/make.jl) for an example.

## Note

This package is unregistered and experimental, and there are currently no tests.
