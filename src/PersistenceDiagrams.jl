"""
# PersistenceDiagrams.jl

Types and functions for working with persistence diagrams.

See https://mtsch.github.io/PersistenceDiagrams.jl/dev/ for documentation.
"""
module PersistenceDiagrams

export
    PersistenceInterval, birth, death, persistence,
    RepresentativeInterval, representative, birth_simplex, death_simplex,
    PersistenceDiagram, dim, threshold,
    Bottleneck, Wasserstein, weight, matching,
    PersistenceImage, PersistenceCurve, BettiCurve, Landscape, Silhuette,
    barcode

using Compat
using Distances
using Hungarian
using RecipesBase

include("intervals.jl")
include("diagrams.jl")

include("matching.jl")
include("persistencecurves.jl")
include("persistenceimages.jl")

include("plotsrecipes.jl")

end
