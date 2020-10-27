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
    barcode

using Compat
using Hungarian
using PersistenceDiagramsBase
using RecipesBase
using Statistics

include("matching.jl")

include("persistencecurves.jl")
include("persistenceimages.jl")

include("plotsrecipes.jl")

end
