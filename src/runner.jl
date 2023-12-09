
abstract type CastBlocks <: ExpanderPipeline end

Selectors.order(::Type{CastBlocks}) = 12.0
Selectors.matcher(::Type{CastBlocks}, node, page, doc) = iscode(node, r"^@cast")



using MarkdownAST

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
    delay = 0.5
    if kwargs !== nothing
        matched = match(r"\bansicolor\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            ansicolor = matched[1] == "true"
        end

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
    height = min(n_lines*2, 24) # try to choose the number of lines more appropriately
    cast = Cast(IOBuffer(), Header(; height, idle_time_limit=1); delay=delay)

    cast_from_string!(x.code, cast; doc=doc, page=page, ansicolor=ansicolor, mod=mod, multicodeblock=multicodeblock)

    name = "$(uuid4()).cast"
    raw_html = """
    <div id="$(name)"></div>
    <script>
    AsciinemaPlayer.create('./assets/casts/$(name)', document.getElementById('$(name)'), { autoPlay: true, fit: false, startAt: $(0.8*delay)});
    </script>
    """

    path = joinpath(page.workdir, "assets", "casts", name)
    mkpath(dirname(path))
    write(path, take!(cast.write_handle))

    # https://github.com/JuliaDocs/Documenter.jl/blob/c5a89ab8a56c9e9c77497070a57362659aadd131/src/expander_pipeline.jl#L58C4-L64C8
    node.element = Documenter.MultiOutput(MarkdownAST.CodeBlock("julia-repl", ""))

    mcb = Documenter.Node(Documenter.MultiCodeBlock(x, "julia-repl", []))

    for element in multicodeblock
        push!(mcb.children, Documenter.Node(element))
    end
    push!(node.children, mcb)
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



function cast_from_string!(code_string::AbstractString, cast::Cast; doc=FakeDoc(), page=FakePage(), ansicolor=true, mod=Module(), multicodeblock=MarkdownAST.CodeBlock[])
    linenumbernode = LineNumberNode(0, "REPL") # line unused, set to 0
    @debug "Evaluating @cast:\n$(x.code)"

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
        else
            Documenter.error_to_string(buffer, c.value, [])
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
    @cast_str(code_string, delay=0) -> Cast

Creates a [`Cast`](@ref) object by executing the code in `code_string` in a REPL-like environment.

## Example

```julia
using Asciicast

c = cast"x=1"0.25 # note we set a delay of 0.25 here

Asciicast.save("test.cast", c)
```

"""
macro cast_str(code_string, delay=0)
    cast = Cast(IOBuffer(); delay=delay)
    cast_from_string!(code_string, cast)
    return cast
end
