"""
    save_code_gif(output_path, code_string; delay=0.25, font_size=28)

Given Julia source code as a string, run the code in a REPL mode and save the results as a gif to `output_path`.
"""
function save_code_gif(output_path, code_string; delay=0.25, font_size=28)
    cast = _cast_str(code_string, delay)
    save_gif(output_path, cast::Cast; font_size)
    return output_path
end

"""
    save_gif(output_path, cast::Cast; font_size=28)

Saves the [`Cast`](@ref) to `output_path` as a gif (using [`agg`](https://github.com/asciinema/agg)).
"""
function save_gif(output_path, cast::Cast; font_size=28)
    mktempdir() do tmp
        input_path = joinpath(tmp, "input.cast")
        save(input_path, cast)
        # Larger font size to reduce blurriness:
        # https://github.com/asciinema/agg/issues/60#issuecomment-1807910643
        run(pipeline(`$(agg()) --font-size $(font_size) $input_path $output_path`; stdout=devnull, stderr=devnull))
    end
    return output_path
end

function get_attribute(attributes, key, default)
    idx = findfirst(attr -> attr[1] == key, attributes)
    if idx === nothing
        value = default
    else
        value = tryparse(typeof(default), attributes[idx][2])
        if value === nothing
            @warn "Invalid $(key) $(attributes[idx][2]). Using default value $default."
            value = 28
        end
    end
    return value
end


# Pandoc filter to add gifs with the contents of `julia {cast="true"}` code blocks.
function cast_action(tag, content, format, meta; base_dir, counter)
    tag == "CodeBlock" || return nothing
    content[1][2][1] == "julia" || return nothing
    attributes = content[1][3]
    ["cast", "true"] in attributes || return nothing
    font_size = get_attribute(attributes, "font-size", 28)
    delay = get_attribute(attributes, "delay", 0.25)
    block = content[2]
    counter[] += 1
    c = counter[]
    name = "output_$(c)_@cast.gif"
    rel_path = joinpath("assets", name)
    save_code_gif(joinpath(base_dir, rel_path), block; delay, font_size)
    return [
        Pandoc.CodeBlock(content...)
        Pandoc.Para([Pandoc.Image(["", [], []], [], [rel_path, ""])])
    ]
end

# Pandoc filter to remove gifs that contain `@cast` in their path
function rm_old_gif(tag, content, format, meta)
    tag == "Image" || return nothing
    path = content[3][1]
    contains(path, "@cast") || return nothing
    endswith(path, ".gif") || return nothing
    return []
end

"""
    cast_readme(MyPackage::Module)
    cast_readme(MyPackage::Module, output_path)

Add gifs for each `julia {cast="true"}` code-block in the README of MyPackage. This is just a smaller helper that calls [`cast_document`](@ref) on `joinpath(pkgdir(MyPackage), "README.md")`.
See [`cast_document`](@ref) for more options and warnings.
"""
cast_readme(mod::Module) = cast_document(joinpath(pkgdir(mod), "README.md"))
cast_readme(mod::Module, output_path) = cast_document(joinpath(pkgdir(mod), "README.md"), output_path)

"""
    cast_document(input_path, output_path=input_path; format="gfm+attributes")

For each `julia {cast="true"}` code-block in the input document, generates a gif
executing that code in a REPL, saves it to `joinpath(dirname(output_path), "assets")`
and inserts it as an image following the code-block, writing the resulting document
to `output_path`.

The default `format` is Github-flavored markdown. Specify the `format` keyword argument to choose an alternate pandoc-supported format (see <https://pandoc.org/MANUAL.html#general-options>). This has only been tested with Github-flavored markdown, but theoretically should work with any pandoc format.

Returns the number of gifs generated.

!!! warning
    This function relies on parsing the document using pandoc and roundtripping through the pandoc AST. This can result in unexpected modifications to the document.

    It is recommended to check your document into source control before running this function,
    or specifying an `output_path` that is different from the input path, in order to assess
    the results.
"""
function cast_document(input_path, output_path=input_path; format="gfm+attributes", hacky_fix=true)
    json = JSON3.read(read(`$(pandoc()) -f $format -t json $input_path`), Dict)
    base_dir = dirname(output_path)
    mkpath(joinpath(base_dir, "assets"))
    counter = Ref{Int}(0)
    act = (args...) -> cast_action(args...; base_dir, counter)
    output = JSON3.write(Pandoc.filter(json, [rm_old_gif, act]))
    open(`$(pandoc()) -f json -t $format --resource-path=$(base_dir) -o $output_path`; write=true) do io
        write(io, output)
    end
    if hacky_fix
        # We do this since GitHub doesn't seem to display syntax highlighting
        # on READMEs for "``` {.julia}", although VSCode does.
        # I also think ```julia is less ugly than ``` {.julia}.
        str = read(output_path, String)
        str = replace(str, r"^``` {.julia "m => "```julia {")
        write(output_path, str)
    end
    return counter[]
end
