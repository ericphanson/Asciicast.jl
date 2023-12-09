# Asciicast.jl

```@index
```

## Simple example

```@cast
using Pkg
Pkg.status()
1 + 1
2+2
3+3
```

## Macro example

```@example
using Asciicast
cast"""
x = 1
x+1
y = x-1
"""0.5
```

## Example with a named block

First block:

```@cast 1
x = -1
x*x
```

The next block continues:
```@cast 1
y = x+1
sqrt(x)
```

Then we move to a REPL block:

```@repl 1
@show y
z = y^2
```

## Modifying the delay
Delay of 0:
```@cast; delay=0
1
2
3
```

Delay of 1:
```@cast; delay=1
1
2
3
```

## API Reference

```@autodocs
Modules = [Asciicast]
```
