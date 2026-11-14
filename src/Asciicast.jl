module Asciicast

using JSON3, Dates, Base64
using Logging
import Random
using REPL
using Documenter
using Documenter: Expanders, Selectors, _any_color_fmt, droplines, prepend_prompt, remove_sandbox_from_output
using Documenter.Expanders: ExpanderPipeline
using UUIDs
using MarkdownAST
using pandoc_jll, agg_jll

export Cast, OutputEvent, InputEvent, write_event!, record_output
export cast_document, cast_readme
export @cast_str, CastExecutionException

const Object = Dict{String, String}

# v2: https://docs.asciinema.org/manual/asciicast/v2/
# v3: https://docs.asciinema.org/manual/asciicast/v3/
"""
    Base.@kwdef struct Header
        version::Int=2
        width::Int=80
        height::Int=24
        timestamp::Union{Int, Nothing}=floor(Int, datetime2unix(now()))
        duration::Union{Float64, Nothing}=nothing
        idle_time_limit::Union{Float64, Nothing}=nothing
        command::Union{String, Nothing}=nothing
        title::Union{String, Nothing}=nothing
        env::Union{$Object,Nothing}=$Object("SHELL" => get(ENV, "SHELL", "/bin/bash"))
        theme::Union{$Object,Nothing}=nothing
        term_type::Union{String, Nothing}=get(ENV, "TERM", "xterm-256color")
        term_version::Union{String, Nothing}=nothing
        tags::Union{Vector{String}, Nothing}=nothing
    end

The header of an asciicast file, for both the
[v2](https://docs.asciinema.org/manual/asciicast/v2/#header) and
[v3](https://docs.asciinema.org/manual/asciicast/v3/#header) formats.
Fields set to `nothing` are omitted when the header is written.

`version` selects the format used when a [`Cast`](@ref) is written: `2` (the default) or `3`.
[`parse_cast`](@ref) sets it to the version of the file it reads.

The fields correspond to the two formats as follows:

* `width` and `height` are `width` and `height` in v2, and `term.cols` and `term.rows` in v3.
* `theme` is `theme` in v2, and `term.theme` in v3.
* `term_type` is `term.type` in v3. v2 has no such field, so it is written as `env["TERM"]`
  if `env` is not `nothing` and has no `TERM` entry, and read from `env["TERM"]`
  (removing it from `env`).
* `term_version` and `tags` exist only in v3, and are not written to v2 files.
* `duration` exists only in v2, and is not written to v3 files.
* The other fields have the same name in both formats.
"""
Base.@kwdef struct Header
    version::Int=2
    width::Int=80
    height::Int=24
    timestamp::Union{Int, Nothing}=floor(Int, datetime2unix(now()))
    duration::Union{Float64, Nothing}=nothing
    idle_time_limit::Union{Float64, Nothing}=nothing
    command::Union{String, Nothing}=nothing
    title::Union{String, Nothing}=nothing
    # `TERM` is kept in `term_type` rather than here, so that v3 output does not
    # contain it twice; the v2 writer adds it back.
    env::Union{Object,Nothing}=Object("SHELL" => get(ENV, "SHELL", "/bin/bash"))
    theme::Union{Object,Nothing}=nothing
    term_type::Union{String, Nothing}=get(ENV, "TERM", "xterm-256color")
    term_version::Union{String, Nothing}=nothing
    tags::Union{Vector{String}, Nothing}=nothing
end

"""
    Asciicast.EventType

An enum of asciicast event types:

* `Asciicast.OutputEvent` (code `"o"`)
* `Asciicast.InputEvent` (code `"i"`)
* `Asciicast.MarkerEvent` (code `"m"`)
* `Asciicast.ResizeEvent` (code `"r"`, data `"{COLS}x{ROWS}"`)
* `Asciicast.ExitEvent` (code `"x"`, data is the exit status; defined in asciicast v3)
"""
@enum EventType OutputEvent InputEvent MarkerEvent ResizeEvent ExitEvent

const EVENT_CODES = Dict(OutputEvent => "o", InputEvent => "i", MarkerEvent => "m",
                         ResizeEvent => "r", ExitEvent => "x")
