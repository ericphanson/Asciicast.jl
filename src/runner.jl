using Markdown
using REPL
using IOCapture
using Documenter
using Documenter: Utilities, Expanders, Documents
using Documenter.Utilities: Selectors
using Documenter.Expanders: ExpanderPipeline, iscode, _any_color_fmt, droplines, prepend_prompt, remove_sandbox_from_output
using UUIDs

abstract type GifBlocks <: ExpanderPipeline end

Selectors.order(::Type{GifBlocks}) = 12.0
Selectors.matcher(::Type{GifBlocks}, node, page, doc) = iscode(node, r"^@gif")

# Slightly modified from:
# https://github.com/JuliaDocs/Documenter.jl/blob/68dbd53d4ff6b339e795a4a3328955ad5c689e0e/src/Expanders.jl#L638-L696
function Selectors.runner(::Type{GifBlocks}, x, page, doc)
    matched = match(r"^@gif(?:\s+([^\s;]+))?\s*(;.*)?$", x.language)
    matched === nothing && error("invalid '@gif' syntax: $(x.language)")
    name, kwargs = matched.captures
    # The sandboxed module -- either a new one or a cached one from this page.
    mod = Utilities.get_sandbox_module!(page.globals.meta, "atexample", name)

    # "parse" keyword arguments to repl
    ansicolor = _any_color_fmt(doc)
    if kwargs !== nothing
        matched = match(r"\bansicolor\s*=\s*(true|false)\b", kwargs)
        if matched !== nothing
            ansicolor = matched[1] == "true"
        end
    end

    name = "$(uuid4()).cast"
    cast = Cast(joinpath(page.workdir, "assets", "casts", name); delay=.5)
    raw_html = Documents.RawHTML("""<asciinema-player src="./assets/casts/$(name)" idle-time-limit="1" autoplay="true" start-at="0.3"></asciinema-player >""")
    multicodeblock = Markdown.Code[]
    linenumbernode = LineNumberNode(0, "REPL") # line unused, set to 0
    @debug "Evaluating @gif block:\n$(x.code)"
    for (ex, str) in Utilities.parseblock(x.code, doc, page; keywords = false,
                                          linenumbernode = linenumbernode)
        buffer = IOBuffer()
        input  = droplines(str)
        if VERSION >= v"1.5.0-DEV.178"
            # Use the REPL softscope for REPLBlocks,
            # see https://github.com/JuliaLang/julia/pull/33864
            ex = REPL.softscope!(ex)
        end
        c = IOCapture.capture(rethrow = InterruptException, color = ansicolor) do
            cd(page.workdir) do
                Core.eval(mod, ex)
            end
        end
        Core.eval(mod, Expr(:global, Expr(:(=), :ans, QuoteNode(c.value))))
        result = c.value
        output = if !c.error
            hide = REPL.ends_with_semicolon(input)
            Documenter.DocTests.result_to_string(buffer, hide ? nothing : c.value)
        else
            Documenter.DocTests.error_to_string(buffer, c.value, [])
        end
        if !isempty(input)
            push!(multicodeblock, Markdown.Code("julia-repl", prepend_prompt(input)))
            write_event!(cast, InputEvent, input)
            write_event!(cast, OutputEvent, prepend_prompt(input) * "\n")
        end
        out = IOBuffer()
        print(out, c.output) # c.output is std(out|err)
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
    page.mapping[x] = Documents.MultiOutput([Documents.MultiCodeBlock("julia-repl", multicodeblock), raw_html])
end
