using SafeTestsets
using Test

@safetestset "matching" begin
    include("matching.jl")
end
@safetestset "persistencecurves" begin
    include("persistencecurves.jl")
end
@safetestset "images" begin
    include("persistenceimages.jl")
end
@safetestset "plotsrecipes" begin
    include("plotsrecipes.jl")
end
@safetestset "aqua" begin
    include("aqua.jl")
end
@safetestset "doctests" begin
    include("doctests.jl")
end