const CODE_EVENTS = Dict(v => k for (k, v) in EVENT_CODES)

"""
    struct Event
        time::Float64
        type::EventType
        event_data::String
    end

Represents an event in a cast file. `time` is the time in seconds since the start of the
recording, for both v2 and v3 casts (v3 files store the interval since the previous
event; [`parse_cast`](@ref) and [`write_event!`](@ref) convert between the two).
See also [`EventType`](@ref).
"""
struct Event
    time::Float64
    type::EventType
    event_data::String
end

function Event(t::Number, type::AbstractString, event_data::AbstractString)
    event_type = get(CODE_EVENTS, type, nothing)
    event_type === nothing && error("Unexpected event type $type")
    return Event(t, event_type, event_data)
end

# Some methods inspired by ArgTools.jl to try to be
# agnostic to IO handles or files.
# We can't use ArgTools itself because we need to be
# able to append.
function write_append!(f, handle::AbstractString)
    open(handle; append=true) do io
        f(io)
    end
end
write_append!(f, handle::IO) = f(handle)

function write!(f, handle::AbstractString)
    open(handle; write=true) do io
        f(io)
    end
end
write!(f, handle::IO) = f(handle)

function collect_bytes(io::IO)
    seekstart(io)
    return read(io)
end
collect_bytes(filename) = read(filename)

struct Cast{T<:Union{IO, AbstractString}}
    write_handle::T
    header::Header
    start_time::Float64
    events_written::Base.RefValue{Int}
    # time (relative to the start of the cast) of the last event written, in
    # milliseconds; used to compute the intervals written in v3 casts
    last_time_ms::Base.RefValue{Int}
    delay::Float64
    loop::Union{Bool, Int}
end

"""
    Cast(file_or_io=IOBuffer(), header=Header(), start_time=time(); delay=0.0, loop=false)

Create a `Cast` object which represents an `asciicast` file
(see <https://docs.asciinema.org/manual/asciicast/v2/> and
<https://docs.asciinema.org/manual/asciicast/v3/> for the formats).
The format is chosen by `header.version`, which may be `2` (the default) or `3`; see [`Header`](@ref).

* Set `delay` to enforce a constant delay between events.
* Set `loop` to `true` to loop continuously, or to an integer to loop a specified number of times. Only supported in the HTML `show` method for asciinema-player (not in the written file format, nor gif support, which currently always loops).

Use [`write_event!`](@ref) to write an event to the cast.
"""
function Cast(write_handle::Union{IO, AbstractString}=IOBuffer(), header::Header=Header(), start_time::Float64=time(); delay=0.0, loop=false)
    header.version in (2, 3) || throw(ArgumentError("Unsupported asciicast version $(header.version); expected 2 or 3"))
    if write_handle isa AbstractString
        mkpath(dirname(write_handle))
    end
    write!(write_handle) do io
        JSON3.write(io, header.version == 3 ? write_header_v3(header) : write_header_v2(header))
        println(io)
    end
    return Cast{typeof(write_handle)}(write_handle, header, start_time, Ref(0), Ref(0), delay, loop)
end

# NamedTuple of the non-`nothing` pairs, so JSON3 writes them in this order and omits the rest
function json_object(pairs...)
    kept = [Symbol(k) => v for (k, v) in pairs if v !== nothing]
    return NamedTuple{Tuple(first.(kept))}(Tuple(last.(kept)))
end

function write_header_v2(header::Header)
    env = header.env
    if env !== nothing && header.term_type !== nothing && !haskey(env, "TERM")
        env = copy(env)
        env["TERM"] = header.term_type
    end
    return json_object("version" => 2, "width" => header.width, "height" => header.height,
                       "timestamp" => header.timestamp, "duration" => header.duration,
                       "idle_time_limit" => header.idle_time_limit, "command" => header.command,
                       "title" => header.title, "env" => env, "theme" => header.theme)
end

