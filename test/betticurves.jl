using PersistenceDiagrams

@testset "With basic constructor." begin
    diagram = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
    bc_1 = BettiCurve(0, 2, length=2)
    @test bc_1(diagram) == [2.1, 1.5]

    bc_2 = BettiCurve(0, 2, length=20)
    @test bc_2(diagram) == [1, 1, 1, 1, 1, 4, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1]

    bc_3 = BettiCurve(0, 2, length=10)
    @test bc_3(diagram) == [1, 1, 2.5, 3, 3, 2, 2, 1.5, 1.0, 1.0]
end

@testset "With learned parameters." begin
    diagram_1 = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
    diagram_2 = PersistenceDiagram(0, [(2, Inf)])

    @testset "Ranges selected correctly" begin
        @testset "with infinite intervals." begin
            bc = BettiCurve([diagram_1, diagram_2])
            @test bc.buckets[1] == 0
            @test bc.buckets[end-1] == 2
            @test length(bc) == 10
            @test length(bc(diagram_1)) == 10
            @test length(bc(diagram_2)) == 10
        end

        @testset "without infinite intervals." begin
            bc = BettiCurve([filter(isfinite, diagram_1), filter(isfinite, diagram_2)])
            @test bc.buckets[1] == 0
            @test bc.buckets[end] == 1.5
            @test length(bc) == 10
            @test length(bc(diagram_1)) == 10
            @test length(bc(diagram_2)) == 10
            @test all(iszero(bc(diagram_2)))
        end
    end
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
