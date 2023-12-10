## Markdown usage

Asciicast provides facilities for maintaining gifs showcasing package functionality in READMEs, or otherwise adding animated gifs to Julia code blocks in documents.

To use this, one simply adds `julia:@cast` code-blocks to their document. For example,

````markdown
```julia:@cast
using Pkg
Pkg.status()
```
````

Then run [`cast_document`](@ref) (or the helper [`cast_readme`](@ref)) on the file. This will turn it into:

````markdown
``` julia:@cast
using Pkg
Pkg.status()
```
![](assets/output_1_@cast.gif)
````
and generate a gif in the `assets` directory.

Here, I chose `julia:@cast` as the syntax, because it is parsable by pandoc (which powers the implementation of this feature) as a code-block "language" (making it identifiable in the pandoc AST), while being interpreted by some syntax highlighters as still being "julia" code.

Additionally, I use `@cast` in the output filename, so that future runs can identify `@cast`-generated gifs and remove the image tags, to prevent duplicating them when running `cast_document` again to update the gifs.

Currently, there are no options to customize this functionality (e.g. to change font-size, to change gif naming, add or change a delay, share state between blocks, etc). Please file an issue if there are features here you would be interested in.
