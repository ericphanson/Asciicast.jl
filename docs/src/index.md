# Asciicast.jl

```@index
```

## Simple example

```@gif
using Pkg
Pkg.status()
1 + 1
```

## Example with a named block

First block:

```@gif 1
x = -1
x*x
```

The next block continues:
```@gif 1
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
```@gif; delay=0
1
2
3
```

Delay of 1:
```@gif; delay=1
1
2
3
```

## API Reference

```@autodocs
Modules = [Asciicast]
```
