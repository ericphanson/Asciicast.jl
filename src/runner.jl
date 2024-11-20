abstract type CastBlocks <: ExpanderPipeline end

Selectors.order(::Type{CastBlocks}) = 9.1 # just after REPL blocks
Selectors.matcher(::Type{CastBlocks}, node, page, doc) = iscode(node, r"^@cast")

# We can't just run the actual REPLBlocks, because then we have no timing information.
# Thus, we need to basically reproduce their implementation, while saving timing info.

# Slightly modified from:
# https://github.com/JuliaDocs/Documenter.jl/blob/c5a89ab8a56c9e9c77497070a57362659aadd131/src/expander_pipeline.jl#L810C1-L881C1
function Selectors.runner(::Type{CastBlocks}, node, page, doc)
    @assert node.element isa MarkdownAST.CodeBlock
    x = node.element

    matched = match(r"^@cast(?:\s+([^\s;]+))?\s*(;.*)?$", x.info)
    matched === nothing && error("invalid '@cast' syntax: $(x.info)")
    name, kwargs = matched.captures

    # Bail early if in draft mode
    if Documenter.is_draft(doc, page)
        @debug "Skipping evaluation of @cast block in draft mode:\n$(x.code)"
        create_draft_result!(node; blocktype="@cast")
        return
    end

    # The sandboxed module -- either a new one or a cached one from this page.
    mod = Documenter.get_sandbox_module!(page.globals.meta, "atexample", name)

    # "parse" keyword arguments to repl
    ansicolor = _any_color_fmt(doc)
    hide_inputs = false
    allow_errors = false
    delay = 0.25
    height = nothing
    loop = false
    if kwargs !== nothing
        # ansicolor
        matched = match(r"\bansicolor\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            ansicolor = matched[1] == "true"
        end

        # hide_inputs
        matched = match(r"\bhide_inputs\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            hide_inputs = matched[1] == "true"
        end

        # allow_errors
        matched = match(r"\ballow_errors\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            allow_errors = matched[1] == "true"
        end

        # height
        matched = match(r"\bheight\s*=\s*([0-9]+)", kwargs)
        if matched !== nothing
            height = parse(Int, matched[1])
        end

        # width
        matched = match(r"\bwidth\s*=\s*([0-9]+)", kwargs)
        if matched !== nothing
            width = parse(Int, matched[1])
        end

        # loop
        # bool:
        matched = match(r"\bloop\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            loop = matched[1] == "true"
        else
            # integer:
            matched = match(r"\bloop\s*=\s*([0-9]+)", kwargs)
            if matched !== nothing
                loop = parse(Int, matched[1])
            end
        end

        # delay
        # match integer delay
        matched = match(r"\bdelay\s*=\s*([0-9]+)", kwargs)
        if matched !== nothing
            delay = convert(Float64, parse(Int, matched[1]))
        else
            # match float delay
            matched = match(r"\bdelay\s*=\s*((?:[0-9]*[.])?[0-9]+)", kwargs)
            if matched !== nothing
                delay = parse(Float64, matched[1])
            end
        end
    end

    multicodeblock = MarkdownAST.CodeBlock[]

    n_lines = length(split(x.code))

    # If `height` isn't provided, we guess the number of lines:
    height = something(height, min(n_lines * 2, 24))
    width = something(width, 80)
    cast = Cast(IOBuffer(), Header(; height, width, idle_time_limit=1); delay, loop)

    cast_from_string!(x.code, cast; doc, page, ansicolor, mod, multicodeblock, allow_errors, x)

    raw_html = sprint(show, MIME"text/html"(), cast)

    # https://github.com/JuliaDocs/Documenter.jl/blob/c5a89ab8a56c9e9c77497070a57362659aadd131/src/expander_pipeline.jl#L58C4-L64C8
    node.element = Documenter.MultiOutput(MarkdownAST.CodeBlock("julia-repl", ""))

    if !hide_inputs
        mcb = Documenter.Node(Documenter.MultiCodeBlock(x, "julia-repl", []))
        for element in multicodeblock
            push!(mcb.children, Documenter.Node(element))
        end
        push!(node.children, mcb)
    end
    push!(node.children, Documenter.Node(Documenter.MultiOutputElement(
        Dict{MIME,Any}(MIME"text/html"() => raw_html)
    )))

end


Base.@kwdef struct FakeDoc
    internal = (; errors=[])
end

Base.@kwdef struct FakePage
    workdir = pwd()
end
Documenter.locrepr(::FakePage) = nothing

struct CastExecutionException <: Exception
    code::String
    error::String
end

function Base.showerror(io::IO, c::CastExecutionException)
    print(io,
        """
        CastExecutionException: Failed to run `cast` block:
        ```
        $(c.code)
        ```
        $(c.error)
        """)
end

function cast_from_string!(code_string::AbstractString, cast::Cast; doc=FakeDoc(), page=FakePage(), ansicolor=true, mod=get_module(), multicodeblock=MarkdownAST.CodeBlock[], allow_errors=false, x=nothing, remove_prompt=false)
    linenumbernode = LineNumberNode(0, "REPL") # line unused, set to 0
    @debug "Evaluating @cast:\n$(x.code)"

    # if there are prompts, and we are to remove them, we will use
    # prompt-pasting semantics, where only lines with the prompt count,
    # and those prompts are removed.
    # xref https://github.com/JuliaLang/julia/pull/17599/files
    if remove_prompt && contains(code_string, r"^julia>"m)
        code_string_io = IOBuffer()
        for line in eachsplit(code_string, r"(?>\r\n|\n|\r)")
            startswith(line, "julia>") || continue
            n = 6 # length("julia>")
            n += startswith(" ", line)
            println(code_string_io, @view(line[(n+1):end]))
        end
        code_string = String(take!(code_string_io))
    end

    pb = Documenter.parseblock(code_string, doc, page; keywords=false,
        linenumbernode=linenumbernode)
    n = length(pb)
    for (i, (ex, str)) in enumerate(pb)
        buffer = IOBuffer()
        input = droplines(str)
        if !isempty(input)
            push!(multicodeblock, MarkdownAST.CodeBlock("julia-repl", prepend_prompt(input)))
            write_event!(cast, InputEvent, input)
            write_event!(cast, OutputEvent, prepend_prompt(input) * "\n")
        end

        if VERSION >= v"1.5.0-DEV.178"
            # Use the REPL softscope for REPLBlocks,
            # see https://github.com/JuliaLang/julia/pull/33864
            ex = REPL.softscope!(ex)
        end
        c = capture(cast; rethrow=InterruptException, color=ansicolor,
            process=str -> remove_sandbox_from_output(str, mod)) do
            cd(page.workdir) do
                Core.eval(mod, ex)
            end
        end
        Core.eval(mod, Expr(:global, Expr(:(=), :ans, QuoteNode(c.value))))
        output = if !c.error
            hide = REPL.ends_with_semicolon(input)
            Documenter.result_to_string(buffer, hide ? nothing : c.value)
        elseif allow_errors
            Documenter.error_to_string(buffer, c.value, [])
        elseif !isnothing(x)
            lines = Documenter.find_block_in_file(x.code, page.source)
            bt = Documenter.remove_common_backtrace(c.backtrace)
            # we pretend to be an `example_block`, since it doesn't seem great
            # to mutate Documenter's global list of error types before parse time
            Documenter.@docerror(doc, :example_block,
                """
                failed to run `@cast` block in $(Documenter.locrepr(page.source, lines))
                ```$(x.info)
                $(x.code)
                ```
                """, exception = (c.value, bt))
            return
        else
            throw(CastExecutionException(code_string, Documenter.error_to_string(buffer, c.value, [])))
        end

        out = IOBuffer()
        if isempty(input) || isempty(output)
            println(out)
        else
            println(out, output, "\n")
        end
        outstr = String(take!(out))
        # Replace references to gensym'd module with Main
        outstr = remove_sandbox_from_output(outstr, mod)

        if i == n
            # On the last line, we chomp the extra newline we tend to get
            trimmed = chomp(outstr)
            if !isempty(trimmed)
                write_event!(cast, OutputEvent, trimmed)
            end
        else
            write_event!(cast, OutputEvent, outstr)
        end
        push!(multicodeblock, MarkdownAST.CodeBlock("documenter-ansi", rstrip(outstr)))
    end
end


"""
    @cast_str(code_string, delay=0, allow_errors=false) -> Cast

Creates a [`Cast`](@ref) object by executing the code in `code_string` in a REPL-like environment.

## Example

```julia
using Asciicast

c = cast"x=1"0.25 # note we set a delay of 0.25 here

Asciicast.save("test.cast", c)
```

To allow exceptions, one needs to invoke the macro manually on a string:

```julia
using Asciicast
c = @cast_str("error()", 0, true)
Asciicast.save("test.cast", c)
```
"""
macro cast_str(code_string, delay=0, allow_errors=false)
    return _cast_str(code_string, delay; allow_errors)
end

function _cast_str(code_string, delay=0; height=nothing, allow_errors=false, mod=get_module())
    n_lines = length(split(code_string))
    height = something(height, min(n_lines * 2, 24)) # try to choose the number of lines more appropriately
    cast = Cast(IOBuffer(), Header(; height); delay=delay)
    cast_from_string!(code_string, cast; allow_errors, remove_prompt=true, mod)
    return cast
end

# Helper to get a module using `get_sandbox_module!` so that things like
# `include` are defined. Xref https://github.com/ericphanson/Asciicast.jl/issues/32
function get_module()
    return Documenter.get_sandbox_module!(Dict(), "", nothing)
end