function write_header_v3(header::Header)
    term = json_object("cols" => header.width, "rows" => header.height,
                       "type" => header.term_type, "version" => header.term_version,
                       "theme" => header.theme)
    return json_object("version" => 3, "term" => term, "timestamp" => header.timestamp,
                       "idle_time_limit" => header.idle_time_limit, "command" => header.command,
                       "title" => header.title, "env" => header.env, "tags" => header.tags)
end

read_object(obj) = obj === nothing ? nothing : Object(string(k) => string(v) for (k, v) in obj)
read_field(obj, key, T) = (v = get(obj, key, nothing); v === nothing ? nothing : convert(T, v))

function read_header_v2(obj)
    env = read_object(get(obj, :env, nothing))
    term_type = env === nothing ? nothing : pop!(env, "TERM", nothing)
    return Header(; version=2, width=obj[:width], height=obj[:height],
                  timestamp=read_field(obj, :timestamp, Int),
                  duration=read_field(obj, :duration, Float64),
                  idle_time_limit=read_field(obj, :idle_time_limit, Float64),
                  command=read_field(obj, :command, String), title=read_field(obj, :title, String),
                  env, theme=read_object(get(obj, :theme, nothing)),
                  term_type, term_version=nothing, tags=nothing)
end

function read_header_v3(obj)
    term = obj[:term]
    tags = get(obj, :tags, nothing)
    return Header(; version=3, width=term[:cols], height=term[:rows],
                  timestamp=read_field(obj, :timestamp, Int), duration=nothing,
                  idle_time_limit=read_field(obj, :idle_time_limit, Float64),
                  command=read_field(obj, :command, String), title=read_field(obj, :title, String),
                  env=read_object(get(obj, :env, nothing)),
                  theme=read_object(get(term, :theme, nothing)),
                  term_type=read_field(term, :type, String),
                  term_version=read_field(term, :version, String),
                  tags=tags === nothing ? nothing : String[string(t) for t in tags])
end

collect_bytes(cast::Cast) = collect_bytes(cast.write_handle)

# The bundled asciinema-player (3.6.3) and agg_jll (1.4.3) only read asciicast v1 and v2
# (v3 support was added in asciinema-player 3.10.0 and agg 1.6.0), so we convert
# v3 casts to v2 before passing them on.
function v2_bytes(cast::Cast)
    bytes = collect_bytes(cast)
    cast.header.version == 2 && return bytes
    header, events = parse_cast(IOBuffer(bytes))
    fields = (k => getfield(header, k) for k in fieldnames(Header) if k != :version)
    v2 = Cast(IOBuffer(), Header(; fields..., version=2))
    for event in events
        write_event!(v2, event)
    end
    return collect_bytes(v2)
end

Base.show(io::IO, ::MIME"text/html", cast::Cast) = show_html(io, cast)
function Base.show(io::IO, ::MIME"juliavscode/html", cast::Cast)
    nodes = Documenter.HTMLWriter.asset_links(".", Asciicast.assets())
    for node in nodes
        print(io, node)
    end
    show_html(io, cast)
end

function show_html(io::IO, cast::Cast)
    base64_str = base64encode(v2_bytes(cast))
    name = uuid4()
    # Note: the extra div with `margin` is me trying to make the asciinema player
    # have a little space around it, so it looks better in documenter pages etc.
    # I don't know what I'm doing; if this is bad, make a PR to improve it!
    html = """
    <div style="margin: 20px">
    <div id="$(name)"></div>
    <script>
    AsciinemaPlayer.create(
    'data:text/plain;base64,$(base64_str)',
    document.getElementById('$(name)'), {autoPlay: true, fit: "width", loop: $(cast.loop)}
    );
    </script>
    </div>
    """
    return print(io, html)
end

"""
    save(output, cast::Cast)

Writes the contents of a [`Cast`](@ref) `cast` to `output`.
"""
save(output, cast::Cast) = write(output, collect_bytes(cast))

