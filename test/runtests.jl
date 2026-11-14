using Asciicast
using Test, JSON, Dates, Aqua, Base64
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
        @test header.env == Dict("SHELL" => "/bin/zsh")
        @test header.term_type == "xterm-256color"
        @test header.theme === nothing
        @test [e.type for e in events] == [OutputEvent, OutputEvent, MarkerEvent, OutputEvent,
                                           ResizeEvent, OutputEvent, ExitEvent]
        # Intervals are accumulated into times since the start, including the interval
        # of the skipped event
        @test [e.time for e in events] ≈ cumsum([0.248, 1.001, 3.5, 0.143, 2.05, 0.5 + 1.041, 0.887])
        @test events[1].event_data == "\e[1;31mHello \e[32mWorld!\e[0m\n"
        @test events[5].event_data == "90x30"
        @test events[end].event_data == "0"

        # `term` fields and `tags` are read; an explicit `TERM` in `env` is kept
        theme = Dict("fg" => "#d0d0d0", "bg" => "#212121", "palette" => join(fill("#151515", 8), ":"))
        header_line = JSON.json(Dict("version" => 3, "tags" => ["demo"],
            "term" => Dict("cols" => 100, "rows" => 50, "type" => "xterm", "version" => "VTE(7802)", "theme" => theme),
            "env" => Dict("TERM" => "screen"), "idle_time_limit" => 2))
        header, events = parse_cast(IOBuffer(header_line * "\n"))
        @test (header.width, header.height) == (100, 50)
        @test header.theme == theme
        @test header.env == Dict("TERM" => "screen")
        @test header.term_type == "xterm"
        @test header.term_version == "VTE(7802)"
        @test header.tags == ["demo"]
        @test header.idle_time_limit == 2.0
        @test isempty(events)

        # Minimal header
        header, events = parse_cast(IOBuffer("""{"version": 3, "term": {"cols": 10, "rows": 5}}\n[1.0, "o", "a"]\n"""))
        @test (header.width, header.height, header.env, header.timestamp) == (10, 5, nothing, nothing)
        @test (header.term_type, header.term_version, header.tags, header.theme) == (nothing, nothing, nothing, nothing)
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
        header_obj = JSON.parse(lines[1])
        @test header_obj.version == 3
        @test header_obj.term.cols == 80
        @test header_obj.term.rows == 24
        @test header_obj.term.type == get(ENV, "TERM", "xterm-256color")
        @test header_obj.term.theme.fg == "#ffffff"
        @test header_obj.title == "t"
        @test !haskey(header_obj, "width") && !haskey(header_obj, "height") && !haskey(header_obj, "theme")
        @test !haskey(header_obj.env, "TERM")
        # Intervals, not absolute times
        @test [JSON.parse(l)[1] for l in lines[2:end]] == [0.25, 0.75, 0.0, 2.5]
        @test [JSON.parse(l)[2] for l in lines[2:end]] == ["o", "i", "m", "x"]

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

    @testset "Event data line endings" begin
        # `write_event!` writes a lone `\n` as `\r\n` in output and input data only
        for version in (2, 3)
            io = IOBuffer()
            cast = Cast(io, Header(; version))
            written = [Event(0.5, OutputEvent, "abc\nX"), Event(0.6, OutputEvent, "a\r\nb"),
                       Event(0.7, InputEvent, "1+1\n"), Event(1.0, MarkerEvent, "first\nsecond"),
                       Event(1.5, ResizeEvent, "100x30"), Event(2.0, ExitEvent, "0")]
            foreach(e -> write_event!(cast, e), written)
            _, events = parse_cast(seekstart(io))
            @test [e.event_data for e in events] == ["abc\r\nX", "a\r\nb", "1+1\r\n", "first\nsecond", "100x30", "0"]
        end

        # Converting a v3 cast to v2 keeps the event data and times as read from the v3 file
        v3 = """{"version":3,"term":{"cols":80,"rows":24}}
            [0.5,"o","abc\\nX"]
            [0.25,"i","y\\n"]
            [0.25,"m","first\\nsecond"]
            [0.125,"r","100x30"]
            [1.0,"x","1"]
            """
        header, events = parse_cast(IOBuffer(v3))
        @test [e.event_data for e in events] == ["abc\nX", "y\n", "first\nsecond", "100x30", "1"]
        cast = Asciicast.Cast{IOBuffer}(IOBuffer(Vector{UInt8}(v3)), header, 0.0, Ref(0), Ref(0), 0.0, false)
        h2, events2 = parse_cast(IOBuffer(Asciicast.v2_bytes(cast)))
        @test h2.version == 2
        @test events2 == events
        html = sprint(show, MIME"text/html"(), cast)
        b64 = match(r"base64,([^']*)'", html)[1]
        @test parse_cast(IOBuffer(base64decode(b64)))[2] == events

        # `delay` is applied once, when the v3 cast is written, not again by the conversion
        io = IOBuffer()
        cast = Cast(io, Header(; version=3); delay=0.5)
        foreach(t -> write_event!(cast, Event(t, OutputEvent, ".")), [0.0, 0.25, 0.5])
        _, events = parse_cast(IOBuffer(Asciicast.collect_bytes(cast)))
        @test [e.time for e in events] == [0.0, 0.75, 1.5]
        @test parse_cast(IOBuffer(Asciicast.v2_bytes(cast)))[2] == events
    end

    @testset "Header reading and writing" begin
        header_line(header) = (io = IOBuffer(); Cast(io, header); String(take!(seekstart(io))))
        reparse(header) = first(parse_cast(IOBuffer(header_line(header))))

        # Top-level key order is fixed by the writer; `env` and `theme` keys are sorted
        header = withenv("TERM" => "xterm-256color", "SHELL" => "/bin/bash") do
            Header(; timestamp=1)
        end
        @test header_line(header) == """{"version":2,"width":80,"height":24,"timestamp":1,"env":{"SHELL":"/bin/bash","TERM":"xterm-256color"}}\n"""
        @test header_line(Header(; timestamp=1, env=nothing)) == """{"version":2,"width":80,"height":24,"timestamp":1}\n"""
        many = Dict(string(c) => "v" for c in 'a':'z')
        theme = Dict("palette" => "#000000:#ffffff", "fg" => "#ffffff", "bg" => "#000000")
        for version in (2, 3)
            line = header_line(Header(; version, env=many, theme, term_type=nothing))
            @test contains(line, "{" * join(("\"$c\":\"v\"" for c in 'a':'z'), ",") * "}")
            @test contains(line, """{"bg":"#000000","fg":"#ffffff","palette":"#000000:#ffffff"}""")
        end

        # v2: `term_type` is stored as `env["TERM"]`, unless `env` has its own `TERM`
        h = reparse(Header(; term_type="xterm", env=Dict("SHELL" => "/bin/sh")))
        @test (h.term_type, h.env) == ("xterm", Dict("SHELL" => "/bin/sh"))
        h = reparse(Header(; term_type="xterm", env=Dict("TERM" => "screen")))
        @test (h.term_type, h.env) == ("screen", Dict{String, String}())

        # v2 has no `term_version` or `tags`
        line = header_line(Header(; term_version="1.0", tags=["a"], duration=1.5))
        @test !contains(line, "tags") && !contains(line, "1.0") && contains(line, "duration")

        # v3 files round-trip through `parse_cast` and `Cast`
        theme = Dict("fg" => "#d0d0d0", "bg" => "#212121", "palette" => join(fill("#151515", 8), ":"))
        v3 = JSON.json(Dict("version" => 3, "tags" => ["demo", "test"], "timestamp" => 1,
            "idle_time_limit" => 2.5, "command" => "julia", "title" => "T",
            "env" => Dict("SHELL" => "/bin/zsh"),
            "term" => Dict("cols" => 100, "rows" => 50, "type" => "xterm", "version" => "VTE(7802)", "theme" => theme)))
        header, _ = parse_cast(IOBuffer(v3 * "\n"))
        @test JSON.parse(header_line(header)) == JSON.parse(v3)
        h = reparse(header)
        @test all(getfield(h, k) == getfield(header, k) for k in fieldnames(Header))
        h = reparse(Header(; version=3, duration=1.5))
        @test h.duration === nothing && h.version == 3

        # Converting v3 to v2 for the player keeps `term_type` (as `env["TERM"]`)
        cast = Cast(IOBuffer(), header)
        write_event!(cast, Event(0.5, OutputEvent, "a"))
        h2, events2 = parse_cast(IOBuffer(Asciicast.v2_bytes(cast)))
        @test h2.version == 2
        @test (h2.term_type, h2.env, h2.theme, h2.tags) == ("xterm", Dict("SHELL" => "/bin/zsh"), theme, nothing)
        @test events2 == [Event(0.5, OutputEvent, "a")]
    end

    # Files written by other tools; see test/casts/README.md for their sources
    @testset "Casts from other tools" begin
        castdir = joinpath(@__DIR__, "casts")
        palette = "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5"
        # Expected values, read from the files by hand. Header fields not listed are `nothing`.
        expected = Dict(
            "asciinema-edit-v2.cast" => (; version=2, width=208, height=59, timestamp=1530639832,
                term_type="xterm-256color", env=Dict("SHELL" => "/bin/zsh"),
                counts=Dict(OutputEvent => 78), markers=String[],
                first=(0.258703, OutputEvent, "\e]7;file://cirocosta.local/Users/cirocosta/Development/go/src/github.com/cirocosta/asciinema-edit\a"),
                last=(13.411091, OutputEvent, "\e]2;exit\a\e]1;exit\a")),
            "termtosvg-awesome-v2.cast" => (; version=2, width=82, height=19,
                theme=Dict("fg" => "#839496", "bg" => "#002b36", "palette" => "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#002b36:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3"),
                counts=Dict(OutputEvent => 94), markers=String[],
                first=(0.0, OutputEvent, "\e[0;31mnico \e[0;34m~\e[0;31m \$ \e[0m"),
                last=(26.349826, OutputEvent, "")),
            # Extra header fields (`sessionId`, `toolVersion`) are ignored
            "agent-tty-v2.cast" => (; version=2, width=100, height=30, timestamp=1777491553,
                title="01KQDC1A7M9FN8EVETNKPJBDDT", term_type="xterm-256color", env=Dict{String, String}(),
                counts=Dict(OutputEvent => 8, MarkerEvent => 1, ResizeEvent => 1), markers=["issue-63-proof"],
                first=(0.0, OutputEvent, "\e[?2004hbash-5.1\$ "),
                last=(9.723, ResizeEvent, "100x30")),
            "server-full-v2.cast" => (; version=2, width=96, height=26, timestamp=1506410422,
                command="/bin/bash -l", title="bashing :)", idle_time_limit=2.5,
                term_type="screen-256color", env=Dict("SHELL" => "/bin/zsh"),
                theme=Dict("fg" => "#aaaaaa", "bg" => "#bbbbbb", "palette" => palette),
                counts=Dict(OutputEvent => 3, ResizeEvent => 1, InputEvent => 1), markers=String[],
                first=(1.234567, OutputEvent, "foo bar"),
                last=(8.456789, OutputEvent, "żółć jaźń")),
            # v3 files may repeat `term.type` as `env["TERM"]`
            "server-full-v3.cast" => (; version=3, width=96, height=26, timestamp=1744302022,
                command="/bin/bash -l", title="bashing :)", idle_time_limit=2.5,
                term_type="xterm-ghostty", term_version="ghostty 1.1.3-889478f-nix",
                env=Dict("TERM" => "xterm-ghostty", "SHELL" => "/usr/bin/fish"),
                theme=Dict("fg" => "#aaaaaa", "bg" => "#bbbbbb", "palette" => palette),
                counts=Dict(OutputEvent => 3, ResizeEvent => 1, InputEvent => 1), markers=String[],
                first=(1.234567, OutputEvent, "foo bar"),
                last=(10.370343, OutputEvent, "żółć jaźń")),
            "server-comments-v3.cast" => (; version=3, width=96, height=26,
                counts=Dict(OutputEvent => 4), markers=String[],
                first=(1.234567, OutputEvent, "foo bar"),
                last=(9.481455, OutputEvent, "bye!")),
            "tagfill-v3.cast" => (; version=3, width=80, height=24, timestamp=1787768995,
                idle_time_limit=1.5, command="./demo/demo.sh", env=Dict("SHELL" => "/usr/bin/bash"),
                counts=Dict(OutputEvent => 23, ExitEvent => 1), markers=String[],
                first=(0.005, OutputEvent, "\r\n\e[1;36m\$ du -sh demo/Music && find demo/Music -type f | wc -l\e[0m\r\n"),
                last=(90.63, ExitEvent, "0")),
            "oobscan-v3.cast" => (; version=3, width=80, height=30, timestamp=1793737262,
                idle_time_limit=1.5, term_type="xterm-256color", term_version="xterm.js(6.1.0-beta.304)",
                command="/tmp/oobscan-demo-wrapper.sh 'oobscan scan --disable-logins 10.0.10.0/24 10.0.20.0/23' '<redacted>'",
                env=Dict("SHELL" => "/bin/zsh"),
                counts=Dict(OutputEvent => 21, ExitEvent => 1), markers=String[],
                first=(0.353, OutputEvent, "\e[1;32mroot@bmc-lab\e[0m:\e[1;34m~\e[0m# oobscan scan --disable-logins 10.0.10.0/24 10.0.20.0/23\r\n"),
                last=(36.611, ExitEvent, "0")),
            "scenetake-basic-v3.cast" => (; version=3, width=80, height=24, timestamp=1702967308,
                title="Basic Demo", term_type="xterm-256color", env=Dict("SHELL" => "bash"),
                theme=Dict("fg" => "#d0d0d0", "bg" => "#282c34", "palette" => palette),
                tags=["st:font-size=16", "st:font-family=ui-monospace, \"Cascadia Mono\", \"Cascadia Code\", \"JetBrains Mono\", \"Noto Sans Mono\", SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", monospace"],
                counts=Dict(OutputEvent => 184, MarkerEvent => 2, ExitEvent => 1),
                markers=["Name of the step", "Coloring stdout"],
                first=(0.9, OutputEvent, "\$ "),
                last=(16.761, ExitEvent, "0")),
        )
        @test sort(collect(keys(expected))) == sort(filter(endswith(".cast"), readdir(castdir)))

        header_fields = (:width, :height, :timestamp, :duration, :idle_time_limit, :command, :title,
                         :env, :theme, :term_type, :term_version, :tags)
        codes = Dict("o" => OutputEvent, "i" => InputEvent, "m" => MarkerEvent, "r" => ResizeEvent, "x" => ExitEvent)
        # `write_event!` writes a lone `\n` in output and input data as `\r\n`
        crlf(e) = e.type in (OutputEvent, InputEvent) ? replace(e.event_data, r"(?<!\r)\n" => "\r\n") : e.event_data
        same_events(a, b; atol) = length(a) == length(b) &&
            all(x.type == y.type && x.event_data == crlf(y) &&
                isapprox(x.time, y.time; atol) for (x, y) in zip(a, b))
        function rewrite(header, events)
            io = IOBuffer()
            cast = Cast(io, header)
            foreach(e -> write_event!(cast, e), events)
            return parse_cast(seekstart(io))
        end
        # A `Cast` over the file's own bytes, so `show` and `v2_bytes` see the file as written
        file_cast(bytes, header) = Asciicast.Cast{IOBuffer}(IOBuffer(bytes), header, 0.0, Ref(0), Ref(0), 0.0, false)

        @testset "$name" for (name, exp) in expected
            path = joinpath(castdir, name)
            header, events = open(parse_cast, path)

            @test header.version == exp.version
            for k in header_fields
                @test getfield(header, k) == get(exp, k, nothing)
            end
            @test Dict(t => count(e -> e.type == t, events) for t in unique(e.type for e in events)) == exp.counts
            @test [e.event_data for e in events if e.type == MarkerEvent] == exp.markers
            @test (events[1].type, events[1].event_data) == exp.first[2:3]
            @test (events[end].type, events[end].event_data) == exp.last[2:3]
            @test events[1].time ≈ exp.first[1]
            @test events[end].time ≈ exp.last[1]

            # Independent reading of the raw lines
            lines = filter(l -> !isempty(strip(l)) && !(exp.version == 3 && startswith(l, "#")), readlines(path))
            @test JSON.parse(lines[1]).version == exp.version
            raw = [JSON.parse(l) for l in lines[2:end]]
            times = exp.version == 3 ? cumsum(Float64[r[1] for r in raw]) : Float64[r[1] for r in raw]
            @test length(events) == length(raw)
            @test [e.time for e in events] ≈ times
            @test [e.type for e in events] == [codes[r[2]] for r in raw]
            @test [e.event_data for e in events] == [String(r[3]) for r in raw]

            # Round trip in the same version; v3 times are rounded to milliseconds when written
            header2, events2 = rewrite(header, events)
            @test header2.version == header.version
            for k in header_fields
                @test getfield(header2, k) == getfield(header, k)
            end
            @test same_events(events2, events; atol=exp.version == 3 ? 0.0005 + 1e-9 : 0.0)

            cast = file_cast(read(path), header)
            if exp.version == 3
                h2, e2 = parse_cast(IOBuffer(Asciicast.v2_bytes(cast)))
                @test h2.version == 2
                @test (h2.width, h2.height, h2.timestamp, h2.idle_time_limit, h2.command, h2.title, h2.theme) ==
                      (header.width, header.height, header.timestamp, header.idle_time_limit, header.command, header.title, header.theme)
                # v2 stores the terminal type only in `env["TERM"]`, which a v3 `env` may already set
                env = header.env
                @test h2.term_type == (env === nothing ? nothing : get(env, "TERM", header.term_type))
                @test e2 == events
            end
            if name in ("asciinema-edit-v2.cast", "oobscan-v3.cast")
                html = sprint(show, MIME"text/html"(), cast)
                @test contains(html, "AsciinemaPlayer.create")
                b64 = match(r"base64,([^']*)'", html)[1]
                @test parse_cast(IOBuffer(base64decode(b64)))[2] == events
            end
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
