using PersistenceDiagrams
using PersistenceDiagrams: Barcode

using RecipesBase
using RecipesBase: apply_recipe

# Hack to avoid having to import Plots.
RecipesBase.is_key_supported(::Symbol) = true

"""
Idea: apply recipe and check the number of series on plots.
Not a perfect way to test, but at least it makes sure all points are plotted and checks that
there are no errors.
"""
series(args...; kwargs...) = apply_recipe(Dict{Symbol, Any}(kwargs), args...)

@testset "diagram plot, barcode, matching" begin
    int1 = PersistenceInterval(3, ∞)
    int2 = PersistenceInterval(1, 2)
    int3 = PersistenceInterval(3, 4)

    diag1 = PersistenceDiagram(1, [int1, int2, int3])
    diag2 = PersistenceDiagram(2, [(1, 2), (3, 4)])

    # inf + x=y, points, ()
    @test length(series(diag1)) == 3
    # x=y + points, ()
    @test length(series(diag2, persistence=true)) == 3
    # inf + x=y, points 2×, ()
    @test length(series([diag1, diag2])) == 4

    # inf + lines, ()
    @test length(series(Barcode((diag1,)))) == 3
    # lines, ()
    @test length(series(Barcode((diag2,)))) == 2
    # inf + lines 2×, ()
    @test length(series(Barcode(([diag1, diag2],)))) == 4

    @test length(series(diag1, infinity=10, persistence=true)) == 3
    @test length(series(diag2, infinity=10)) == 3
    @test length(series([diag1, diag2], infinity=10)) == 4

    @test length(series(Barcode((diag1,)), infinity=10)) == 3
    @test length(series(Barcode((diag2,)), infinity=10)) == 2
    @test length(series(Barcode(([diag1, diag2],)), infinity=10)) == 4

    @test_throws MethodError series(Barcode((1,)))
    @test_throws MethodError series(Barcode((diag1,2)))

    diag3 = PersistenceDiagram(2, [(1, 2), (2, 10), (5, 9)])
    match1 = matching(Bottleneck(), diag2, diag3)
    match2 = matching(Wasserstein(), diag2, diag3)

    @test length(series(match1)) == 3
    @test length(series(match1, barcode=false)) == 3
    @test length(series(match2)) == 3
end