"""
    write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)
    write_event!(cast::Cast, event::Event)

Write an event to `cast` of type `event_type` (e.g. `OutputEvent` or `InputEvent`; see [`EventType`](@ref)) with data given by `event_data`.

For v3 casts, the interval since the previous event is written, rounded to millisecond
precision. The rounding error is carried over to the next event, so the sum of the intervals stays within
half a millisecond of the event times.
"""
function write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)
    event = Event(time() - cast.start_time, event_type, event_data)
    return write_event!(cast::Cast, event)
end

function write_event!(cast::Cast, event::Event)
    write_append!(cast.write_handle) do io
        # asciinema's player seems to require `\r\n` instead of just `\n`
        # regex help: https://stackoverflow.com/a/32704
        event_data = replace(event.event_data, r"(?<!\r)\n" => "\r\n")
        t = event.time + cast.delay*cast.events_written[]
        if cast.header.version == 3
            # Write intervals from rounded absolute times, so rounding errors do not accumulate
            t_ms = round(Int, t * 1000)
            t = (t_ms - cast.last_time_ms[]) / 1000
            cast.last_time_ms[] = t_ms
        end
        JSON3.write(io, (t, EVENT_CODES[event.type], event_data))
        write(io, "\r\n")
    end
    cast.events_written[] += 1
    return event.time
end

include("capture.jl")
include("runner.jl")
include("Pandoc.jl")
using .Pandoc
include("gif.jl")


"""
    record_output(f, filepath::AbstractString, start_time::Float64=time(); delay=0, kw...) -> filepath
    record_output(f, io::IO=IOBuffer(), start_time::Float64=time(); delay=0, kw...)

Executes `f()` while saving all output to a cast whose data is saved to `io`, or to a file at `filepath`. The arguments `kw...` may be any keyword arguments accepted by [`Header`](@ref).

The parameters of the cast may be passed here; see [`Cast`](@ref) for more details.

Returns a `Cast` object.
"""
function record_output(f, filepath::AbstractString, args...; kw...)
    open(filepath; write=true) do io
        return record_output(f, io, args...; kw...)
    end
end

function record_output(f, io::IO=IOBuffer(), start_time::Float64=time(); delay=0, kw...)
    cast = Cast(io, Header(; kw...), start_time; delay=delay)
    capture(f, cast; color = true)
    return cast
end

"""
    Asciicast.parse_cast(io::IO) -> header, events

Returns a tuple consisting of a [`Header`](@ref) and vector of [`Event`](@ref)'s.

Both asciicast v2 and v3 files are supported. For v3 files, event intervals are converted to
times since the start of the recording, and lines starting with `#` (comments) are skipped.
See [`Header`](@ref) for how the header fields of each version are read.
Empty lines and events with unknown event codes are skipped, as required by both specifications.
"""
function parse_cast(io::IO)
    header_line = readline(io)
    header_obj = JSON3.read(header_line)
    version = get(header_obj, :version, nothing)
    header = if version == 2
        read_header_v2(header_obj)
    elseif version == 3
        read_header_v3(header_obj)
    else
        error("Unsupported asciicast version $(repr(version)); expected 2 or 3")
    end
    events = Event[]
    t = 0.0
    for line in eachline(io)
        isempty(strip(line)) && continue
        version == 3 && startswith(line, '#') && continue
        event_time, code, data = JSON3.read(line)
        t = version == 3 ? t + event_time : Float64(event_time)
        haskey(CODE_EVENTS, code) || continue
        push!(events, Event(t, CODE_EVENTS[code], data))
    end
    return (header, events)
end

"""
    Asciicast.assets(asciinema_version = "3.6.3")

Provides a collection of Documenter assets which can be used in `makedocs`,
e.g. `makedocs(; assets=Asciicast.assets())`.
"""
function assets(asciinema_version = "3.6.3")
    asciinema_js_url = "https://cdn.jsdelivr.net/npm/asciinema-player@$(asciinema_version)/dist/bundle/asciinema-player.min.js"
    asciinema_css_url = "https://cdn.jsdelivr.net/npm/asciinema-player@$(asciinema_version)/dist/bundle/asciinema-player.min.css"
    return [Documenter.asset(asciinema_js_url; class=:js),
            Documenter.asset(asciinema_css_url; class=:css)]
end


end # module
