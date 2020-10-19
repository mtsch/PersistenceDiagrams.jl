using PersistenceDiagrams
using Compat
using DataFrames
using Test

@testset "PersistenceInterval" begin
    int1 = PersistenceInterval(1, 2)
    int2 = PersistenceInterval(1, Inf)
    r = [1, 2, 6, 3]
    int3 = PersistenceInterval(1, 2; birth_simplex=:σ, death_simplex=:τ, representative=r)
    int4 = PersistenceInterval(int1; birth_simplex=:σ, death_simplex=:τ, representative=r)

    @testset "Equality, order" begin
        @test int1 ≠ int2
        @test int1 == int3
        @test int1 < int2
    end

    @testset "Conversion" begin
        M = @NamedTuple begin
            birth_simplex::Union{Nothing,Symbol}
            death_simplex::Symbol
            representative::typeof(r)
        end
        T = PersistenceInterval{M}
        @test typeof(convert(T, int3)) ≡ T
    end

    @testset "Comparison with tuples" begin
        @test int1 == (1, 2)
        @test int2 == (1, Inf)
        @test int4 == (1.0, 2.0)

        @test PersistenceInterval((1, 2)) == int1
    end

    @testset "Birth, death, iteration" begin
        @test int1[1] == birth(int1) == 1
        @test int1[2] == death(int1) == 2
        @test int3[1] == birth(int1) == 1
        @test int4[2] == death(int1) == 2

        @test eltype(int1) ≡ Float64
        @test length(int1) == 2
        @test collect(int1) == [1, 2]
        @test tuple(int1...) ≡ (1.0, 2.0)
        @test firstindex(int1) == 1
        @test lastindex(int1) == 2
        @test first(int1) == 1
        @test last(int1) == 2

        @test_throws BoundsError int2[0]
        @test_throws BoundsError int2[3]
    end

    @testset "Metadata access" begin
        @test int1.meta == NamedTuple()
        @test birth_simplex(int3) == :σ
        @test int4.birth_simplex == :σ
        @test death_simplex(int4) == :τ
        @test int3.death_simplex == :τ
        @test representative(int3) == r

        @test propertynames(int1) == (:birth, :death)
        @test propertynames(int1, true) == (:birth, :death, :meta)
        @test propertynames(int3) ==
              (:birth, :death, :birth_simplex, :death_simplex, :representative)
        @test propertynames(int3, true) ==
              (:birth, :death, :birth_simplex, :death_simplex, :representative, :meta)

        @test_throws ErrorException birth_simplex(int1)
        @test_throws ErrorException death_simplex(int1)
        @test_throws ErrorException representative(int1)
        @test_throws ErrorException int3.something
    end

    @testset "Printing" begin
        @test sprint(print, int1) == "[1.0, 2.0)"
        @test sprint(print, int2) == "[1.0, ∞)"
        @test sprint(print, int3) == "[1.0, 2.0)"

        print_text_plain(io, x) = show(io, MIME"text/plain"(), x)
        @test sprint(print_text_plain, int1) == "[1.0, 2.0)"
        @test sprint(print_text_plain, int2) == "[1.0, ∞)"
        @test sprint(print_text_plain, int3) ==
              "[1.0, 2.0) with:\n" *
              " birth_simplex: Symbol\n" *
              " death_simplex: Symbol\n" *
              " representative: 4-element $(typeof(r))"
    end
end

