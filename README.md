# Asciicast

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ericphanson.github.io/Asciicast.jl/dev)[![codecov](https://codecov.io/gh/ericphanson/Asciicast.jl/graph/badge.svg?token=0ZK1A45AQ0)](https://codecov.io/gh/ericphanson/Asciicast.jl)

Asciicast.jl is all about showcasing Julia code running in a REPL using
technologies developed by the open-source
[asciinema](https://asciinema.org/) project. (It is totally unaffiliated
with the authors of that project, however).

It does so in a few ways:

- provides a convenient way to generate and maintain gifs showing code
  execution in READMEs and other documents. See the [Markdown
  Usage](https://ericphanson.github.io/Asciicast.jl/dev/markdown_usage/)
  portion of the docs.
- provides integration with Documenter, providing `@cast` Documenter
  blocks that render code outputs as gifs in Documenter websites. See
  the [Documenter
  Usage](https://ericphanson.github.io/Asciicast.jl/dev/documenter_usage/)
  portion of the docs.
- provides functionality to generate `asciicast` files (using the [v2
  file
  format](https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md))
  from Julia code, using the `cast""` string macro, a `record_output`
  function, or using low-level `write_event` commands. These files can
  be played in the terminal or uploaded to asciinema.org with the
  `asciinema` player, or played in a web browser using
  [asciinema-player](https://github.com/asciinema/asciinema-player). See
  the [docs](https://ericphanson.github.io/Asciicast.jl/dev/) for more.

Demo:

```julia {cast="true"}
@info "Hello!"
println("That was a logging statement, but this is printing.")
x = rand(10, 10)
using LinearAlgebra
svd(x)
println("Now I'll wait a second")
sleep(1)
println("ok, done!")
```

![](assets/output_1_@cast.gif)
