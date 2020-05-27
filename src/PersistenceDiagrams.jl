module PersistenceDiagrams

export Infinity, ∞
export PersistenceInterval, PersistenceDiagram
export birth, death, persistence, representative, dim, threshold
export Bottleneck, Wasserstein, distance, matching, Matching
export barcode, barcode!

using Compat
using Distances
using Hungarian
using RecipesBase

include("infinity.jl")
include("diagrams.jl")
include("distances.jl")
include("plotsrecipes.jl")

end
