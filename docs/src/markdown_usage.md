## Markdown usage

Asciicast provides facilities for maintaining gifs showcasing package functionality in READMEs, or otherwise adding animated gifs to Julia code blocks in documents.

### `julia {cast="true"}` code blocks

To use functionality, simply add `julia {cast="true"}` code-blocks to your document. For example,

````markdown
```julia {cast="true"}
using Pkg
Pkg.status()
```
````

Then run [`cast_document`](@ref) (or the helper [`cast_readme`](@ref)) on the file. This will turn it into:

````markdown
```julia {cast="true"}
using Pkg
Pkg.status()
```
![](assets/output_1_@cast.gif)
````
and generate a gif in the `assets` directory.

One can also customize the font-size and the delay:

````markdown
```julia {cast="true" font-size=28 delay=0.5}
using Pkg
Pkg.status()
```
````

Note that the attributes must be separated by spaces, not commas, as shown above.

Here, the gifs are generated with [`agg`](https://github.com/asciinema/agg) (which is installed automatically using a JLL package), and the font-size parameter is passed there. Currently no other `agg` parameters are supported, but file an issue if you have a use for one.

### All supported attributes

* `delay::Float64=0.25`. The amount of delay between line executions (to emulate typing time).
* `font-size::Int=28`. Used by `agg` when generating the gif.
* `height::Int`. Heuristically determined by default. Set to an integer to specify the number of lines.
* `allow_errors::Bool=true`. Whether or not [`cast_document`](@ref) (or [`cast_readme`](@ref)) should fail if exceptions are encountered during execution of the block.

### Syntax notes

A note on the syntax. Here we want to ensure that the code snippet continues to get syntax highlighting, but also mark it somehow so we can detect that we want to generate a gif for this snippet. The implementation behind-the-scenes uses pandoc, so we are somewhat limited by what pandoc can support. Here, we are using "attributes" (`{cast="true"}`) so we can keep "julia" as the first "class", so that syntax highlighting still works, while being able to pass `cast="true"` into the pandoc AST so that we can detect it there and generate the gif. I initially tried just `julia-cast` or `julia:@cast` as the language, but GitHub stops providing julia highlighting in that case.

Additionally, I use `@cast` in the output filename, so that future runs can identify `@cast`-generated gifs and remove the image tags, to prevent duplicating them when running `cast_document` again to update the gifs.

### Reference docs

```@docs
Asciicast.cast_readme
Asciicast.cast_document
```
