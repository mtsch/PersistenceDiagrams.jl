using SafeTestsets
using Test

@safetestset "diagrams" begin
    include("diagrams.jl")
end
#@safetestset "matching" begin
#    include("matching.jl")
#end
@safetestset "matching" begin
    include("matching.jl")
end
@safetestset "persistencecurves" begin
    include("persistencecurves.jl")
end
@safetestset "persistenceimages" begin
    include("persistenceimages.jl")
end
@safetestset "scitypes" begin
    include("scitypes.jl")
end
@safetestset "mlj" begin
    include("mlj.jl")
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
