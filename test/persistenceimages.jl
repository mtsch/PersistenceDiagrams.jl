using PersistenceDiagrams
using Test

@testset "Constructors" begin
    pi_1 = PersistenceImage((0, 2), (0, 3); size=(10, 15))
    @test length(pi_1.ys) == 11
    @test length(pi_1.xs) == 16
    @test first(pi_1.ys) == 0
    @test last(pi_1.ys) == 2
    @test first(pi_1.xs) == 0
    @test last(pi_1.xs) == 3
    @test pi_1.weight == PersistenceDiagrams.DefaultWeightingFunction(2.0)
    @test pi_1.distribution == PersistenceDiagrams.Binormal(0.375)

    pi_2 = PersistenceImage((1, 3), (2, 4); sigma=2.0, slope_end=0.5)
    @test length(pi_2.ys) == 6
    @test length(pi_2.xs) == 6
    @test first(pi_2.ys) == 1
    @test last(pi_2.ys) == 3
    @test first(pi_2.xs) == 2
    @test last(pi_2.xs) == 4
    @test pi_2.weight == PersistenceDiagrams.DefaultWeightingFunction(1.5)
    @test pi_2.distribution == PersistenceDiagrams.Binormal(2.0)

    @test PersistenceImage((0, 8), (0, 7); distribution=*).distribution == (*)
    @test PersistenceImage((0, 8), (0, 7); weight=*).weight == (*)

    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4); sigma=4, distribution=*)
    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4); slope_end=1, weight=*)
    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4); slope_end=5)
    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4); slope_end=0)
    @test_throws ArgumentError PersistenceImage((1, 2), (3, 4); sigma=0)

    diagram_1 = PersistenceDiagram([(1, 2), (1, 7), (3, 4), (2, 3)])
    diagram_2 = PersistenceDiagram([(0, 2), (-1, Inf), (4, 5)])

    pi_3 = PersistenceImage([diagram_1, diagram_2]; margin=0, zero_start=false)
    @test pi_3.ys == range(1, 6; length=6)
    @test pi_3.xs == range(0, 4; length=6)
    @test pi_3.weight == PersistenceDiagrams.DefaultWeightingFunction(6.0)

    pi_4 = PersistenceImage([diagram_1, diagram_2]; margin=0)
    @test pi_4.ys == range(0, 6; length=6)
    @test pi_4.xs == range(0, 4; length=6)
    @test pi_4.weight == PersistenceDiagrams.DefaultWeightingFunction(6.0)

    pi_5 = PersistenceImage([diagram_1, diagram_2]; margin=0.5)
    @test pi_5.ys == range(0, 9; length=6)
    @test pi_5.xs == range(-2, 6; length=6)
    @test pi_5.weight == PersistenceDiagrams.DefaultWeightingFunction(9.0)

    @test_throws ArgumentError PersistenceImage([diagram_1, diagram_2]; margin=-1)

    @test sprint(show, pi_1) == "10×15 PersistenceImage"
    @test sprint(show, pi_2) == "5×5 PersistenceImage"
    @test sprint(show, pi_3) == "5×5 PersistenceImage"

    @test sprint((io, x) -> show(io, MIME"text/plain"(), x), pi_1) ==
          "10×15 PersistenceImage(\n" *
          "  distribution = PersistenceDiagrams.Binormal(0.375),\n" *
          "  weight = PersistenceDiagrams.DefaultWeightingFunction(2.0),\n)"
end

@testset "Transform" begin
    diagram_1 = PersistenceDiagram([(1, 2), (1, 6), (3, 4), (2, 3)])
    diagram_2 = PersistenceDiagram([(0, 2), (0, Inf), (5, 5)])

    image_1 = PersistenceImage((0, 2), (0, 3); size=20, weight=*)
    image_2 = PersistenceImage((0, 2), (0, 3); size=(10, 15), slope_end=0.5)
    image_3 = PersistenceImage([diagram_1, diagram_2])

    @test size(image_1(diagram_1)) == (20, 20)
    @test size(image_2(diagram_1)) == (10, 15)
    @test size(image_3(diagram_1)) == (5, 5)
    @test size(image_1(diagram_2)) == (20, 20)
    @test size(image_2(diagram_2)) == (10, 15)
    @test size(image_3(diagram_2)) == (5, 5)

    diagram_3 = PersistenceDiagram([(1, 1), (2, 2), (3, 3)])
    @test all(iszero, image_1(diagram_3))
    @test all(iszero, image_2(diagram_3))
    @test all(iszero, image_3(diagram_3))
end
