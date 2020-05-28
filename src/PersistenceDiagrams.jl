module PersistenceDiagrams

export PersistenceInterval, PersistenceDiagram
export birth, death, persistence, representative, dim, threshold
export Bottleneck, Wasserstein, distance, matching, Matching
export barcode, barcode!

using Compat
using Distances
using Hungarian
using RecipesBase

include("diagrams.jl")
include("matching.jl")
include("plotsrecipes.jl")

end
