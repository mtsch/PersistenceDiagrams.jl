"""
# PersistenceDiagrams.jl

Types and functions for working with persistence diagrams.

See [the docs](https://mtsch.github.io/PersistenceDiagrams.jl/dev/) for documentation.
"""
module PersistenceDiagrams

export PersistenceDiagram,
    PersistenceInterval,
    birth,
    death,
    persistence,
    midlife,
    representative,
    birth_simplex,
    death_simplex,
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
    barcode,
    PersistenceImageVectorizer,
    PersistenceCurveVectorizer,
    PersistenceLandscapeVectorizer

using Compat
using Hungarian
using RecipesBase
using ScientificTypes
using Statistics
using Tables

include("intervals.jl")
include("diagrams.jl")
include("tables.jl")
include("matching.jl")

include("persistencecurves.jl")
include("persistenceimages.jl")

include("plotsrecipes.jl")

include("scitypes.jl")
include("mlj.jl")

end
