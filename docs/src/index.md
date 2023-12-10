# Asciicast.jl

Asciicast.jl is all about showcasing Julia code running in a REPL using
technologies developed by the open-source
[asciinema](https://asciinema.org/) project. (It is totally unaffiliated
with the authors of that project, however).

#### Quick example

```@example
using Asciicast
cast"""
    using Pkg
    Pkg.status()
    1 + 1
    """0.25
```

This example creates a [`Cast`](@ref) object using the [`@cast_str`](@ref) macro, which captures the input and the output. Check out [Creating casts](@ref) for more on creating `Cast` objects (or [Cast files](@ref) for a lower level API, if you are interested).

Here, the `Cast` object is being rendered by the javascript [asciinema-player](https://github.com/asciinema/asciinema-player) loaded by Documenter. See [Documenter usage](@ref) for more on that.

Likewise, check out [Markdown usage](@ref) for using Asciicast.jl to generate and maintain gifs of code execution in documents like READMEs.


#### Table of contents

```@contents
Depth = 2:3
Pages = ["index.md", "creating_casts.md", "documenter_usage.md", "markdown_usage.md", "cast_files.md", "limitations.md"]
```
