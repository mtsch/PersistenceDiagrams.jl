var documenterSearchIndex = {"docs":
[{"location":"api/diagrams/#Persistence-Intervals-and-Diagrams","page":"API","title":"Persistence Intervals and Diagrams","text":"","category":"section"},{"location":"api/diagrams/","page":"API","title":"API","text":"PersistenceInterval","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.PersistenceInterval","page":"API","title":"PersistenceDiagrams.PersistenceInterval","text":"PersistenceInterval{T<:AbstractFloat, C}\n\nThe type that represents a persistence interval. It behaves exactly like a Tuple{Float64, Float64}.\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"birth","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.birth","page":"API","title":"PersistenceDiagrams.birth","text":"birth(interval)\n\nGet the birth time of interval.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"death","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.death","page":"API","title":"PersistenceDiagrams.death","text":"death(interval)\n\nGet the death time of interval.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"persistence","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.persistence","page":"API","title":"PersistenceDiagrams.persistence","text":"persistence(interval)\n\nGet the persistence of interval, which is equal to death - birth.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"RepresentativeInterval","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.RepresentativeInterval","page":"API","title":"PersistenceDiagrams.RepresentativeInterval","text":"RepresentativeInterval{P<:AbstractInterval, B, D, R} <: AbstractInterval\n\nA persistence interval with a representative (co)cycles and critical simplices attached.\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"representative","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.representative","page":"API","title":"PersistenceDiagrams.representative","text":"representative(interval::RepresentativeInterval)\n\nGet the representative (co)cycle attached to interval.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"birth_simplex","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.birth_simplex","page":"API","title":"PersistenceDiagrams.birth_simplex","text":"birth_simplex(interval::RepresentativeInterval)\n\nGet the critical birth simplex of interval.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"death_simplex","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.death_simplex","page":"API","title":"PersistenceDiagrams.death_simplex","text":"death_simplex(interval::RepresentativeInterval)\n\nGet the critical death simplex of interval.\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"PersistenceDiagram","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.PersistenceDiagram","page":"API","title":"PersistenceDiagrams.PersistenceDiagram","text":"PersistenceDiagram{P<:AbstractInterval} <: AbstractVector{P}\n\nType for representing persistence diagrams. Behaves exactly like an array of AbstractIntervals, but is aware of its dimension and supports pretty printing and plotting.\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"barcode(::Union{PersistenceDiagram, AbstractVector{<:PersistenceDiagram}})","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.barcode-Tuple{Union{AbstractArray{#s12,1} where #s12<:PersistenceDiagram, PersistenceDiagram}}","page":"API","title":"PersistenceDiagrams.barcode","text":"barcode(diagram)\n\nPlot the barcode plot of persistence diagram or multiple diagrams diagrams. The infinity keyword argument determines where the infinity line is placed. If unset, the function tries to use threshold(diagram) or guess a good position to place the line at.\n\n\n\n\n\n","category":"method"},{"location":"api/diagrams/#Distances-Between-Persistence-Diagrams","page":"API","title":"Distances Between Persistence Diagrams","text":"","category":"section"},{"location":"api/diagrams/","page":"API","title":"API","text":"Bottleneck","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.Bottleneck","page":"API","title":"PersistenceDiagrams.Bottleneck","text":"Bottleneck\n\nUse this object to find the bottleneck distance or matching between persistence diagrams. The distance value is equal to\n\nW_infty(X Y) = inf_etaXrightarrow Y sup_xin X x-eta(x)_infty\n\nwhere X and Y are the persistence diagrams and eta is a perfect matching between the intervals. Note the X and Y don't need to have the same number of points, as the diagonal points are considered in the matching as well.\n\nWarning\n\nComputing the bottleneck distance requires mathcalO(n^2) space. Be careful when computing distances between very large diagrams!\n\nUsage\n\nBottleneck()(left, right[; matching=false]): find the bottleneck matching (if matching=true) or distance (if matching=false) between persistence diagrams left and right\n\nExample\n\nleft = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])\nright = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])\nBottleneck()(left, right)\n\n# output\n\n2.0\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"Wasserstein","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.Wasserstein","page":"API","title":"PersistenceDiagrams.Wasserstein","text":"Wasserstein(q=1)\n\nUse this object to find the Wasserstein distance or matching between persistence diagrams. The distance value is equal to\n\nW_q(XY)=leftinf_etaXrightarrow Ysum_xin Xx-eta(x)_infty^qright\n\nwhere X and Y are the persistence diagrams and eta is a perfect matching between the intervals. Note the X and Y don't need to have the same number of points, as the diagonal points are considered in the matching as well.\n\nWarning\n\nComputing the Wasserstein distance requires mathcalO(n^2) space. Be careful when computing distances between very large diagrams!\n\nUsage\n\nWasserstein(q=1)(left, right[; matching=false]): find the Wasserstein matching (if matching=true) or distance (if matching=false) between persistence diagrams left and right.\n\nExample\n\nleft = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])\nright = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])\nWasserstein()(left, right)\n\n# output\n\n3.0\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"matching","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.matching","page":"API","title":"PersistenceDiagrams.matching","text":"matching(::MatchingDistance, left, right)\nmatching(::Matching)\n\nGet the matching between persistence diagrams left and right.\n\nSee also\n\nmatching\nBottleneck\nWasserstein\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/","page":"API","title":"API","text":"weight","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.weight","page":"API","title":"PersistenceDiagrams.weight","text":"weight(::MatchingDistance, left, right)\nweight(::Matching)\n\nGet the weight of the matching between persistence diagrams left and right.\n\nSee also\n\nmatching\nBottleneck\nWasserstein\n\n\n\n\n\n","category":"function"},{"location":"api/diagrams/#Persistence-Diagram-Vectorization-Methods","page":"API","title":"Persistence Diagram Vectorization Methods","text":"","category":"section"},{"location":"api/diagrams/","page":"API","title":"API","text":"BettiCurve","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.BettiCurve","page":"API","title":"PersistenceDiagrams.BettiCurve","text":"BettiCurve\n\nA betti curve is a simple way of transforming a persistence diagram to a vector of real numbers. A BettiCurve bc splits the barcode of a diagram into length(bc) buckets, counting the number of bars in each bucket. If only a part of a bar is contained in a bucket, it is only partially counted.\n\nOnce a BettiCurve is constructed (see below), it can be called to convert a persistence diagram to a vector of floats.\n\nUnlike most diagram vectorization methods, BettiCurve can handle infinite intervals.\n\nConstructors\n\nBettiCurve(t_start, t_end; length=10): length buckets with the first strating on t_start and the last ending on t_end.\nBettiCurve(diagrams; length=10): learn the t_start and t_end parameters from a collection of persistence diagrams.\nBettiCurve(buckets): manually select the buckets. buckets should be an AbstractVector of length one higher than the desired output size.\n\nExample\n\ndiagram = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])\ncurve = BettiCurve(0, 2, length = 4)\ncurve(diagram)\n\n# output\n\n4-element Array{Float64,1}:\n 1.0\n 3.2\n 2.0\n 1.0\n\n\n\n\n\n","category":"type"},{"location":"api/diagrams/","page":"API","title":"API","text":"PersistenceImage","category":"page"},{"location":"api/diagrams/#PersistenceDiagrams.PersistenceImage","page":"API","title":"PersistenceDiagrams.PersistenceImage","text":"PersistenceImage\n\nPersistenceImage provides a vectorization method for persistence diagrams. Each point in the diagram is first transformed into birth, persistence coordinates. Then, it is weighted by a weighting function and widened by a distribution (default: gaussian with σ=1). Once all the points are transformed, their distributions are summed together and discretized into an image.\n\nThe weighting ensures points near the diagonal have a small contribution. This ensures this representation of the diagram is stable.\n\nOnce a PersistenceImage is constructed (see below), it can called like a function to transform a diagram to an image.\n\nInfinite intervals in the diagram are ignored.\n\nConstructors\n\nPersistenceImage(ylims, xlims; size=5, kwargs...)\nPersistenceImage(diagrams; size=5, kwargs...)\n\nArguments\n\nylims, xlims: Limits of the square on which the image is created, both 2-tuples. Note that y comes first as this is the way arrays are indexed.\ndiagrams: Collection of persistence diagrams. This constructor sets ylims and xlims according to minimum and maximum birth time and persistence time. Sets slope_end to maximum persistence time.\n\nKeyword Arguments\n\ndistribution: A function or callable object used to smear each interval in diagram.  Has to be callable with two Float64s as input and should return a Float64. Defaults to a normal distribution with sigma equal to 1.\nsigma: The width of the gaussian distribution. Only applicable when distribution is unset.\nweight: A function or callable object used as the weighting function. Has to be callable with two Float64s as input and should return a Float64. Should equal 0.0 for x=0, but this is not enforced.\nslope_end: the y value at which the default weight function stops increasing.\nsize: integer or tuple of two integers. Determines the size of the array containing the image. Defaults to 5.\n\nExample\n\ndiag_1 = PersistenceDiagram(0, [(0, 1), (0, 1.5), (1, 2)])\ndiag_2 = PersistenceDiagram(0, [(1, 2), (1, 1.5)])\nimage = PersistenceImage([diag_1, diag_2])\n\n# output\n\n5×5 PersistenceImage(\n  distribution = PersistenceDiagrams.Binormal(1.0),\n  weight = PersistenceDiagrams.DefaultWeightingFunction(1.5)\n)\n\nimage(diag_1)\n\n# output\n\n5×5 Array{Float64,2}:\n 0.266562  0.269891  0.264744  0.251762  0.232227\n 0.294472  0.297554  0.291244  0.276314  0.254244\n 0.31342   0.316057  0.308664  0.292136  0.268117\n 0.32141   0.323446  0.315164  0.297554  0.272373\n 0.31758   0.318928  0.310047  0.29199   0.266562\n\n\n\n\n\n","category":"type"},{"location":"#PersistenceDiagrams.jl","page":"Home","title":"PersistenceDiagrams.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package provides the PersistenceInterval and PersistenceDiagram types as well as some functions for working with them. If you want to compute persistence diagrams, please see Ripserer.jl. For examples and tutorials, see the Ripserer.jl docs.","category":"page"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package currently supports the following.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Persistence diagram plotting.\nBottleneck and Wasserstein matching and distance computation.\nBetti curves.\nPersistence images.","category":"page"}]
}
