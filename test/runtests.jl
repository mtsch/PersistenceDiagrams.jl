using SafeTestsets
using Test

@safetestset "Aqua" begin
    include("aqua.jl")
end
@safetestset "infinity" begin
    include("infinity.jl")
end
@safetestset "diagrams" begin
    include("diagrams.jl")
end
@safetestset "distances" begin
    include("distances.jl")
end
@safetestset "plotsrecipes" begin
    include("plotsrecipes.jl")
end
