
abstract type CastBlocks <: ExpanderPipeline end

Selectors.order(::Type{CastBlocks}) = 12.0
Selectors.matcher(::Type{CastBlocks}, node, page, doc) = iscode(node, r"^@cast")

# Slightly modified from:
# https://github.com/JuliaDocs/Documenter.jl/blob/c5a89ab8a56c9e9c77497070a57362659aadd131/src/expander_pipeline.jl#L810C1-L881C1
function Selectors.runner(::Type{CastBlocks}, node, page, doc)
    @assert node.element isa MarkdownAST.CodeBlock
    x = node.element
    x.info = replace(x.info, "@cast" => "@repl")
    Selectors.runner(Expanders.REPLBlocks, node, page, doc)
    delay = 0.5
    n_lines = length(split(x.code))
    height = min(n_lines * 2 + 1, 24) # try to choose the number of lines more appropriately
    cast = Cast(IOBuffer(), Header(; height, idle_time_limit=1); delay=delay)
    code_blocks_to_cast!(cast, node.children; repl=true)
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

    mcb = MarkdownAST.Node(node.element)
    node.element = Documenter.MultiOutput(MarkdownAST.CodeBlock("julia-repl", ""))

    # Here, we move the children of `node` to be children of `mcb`
    # `collect` seems necessary, which is weird
    for elt in collect(node.children)
        push!(mcb.children, elt)
    end

    # Now we place our own children
    empty!(node.children)

    push!(node.children, mcb)
    push!(node.children, Documenter.Node(Documenter.MultiOutputElement(
        Dict{MIME,Any}(MIME"text/html"() => raw_html)
    )))
    return cast
end

function strip_prompt(line)
    prompt = match(Documenter.PROMPT_REGEX, line)
    prompt === nothing && return line
    return prompt[1]
end

function code_blocks_to_cast!(cast, code_blocks; repl)
    for block in code_blocks
        block = block.element
        if repl && block.info == "julia-repl"
            write_event!(cast, InputEvent, strip_prompt(block.code) * "\n")
        end
        str = block.code
        if !isempty(str) && block.info != "julia-repl"
            str *= "\n\n"
        else
            str *= "\n"
        end
        write_event!(cast, OutputEvent, str)
    end
    return cast
end

function _cast(code; delay=0)
    node = MarkdownAST.Node(MarkdownAST.CodeBlock("@repl", code))
    Selectors.runner(Expanders.REPLBlocks, node, FakePage(), FakeDoc())
    n_lines = length(split(code)) - 2
    height = min(n_lines * 2 + 1, 24) # try to choose the number of lines more appropriately
    cast = Cast(IOBuffer(), Header(; height, idle_time_limit=1); delay=delay)
    code_blocks_to_cast!(cast, node.children; repl=true)
    return cast
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
    return _cast(code_string; delay)
end

Base.@kwdef struct FakeDoc
    internal = (; errors=[])
end
Documenter.is_draft(::FakeDoc) = false
Documenter._any_color_fmt(::FakeDoc) = true
Base.@kwdef struct FakePage
    workdir = pwd()
    globals = Documenter.Globals()
end
Documenter.locrepr(::FakePage) = nothing
