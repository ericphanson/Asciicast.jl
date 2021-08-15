using Documenter, Asciicast

asciinema_version = "2.6.1"
makedocs(;
    modules=[Asciicast],
    authors="Eric P. Hanson",
    repo="https://github.com/ericphanson/Asciicast.jl/blob/{commit}{path}#L{line}",
    sitename="Asciicast.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/Asciicast.jl",
        assets=[asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/$(asciinema_version)/asciinema-player.min.js"),
                asset("https://cdnjs.cloudflare.com/ajax/libs/asciinema-player/$(asciinema_version)/asciinema-player.min.css")],
    ),
    pages=[
        "Home" => "index.md",
    ],
)


deploydocs(;
    repo="github.com/ericphanson/Asciicast.jl",
    push_preview=true,
)
