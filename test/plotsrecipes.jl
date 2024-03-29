using PersistenceDiagrams
using PersistenceDiagrams: Barcode, InfinityLine, ZeroPersistenceLine
using PersistenceDiagrams: dim_str, clamp_death, clamp_persistence, limits, set_default!

using Compat
using Test

using RecipesBase
using RecipesBase: apply_recipe

# Hack to avoid having to import Plots.
RecipesBase.is_key_supported(::Symbol) = true

"""
Idea: apply recipe and check the number of series on plots.
Not a perfect way to test, but at least it makes sure all points are plotted and checks that
there are no errors.
"""
series(args...; kwargs...) = apply_recipe(Dict{Symbol,Any}(kwargs), args...)
n_series(args...; kwargs...) = length(series(args...; kwargs...))

@testset "Helpers" begin
    @test dim_str(PersistenceDiagram([(1, 1)]; dim=0)) == "₀"
    @test dim_str(PersistenceDiagram([(1, 1)]; dim=1990)) == "₁₉₉₀"
    @test dim_str(PersistenceDiagram([(1, 1)])) == "ₓ"

    int1 = PersistenceInterval(3, Inf)
    int2 = PersistenceInterval(1, 2)
    @test clamp_death(int1, 5) == 5
    @test clamp_persistence(int1, 5) == 5
    @test clamp_death(int2, 5) == 2
    @test clamp_persistence(int2, 5) == 1

    diag1 = PersistenceDiagram([(1, 2), (2, 3), (2, Inf)])
    diag2 = PersistenceDiagram([(0, 2), (2, 3), (2, 5)])
    diag3 = PersistenceDiagram([(0, 2), (2, 3), (2, Inf)]; threshold=6)
    diag4 = PersistenceDiagram([(0, 2), (2, 3), (2, 5)]; threshold=7)

    @test limits((diag1,)) == (0, 3 * 1.25, 3 * 1.25)
    @test limits((diag2,)) == (0, 5, 5 * 1.25)
    @test limits((diag1, diag3)) == (0, 6, 6)
    @test limits((diag1, diag4)) == (0, 7, 7)
    @test limits((diag2, diag4)) == (0, 5, 7)
    @test limits((diag2, diag3)) == (0, 6, 6)

    d = set_default!(Dict(:a => 1), :a, 2)
    @test d[:a] == 1
    d = set_default!(Dict(:a => 1), :b, 2)
    @test d[:b] == 2
end

@testset "Recipes" begin
    @testset "InfinityLine" begin
        @test isequal(only(series(InfinityLine, InfinityLine(true))).args, ([NaN],))
        @test only(series(InfinityLine, InfinityLine(true); infinity=5)).args == ([5],)
        @test only(series(InfinityLine, InfinityLine(true); infinity=5)).plotattributes[:seriestype] ==
            :vline
        @test only(series(InfinityLine, InfinityLine(false); infinity=5)).plotattributes[:seriestype] ==
            :hline
    end

    @testset "ZeroPersistenceLine" begin
        @test only(series(ZeroPersistenceLine, ZeroPersistenceLine())).args == (identity,)
        @test only(
            series(ZeroPersistenceLine, ZeroPersistenceLine(); persistence=true)
        ).args == ([0],)
    end

    @testset "Diagram recipe" begin
        diag = PersistenceDiagram([(1, 2), (2, 3), (3, Inf)])
        @test only(series(typeof(diag), diag; letter=:x)).args == ([1, 2, 3],)
        @test only(series(typeof(diag), diag; letter=:y)).args == ([2, 3, Inf],)
        @test only(series(typeof(diag), diag; letter=:y, infinity=4)).args == ([2, 3, 4],)
    end

    @testset "Persistencediagram" begin
        @test only(series(Val{:persistencediagram}, 1:4, 1:4, nothing)).plotattributes[:markerstrokecolor] ==
            :auto
        @test only(series(Val{:persistencediagram}, 1:4, 1:4, nothing)).plotattributes[:seriestype] ==
            :scatter
    end

    @testset "Diagram plot" begin
        diag1 = PersistenceDiagram([(3, Inf), (1, 2), (3, 4)])
        diag2 = PersistenceDiagram([
            PersistenceInterval(1, 2; a=:a, b=:b, c=[1, 2, 3]),
            PersistenceInterval(3, 4; a=:b, b=:c, c=[1, 0]),
        ])
        diag3 = PersistenceDiagram(PersistenceInterval[])

        @test n_series((diag1,)) == 1 + 1 + 1
        @test n_series((diag1,); infinity=5) == 1 + 1 + 1
        @test n_series((diag1,); persistence=true) == 1 + 1 + 1
        @test n_series((diag1, diag2)) == 1 + 1 + 2
        @test n_series((diag1, diag2); infinity=5) == 1 + 1 + 2
        @test n_series((diag1, diag2); persistence=true) == 1 + 1 + 2
        @test n_series((diag3,); persistence=true) == 1 + 1 + 1
        @test n_series((diag3, diag3); persistence=true) == 1 + 1 + 2
    end

    @testset "Matching plot" begin
        diag1 = PersistenceDiagram([(3, 4), (1, 2), (3, 4)])
        diag2 = PersistenceDiagram([(1, 2), (3, 4)])
        match = matching(Bottleneck(), diag1, diag2)

        @test n_series(match) == 1 + 1 + 1 + 2
    end

    @testset "Barcode plot" begin
        diag1 = PersistenceDiagram([(3, Inf), (1, 2), (3, 4)])
        diag2 = PersistenceDiagram([
            PersistenceInterval(1, 2; a=:a, b=:b, c=[1, 2, 3]),
            PersistenceInterval(3, 4; a=:b, b=:c, c=[1, 0]),
        ])
        diag3 = PersistenceDiagram(PersistenceInterval[])

        @test n_series(Barcode(diag1)) == 1 + 1
        @test n_series(Barcode((diag1,)); infinity=5) == 1 + 1
        @test n_series(Barcode((diag1, diag2))) == 1 + 2
        @test n_series(Barcode([diag1, diag2]); infinity=5) == 1 + 2
        @test n_series(Barcode(typeof(diag1)[])) == 1
        @test n_series(Barcode(diag3)) == 2
        @test n_series(Barcode(diag3, diag3)) == 3
    end
end
