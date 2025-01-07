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

        # We can also test the `write_event!` pathway with `Event` objects.
        # This also checks we can roundtrip effectively.
        io2 = IOBuffer()
        cast2 = Cast(io2, header)
        for event in events
            write_event!(cast2, event)
        end
        seekstart(io2)
        header2, events2 = parse_cast(io2)
        for property in propertynames(header)
            @test getproperty(header, property) == getproperty(header2, property)
        end
        @test events == events2
    end


    @testset "README updated" begin
        # Test that the README functionality works, and the README is up-to-date:
        tmp = mktempdir()
        output = joinpath(tmp, "output.md")
        cast_readme(Asciicast, output)
        existing_readme = read(joinpath(pkgdir(Asciicast), "README.md"), String)
        updated_readme = read(output, String)
        if !Sys.iswindows() # skip windows bc backslashes change etc
            # If this fails, you can just update the README with `Asciicast.cast_readme(Asciicast)`.
            @test existing_readme == updated_readme
        end
    end

    @testset "markdown parsing" begin
        tmp = mktempdir()
        output = joinpath(tmp, "output.md")
        # Check that we can parse these blocks and produce the gif tags.
        n = 6
        @test cast_document("test_doc.md", output) == n
        str = read(output, String)
        for i in 1:n
            @test contains(str, "output_$(i)_@cast.gif")
        end
    end

    @testset "markdown errors" begin
        tmp = mktempdir()
        output = joinpath(tmp, "output.md")
        @test_throws CastExecutionException cast_document("bad.md", output)
    end

    @testset "`Cast` show methods" begin
        c = cast"""
           julia> 1+1
           2

           julia> 3
           3
           """0.25
        vscode_str = sprint(show, MIME"juliavscode/html"(), c)
        # Contains the JS and css:
        @test contains(vscode_str, "asciinema-player.min.js")
        @test contains(vscode_str, "asciinema-player.min.css")
        @test contains(vscode_str, "AsciinemaPlayer.create")

        html_str = sprint(show, MIME"text/html"(), c)
        @test contains(html_str, "AsciinemaPlayer.create")
    end

    # https://github.com/ericphanson/Asciicast.jl/issues/32
    @testset "`include` defined" begin
        c = cast"""include("test_file.jl")"""
        @test c isa Cast
    end

    @testset "Float-int parsing" begin
        @test Asciicast.parse_float_int("delay", "delay=0.5, loop=true, loop_delay=4.5, hide_inputs=true") == 0.5
        @test Asciicast.parse_float_int("delay", "delay=1, loop=true, loop_delay=4.5, hide_inputs=true") == 1.0
        @test Asciicast.parse_float_int("delay", "delay=1.0, loop=true, loop_delay=4.5, hide_inputs=true") == 1.0
        @test Asciicast.parse_float_int("delay", "delay=1.5, loop=true, loop_delay=4.5, hide_inputs=true") == 1.5
    end
end


# Test that the docs build:
@testset "Docs build" begin
    include(joinpath(pkgdir(Asciicast), "docs", "_make.jl"))
end
