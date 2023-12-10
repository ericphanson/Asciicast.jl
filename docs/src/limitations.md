## Limitations

The approach used in Asciicast.jl has some limitations, and for some use cases it may be better to use the command-line tool [asciinema](https://asciinema.org/docs/getting-started) directly.

### Cannot use keyboard input

Since Asciicast.jl works by running short Julia scripts and capturing the inputs and outputs, one cannot use keyboard input to direct what runs. This makes it hard to capture things like terminal menus and other UI which requires input via Asciicast.jl.

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
