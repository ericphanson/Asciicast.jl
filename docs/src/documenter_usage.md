## Documenter usage

To use Asciicast with documenter, the [asciinema-player](https://github.com/asciinema/asciinema-player) javascript and CSS assets must be provided to Documenter in `makedocs` in your `docs/make.jl` file.

This can be done using the [`Asciicast.assets`](@ref) function, e.g.

```julia
makedocs(;
    # ...
    format=Documenter.HTML(;
        assets=Asciicast.assets(),
        # ...
    ),
)
```

Besides that, the only other requirement is to load `Asciicast` in your `make.jl` (`using Asciicast`).

### `@cast` blocks

Asciicast.jl works as a Documenter plugin, providing `@cast` blocks which work similarly to `@repl` blocks. For example:

````markdown
```@cast
using Pkg
Pkg.status()
1 + 1
```
````

The above `@cast` block will effectively generate both a standard Documenter `@repl` block:

````markdown
```@repl
using Pkg
Pkg.status()
1 + 1
```
````
and some raw HTML output:
````html
<div id="d59ee38d-184a-4888-8749-41b4df76ae3b"></div>
<script>
AsciinemaPlayer.create(
'data:text/plain;base64,eyJ2ZXJzaW9uIjoyLCJ3aWR0aCI6ODAsImhlaWdodCI6MTIsInRpbWVzdGFtcCI6MTcwMjE1ODMyMywiaWRsZV90aW1lX2xpbWl0IjoxLjAsImVudiI6eyJURVJNIjoieHRlcm0tMjU2Y29sb3IiLCJTSEVMTCI6Ii9iaW4venNoIn19ClswLjAwMTA5ODE1NTk3NTM0MTc5NjksImkiLCJ1c2luZyBQa2ciXQ0KWzAuNTAxMzQ1MTU3NjIzMjkxLCJvIiwianVsaWE+IHVzaW5nIFBrZ1xyXG4iXQ0KWzEuMDAyODIxMjA3MDQ2NTA4OCwibyIsIiJdDQpbMS41MDI5NzAyMTg2NTg0NDczLCJvIiwiXHJcbiJdDQpbMi4wMDI5NzQ5ODcwMzAwMjkzLCJpIiwiUGtnLnN0YXR1cygpIl0NClsyLjUwMjk3NjE3OTEyMjkyNSwibyIsImp1bGlhPiBQa2cuc3RhdHVzKClcclxuIl0NClszLjAxNTQ2MDAxNDM0MzI2MTcsIm8iLCJcdTAwMWJbMzJtXHUwMDFiWzFtU3RhdHVzXHUwMDFiWzIybVx1MDAxYlszOW0gIl0NClszLjUxNTUwNDEyMTc4MDM5NTUsIm8iLCJgfi9Bc2NpaWNhc3QuamwvZG9jcy9Qcm9qZWN0LnRvbWxgXHJcbiJdDQpbNC4wMTcxMTMyMDg3NzA3NTIsIm8iLCIgICJdDQpbNC41MTcxOTQwMzI2NjkwNjcsIm8iLCJcdTAwMWJbOTBtWzI2MDBkNDQ1XSBcdTAwMWJbMzltQXNjaWljYXN0IHYwLjEuMCBgLi5gIl0NCls1LjAxNzIzODE0MDEwNjIwMSwibyIsIlxyXG4gIl0NCls1LjUxNzI3NzAwMjMzNDU5NSwibyIsIiBcdTAwMWJbOTBtW2UzMDE3MmY1XSBcdTAwMWJbMzltIl0NCls2LjAxNzMxNTE0OTMwNzI1MSwibyIsIkRvY3VtZW50ZXIgdjEuMi4xXHJcbiJdDQpbNi41MTc3NzAwNTE5NTYxNzcsIm8iLCIiXQ0KWzcuMDE3OTI0MDcwMzU4Mjc2LCJvIiwiXHJcbiJdDQpbNy41MTc5MzIxNzY1ODk5NjYsImkiLCIxICsgMSJdDQpbOC4wMTc5MzMxMzAyNjQyODIsIm8iLCJqdWxpYT4gMSArIDFcclxuIl0NCls4LjUxODA5MzEwOTEzMDg2LCJvIiwiIl0NCls5LjAxODU5NDAyNjU2NTU1MiwibyIsIjJcclxuIl0NCg==',
document.getElementById('d59ee38d-184a-4888-8749-41b4df76ae3b'), { autoPlay: true, fit: false}
);
</script>
````

Here, the `id` is randomly generated with `uuid4()`, and the contents of the cast itself are base64-encoded and inlined into the HTML. Note: I initially tried saving these as separate files, but had trouble with casts not showing up on deployed pages, while inlining works reliably every time.

The output of this looks like:

```@cast
using Pkg
Pkg.status()
1 + 1
```

### Hiding REPL inputs

You can also use `hide_inputs=true` to hide the inputs, showing just the asciinema player. The syntax for that is:

````markdown
```@cast; hide_inputs=true
using Pkg
Pkg.status()
1 + 1
```
````

This looks like:

```@cast; hide_inputs=true
using Pkg
Pkg.status()
1 + 1
```

### Exceptions

Unlike in `@repl` blocks, exceptions are not allowed by default. Instead, they must be opt-ed in with `allow_errors=true`

````markdown
```@cast; allow_errors=true
error("This is an exception!")
```
````

This looks like:

```@cast; allow_errors=true
error("This is an exception!")
```

### Example with a named block

First block:

````markdown
```@cast 1; hide_inputs=true
x = -1
x*x
```
````

```@cast 1; hide_inputs=true
x = -1
x*x
```


The next block continues:

````markdown
```@cast 1; hide_inputs=true, allow_errors=true
y = x+1
sqrt(x)
```
````

```@cast 1; hide_inputs=true, allow_errors=true
y = x+1
sqrt(x)
```

Then we move to a REPL block:

````markdown
```@repl 1
@show y
z = y^2
```
````

```@repl 1
@show y
z = y^2
```

### Modifying the delay
Delay of 0:

````markdown
```@cast; delay=0, hide_inputs=true
1
2
3
```
````

```@cast; delay=0, hide_inputs=true
1
2
3
```

Delay of 1:

````markdown
```@cast; delay=1, hide_inputs=true
1
2
3
```
````

```@cast; delay=1, hide_inputs=true
1
2
3
```

### Window size

The size of the window can be set with `height` and `width`.

````markdown
```@cast
println("="^80)
```
````

```@cast; hide_inputs=true
println("="^80)
```

````markdown
```@cast; width=50, height=10
println("="^80)
```
````

```@cast; width=50, height=10, hide_inputs=true
println("="^80)
```

### Loops
We can use `loop=true` to infinitely loop the cast:

````markdown
```@cast; delay=0.5, loop=true, hide_inputs=true
1
2
3
```
````

```@cast; delay=0.5, loop=true, hide_inputs=true
1
2
3
```

We can also specify a delay to write at the end of each loop:

````markdown
```@cast; delay=0.5, loop=true, loop_delay=4.5, hide_inputs=true
1
2
3
```
````

```@cast; delay=0.5, loop=true, loop_delay=4.5, hide_inputs=true
1
2
3
```

Note that currently setting `loop_delay` increases `idle_time_limit` as an implementation detail, meaning that delays of up to `loop_delay` during code execution will be shown.

### All supported options in `@cast` Documenter blocks

* `hide_inputs::Bool=false`. Whether or not to hide the `@repl`-style inputs before the animated gif.
* `allow_errors::Bool=false`. Whether or not the Documenter build should fail if exceptions are encountered during execution of the `@cast` block.
* `delay::Float64=0.25`. The amount of delay between line executions (to emulate typing time).
* `loop::Union{Int,Bool}=false`. Set to `true` for infinite looping, or an integer to loop a fixed number of times.
* `loop_delay::Union{Int,Float64}=0`. An amount of time to wait at the end of the cast, usually useful to pause before looping.
* `idle_time_limit::Union{Int,Float64}=1`. Sets the maximum amount of time to wait between printing.
* `height::Int`. Heuristically determined by default. Set to an integer to specify the number of lines.
* `width::Int`. Set to `80` by default. Set to an integer to specify the number of columns.

### Reference docs

```@docs
Asciicast.assets
```
