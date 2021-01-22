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
using PersistenceDiagramsBase
using RecipesBase
using Statistics
using Tables

include("matching.jl")

include("persistencecurves.jl")
include("persistenceimages.jl")

include("plotsrecipes.jl")

include("mlj.jl")

end
