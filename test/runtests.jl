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
