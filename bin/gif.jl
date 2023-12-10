#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."); io=devnull)
using Asciicast

Asciicast.xyz()
