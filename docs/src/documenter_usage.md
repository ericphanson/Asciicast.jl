# Documenter usage

## `@cast` blocks

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
<div id="dc05156e-99be-4621-80d5-cdd48b72f313.cast"></div>
<script>
AsciinemaPlayer.create('./assets/casts/dc05156e-99be-4621-80d5-cdd48b72f313.cast', document.getElementById('dc05156e-99be-4621-80d5-cdd48b72f313.cast'), { autoPlay: true, fit: false, startAt: 0.4});
</script>
````

Here, the name of the file is randomly generated with `uuid4()`, and the file itself is saved in the `assets` directory.

This looks like:

```@cast
using Pkg
Pkg.status()
1 + 1
```

## Hiding REPL inputs

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

## Exceptions

Like in `@repl` blocks, exceptions are allowed. For example:

````markdown
```@cast
error("This is an exception!")
```
````

This looks like:

```@cast
error("This is an exception!")
```

To prevent exceptions, use `allow_errors=false`, as in

````markdown
```@cast; allow_errors=false
error("This is an exception!")
```
````

## Example with a named block

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
```@cast 1; hide_inputs=true
y = x+1
sqrt(x)
```
````

```@cast 1; hide_inputs=true
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

## Modifying the delay
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
