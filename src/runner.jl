using Markdown
using REPL
using Documenter
using Documenter: Utilities, Expanders, Documents
using Documenter.Utilities: Selectors
using Documenter.Expanders: ExpanderPipeline, iscode, _any_color_fmt, droplines, prepend_prompt, remove_sandbox_from_output
using UUIDs

abstract type CastBlocks <: ExpanderPipeline end

Selectors.order(::Type{CastBlocks}) = 12.0
Selectors.matcher(::Type{CastBlocks}, node, page, doc) = iscode(node, r"^@cast")

# Slightly modified from:
# https://github.com/JuliaDocs/Documenter.jl/blob/68dbd53d4ff6b339e795a4a3328955ad5c689e0e/src/Expanders.jl#L638-L696
function Selectors.runner(::Type{CastBlocks}, x, page, doc)
    matched = match(r"^@cast(?:\s+([^\s;]+))?\s*(;.*)?$", x.language)
    matched === nothing && error("invalid '@cast' syntax: $(x.language)")
    name, kwargs = matched.captures
    # The sandboxed module -- either a new one or a cached one from this page.
    mod = Utilities.get_sandbox_module!(page.globals.meta, "atexample", name)

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

    multicodeblock = Markdown.Code[]
    cast = Cast(IOBuffer(); delay=delay)
    cast_from_string!(x.code, cast; doc=doc, page=page, ansicolor=ansicolor, mod=mod, multicodeblock=multicodeblock)
    
    name = "$(uuid4()).cast"
    raw_html = Documents.RawHTML("""<asciinema-player src="./assets/casts/$(name)" idle-time-limit="1" autoplay="true" start-at="0.3"></asciinema-player >""")

    path = joinpath(page.workdir, "assets", "casts", name)
    mkpath(dirname(path))
    write(path, take!(cast.write_handle))

    page.mapping[x] = Documents.MultiOutput([Documents.MultiCodeBlock("julia-repl", multicodeblock), raw_html])
end


Base.@kwdef struct FakeDoc
    internal = (; errors = [])
end

Base.@kwdef struct FakePage
    workdir = pwd()
end
Utilities.locrepr(::FakePage) = nothing



function cast_from_string!(code_string::AbstractString, cast::Cast; doc=FakeDoc(), page=FakePage(), ansicolor=true, mod = Module(), multicodeblock = Markdown.Code[])
    linenumbernode = LineNumberNode(0, "REPL") # line unused, set to 0
    @debug "Evaluating @cast:\n$(x.code)"
    for (ex, str) in Utilities.parseblock(code_string, doc, page; keywords = false,
                                          linenumbernode = linenumbernode)
        buffer = IOBuffer()
        input  = droplines(str)
        if !isempty(input)
            push!(multicodeblock, Markdown.Code("julia-repl", prepend_prompt(input)))
            write_event!(cast, InputEvent, input)
            write_event!(cast, OutputEvent, prepend_prompt(input) * "\n")
        end
        
        if VERSION >= v"1.5.0-DEV.178"
            # Use the REPL softscope for REPLBlocks,
            # see https://github.com/JuliaLang/julia/pull/33864
            ex = REPL.softscope!(ex)
        end
        c = capture(cast; rethrow = InterruptException, color = ansicolor,
        process = str -> remove_sandbox_from_output(str, mod)) do
            cd(page.workdir) do
                Core.eval(mod, ex)
            end
        end
        Core.eval(mod, Expr(:global, Expr(:(=), :ans, QuoteNode(c.value))))
        output = if !c.error
            hide = REPL.ends_with_semicolon(input)
            Documenter.DocTests.result_to_string(buffer, hide ? nothing : c.value)
        else
            Documenter.DocTests.error_to_string(buffer, c.value, [])
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
        write_event!(cast, OutputEvent, outstr)
    end
end


"""
    @cast_str(code_string, delay=0) -> Cast

Creates a [`Cast`](@ref) object by executing the code in `code_string` in a REPL-like environment.

## Example

```julia
using Asciicast

c = cast"x=1"0.5 # note we set a delay of 0.5 here

Asciicast.save("test.cast", c)
```

"""
macro cast_str(code_string, delay=0)
    cast = Cast(IOBuffer(); delay=delay)
    cast_from_string!(code_string, cast)
    return cast
end