@testset "PersistenceDiagram" begin
    diagram1 = PersistenceDiagram(
        [(1, 3), (3, 4), (3, Inf)], [(; a=1), (; a=2), (; a=3)]; dim=1
    )
    diagram2 = PersistenceDiagram([(1, 3), (3, 4), (3, Inf)]; threshold=0.3)
    diagram3 = PersistenceDiagram(
        [PersistenceInterval(1, 2), PersistenceInterval(3, 4), PersistenceInterval(3, Inf)];
        a=1,
    )

    @testset "A persistence diagram is an array" begin
        @test diagram1[1] == (1, 3)
        @test diagram2[2] == (3, 4)
        @test diagram3[3] == (3, Inf)

        @test_throws BoundsError diagram1[0]
        @test_throws BoundsError diagram2[4]

        @test diagram1 == diagram2
        @test diagram1 == [(1, 3), (3, 4), (3, Inf)]

        @test length(diagram1) == 3
        @test firstindex(diagram2) == 1
        @test lastindex(diagram3) == 3
        @test length(diagram1) == 3
        @test size(diagram2) == (3,)

        @test first(diagram1) == (1, 3)
        @test last(diagram2) == (3, Inf)

        @test copy(diagram1) == diagram1
        @test copy(diagram2).threshold == 0.3

        @test similar(diagram1) isa typeof(diagram1)
        @test similar(diagram1).dim == 1
        @test similar(diagram3, (Base.OneTo(2),)) isa typeof(diagram3)
        @test similar(diagram3, (Base.OneTo(2),)).a == 1

        @test sort(diagram3) isa typeof(diagram3)
        @test sort(diagram2; by=death, rev=true) == [(3, Inf), (3, 4), (1, 3)]
        @test sort(diagram3; by=death, rev=true).a == 1
    end

    @testset "Metadata access" begin
        @test dim(diagram1) == diagram1.dim == 1
        @test threshold(diagram2) == diagram2.threshold == 0.3
        @test diagram3.a == 1

        @test_throws ErrorException diagram1.threshold
        @test_throws ErrorException diagram2.dim

        @test diagram1[1].a == 1
        @test diagram1[2].a == 2
        @test diagram1[3].a == 3
    end

    @testset "Printing" begin
        print_text_plain(io, x) = show(io, MIME"text/plain"(), x)

        @test sprint(print, diagram1) == "3-element 1-dimensional PersistenceDiagram"
        @test sprint(print_text_plain, diagram1) ==
              "3-element 1-dimensional PersistenceDiagram:\n" *
              " [1.0, 3.0)\n" *
              " [3.0, 4.0)\n" *
              " [3.0, ∞)"

        @test sprint(print, diagram2) == "3-element PersistenceDiagram"
        @test sprint(print_text_plain, diagram2) ==
              "3-element PersistenceDiagram:\n" *
              " [1.0, 3.0)\n" *
              " [3.0, 4.0)\n" *
              " [3.0, ∞)"
    end
end

@testset "Tables.jl interface" begin
    diag1 = PersistenceDiagram(
        [PersistenceInterval(1, 2), PersistenceInterval(1, 3)]; dim=0, threshold=4
    )

    df = DataFrame(diag1)
    @test names(df) == ["birth", "death", "dim", "threshold"]
    @test nrow(df) == 2
    @test PersistenceDiagram(df) == diag1

    diag2 = PersistenceDiagram(
        [
            PersistenceInterval(1, 2; a=nothing),
            PersistenceInterval(1, 3; a=nothing),
            PersistenceInterval(1, 4; a=1),
        ];
        dim=1,
        b=2,
    )

    df = DataFrame(diag2)
    @test names(df) == ["birth", "death", "dim", "threshold"]
    @test nrow(df) == 3
    @test all(ismissing, df.threshold)

    df = DataFrame(PersistenceDiagrams.table([diag1, diag2]))
    @test names(df) == ["birth", "death", "dim", "threshold"]
    @test df.dim isa Vector{Int}
    @test df.threshold isa Vector{Union{Float64,Missing}}
    @test nrow(df) == 5

    table = Tables.columntable((dim=[0, 1], birth=[0, 0], death=[0, 0]))
    @test_throws ArgumentError PersistenceDiagram(table)
    table = Tables.columntable((threshold=[0, 1], birth=[0, 0], death=[0, 0]))
    @test_throws ArgumentError PersistenceDiagram(table)
    table = Tables.columntable((threshold=[1, 1], birth=[0, 0], death=[0, 0]))
    diagram = PersistenceDiagram(table)
    @test ismissing(dim(diagram))
    @test threshold(diagram) == 1
end
