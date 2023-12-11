module Asciicast

using JSON3, Dates, StructTypes, Base64
using Logging
import Random
using REPL
using Documenter
using Documenter: Expanders, Selectors, iscode, _any_color_fmt, droplines, prepend_prompt, remove_sandbox_from_output
using Documenter.Expanders: ExpanderPipeline
using UUIDs
using MarkdownAST
using pandoc_jll, agg_jll

export Cast, OutputEvent, InputEvent, write_event!, record_output
export cast_document, cast_readme
export @cast_str, CastExecutionException

const Object = Dict{String, String}

# https://github.com/asciinema/asciinema/blob/2c8af028dec448bb51ec0a1848e96a08121827b0/doc/asciicast-v2.md
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
        env::Union{$Object,Nothing}=$Object("SHELL" => get(ENV, "SHELL", "/bin/bash"),
                                                "TERM" => get(ENV, "TERM", "xterm-256color"))
        theme::Union{$Object,Nothing}=nothing
    end

The header of an asciicast file. Documented at <https://github.com/asciinema/asciinema/blob/v2.4.0/doc/asciicast-v2.md#header>.
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
    env::Union{Object,Nothing}=Object("SHELL" => get(ENV, "SHELL", "/bin/bash"),
                                               "TERM" => get(ENV, "TERM", "xterm-256color"))
    theme::Union{Object,Nothing}=nothing
end

StructTypes.StructType(::Type{Header}) = StructTypes.Struct()
StructTypes.omitempties(::Type{Header}) = true

"""
    Asciicast.EventType

An enum consisting of `Asciicast.OutputEvent` and `Asciicast.InputEvent`.
"""
@enum EventType OutputEvent InputEvent

"""
    struct Event
        time::Float64
        type::EventType
        event_data::String
    end

Represents an event in a cast file. See also [`EventType`](@ref).
"""
struct Event
    time::Float64
    type::EventType
    event_data::String
end

function Event(t::Number, type::AbstractString, event_data::AbstractString)
    event_type = if type == "i"
        InputEvent
    elseif type == "o"
        OutputEvent
    else
        error("Unexpected event type $type")
    end
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
    delay::Float64
    loop::Union{Bool, Int}
end

"""
    Cast(file_or_io=IOBuffer(), header=Header(), start_time=time(); delay=0.0, loop=false)

Create a `Cast` object which represents an `asciicast` file
(see <https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md>
for the format).

* Set `delay` to enforce a constant delay between events.
* Set `loop` to `true` to loop continuously, or to an integer to loop a specified number of times. Only supported in the HTML `show` method for asciinema-player (not in the written file format, nor gif support, which currently always loops).

Use [`write_event!`](@ref) to write an event to the cast.
"""
function Cast(write_handle::Union{IO, AbstractString}=IOBuffer(), header::Header=Header(), start_time::Float64=time(); delay=0.0, loop=false)
    if write_handle isa AbstractString
        mkpath(dirname(write_handle))
    end
    write!(write_handle) do io
        JSON3.write(io, header)
        println(io)
    end
    return Cast{typeof(write_handle)}(write_handle, header, start_time, Ref(0), delay, loop)
end

collect_bytes(cast::Cast) = collect_bytes(cast.write_handle)

function Base.show(io::IO, mime::MIME"text/html", cast::Cast)
    base64_str = base64encode(collect_bytes(cast))
    name = uuid4()
    # Note: the extra div with `margin` is me trying to make the asciinema player
    # have a little space around it, so it looks better in documenter pages etc.
    # I don't know what I'm doing; if this is bad, make a PR to improve it!
    html = HTML("""
    <div style="margin: 20px">
    <div id="$(name)"></div>
    <script>
    AsciinemaPlayer.create(
    'data:text/plain;base64,$(base64_str)',
    document.getElementById('$(name)'), {autoPlay: true, fit: false, loop: $(cast.loop)}
    );
    </script>
    </div>
    """)
    return show(io, mime, html)
end

"""
    save(output, cast::Cast)

Writes the contents of a [`Cast`](@ref) `cast` to `output`.
"""
save(output, cast::Cast) = write(output, collect_bytes(cast))

"""
    write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)
    write_event!(cast::Cast, event::Event)

Write an event to `cast` of type `event_type` (either `OutputEvent` or `InputEvent`) with data given by `event_data`.
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
        JSON3.write(io, (event.time + cast.delay*cast.events_written[], event.type == OutputEvent ? "o" : "i", event_data))
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
"""
function parse_cast(io::IO)
    header_line = readline(io)
    header = JSON3.read(header_line, Header)
    events = Event[]
    for line in eachline(io)
        push!(events, Event(JSON3.read(line)...))
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
