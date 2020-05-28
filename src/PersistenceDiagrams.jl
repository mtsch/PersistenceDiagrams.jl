"""
# PersistenceDiagrams.jl

Types and functions for working with persistence diagrams.

See https://mtsch.github.io/PersistenceDiagrams.jl/dev/ for documentation.
"""
module PersistenceDiagrams

export PersistenceInterval, PersistenceDiagram
export birth, death, persistence, representative, dim, threshold
export Bottleneck, Wasserstein, Matching, distance, matching
export PersistenceImage, transform, transform!
export barcode, barcode!

using Compat
using Distances
using Hungarian
using RecipesBase

include("diagrams.jl")

include("matching.jl")
include("transformers.jl")
include("images.jl")

include("plotsrecipes.jl")

end
