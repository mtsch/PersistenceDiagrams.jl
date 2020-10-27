using PersistenceDiagrams
using Test

using PersistenceDiagrams:
    BottleneckGraph,
    _adjacency_matrix,
    _depth_layers,
    _augmenting_paths,
    _augment!,
    _hopcroft_karp!

@testset "_adjacency_matrix" begin
    diag1 = PersistenceDiagram([(1, 2), (1, Inf)])
    diag2 = PersistenceDiagram([(3, 4), (5, 10), (7, Inf)])

    @test _adjacency_matrix(diag1, diag2) == [
        # 1,2 1,∞ 3,3 5,5 7,7
        2.0 Inf 1.0 Inf Inf  # 3,4
        8.0 Inf Inf 5.0 Inf  # 5,7
        Inf 6.0 Inf Inf Inf  # 7,∞
        1.0 Inf 0.0 0.0 0.0  # 1,1
        Inf Inf 0.0 0.0 0.0  # 1,1
    ]

    @test _adjacency_matrix(diag1, diag2) == _adjacency_matrix(diag2, diag1)'
end

@testset "Hopcroft-Karp" begin
    adj = [
        1 1 9
        1 9 1
        9 9 2
    ]
    graph = BottleneckGraph(adj, [0, 0, 0], [0, 0, 0], Int[], 3)

    @test _depth_layers(graph, 2) == ([1, 1, 1], 1)
    @test _augmenting_paths(graph, 2) == [[1, 1], [3, 2]]

    graph = BottleneckGraph(adj, [1, 0, 2], [1, 3, 0], Int[], 3)
    @test _depth_layers(graph, 2) == ([1, 2, 3], 3)
    @test _augmenting_paths(graph, 2) == [[2, 1, 1, 2, 3, 3]]
    _augment!(graph, [2, 1, 1, 2, 3, 3])
    @test graph.match_left == [2, 1, 3]
    @test graph.match_right == [2, 1, 3]

    graph = BottleneckGraph(adj, [0, 0, 0], [0, 0, 0], Int[], 3)
    @test _hopcroft_karp!(graph, 2) == ([1 => 2, 2 => 1, 3 => 3], true)
    @test _hopcroft_karp!(graph, 1) == ([1 => 1, 3 => 2], false)
end

@testset "Bottleneck basics" begin
    diag1 = PersistenceDiagram([(1, 2), (5, 8)])
    diag2 = PersistenceDiagram([(1, 2), (3, 4), (5, 10)])

    m = Bottleneck()(diag1, diag2; matching=true)
    @test matching(m) == [(5, 8) => (5, 10)]
    @test matching(m; bottleneck=false) ==
          [(1, 2) => (1, 2), (3, 3) => (3, 4), (5, 8) => (5, 10)]
    @test weight(m) ≡ 2.0
    @test Bottleneck()(diag1, diag2) ≡ 2.0
    @test Bottleneck()(diag1, diag2) == weight(matching(Bottleneck(), diag2, diag1))

    @test weight(Bottleneck(), diag1, diag1) ≡ 0.0
end

@testset "Wasserstein basics" begin
    diag1 = PersistenceDiagram([(1, 2), (5, 8)])
    diag2 = PersistenceDiagram([(1, 2), (3, 4), (5, 10)])

    m = Wasserstein()(diag1, diag2; matching=true)
    @test matching(m) == [(1, 2) => (1, 2), (3, 3) => (3, 4), (5, 8) => (5, 10)]
    @test weight(m) ≡ 3.0
    @test Wasserstein()(diag1, diag2) ≡ 3.0
    @test weight(matching(Wasserstein(2), diag1, diag2)) ≡ √(1 + 4)
    for i in 1:3
        @test Wasserstein(i)(diag1, diag2) ≡ Wasserstein(i)(diag2, diag1)
    end

    @test weight(Wasserstein(), diag1, diag1) ≡ 0.0
end

@testset "Infinite intervals" begin
    diag1 = PersistenceDiagram([(1, 2), (5, 8), (1, Inf)])
    diag2 = PersistenceDiagram([(1, 2), (3, 4), (5, 10)])
    diag3 = PersistenceDiagram([(1, 2), (3, 4), (5, 10), (1, Inf)])
    diag4 = PersistenceDiagram([(1, Inf)])
    diag5 = PersistenceDiagram([(2, Inf)])

    for Distance in (Bottleneck(), Wasserstein(), Wasserstein(2))
        @test Distance(diag1, diag2) ≡ Inf
        @test Distance(diag2, diag1) ≡ Inf
        @test weight(Distance(diag1, diag2; matching=true)) ≡ Inf
        @test isempty(matching(Distance, diag1, diag2))
        @test Distance(diag1, diag1) == 0
        @test 0 < Distance(diag1, diag3) < Inf
        @test Distance(diag4, diag5) == 1
    end
end

@testset "Different sizes" begin
    diag1 = PersistenceDiagram(vcat((90, 100), [(i, i + 1) for i in 1:100]))
    diag2 = PersistenceDiagram([(100, 110)])

    @test Bottleneck()(diag1, diag2) == 10
    @test Bottleneck()(diag2, diag1) == 10
    @test Wasserstein()(diag1, diag2) == 110
    @test Wasserstein()(diag2, diag1) == 110
    @test Wasserstein(2)(diag1, diag2) == √200
    @test Wasserstein(2)(diag2, diag1) == √200
end
