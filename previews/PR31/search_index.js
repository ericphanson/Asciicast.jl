var documenterSearchIndex = {"docs":
[{"location":"Pandoc/#Pandoc-submodule","page":"Pandoc","title":"Pandoc submodule","text":"","category":"section"},{"location":"Pandoc/","page":"Pandoc","title":"Pandoc","text":"Modules = [Asciicast.Pandoc]","category":"page"},{"location":"Pandoc/#Asciicast.Pandoc.walk!","page":"Pandoc","title":"Asciicast.Pandoc.walk!","text":"walk!(x::Any, action::Function, format, meta)\n\nWalk the Pandoc document abstract source tree (AST) and apply filter function on each element of the document AST, modifying the tree in place.\n\naction must be a function which takes four arguments, tag, content, format, meta, and should return:\nnothing to leave the element unchanged\n[] to delete the element\nA Pandoc element to replace the element\nor a list of Pandoc elements which will be spliced into the list the original object belongs to.\n\n\n\n\n\n","category":"function"},{"location":"documenter_usage/#Documenter-usage","page":"Documenter usage","title":"Documenter usage","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"To use Asciicast with documenter, the asciinema-player javascript and CSS assets must be provided to Documenter in makedocs in your docs/make.jl file.","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"This can be done using the Asciicast.assets function, e.g.","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"makedocs(;\n    # ...\n    format=Documenter.HTML(;\n        assets=Asciicast.assets(),\n        # ...\n    ),\n)","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Besides that, the only other requirement is to load Asciicast in your make.jl (using Asciicast).","category":"page"},{"location":"documenter_usage/#@cast-blocks","page":"Documenter usage","title":"@cast blocks","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Asciicast.jl works as a Documenter plugin, providing @cast blocks which work similarly to @repl blocks. For example:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast\nusing Pkg\nPkg.status()\n1 + 1\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"The above @cast block will effectively generate both a standard Documenter @repl block:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@repl\nusing Pkg\nPkg.status()\n1 + 1\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"and some raw HTML output:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"<div id=\"d59ee38d-184a-4888-8749-41b4df76ae3b\"></div>\n<script>\nAsciinemaPlayer.create(\n'data:text/plain;base64,eyJ2ZXJzaW9uIjoyLCJ3aWR0aCI6ODAsImhlaWdodCI6MTIsInRpbWVzdGFtcCI6MTcwMjE1ODMyMywiaWRsZV90aW1lX2xpbWl0IjoxLjAsImVudiI6eyJURVJNIjoieHRlcm0tMjU2Y29sb3IiLCJTSEVMTCI6Ii9iaW4venNoIn19ClswLjAwMTA5ODE1NTk3NTM0MTc5NjksImkiLCJ1c2luZyBQa2ciXQ0KWzAuNTAxMzQ1MTU3NjIzMjkxLCJvIiwianVsaWE+IHVzaW5nIFBrZ1xyXG4iXQ0KWzEuMDAyODIxMjA3MDQ2NTA4OCwibyIsIiJdDQpbMS41MDI5NzAyMTg2NTg0NDczLCJvIiwiXHJcbiJdDQpbMi4wMDI5NzQ5ODcwMzAwMjkzLCJpIiwiUGtnLnN0YXR1cygpIl0NClsyLjUwMjk3NjE3OTEyMjkyNSwibyIsImp1bGlhPiBQa2cuc3RhdHVzKClcclxuIl0NClszLjAxNTQ2MDAxNDM0MzI2MTcsIm8iLCJcdTAwMWJbMzJtXHUwMDFiWzFtU3RhdHVzXHUwMDFiWzIybVx1MDAxYlszOW0gIl0NClszLjUxNTUwNDEyMTc4MDM5NTUsIm8iLCJgfi9Bc2NpaWNhc3QuamwvZG9jcy9Qcm9qZWN0LnRvbWxgXHJcbiJdDQpbNC4wMTcxMTMyMDg3NzA3NTIsIm8iLCIgICJdDQpbNC41MTcxOTQwMzI2NjkwNjcsIm8iLCJcdTAwMWJbOTBtWzI2MDBkNDQ1XSBcdTAwMWJbMzltQXNjaWljYXN0IHYwLjEuMCBgLi5gIl0NCls1LjAxNzIzODE0MDEwNjIwMSwibyIsIlxyXG4gIl0NCls1LjUxNzI3NzAwMjMzNDU5NSwibyIsIiBcdTAwMWJbOTBtW2UzMDE3MmY1XSBcdTAwMWJbMzltIl0NCls2LjAxNzMxNTE0OTMwNzI1MSwibyIsIkRvY3VtZW50ZXIgdjEuMi4xXHJcbiJdDQpbNi41MTc3NzAwNTE5NTYxNzcsIm8iLCIiXQ0KWzcuMDE3OTI0MDcwMzU4Mjc2LCJvIiwiXHJcbiJdDQpbNy41MTc5MzIxNzY1ODk5NjYsImkiLCIxICsgMSJdDQpbOC4wMTc5MzMxMzAyNjQyODIsIm8iLCJqdWxpYT4gMSArIDFcclxuIl0NCls4LjUxODA5MzEwOTEzMDg2LCJvIiwiIl0NCls5LjAxODU5NDAyNjU2NTU1MiwibyIsIjJcclxuIl0NCg==',\ndocument.getElementById('d59ee38d-184a-4888-8749-41b4df76ae3b'), { autoPlay: true, fit: false}\n);\n</script>","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Here, the id is randomly generated with uuid4(), and the contents of the cast itself are base64-encoded and inlined into the HTML. Note: I initially tried saving these as separate files, but had trouble with casts not showing up on deployed pages, while inlining works reliably every time.","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"The output of this looks like:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/#Hiding-REPL-inputs","page":"Documenter usage","title":"Hiding REPL inputs","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"You can also use hide_inputs=true to hide the inputs, showing just the asciinema player. The syntax for that is:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast; hide_inputs=true\nusing Pkg\nPkg.status()\n1 + 1\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"This looks like:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/#Exceptions","page":"Documenter usage","title":"Exceptions","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Unlike in @repl blocks, exceptions are not allowed by default. Instead, they must be opt-ed in with allow_errors=true","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast; allow_errors=true\nerror(\"This is an exception!\")\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"This looks like:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/#Example-with-a-named-block","page":"Documenter usage","title":"Example with a named block","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"First block:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast 1; hide_inputs=true\nx = -1\nx*x\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"The next block continues:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast 1; hide_inputs=true, allow_errors=true\ny = x+1\nsqrt(x)\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Then we move to a REPL block:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@repl 1\n@show y\nz = y^2\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"@show y\nz = y^2","category":"page"},{"location":"documenter_usage/#Modifying-the-delay","page":"Documenter usage","title":"Modifying the delay","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Delay of 0:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast; delay=0, hide_inputs=true\n1\n2\n3\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Delay of 1:","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"```@cast; delay=1, hide_inputs=true\n1\n2\n3\n```","category":"page"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"","category":"page"},{"location":"documenter_usage/#All-supported-options-in-@cast-Documenter-blocks","page":"Documenter usage","title":"All supported options in @cast Documenter blocks","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"hide_inputs::Bool=false. Whether or not to hide the @repl-style inputs before the animated gif.\nallow_errors::Bool=false. Whether or not the Documenter build should fail if exceptions are encountered during execution of the @cast block.\ndelay::Float64=0.25. The amount of delay between line executions (to emulate typing time).\nloop::Union{Int,Bool}=false. Set to true for infinite looping, or an integer to loop a fixed number of times.\nheight::Int. Heuristically determined by default. Set to an integer to specify the number of lines.","category":"page"},{"location":"documenter_usage/#Reference-docs","page":"Documenter usage","title":"Reference docs","text":"","category":"section"},{"location":"documenter_usage/","page":"Documenter usage","title":"Documenter usage","text":"Asciicast.assets","category":"page"},{"location":"documenter_usage/#Asciicast.assets","page":"Documenter usage","title":"Asciicast.assets","text":"Asciicast.assets(asciinema_version = \"3.6.3\")\n\nProvides a collection of Documenter assets which can be used in makedocs, e.g. makedocs(; assets=Asciicast.assets()).\n\n\n\n\n\n","category":"function"},{"location":"markdown_usage/#Markdown-usage","page":"Markdown usage","title":"Markdown usage","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Asciicast provides facilities for maintaining gifs showcasing package functionality in READMEs, or otherwise adding animated gifs to Julia code blocks in documents.","category":"page"},{"location":"markdown_usage/#julia-{cast\"true\"}-code-blocks","page":"Markdown usage","title":"julia {cast=\"true\"} code blocks","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"To use functionality, simply add julia {cast=\"true\"} code-blocks to your document. For example,","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"```julia {cast=\"true\"}\nusing Pkg\nPkg.status()\n```","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Then run cast_document (or the helper cast_readme) on the file. This will turn it into:","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"```julia {cast=\"true\"}\nusing Pkg\nPkg.status()\n```\n![](assets/output_1_@cast.gif)","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"and generate a gif in the assets directory.","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"One can also customize the font-size and the delay:","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"```julia {cast=\"true\" font-size=28 delay=0.5}\nusing Pkg\nPkg.status()\n```","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Note that the attributes must be separated by spaces, not commas, as shown above.","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Here, the gifs are generated with agg (which is installed automatically using a JLL package), and the font-size parameter is passed there. Currently no other agg parameters are supported, but file an issue if you have a use for one.","category":"page"},{"location":"markdown_usage/#Named-blocks","page":"Markdown usage","title":"Named blocks","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"One can name blocks to continue execution after interrupting by some text. For example:","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Here we have `x`:\n```julia {cast=\"true\" name=\"ex1\"}\nx=2\n\n```\n\nNow we add 1:\n```julia {cast=\"true\" name=\"ex1\"}\ny = x+1\n\n```","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"This works the same way as named example blocks in Documenter.","category":"page"},{"location":"markdown_usage/#All-supported-attributes","page":"Markdown usage","title":"All supported attributes","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"delay::Float64=0.25. The amount of delay between line executions (to emulate typing time).\nfont-size::Int=28. Used by agg when generating the gif.\nheight::Int. Heuristically determined by default. Set to an integer to specify the number of lines.\nallow_errors::Bool=false. Whether or not cast_document (or cast_readme) should fail if exceptions are encountered during execution of the block.\nname::String. Optionally provide a name to allow running multiple examples in the same module, similar to named example blocks in Documenter.","category":"page"},{"location":"markdown_usage/#Syntax-notes","page":"Markdown usage","title":"Syntax notes","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"A note on the syntax. Here we want to ensure that the code snippet continues to get syntax highlighting, but also mark it somehow so we can detect that we want to generate a gif for this snippet. The implementation behind-the-scenes uses pandoc, so we are somewhat limited by what pandoc can support. Here, we are using \"attributes\" ({cast=\"true\"}) so we can keep \"julia\" as the first \"class\", so that syntax highlighting still works, while being able to pass cast=\"true\" into the pandoc AST so that we can detect it there and generate the gif. I initially tried just julia-cast or julia:@cast as the language, but GitHub stops providing julia highlighting in that case.","category":"page"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Additionally, I use @cast in the output filename, so that future runs can identify @cast-generated gifs and remove the image tags, to prevent duplicating them when running cast_document again to update the gifs.","category":"page"},{"location":"markdown_usage/#Reference-docs","page":"Markdown usage","title":"Reference docs","text":"","category":"section"},{"location":"markdown_usage/","page":"Markdown usage","title":"Markdown usage","text":"Asciicast.cast_readme\nAsciicast.cast_document","category":"page"},{"location":"markdown_usage/#Asciicast.cast_readme","page":"Markdown usage","title":"Asciicast.cast_readme","text":"cast_readme(MyPackage::Module)\ncast_readme(MyPackage::Module, output_path)\n\nAdd gifs for each julia {cast=\"true\"} code-block in the README of MyPackage. This is just a smaller helper that calls cast_document on joinpath(pkgdir(MyPackage), \"README.md\"). See cast_document for more options and warnings.\n\n\n\n\n\n","category":"function"},{"location":"markdown_usage/#Asciicast.cast_document","page":"Markdown usage","title":"Asciicast.cast_document","text":"cast_document(input_path, output_path=input_path; format=\"gfm+attributes\")\n\nFor each julia {cast=\"true\"} code-block in the input document, generates a gif executing that code in a REPL, saves it to joinpath(dirname(output_path), \"assets\") and inserts it as an image following the code-block, writing the resulting document to output_path.\n\nThe default format is Github-flavored markdown. Specify the format keyword argument to choose an alternate pandoc-supported format (see https://pandoc.org/MANUAL.html#general-options). This has only been tested with Github-flavored markdown, but theoretically should work with any pandoc format.\n\nReturns the number of gifs generated.\n\nwarning: Warning\nThis function relies on parsing the document using pandoc and roundtripping through the pandoc AST. This can result in unexpected modifications to the document.It is recommended to check your document into source control before running this function, or specifying an output_path that is different from the input path, in order to assess the results.\n\n\n\n\n\n","category":"function"},{"location":"lookup/#Index","page":"-","title":"Index","text":"","category":"section"},{"location":"lookup/","page":"-","title":"-","text":"","category":"page"},{"location":"creating_casts/#Creating-casts","page":"Creating casts","title":"Creating casts","text":"","category":"section"},{"location":"creating_casts/#the-@cast_str-macro","page":"Creating casts","title":"the @cast_str macro","text":"","category":"section"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"The string macro @cast_str provides a convenient API to construct a Cast object:","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"using Asciicast\ncast\"\"\"\n    using Pkg\n    Pkg.status()\n    1 + 1\n    \"\"\"0.25","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"The Cast objects have a show method defined for HTML, allowing rich display with a local asciinema-player, in Documenter, Pluto, jupyter, VSCode, etc. For convenient use with Documenter in particular, see the @cast syntax in Documenter usage. Note that this player needs the asciinema-player javascript and CSS assets to be loaded (note that in VSCode, this happens automatically).","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"They can be saved to a .cast file using Asciicast.save or saved to a gif using Asciicast.save_gif. See also Markdown usage for easier integration into READMEs and other documents.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Note also that julia> prompts may be prepended. In this case, existing outputs will be discarded, similarly to the REPL's prompt-pasting feature:","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"using Asciicast\nc = cast\"\"\"\n       julia> 1+1\n       3 # note: wrong!\n\n       \"\"\"0.25","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"@cast_str","category":"page"},{"location":"creating_casts/#Asciicast.@cast_str","page":"Creating casts","title":"Asciicast.@cast_str","text":"@cast_str(code_string, delay=0, allow_errors=false) -> Cast\n\nCreates a Cast object by executing the code in code_string in a REPL-like environment.\n\nExample\n\nusing Asciicast\n\nc = cast\"x=1\"0.25 # note we set a delay of 0.25 here\n\nAsciicast.save(\"test.cast\", c)\n\nTo allow exceptions, one needs to invoke the macro manually on a string:\n\nusing Asciicast\nc = @cast_str(\"error()\", 0, true)\nAsciicast.save(\"test.cast\", c)\n\n\n\n\n\n","category":"macro"},{"location":"creating_casts/#record_output","page":"Creating casts","title":"record_output","text":"","category":"section"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Here only the outputs can be captured, as record_output is a function, not a macro.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"using Asciicast\nrecord_output(; height=10) do\n    @info \"Hello!\"\n    println(\"That was a logging statement, but this is printing.\")\n    x = 1\n    x + 1 # does not print anything-- no output!\n    @info \"here's `x`\" x\n    println(\"Now I'll wait a second\")\n    sleep(1)\n    println(\"ok, done!\")\nend","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"This likewise produces a Cast object. You can provide a filename to have it save the results directly to that file.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Asciicast.record_output","category":"page"},{"location":"creating_casts/#Asciicast.record_output","page":"Creating casts","title":"Asciicast.record_output","text":"record_output(f, filepath::AbstractString, start_time::Float64=time(); delay=0, kw...) -> filepath\nrecord_output(f, io::IO=IOBuffer(), start_time::Float64=time(); delay=0, kw...)\n\nExecutes f() while saving all output to a cast whose data is saved to io, or to a file at filepath. The arguments kw... may be any keyword arguments accepted by Header.\n\nThe parameters of the cast may be passed here; see Cast for more details.\n\nReturns a Cast object.\n\n\n\n\n\n","category":"function"},{"location":"creating_casts/#Cast-objects-and-a-manual-example","page":"Creating casts","title":"Cast objects and a manual example","text":"","category":"section"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Asciicast provides a type Cast which can be used for constructing asciicast v2 files. The most low-level interface is to use manual write_event! calls as follows:","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"using Asciicast\nusing Asciicast: Header\ncast = Cast(IOBuffer(), Header(; height=5))\nwrite_event!(cast, OutputEvent, \"hello\\n\")\nwrite_event!(cast, OutputEvent, \"Let us wait...\")\nsleep(.5)\nwrite_event!(cast, OutputEvent, \"\\nDone!\")\ncast","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Such a Cast can be saved to a .cast file using Asciicast.save. These files are JSON lines files, which can be read with JSON3.read with the jsonlines=true keyword argument. They can also be parsed with Asciicast.parse_cast. They can be played in the terminal or uploaded to <asciinema.org> with asciinema, and converted to gifs with agg. Note that Asciicast.jl does not upload or embed any casts, using a local player instead.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"See also: Cast files.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Cast\nwrite_event!","category":"page"},{"location":"creating_casts/#Asciicast.Cast","page":"Creating casts","title":"Asciicast.Cast","text":"Cast(file_or_io=IOBuffer(), header=Header(), start_time=time(); delay=0.0, loop=false)\n\nCreate a Cast object which represents an asciicast file (see https://github.com/asciinema/asciinema/blob/asciicast-v2/doc/asciicast-v2.md for the format).\n\nSet delay to enforce a constant delay between events.\nSet loop to true to loop continuously, or to an integer to loop a specified number of times. Only supported in the HTML show method for asciinema-player (not in the written file format, nor gif support, which currently always loops).\n\nUse write_event! to write an event to the cast.\n\n\n\n\n\n","category":"type"},{"location":"creating_casts/#Asciicast.write_event!","page":"Creating casts","title":"Asciicast.write_event!","text":"write_event!(cast::Cast, event_type::EventType, event_data::AbstractString)\nwrite_event!(cast::Cast, event::Event)\n\nWrite an event to cast of type event_type (either OutputEvent or InputEvent) with data given by event_data.\n\n\n\n\n\n","category":"function"},{"location":"creating_casts/#Saving-outputs","page":"Creating casts","title":"Saving outputs","text":"","category":"section"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Cast objects (whether created via @cast_str, record_output, or manual construction with Cast and write_event!) can be saved to .cast files with Asciicast.save or to gifs with Asciicast.save_gif. Additionally, Asciicast.save_code_gif provides a shortcut to create a Cast object from code and save it to a gif in one go.","category":"page"},{"location":"creating_casts/","page":"Creating casts","title":"Creating casts","text":"Asciicast.save\nAsciicast.save_gif\nAsciicast.save_code_gif","category":"page"},{"location":"creating_casts/#Asciicast.save","page":"Creating casts","title":"Asciicast.save","text":"save(output, cast::Cast)\n\nWrites the contents of a Cast cast to output.\n\n\n\n\n\n","category":"function"},{"location":"creating_casts/#Asciicast.save_gif","page":"Creating casts","title":"Asciicast.save_gif","text":"save_gif(output_path, cast::Cast; font_size=28)\n\nSaves the Cast to output_path as a gif (using agg).\n\n\n\n\n\n","category":"function"},{"location":"creating_casts/#Asciicast.save_code_gif","page":"Creating casts","title":"Asciicast.save_code_gif","text":"save_code_gif(output_path, code_string; delay=0.25, font_size=28, height=nothing, allow_errors=false)\n\nGiven Julia source code as a string, run the code in a REPL mode and save the results as a gif to output_path.\n\n\n\n\n\n","category":"function"},{"location":"limitations/#Limitations","page":"Limitations","title":"Limitations","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"The approach used in Asciicast.jl has some limitations, and for some use cases it may be better to use the command-line tool asciinema directly.","category":"page"},{"location":"limitations/#Cannot-use-keyboard-input","page":"Limitations","title":"Cannot use keyboard input","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"Since Asciicast.jl works by running short Julia scripts and capturing the inputs and outputs, one cannot use keyboard input to direct what runs. This makes it hard to capture things like terminal menus and other UI which requires input via Asciicast.jl.","category":"page"},{"location":"limitations/#Cannot-rely-on-stdout-(or-stderr)-in-one-line-being-still-open-in-the-next","page":"Limitations","title":"Cannot rely on stdout (or stderr) in one line being still open in the next","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"This is an Documenter limitation which also affects Asciicast, both in @cast blocks in Documenter, as well as in the @cast_str and gifs generated via cast_document. For example, in the code","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"using ProgressMeter\nprog = ProgressThresh(1e-5; desc=\"Minimizing:\")\nfor val in exp10.(range(2, stop=-6, length=20))\n    update!(prog, val)\n    sleep(0.1)\nend","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"prog implicitly captures stdout inside the ProgressThresh object. However, the way this code is processed is basically one \"block\" at a time (the same as the REPL works). But each block is given a different stdout object (in order to capture it's outputs individually) which is closed at the end of the execution that block. That is, prog = ProgressThresh(1e-5; desc=\"Minimizing:\") gets a stdout, which is then closed before the for-loop runs. Then update! in the for-loop tries to write to this stdout, which has already been closed.","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"One workaround here is to use a begin or let block, to group lines that need to share access to the stdout object:","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"","category":"page"},{"location":"limitations/#Limited-emoji-support-in-gifs","page":"Limitations","title":"Limited emoji support in gifs","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"This is an agg limitation[1]. Currently, emojis are only supported if you install the font Noto Emoji, and they are monochrome only (not color).","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"[1]: In fact, this is an even further upstream issue in the renderers used by agg.","category":"page"},{"location":"limitations/#cast_document-effectively-reformats-the-document","page":"Limitations","title":"cast_document effectively reformats the document","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"pandoc is not a source-precise markdown parser, and ignores \"syntax trivia\" like whitespace and so forth in its internal representation of the document. This means when it writes out the document after processing, it changes the whitespace, some newlines, and things like that. The rendered output should generally not change, but the file itself can change quite a bit.","category":"page"},{"location":"limitations/#Non-limitations","page":"Limitations","title":"Non-limitations","text":"","category":"section"},{"location":"limitations/#ANSI-escape-codes-work-properly","page":"Limitations","title":"ANSI escape codes work properly","text":"","category":"section"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"Tools like ProgressMeter.jl use escape codes so modify the terminal state so that the progress meter overwrites itself. This isn't compatible with standard @repl blocks:","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"using ProgressMeter\n@showprogress dt=0.1 desc=\"Computing...\" for i in 1:10\n    sleep(0.1)\nend","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"But it does tend to work with @cast blocks and other Asciicast constructs:","category":"page"},{"location":"limitations/","page":"Limitations","title":"Limitations","text":"","category":"page"},{"location":"cast_files/#Cast-files","page":"Cast files","title":"Cast files","text":"","category":"section"},{"location":"cast_files/","page":"Cast files","title":"Cast files","text":"Pages = [\"cast_files.md\"]","category":"page"},{"location":"cast_files/#Reference-docs","page":"Cast files","title":"Reference docs","text":"","category":"section"},{"location":"cast_files/","page":"Cast files","title":"Cast files","text":"Asciicast.Header\nAsciicast.EventType\nAsciicast.Event\nAsciicast.parse_cast","category":"page"},{"location":"cast_files/#Asciicast.Header","page":"Cast files","title":"Asciicast.Header","text":"Base.@kwdef struct Header\n    version::Int=2\n    width::Int=80\n    height::Int=24\n    timestamp::Union{Int, Nothing}=floor(Int, datetime2unix(now()))\n    duration::Union{Float64, Nothing}=nothing\n    idle_time_limit::Union{Float64, Nothing}=nothing\n    command::Union{String, Nothing}=nothing\n    title::Union{String, Nothing}=nothing\n    env::Union{Dict{String, String},Nothing}=Dict{String, String}(\"SHELL\" => get(ENV, \"SHELL\", \"/bin/bash\"),\n                                            \"TERM\" => get(ENV, \"TERM\", \"xterm-256color\"))\n    theme::Union{Dict{String, String},Nothing}=nothing\nend\n\nThe header of an asciicast file. Documented at https://github.com/asciinema/asciinema/blob/v2.4.0/doc/asciicast-v2.md#header.\n\n\n\n\n\n","category":"type"},{"location":"cast_files/#Asciicast.EventType","page":"Cast files","title":"Asciicast.EventType","text":"Asciicast.EventType\n\nAn enum consisting of Asciicast.OutputEvent and Asciicast.InputEvent.\n\n\n\n\n\n","category":"type"},{"location":"cast_files/#Asciicast.Event","page":"Cast files","title":"Asciicast.Event","text":"struct Event\n    time::Float64\n    type::EventType\n    event_data::String\nend\n\nRepresents an event in a cast file. See also EventType.\n\n\n\n\n\n","category":"type"},{"location":"cast_files/#Asciicast.parse_cast","page":"Cast files","title":"Asciicast.parse_cast","text":"Asciicast.parse_cast(io::IO) -> header, events\n\nReturns a tuple consisting of a Header and vector of Event's.\n\n\n\n\n\n","category":"function"},{"location":"#Asciicast.jl","page":"Home","title":"Asciicast.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Asciicast.jl is all about showcasing Julia code running in a REPL using technologies developed by the open-source asciinema project. (It is totally unaffiliated with the authors of that project, however).","category":"page"},{"location":"#Quick-example","page":"Home","title":"Quick example","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Asciicast\ncast\"\"\"\n    using Pkg\n    Pkg.status()\n    1 + 1\n    \"\"\"0.25","category":"page"},{"location":"","page":"Home","title":"Home","text":"This example creates a Cast object using the @cast_str macro, which captures the input and the output. Check out Creating casts for more on creating Cast objects (or Cast files for a lower level API, if you are interested).","category":"page"},{"location":"","page":"Home","title":"Home","text":"Here, the Cast object is being rendered by the javascript asciinema-player loaded by Documenter. See Documenter usage for more on that.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Likewise, check out Markdown usage for using Asciicast.jl to generate and maintain gifs of code execution in documents like READMEs.","category":"page"},{"location":"#Table-of-contents","page":"Home","title":"Table of contents","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Depth = 2:3\nPages = [\"index.md\", \"creating_casts.md\", \"documenter_usage.md\", \"markdown_usage.md\", \"cast_files.md\", \"limitations.md\"]","category":"page"}]
}
