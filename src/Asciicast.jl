module Asciicast

using JSON3, Dates, StructTypes

export Cast, OutputEvent, InputEvent, write_event!, record_output

const Object = Dict{String, String}

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

@enum EventType OutputEvent InputEvent

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


struct Cast{T<:Union{IO, AbstractString}}
    write_handle::T
    header::Header
    start_time::Float64
    events_written::Base.RefValue{Int}
    delay::Float64
end

"""
    Cast(file_or_io, header=Header(), start_time=time(); delay=0.0)

Create a `Cast` object which represents an `asciicast` file
(see <https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md>
for the format).

Set `delay` to enforce a constant delay between events.

Use [`write_event!`](@ref) to write an event to the cast.
"""
function Cast(write_handle::Union{IO, AbstractString}, header::Header=Header(), start_time::Float64=time(); delay=0.0)
    if write_handle isa AbstractString
        mkpath(dirname(write_handle))
    end
    write!(write_handle) do io
        JSON3.write(io, header)
        println(io)
    end
    return Cast{typeof(write_handle)}(write_handle, header, start_time, Ref(0), delay)
end


"""
    write_event!(cast::Cast, event_type::EventType, event_data::AbstractString) -> time_since_start

Write an event to `cast` of type `event_type` (either `OutputEvent` or `InputEvent`) with data given by `event_data`.
"""
function write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)
    t = time() - cast.start_time
    write_append!(cast.write_handle) do io
        # asciinema's player seems to require `\r\n` instead of just `\n`
        event_data = replace(event_data, "\n" => "\r\n")
        JSON3.write(io, (t + cast.delay*cast.events_written[], event_type == OutputEvent ? "o" : "i", event_data))
        write(io, "\r\n")
    end
    cast.events_written[] += 1
    return t
end

include("capture.jl")
include("runner.jl")

"""
    record_output(f, filepath, h::Header=Header(), start_time::Float64=time(); delay=0) -> filepath

Executes `f()` while saving all output to a cast that's located at `filepath`. `filepath` may
be of any type but must support `open`.

The parameters of the cast may be passed here; see [`Cast`](@ref) for more details.
"""
function record_output(f, filepath, h::Header=Header(), start_time::Float64=time(); delay=0)
    open(filepath; write=true) do io
        cast = Cast(io, h, start_time; delay=delay)
        capture(f, cast; color = true)
    end
    return filepath
end

end # module
