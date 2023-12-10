using Asciicast
using Test, JSON3, Dates, Aqua
using Asciicast: Event, Header, OutputEvent, InputEvent, parse_cast

function test_default_header(header)
    @test header isa Header
    @test header.timestamp < datetime2unix(now())
    @test header.version == 2
end

@testset "Asciicast.jl" begin
    @testset "Aqua" begin
        Aqua.test_all(Asciicast)
    end

    @testset "Example 1" begin
        io = IOBuffer()
        cast = Cast(io)
        write_event!(cast, OutputEvent, "hello\n")
        write_event!(cast, OutputEvent, "Let us wait...")
        sleep(0.5)
        write_event!(cast, OutputEvent, "\nDone!")
        seekstart(io)
        header, events = parse_cast(io)

        test_default_header(header)

        @test all(event.type == OutputEvent for event in events)
        @test issorted(event.time for event in events)

        @test strip(events[1].event_data) == "hello"
        @test strip(events[2].event_data) == "Let us wait..."
        @test strip(events[3].event_data) == "Done!"
        # Delay
        @test events[3].time - events[2].time >= 0.5
    end

    @testset "Example 2" begin
        io = IOBuffer()
        ret = record_output(io) do
            @info "Hello!"
            println("That was a logging statement, but this is printing.")
            x = 1
            x + 1 # does not print anything-- no output!
            @info "here's `x`" x
            println("Now I'll wait a second")
            sleep(1)
            println("ok, done!")
        end
        @test ret isa Cast
        seekstart(io)
        header, events = parse_cast(io)
        test_default_header(header)
        # Still all outputs, since not the string macro
        @test all(event.type == OutputEvent for event in events)
        @test issorted(event.time for event in events)

        # Sometimes the event here has 2 lines rather than 1 :(. So we will just test
        # `contains`.
        @test contains(strip(events[1].event_data), "\e[36m\e[1m[ \e[22m\e[39m\e[36m\e[1mInfo: \e[22m\e[39mHello!")
    end

    @testset "Example 3" begin
        cast = cast"""
        @info "Hello!"
        println("That was a logging statement, but this is printing.")
        x = 1
        x + 1
        @info "here's `x`" x
        println("Now I'll wait a second")
        sleep(1)
        println("ok, done!")
        """
        io = cast.write_handle
        seekstart(io)
        header, events = parse_cast(io)
        test_default_header(header)
        @test !all(event.type == OutputEvent for event in events)
        @test issorted(event.time for event in events)
        @test events[1].type == InputEvent
        @test strip(events[1].event_data) == "@info \"Hello!\""
    end
end

# Test that the docs build:
include(joinpath(pkgdir(Asciicast), "docs", "_make.jl"))

# Test that the README functionality works, and the README is up-to-date:
tmp = mktempdir()
output = joinpath(tmp, "output.md")
Asciicast.cast_readme(Asciicast, output)
existing_readme = read(joinpath(pkgdir(Asciicast), "README.md"), String)
updated_readme = read(output, String)
# If this fails, you can just update the README with `Asciicast.cast_readme(Asciicast)`.
@test existing_readme == updated_readme
