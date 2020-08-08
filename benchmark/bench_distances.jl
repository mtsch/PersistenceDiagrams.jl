module BenchDistances
using BenchmarkTools
using PersistenceDiagrams
using Random

Random.seed!(2000)
suite = BenchmarkGroup()

pd_big = PersistenceDiagram([(rand(), 1 + rand()) for _ in 1:2000])
pd_med1 = PersistenceDiagram([(rand(), 1 + rand()) for _ in 1:100])
pd_med2 = PersistenceDiagram([(rand(), 1 + rand()) for _ in 1:100])
pd_small1 = PersistenceDiagram([(rand(), 1 + rand()) for _ in 1:50])
pd_small2 = PersistenceDiagram([(rand(), 1 + rand()) for _ in 1:50])

suite["Bottleneck() large a"] =
    @benchmarkable Bottleneck()($pd_big, $pd_med1) seconds=30
suite["Bottleneck() large b"] =
    @benchmarkable Bottleneck()($pd_med1, $pd_big) seconds=30
suite["Bottleneck() medium"] =
    @benchmarkable Bottleneck()($pd_med1, $pd_med2) seconds=30
suite["Bottleneck() small"] =
    @benchmarkable Bottleneck()($pd_small1, $pd_small2) seconds=30

suite["Wasserstein() large a"] =
    @benchmarkable Wasserstein()($pd_big, $pd_med1) seconds=30
suite["Wasserstein() large b"] =
    @benchmarkable Wasserstein()($pd_med1, $pd_big) seconds=30
suite["Wasserstein() medium"] =
    @benchmarkable Wasserstein()($pd_med1, $pd_med2) seconds=30
suite["Wasserstein() small"] =
    @benchmarkable Wasserstein()($pd_small1, $pd_small2) seconds=30

end

BenchDistances.suite
