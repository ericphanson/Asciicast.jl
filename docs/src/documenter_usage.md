# Documenter usage

## `@cast` blocks

Asciicast.jl works as a Documenter plugin, providing `@cast` blocks which work similarly to `@repl` blocks. For example:

````markdown
```@cast repl=true
using Pkg
Pkg.status()
1 + 1
```
````

The above `@cast repl=true` block will effectively generate both a standard Documenter `@repl` block:


````markdown
```@repl
using Pkg
Pkg.status()
1 + 1
```
````
and some raw HTML output:
````html
<div id="dc05156e-99be-4621-80d5-cdd48b72f313.cast"></div>
<script>
AsciinemaPlayer.create('./assets/casts/dc05156e-99be-4621-80d5-cdd48b72f313.cast', document.getElementById('dc05156e-99be-4621-80d5-cdd48b72f313.cast'), { autoPlay: true, fit: false, startAt: 0.4});
</script>
````
Here, the name of the file is randomly generated with `uuid4()`, and the file itself is saved in the `assets` directory.
