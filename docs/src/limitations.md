## Limitations

The approach used in Asciicast.jl has some limitations, and for some use cases it may be better to use the command-line tool [asciinema](https://asciinema.org/docs/getting-started) directly.

### Cannot use keyboard input

Since Asciicast.jl works by running short Julia scripts and capturing the inputs and outputs, one cannot use keyboard input to direct what runs. This makes it hard to capture things like terminal menus and other UI which requires input via Asciicast.jl.

### Cannot rely on `stdout` (or `stderr`) in one line being still `open` in the next

This is an [Documenter limitation](https://github.com/JuliaDocs/Documenter.jl/issues/1580#issuecomment-1849121475) which also affects Asciicast, both in `@cast` blocks in Documenter, as well as in the [`@cast_str`](@ref) and gifs generated via [`cast_document`](@ref). For example, in the code
```julia
using ProgressMeter
prog = ProgressThresh(1e-5; desc="Minimizing:")
for val in exp10.(range(2, stop=-6, length=20))
    update!(prog, val)
    sleep(0.1)
end
```
`prog` implicitly captures `stdout` inside the `ProgressThresh` object. However, the way this code is processed is basically one "block" at a time (the same as the REPL works). But each block is given a different `stdout` object (in order to capture it's outputs individually) which is closed at the end of the execution that block. That is, `prog = ProgressThresh(1e-5; desc="Minimizing:")` gets a stdout, which is then closed before the `for`-loop runs. Then `update!` in the for-loop tries to write to this stdout, which has already been closed.

One workaround here is to use a `begin` or `let` block, to group lines that need to share access to the `stdout` object:

```@cast
using ProgressMeter
begin
prog = ProgressThresh(1e-5; desc="Minimizing:")
for val in exp10.(range(2, stop=-6, length=20))
    update!(prog, val)
    sleep(0.1)
end
end
```

### Limited emoji support in gifs

This is an [agg](https://github.com/asciinema/agg#emoji) limitation[^1]. Currently, emojis are only supported if you install the font [Noto Emoji](https://fonts.google.com/noto/specimen/Noto+Emoji), and they are monochrome only (not color).

[^1]: In fact, this is an [even further upstream issue](https://github.com/asciinema/agg/issues/28#issuecomment-1490383327) in the renderers used by `agg`.

## Non-limitations

### ANSI escape codes do work properly

Tools like ProgressMeter.jl use escape codes so modify the terminal state so that the progress meter overwrites itself. This isn't compatible with standard `@repl` blocks:

```@repl
using ProgressMeter
@showprogress dt=0.1 desc="Computing..." for i in 1:10
    sleep(0.1)
end
```

But it does tend to work with `@cast` blocks and other Asciicast constructs:

```@cast; height=10, delay=0, loop=true
using ProgressMeter
@showprogress dt=0.1 desc="Computing..." for i in 1:10
    sleep(0.1)
end
```
