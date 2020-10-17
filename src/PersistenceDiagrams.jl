"""
# PersistenceDiagrams.jl

Types and functions for working with persistence diagrams.

See [the docs](https://mtsch.github.io/PersistenceDiagrams.jl/dev/) for documentation.
"""
module PersistenceDiagrams

export PersistenceInterval,
    birth,
    death,
    persistence,
    representative,
    birth_simplex,
    death_simplex,
    PersistenceDiagram,
    dim,
    threshold,
    Bottleneck,
    Wasserstein,
    weight,
    matching,
    PersistenceImage,
    PersistenceCurve,
    BettiCurve,
    Life,
    Midlife,
    LifeEntropy,
    MidlifeEntropy,
    PDThresholding,
    Landscape,
    Landscapes,
    Silhuette,
    barcode

using Compat
using Distances
using Hungarian
using RecipesBase
using Statistics
using Tables

include("intervals.jl")
include("diagrams.jl")
include("tables.jl")

include("matching.jl")

include("persistencecurves.jl")
include("persistenceimages.jl")

include("plotsrecipes.jl")

# WIP
include("mlj.jl")
module MLJPersistenceDiagrams
using ..PersistenceDiagrams:
    PersistenceImageVectorizer, PersistenceCurveVectorizer, PersistenceLandscapeVectorizer
export PersistenceImageVectorizer,
    PersistenceCurveVectorizer, PersistenceLandscapeVectorizer
end
export MLJPersistenceDiagrams

end
