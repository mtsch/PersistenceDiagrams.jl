using PersistenceDiagrams
using Compat

using PersistenceDiagrams: stripped

@testset "PersistenceInterval" begin
    @testset "no representative" begin
        int1 = PersistenceInterval(1, 2)
        @test eltype(int1) == Float64
        b, d = int1
        @test b == birth(int1) == 1
        @test d == death(int1) == 2
        @test persistence(int1) == 1
        @test int1 == (1, 2)
        @test convert(
            PersistenceInterval{Nothing}, (1, 2)
        ) ≡ PersistenceInterval(1, 2)
        @test convert(
            PersistenceInterval{Nothing}, (1, Inf)
        ) ≡ PersistenceInterval(1, Inf)
        @test_throws BoundsError int1[0]
        @test int1[1] == 1
        @test int1[2] == 2
        @test_throws BoundsError int1[3]

        int2 = PersistenceInterval(1, Inf)
        @test eltype(int2) == Float64
        b, d = int2
        @test b == birth(int2) == 1
        @test d == death(int2) == Inf
        @test persistence(int2) == Inf

        # Iteration
        @test length(int1) == 2
        @test collect(int1) == [1, 2]
        @test eltype(collect(int1)) ≡ Float64
        @test tuple(int1...) ≡ (1.0, 2.0)
        @test firstindex(int1) == 1
        @test lastindex(int1) == 2
        @test first(int1) == 1
        @test last(int1) == 2

        @test int1 < int2
        @test int1 < PersistenceInterval(2, 2)

        @test_throws ErrorException representative(int1)

        @test sprint(print, int1) == "[1.0, 2.0)"
        @test sprint(print, int2) == "[1.0, ∞)"
        @test sprint((io, val) -> show(io, MIME"text/plain"(), val), int1) ==
            "PersistenceInterval(1.0, 2.0)"
    end
    @testset "with representative" begin
        int1 = PersistenceInterval(2.0, 3.0, [1, 2, 3, 4])
        @test eltype(int1) == Float64
        b, d = int1
        @test b == birth(int1) == 2.0
        @test d == death(int1) == 3.0
        @test persistence(int1) == 1.0
        @test int1 == (2.0, 3.0)
        @test_throws BoundsError int1[0]
        @test int1[1] == 2.0
        @test int1[2] == 3.0
        @test_throws BoundsError int1[3]

        int2 = PersistenceInterval(1.0, Inf, [1, 2])
        @test eltype(int2) == Float64
        b, d = int2
        @test b == birth(int2) == 1.0
        @test d == death(int2) == Inf
        @test persistence(int2) == Inf

        @test int1 > int2
        @test int1 > PersistenceInterval(2.0, 2.0, [1, 2])

        @test representative(int1) == [1, 2, 3, 4]
        @test representative(int2) == [1, 2]
        @test tuple(stripped(int1)...) == tuple(int1...)
        @test stripped(int1) ≢ int1
        @test stripped(int1) isa PersistenceInterval{Nothing}

        @test sprint(print, int1) == "[2.0, 3.0)"
        @test sprint(print, int2) == "[1.0, ∞)"
        @test sprint((io, val) -> show(io, MIME"text/plain"(), val), int1) ==
            """
                PersistenceInterval(2.0, 3.0) with representative:
                4-element Array{Int64,1}:
                 1
                 2
                 3
                 4"""
    end
end

@testset "PersistenceDiagram" begin
    @testset "basics" begin
        int1 = PersistenceInterval(3, Inf)
        int2 = PersistenceInterval(1, 3)
        int3 = PersistenceInterval(3, 4)

        diag = PersistenceDiagram(1, [int1, int2, int3], threshold=2)
        @test dim(diag) == 1
        sort!(diag)
        @test diag == [int2, int3, int1]
        @test diag == PersistenceDiagram(1, [(1, 3), (3, 4), (3, Inf)])
        @test diag[1] == int2
        @test diag[2] == int3
        @test diag[3] == int1
        @test_throws BoundsError diag[4]
        @test sprint(print, diag) ==
            "3-element 1-dimensional PersistenceDiagram"
        @test sprint((io, val) -> show(io, MIME"text/plain"(), val), diag) ==
            """
                3-element 1-dimensional PersistenceDiagram:
                 [1.0, 3.0)
                 [3.0, 4.0)
                 [3.0, ∞)"""

        @test copy(diag) == diag
        @test similar(diag) isa typeof(diag)
        @test similar(diag, (Base.OneTo(2),)) isa typeof(diag)
        @test sort(diag) isa typeof(diag)
        @test filter(isfinite, diag) isa typeof(diag)

        @test threshold(diag) == 2

        diag[2] = (3, 5)
        @test diag == PersistenceDiagram(1, [(1, 3), (3, 5), (3, Inf)])
        @test firstindex(diag) == 1
        @test lastindex(diag) == 3
        @test first(diag) == (1, 3)
        @test last(diag) == (3, Inf)
    end
end
