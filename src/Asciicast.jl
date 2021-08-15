module Asciicast

using JSON3, Dates, StructTypes

export Cast, OutputEvent, InputEvent, write_event!

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

function write_append!(f, handle::AbstractString)
    open(handle; append=true) do io
        f(io)
    end
end

function write_append!(f, handle::IO)
    f(handle)
end

function write!(f, handle::AbstractString)
    open(handle; write=true) do io
        f(io)
    end
end

function write!(f, handle::IO)
    f(handle)
end


struct Cast{T<:Union{IO, AbstractString}}
    write_handle::T
    header::Header
    start_time::Float64
    function Cast(write_handle::Union{IO, AbstractString}, header::Header=Header(), start_time::Float64=time())
        if write_handle isa AbstractString
            mkpath(dirname(write_handle))
        end
        write!(write_handle) do io
            JSON3.write(io, header)
            println(io)
        end
        new{typeof(write_handle)}(write_handle, header, start_time)
    end
end

function write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)
    t = time() - cast.start_time
    write_append!(cast.write_handle) do io
        JSON3.write(io, (t, event_type == OutputEvent ? "o" : "i", event_data))
        println(io)
    end
    return t
end

include("runner.jl")

end # module
