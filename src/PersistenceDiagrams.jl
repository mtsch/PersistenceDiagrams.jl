"""
# PersistenceDiagrams.jl

Types and functions for working with persistence diagrams.

See https://mtsch.github.io/PersistenceDiagrams.jl/dev/ for documentation.
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
    Landscape,
    Silhuette,
    Life,
    Midlife,
    LifeEntropy,
    MidlifeEntropy,
    PDThresholding,
    barcode

using Compat
using Distances
using Hungarian
using RecipesBase
using Statistics
using Tables

import MLJModelInterface
const MMI = MLJModelInterface

include("intervals.jl")
include("diagrams.jl")
include("tables.jl")

include("matching.jl")

include("persistencecurves.jl")
include("persistenceimages.jl")
include("mlj.jl")

include("plotsrecipes.jl")

end
