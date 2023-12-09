# We have a separate file for just "make"ing the docs,
# so we can run them in the tests easier.
using Documenter, Asciicast

asciinema_version = "3.6.3"
asciinema_js_url = "https://cdn.jsdelivr.net/npm/asciinema-player@$(asciinema_version)/dist/bundle/asciinema-player.min.js"
asciinema_css_url = "https://cdn.jsdelivr.net/npm/asciinema-player@$(asciinema_version)/dist/bundle/asciinema-player.min.css"

makedocs(;
    modules=[Asciicast],
    authors="Eric P. Hanson",
    repo=Remotes.GitHub("ericphanson", "Asciicast.jl"),
    sitename="Asciicast.jl",
    format=Documenter.HTML(;
        ansicolor=true,
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ericphanson.github.io/Asciicast.jl",
        assets=Asciicast.assets(),
    ),
    pages=[
        "Home" => "index.md",
        "Documenter usage" => "documenter_usage.md",
    ],
)
