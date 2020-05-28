using PersistenceDiagrams

@testset "constructor" begin
    pi_1 = PersistenceImage((0, 2), (0, 3), size=(10, 15))
    @test length(pi_1.ys) == 11
    @test length(pi_1.xs) == 16
    @test first(pi_1.ys) == 0
    @test last(pi_1.ys) == 2
    @test first(pi_1.xs) == 0
    @test last(pi_1.xs) == 3
    @test pi_1.weight == PersistenceDiagrams.DefaultWeightingFunction(1.0)
    @test pi_1.distribution == PersistenceDiagrams.Binormal(1.0)

    pi_2 = PersistenceImage((1, 3), (2, 4), sigma=2.0, slope_end=3)
    @test length(pi_2.ys) == 51
    @test length(pi_2.xs) == 51
    @test first(pi_2.ys) == 1
    @test last(pi_2.ys) == 3
    @test first(pi_2.xs) == 2
    @test last(pi_2.xs) == 4
    @test pi_2.weight == PersistenceDiagrams.DefaultWeightingFunction(3.0)
    @test pi_2.distribution == PersistenceDiagrams.Binormal(2.0)

    @test PersistenceImage((0, 8), (0, 7), distribution=*).distribution == (*)
    @test PersistenceImage((0, 8), (0, 7), weight=*).weight == (*)

    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4), sigma=4, distribution=*)
    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4), slope_end=4, weight=*)

    diagram_1 = PersistenceDiagram(0, [(1, 2), (1, 7), (3, 4), (2, 3)])
    diagram_2 = PersistenceDiagram(0, [(0, 2), (-1, Inf), (4, 5)])

    pi_3 = PersistenceImage([diagram_1, diagram_2])
    @test pi_3.ys == range(1, 6, length=51)
    @test pi_3.xs == range(0, 4, length=51)
    @test pi_3.weight == PersistenceDiagrams.DefaultWeightingFunction(6.0)

    @test sprint(show, pi_1) == "10×15 PersistenceImage"
    @test sprint(show, pi_2) == "50×50 PersistenceImage"
    @test sprint(show, pi_3) == "50×50 PersistenceImage"

    @test sprint((io, x) -> show(io, MIME"text/plain"(), x), pi_1) ==
        """
        10×15 PersistenceImage(
          distribution = PersistenceDiagrams.Binormal(1.0),
          weight = PersistenceDiagrams.DefaultWeightingFunction(1.0)
        )"""
end

@testset "transform" begin
    diagram_1 = PersistenceDiagram(0, [(1, 2), (1, 6), (3, 4), (2, 3)])
    diagram_2 = PersistenceDiagram(0, [(0, 2), (0, Inf), (5, 5)])

    pi_1 = PersistenceImage((0, 2), (0, 3), size=20, weight=*)
    pi_2 = PersistenceImage((0, 2), (0, 3), size=(10, 15), slope_end=5)
    pi_3 = PersistenceImage([diagram_1, diagram_2])

    @test size(transform(pi_1, diagram_1)) == (20, 20)
    @test size(transform(pi_2, diagram_1)) == (10, 15)
    @test size(transform(pi_3, diagram_1)) == (50, 50)
    @test size(transform(pi_1, diagram_2)) == (20, 20)
    @test size(transform(pi_2, diagram_2)) == (10, 15)
    @test size(transform(pi_3, diagram_2)) == (50, 50)

    @test_throws ArgumentError transform!(zeros(20, 20), pi_2, diagram_1)

    diagram_3 = PersistenceDiagram(0, [(1, 1), (2, 2), (3, 3)])
    @test all(iszero, transform(pi_1, diagram_3))
    @test all(iszero, transform!(zeros(10, 15), pi_2, diagram_3))
    @test all(iszero, transform(pi_3, diagram_3))
end
