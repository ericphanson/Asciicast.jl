using Asciicast
using Test, JSON3, Dates, Aqua, Base64
using Asciicast: Event, Header, OutputEvent, InputEvent, MarkerEvent, ResizeEvent, ExitEvent, parse_cast

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
        # `record_output` only emits color if `stdout` has color enabled, which depends
        # on how the tests were launched (e.g. `--color=yes`, or a terminal vs. a pipe).
        expected = if get(stdout, :color, false)
            "\e[36m\e[1m[ \e[22m\e[39m\e[36m\e[1mInfo: \e[22m\e[39mHello!"
        else
            "[ Info: Hello!"
        end
        @test contains(strip(events[1].event_data), expected)
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


    @testset "asciicast v3 parsing" begin
        # Example from https://docs.asciinema.org/manual/asciicast/v3/, plus an empty
        # line and an event with an unknown code (both must be ignored)
        v3 = """
        {"version": 3, "term": {"cols": 80, "rows": 24, "type": "xterm-256color"}, "timestamp": 1504467315, "title": "Demo", "env": {"SHELL": "/bin/zsh"}}
        # event stream follows the header
        [0.248, "o", "\\u001b[1;31mHello \\u001b[32mWorld!\\u001b[0m\\n"]
        [1.001, "o", "That was ok\\rThis is better."]
        [3.500, "m", ""]
        [0.143, "o", "Now... "]
        # terminal window resized to 90 cols and 30 rows
        [2.050, "r", "90x30"]

        [0.500, "z", "unknown event code"]
        [1.041, "o", "Bye!"]
        [0.887, "x", "0"]
        """
        header, events = parse_cast(IOBuffer(v3))
        @test header.version == 3
        @test header.width == 80
        @test header.height == 24
        @test header.timestamp == 1504467315
        @test header.title == "Demo"
        @test header.env == Dict("SHELL" => "/bin/zsh", "TERM" => "xterm-256color")
        @test header.theme === nothing
        @test [e.type for e in events] == [OutputEvent, OutputEvent, MarkerEvent, OutputEvent,
                                           ResizeEvent, OutputEvent, ExitEvent]
        # Intervals are accumulated into times since the start, including the interval
        # of the skipped event
        @test [e.time for e in events] ≈ cumsum([0.248, 1.001, 3.5, 0.143, 2.05, 0.5 + 1.041, 0.887])
        @test events[1].event_data == "\e[1;31mHello \e[32mWorld!\e[0m\n"
        @test events[5].event_data == "90x30"
        @test events[end].event_data == "0"

        # Theme is read from `term.theme`; an explicit `TERM` in `env` is kept
        theme = Dict("fg" => "#d0d0d0", "bg" => "#212121", "palette" => join(fill("#151515", 8), ":"))
        header_line = JSON3.write(Dict("version" => 3, "tags" => ["demo"],
            "term" => Dict("cols" => 100, "rows" => 50, "type" => "xterm", "version" => "VTE(7802)", "theme" => theme),
            "env" => Dict("TERM" => "screen"), "idle_time_limit" => 2))
        header, events = parse_cast(IOBuffer(header_line * "\n"))
        @test (header.width, header.height) == (100, 50)
        @test header.theme == theme
        @test header.env == Dict("TERM" => "screen")
        @test header.idle_time_limit == 2.0
        @test isempty(events)

        # Minimal header
        header, events = parse_cast(IOBuffer("""{"version": 3, "term": {"cols": 10, "rows": 5}}\n[1.0, "o", "a"]\n"""))
        @test (header.width, header.height, header.env, header.timestamp) == (10, 5, nothing, nothing)
        @test only(events) == Event(1.0, OutputEvent, "a")

        # v2 files with marker and resize events; times are absolute
        header, events = parse_cast(IOBuffer("""
        {"version": 2, "width": 80, "height": 24}
        [0.5, "o", "a"]
        [1.5, "m", ""]
        [4.0, "r", "90x30"]
        """))
        @test header.version == 2
        @test events == [Event(0.5, OutputEvent, "a"), Event(1.5, MarkerEvent, ""), Event(4.0, ResizeEvent, "90x30")]

        @test_throws ErrorException parse_cast(IOBuffer("""{"version": 1, "width": 80, "height": 24}\n"""))
    end

    @testset "asciicast v3 writing" begin
        @test_throws ArgumentError Cast(IOBuffer(), Header(; version=4))

        io = IOBuffer()
        cast = Cast(io, Header(; version=3, title="t", theme=Dict("fg" => "#ffffff", "bg" => "#000000", "palette" => "#000000:#ffffff")))
        write_event!(cast, Event(0.25, OutputEvent, "hello\n"))
        write_event!(cast, Event(1.0, InputEvent, "x"))
        write_event!(cast, Event(1.0, MarkerEvent, "label"))
        write_event!(cast, Event(3.5, ExitEvent, "0"))
        lines = split(String(take!(copy(io))), "\n"; keepempty=false)
        header_obj = JSON3.read(lines[1])
        @test header_obj.version == 3
        @test header_obj.term.cols == 80
        @test header_obj.term.rows == 24
        @test header_obj.term.type == get(ENV, "TERM", "xterm-256color")
        @test header_obj.term.theme.fg == "#ffffff"
        @test header_obj.title == "t"
        @test !haskey(header_obj, :width) && !haskey(header_obj, :height) && !haskey(header_obj, :theme)
        # Intervals, not absolute times
        @test [JSON3.read(l)[1] for l in lines[2:end]] == [0.25, 0.75, 0.0, 2.5]
        @test [JSON3.read(l)[2] for l in lines[2:end]] == ["o", "i", "m", "x"]

        seekstart(io)
        header, events = parse_cast(io)
        @test header.version == 3
        @test header.title == "t"
        @test [e.time for e in events] ≈ [0.25, 1.0, 1.0, 3.5]
        @test [e.event_data for e in events] == ["hello\r\n", "x", "label", "0"]

        # Intervals are rounded to milliseconds, carrying the rounding error forward,
        # so the times read back stay within half a millisecond of the times written
        io = IOBuffer()
        cast = Cast(io, Header(; version=3))
        times = [0.0004 * k for k in 1:1000]
        for t in times
            write_event!(cast, Event(t, OutputEvent, "."))
        end
        seekstart(io)
        _, events = parse_cast(io)
        @test maximum(abs.([e.time for e in events] .- times)) <= 0.0005 + 1e-9

        # `record_output` accepts `version`, like other `Header` keyword arguments
        io = IOBuffer()
        record_output(io; version=3) do
            println("hi")
        end
        seekstart(io)
        header, events = parse_cast(io)
        @test header.version == 3
        @test any(e -> contains(e.event_data, "hi"), events)

        # Re-writing the events of a `cast"..."` cast as v3 and reading them back
        # gives the same events up to millisecond rounding
        c = cast"""
           julia> 1+1
           2
           """0.25
        _, events = parse_cast(IOBuffer(Asciicast.collect_bytes(c)))
        io = IOBuffer()
        c3 = Cast(io, Header(; version=3))
        foreach(e -> write_event!(c3, e), events)
        seekstart(io)
        _, events3 = parse_cast(io)
        @test [(e.type, e.event_data) for e in events3] == [(e.type, e.event_data) for e in events]
        @test all(isapprox(a.time, b.time; atol=0.0005 + 1e-9) for (a, b) in zip(events, events3))

        # The bundled player and agg only read v2, so v3 casts are shown and converted
        # to gifs via v2
        html_str = sprint(show, MIME"text/html"(), c3)
        b64 = match(r"base64,([^']*)'", html_str)[1]
        header2, events2 = parse_cast(IOBuffer(base64decode(b64)))
        @test header2.version == 2
        @test [e.event_data for e in events2] == [e.event_data for e in events3]
        @test [e.time for e in events2] ≈ [e.time for e in events3]
        mktempdir() do tmp
            gif = joinpath(tmp, "out.gif")
            Asciicast.save_gif(gif, c3)
            @test filesize(gif) > 0
        end
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

    @testset "YAML metadata block is preserved" begin
        tmp = mktempdir()
        output = joinpath(tmp, "output.md")
        input = read("yaml_doc.md", String)
        @test cast_document("yaml_doc.md", output) == 1
        str = read(output, String)
        # The metadata block is copied verbatim (comments, key order, and
        # values like `1.10` are not rewritten by pandoc)
        front_matter = first(split(input, "Some text."))
        @test startswith(str, front_matter)
        @test startswith(replace(str, "\r\n" => "\n"), replace(front_matter, "\r\n" => "\n") * "Some text.\n")
        @test count("usepackage", str) == 1
        @test contains(str, "output_1_@cast.gif")

        # The same holds for a document with CRLF line endings, whichever line
        # endings the checkout of `yaml_doc.md` has
        crlf_input = joinpath(tmp, "crlf_input.md")
        write(crlf_input, replace(replace(input, "\r\n" => "\n"), "\n" => "\r\n"))
        crlf_output = joinpath(tmp, "crlf_output.md")
        @test cast_document(crlf_input, crlf_output) == 1
        crlf_front_matter = first(split(read(crlf_input, String), "Some text."))
        @test startswith(read(crlf_output, String), crlf_front_matter * "Some text.")

        # Documents without a metadata block are unaffected, including ones
        # that start with a horizontal rule
        @test Asciicast.split_front_matter("---\n\nhello\n\n---\n", "gfm+attributes") == ("", "---\n\nhello\n\n---\n")
        @test Asciicast.split_front_matter("hello\n", "gfm+attributes") == ("", "hello\n")
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
        @test Asciicast.parse_float_int("delay",
            "width=100, height=50, delay=0.1, loop=true, loop_delay=5") == 0.1
        @test Asciicast.parse_float_int("loop_delay",
            "width=100, height=50, delay=0.1, loop=true, loop_delay=5") == 5
    end

    @testset "`@cast` block matcher" begin
        # Documenter calls this matcher on every node of a page to decide whether
        # `CastBlocks` should handle it. We wrap a fenced code block with the given
        # info string (the text after the opening ```) in a node and check that only
        # `@cast` blocks are matched. `page` and `doc` are unused, so we pass `nothing`.
        matches(info) = Asciicast.Selectors.matcher(Asciicast.CastBlocks,
            Asciicast.MarkdownAST.Node(Asciicast.MarkdownAST.CodeBlock(info, "1 + 1")),
            nothing, nothing)
        @test matches("@cast")
        @test matches("@cast name")
        @test matches("@cast name; delay=0.5")
        @test !matches("@example")
        @test !matches("julia")
        # Nodes that are not code blocks (here a paragraph) have no info string
        # and must not be matched.
        @test !Asciicast.Selectors.matcher(Asciicast.CastBlocks,
            Asciicast.MarkdownAST.Node(Asciicast.MarkdownAST.Paragraph()), nothing, nothing)
    end
end


# Test that the docs build:
@testset "Docs build" begin
    include(joinpath(pkgdir(Asciicast), "docs", "_make.jl"))
end
