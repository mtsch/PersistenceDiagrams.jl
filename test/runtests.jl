using SafeTestsets
using Test

@safetestset "Aqua" begin
    include("aqua.jl")
end
@safetestset "diagrams" begin
    include("diagrams.jl")
end
@safetestset "distances" begin
    include("distances.jl")
end
@safetestset "plotting" begin
    include("plotting.jl")
end
