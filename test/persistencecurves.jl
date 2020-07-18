using Test
using PersistenceDiagrams

@testset "Construction" begin
    for (start, stop) in ((0, 2), (ℯ, π)), len in (2, 13, 1001)
        curve = PersistenceCurve(identity, len, start, stop, length=len)
        @testset "moving from `start` to `stop` by `step` yields `len` steps" begin
            t = curve.start
            count = 0
            while Float64(t) < curve.stop
                t += curve.step
                count += 1
            end
            @test count == len
        end
        @testset "indexing" begin
            @test curve[1] == Float64(curve.start + curve.step/2)
            @test curve[end] == Float64(curve.stop - curve.step/2)
            @test length(curve) == len
            @test eachindex(curve) == 1:len
            @test_throws BoundsError curve[0]
            @test_throws BoundsError curve[len + 1]

            i1, i2 = curve[1:2]
            @test i2 - i1 ≈ Float64(curve.step)
        end
    end

    @testset "ranges are selected correctly when learning parameters" begin
        diagram_1 = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
        diagram_2 = PersistenceDiagram(0, [(2, Inf)])

        @testset "for diagrams with infinite intervals" begin
            bc = PersistenceCurve((_...) -> 1.0, sum, [diagram_1, diagram_2])
            @test bc.start == 0
            @test bc.stop == Float64(2 + bc.step)
            @test length(bc) == 10
            @test length(bc(diagram_1)) == 10
            @test length(bc(diagram_2)) == 10
        end

        @testset "for diagrams without infinite intervals" begin
            finite = [filter(isfinite, diagram_1), filter(isfinite, diagram_2)]
            bc = PersistenceCurve((_...) -> 1.0, sum, finite)
            @test bc.start == 0
            @test bc.stop == 1.5
            @test length(bc) == 10
            @test length(bc(diagram_1)) == 10
            @test length(bc(diagram_2)) == 10
            @test all(iszero(bc(diagram_2)))
        end
    end
end

@testset "BettiCurve" begin
    @testset "With basic constructor" begin
        diagram = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
        bc_1 = BettiCurve(0, 2, length=2)
        @test bc_1(diagram) == [2.1, 1.5]

        bc_2 = BettiCurve(0, 2, length=20)
        @test bc_2(diagram) == [1, 1, 1, 1, 1, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1]

        bc_3 = BettiCurve(0, 2, length=10)
        @test bc_3(diagram) == [1, 1, 2.5, 3, 3, 2, 2, 1.5, 1.0, 1.0]
    end

    @testset "With learned parameters" begin
        diagram_1 = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
        diagram_2 = PersistenceDiagram(0, [(2, Inf)])
        @testset "Last bucket only contains infinite intervals." begin
            for len in (10, 20, 40)
                bc = BettiCurve([diagram_1], length=len)
                @test bc(diagram_1)[end] == 1
                @test bc(diagram_1)[end - 1] == 2
                @test length(bc) == len
                @test length(bc(diagram_1)) == len
                @test length(bc(diagram_2)) == len
            end
        end
    end
end

@testset "Landscape" begin
    diagram = PersistenceDiagram(1, [(3, 9), (4, 6), (5, 11)])

    @testset "(k + 1)-th landscape is below the k-th landscape" begin
        for k in 1:3
            scape_1 = Landscape(k, 0, 12, length=12)
            scape_2 = Landscape(k + 1, 0, 12, length=12)
            @test all(scape_2(diagram) .≤ scape_1(diagram))
        end
    end

    @testset "for a large enough k, a landscape is zero everywhere" begin
        scape = Landscape(4, 0, 12, length=12)
        @test all(iszero, scape(diagram))
    end
end

@testset "Silhuette" begin
    diagram = PersistenceDiagram(1, [(3, 9), (4, 6), (5, 11)])

    @testset "a silhuette is equivalent to the sum of landscapes" begin
        scape_res = zeros(24)
        for k in 1:3
            scape_res .+= Landscape(k, 0, 12, length=24)(diagram)
        end
        @test Silhuette(0, 12, length=24)(diagram) == scape_res
    end
end
