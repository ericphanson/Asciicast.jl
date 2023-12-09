include("_make.jl")

deploydocs(;
    repo="github.com/ericphanson/Asciicast.jl",
    push_preview=true,
    devbranch="main"
)
