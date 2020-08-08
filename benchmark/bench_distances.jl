module BenchDistances
using PersistenceDiagrams
using BenchmarkTools
suite = BenchmarkGroup()

pd_big = PersistenceDiagram(0, [(rand(), rand()) for _ in 1:2000])
pd_med = PersistenceDiagram(0, [(rand(), rand()) for _ in 1:100])
pd_small = PersistenceDiagram(0, [(rand(), rand()) for _ in 1:50])

suite["Bottleneck() large a"] =
    @benchmarkable Bottleneck()($pd_big, $pd_med) seconds=30
suite["Bottleneck() large b"] =
    @benchmarkable Bottleneck()($pd_med, $pd_big) seconds=30
suite["Bottleneck() medium"] =
    @benchmarkable Bottleneck()($pd_med, $pd_med) seconds=30
suite["Bottleneck() small"] =
    @benchmarkable Bottleneck()($pd_small, $pd_small) seconds=30

suite["Wasserstein() large a"] =
    @benchmarkable Wasserstein()($pd_big, $pd_med) seconds=30
suite["Wasserstein() large b"] =
    @benchmarkable Wasserstein()($pd_med, $pd_big) seconds=30
suite["Wasserstein() medium"] =
    @benchmarkable Wasserstein()($pd_med, $pd_med) seconds=30
suite["Wasserstein() small"] =
    @benchmarkable Wasserstein()($pd_small, $pd_small) seconds=30

end

BenchDistances.suite
