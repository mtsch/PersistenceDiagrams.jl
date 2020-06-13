using SafeTestsets
using Test

@safetestset "Aqua" begin
    include("aqua.jl")
end
@safetestset "diagrams" begin
    include("diagrams.jl")
end
@safetestset "matching" begin
    include("matching.jl")
end
@safetestset "betticurves" begin
    include("betticurves.jl")
end
@safetestset "images" begin
    include("persistenceimages.jl")
end
@safetestset "plotsrecipes" begin
    include("plotsrecipes.jl")
end
