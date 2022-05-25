var documenterSearchIndex = {"docs":
[{"location":"mlj/#MLJ-Models","page":"MLJ Models","title":"MLJ Models","text":"","category":"section"},{"location":"mlj/","page":"MLJ Models","title":"MLJ Models","text":"PersistenceDiagrams.PersistenceImageVectorizer","category":"page"},{"location":"mlj/#PersistenceDiagrams.PersistenceImageVectorizer","page":"MLJ Models","title":"PersistenceDiagrams.PersistenceImageVectorizer","text":"PersistenceImageVectorizer(; kwargs...)\n\nConverts persistence diagrams into persistence images. Each pixel in the image curve is mapped to a column.\n\nHyperparameters\n\ndistribution::Any = :default: the distribution used to smear each point in the diagram. Can be a function, a callable object, or :default. When set to :default, a binormal distribution is used.\nsigma::Float64 = -1: the width of the gaussian distribution. Only applicable when distribution=:default. If set to -1, its value is learned from data.\nweight::Any = :default: the weighting function. Can be a function, a callable object, or :default. When set to :default, a piecewise linear function is used. To make this method work correctly, weight(0.0, _) == 0.0 should always hold.\nslope_end::Float64 = 1.0: the (relative) position in the diagram where the default weight function stops decreasing. Only applicable when weight=:default.\nwidth::Int = 10, height::Int = 10: the size of the image. Note that all pixels of the image will be converted to columns. For example a 3×4 image will produce 12 columns per dimension.\n\nSee also\n\nPersistenceImage\n\n\n\n\n\n","category":"type"},{"location":"mlj/","page":"MLJ Models","title":"MLJ Models","text":"PersistenceDiagrams.PersistenceCurveVectorizer","category":"page"},{"location":"mlj/#PersistenceDiagrams.PersistenceCurveVectorizer","page":"MLJ Models","title":"PersistenceDiagrams.PersistenceCurveVectorizer","text":"PersistenceCurveVectorizer(; kwargs...)\n\nConverts persistence diagrams into persistence curves. Each value of the curve is mapped to a column.\n\nHyperparameters\n\nfun::Function = always_one: The function used to construct the curve. See also PersistenceCurve. Note: the curve argument must be :custom if this argument is set.\nstat::Function = sum: The statistic used to construct the curve. See also PersistenceCurve. Note: the curve argument must be :custom if this argument is set.\ncurve::Symbol = :custom: The type of curve used. Available options are :custom, :betti, :silhuette, :life, :midlife, :life_entropy, :midlife_entropy, and :pd_thresholding.\nintegrate::Bool = true: If set to true, the curve is integrated. If set to false, the curve is simply sampled at specified points.\nnormalize::Bool = false: Normalize the curve by dividing all values by stat(fun.(diagram)).\nlength::Int = 10: The number of columns per dimension to output.\n\nSee also\n\nPersistenceCurve\nBettiCurve\nSilhuette\nLife\nMidlife\nLifeEntropy\nMidlifeEntropy\nPDThresholding\n\n\n\n\n\n","category":"type"},{"location":"mlj/","page":"MLJ Models","title":"MLJ Models","text":"PersistenceDiagrams.PersistenceLandscapeVectorizer","category":"page"},{"location":"mlj/#PersistenceDiagrams.PersistenceLandscapeVectorizer","page":"MLJ Models","title":"PersistenceDiagrams.PersistenceLandscapeVectorizer","text":"PersistenceLandscapeVectorizer\n\nConverts persistence diagrams into persistence landscapes. Each value of the curve is mapped to a column.\n\nHyperparameters\n\nn_landscapes = 1: use the top n landscapes.\nlength = 10: the number of columns per dimension per landscape to output. For example, for n_landscapes=3, length=10, and two persistence diagrams, the vectorization will produce 30 columns.\n\nSee also\n\nLandscapes\nLandscape\n\n\n\n\n\n","category":"type"},{"location":"vectorization/#Persistence-Diagram-Vectorization","page":"Vectorization","title":"Persistence Diagram Vectorization","text":"","category":"section"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"PersistenceImage","category":"page"},{"location":"vectorization/#PersistenceDiagrams.PersistenceImage","page":"Vectorization","title":"PersistenceDiagrams.PersistenceImage","text":"PersistenceImage\n\nPersistenceImage provides a vectorization method for persistence diagrams. Each point in the diagram is first transformed into birth, persistence coordinates. Then, it is weighted by a weighting function and widened by a distribution (default: gaussian with σ=1). Once all the points are transformed, their distributions are summed together and discretized into an image.\n\nThe weighting ensures points near the diagonal have a small contribution. This ensures this representation of the diagram is stable.\n\nOnce a PersistenceImage is constructed (see below), it can called like a function to transform a diagram to an image.\n\nInfinite intervals in the diagram are ignored.\n\nConstructors\n\nPersistenceImage(ylims, xlims; kwargs...)\n\nCreate an image ranging from ylims[1] to ylims[2] in the y direction and equivalently for the x direction.\n\nPersistenceImage(diagrams; zero_start=true, margin=0.1, kwargs...)\n\nLearn the x and y ranges from diagrams, ensuring all diagrams will fully fit in the image. Limits are increased by the margin. If zero_start is true, set the minimum y value to 0. If all intervals in diagrams have the same birth (e.g. in the zeroth dimension), a single column image is produced.\n\nKeyword Arguments\n\nsize: integer or tuple of two integers. Determines the size of the array containing the image. Defaults to 5.\ndistribution: A function or callable object used to smear each interval in diagram.  Has to be callable with two Float64s as input and should return a Float64. Defaults to a normal distribution.\nsigma: The width of the normal distribution mentioned above. Only applicable when distribution is unset. Defaults to twice the size of each pixel.\nweight: A function or callable object used as the weighting function. Has to be callable with two Float64s as input and should return a Float64. Should equal 0.0 for x=0, but this is not enforced. Defaults to function that is zero at y=0, and increases linearly to 1 until slope_end is reached.\nslope_end: the relative y value at which the default weight function stops increasing. Defaults to 1.0.\n\nExample\n\njulia> diag_1 = PersistenceDiagram([(0, 1), (0, 1.5), (1, 2)]);\n\njulia> diag_2 = PersistenceDiagram([(1, 2), (1, 1.5)]);\n\njulia> image = PersistenceImage([diag_1, diag_2])\n5×5 PersistenceImage(\n  distribution = PersistenceDiagrams.Binormal(0.5499999999999999),\n  weight = PersistenceDiagrams.DefaultWeightingFunction(1.65),\n)\n\njulia> image(diag_1)\n5×5 Matrix{Float64}:\n 0.156707  0.164263  0.160452  0.149968  0.133353\n 0.344223  0.355089  0.338991  0.308795  0.268592\n 0.571181  0.577527  0.535069  0.47036   0.396099\n 0.723147  0.714873  0.639138  0.536823  0.432264\n 0.700791  0.677237  0.582904  0.46433   0.352962\n\n\nReference\n\nAdams, H., Emerson, T., Kirby, M., Neville, R., Peterson, C., Shipman, P., ... & Ziegelmeier, L. (2017). Persistence images: A stable vector representation of persistent homology. The Journal of Machine Learning Research, 18(1), 218-252.\n\n\n\n\n\n","category":"type"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"PersistenceCurve","category":"page"},{"location":"vectorization/#PersistenceDiagrams.PersistenceCurve","page":"Vectorization","title":"PersistenceDiagrams.PersistenceCurve","text":"PersistenceCurve\n\nPersistence curves offer a general way to transform a persistence diagram into a vector of numbers.\n\nThis is done by first splitting the time domain into buckets. Then the intervals contained in the bucket are collected and transformed by applying fun to each of them. The result is then summarized with the stat function. If an interval is only parially contained in a bucket, it is counted partially.\n\nOnce a PersistenceCurve is constructed (see below), it can be called to convert a persistence diagram to a vector of floats.\n\nConstructors\n\nPersistenceCurve(fun, stat, start, stop; length=10, integrate=true, normalize=false): length buckets with the first strating on t_start and the last ending on t_end.\nPersistenceCurve(fun, stat, diagrams; length=10, integreate=true, normalize=false): learn the start and stop parameters from a collection of persistence diagrams.\n\nArguments\n\nlength: the length of the output. Defaults to 10.\nfun: the function applied to each interval. Must have the following signature. fun(::AbstractPersistenceInterval, ::PersistenceDiagram, time)::T\nstat: the summary function applied the results of fun. Must have the following signature. stat(::Vector{T})::Float64\nnormalize: if set to true, normalize the result. Does not work for time-dependent funs. Defaults to false. Normalization is performed by dividing all values by stat(fun.(diag)).\nintegrate: if set to true, the amount of overlap between an interval and a bucket is considered. This prevents missing very small bars, but does not work correctly for curves with time-dependent funs where stat is a selection function (such as landscapes). If set to false, the curve is simply sampled at midpoints of buckets. Defaults to true.\n\nCall\n\n(::PersistenceCurve)(diagram; normalize, integrate)\n\nTransforms a diagram. normalize and integrate override defaults set in constructor.\n\nExample\n\njulia> diagram = PersistenceDiagram([(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)]);\n\njulia> curve = BettiCurve(0, 2, length = 4)\nPersistenceCurve(always_one, sum, 0.0, 2.0; length=4, normalize=false, integrate=true)\n\njulia> curve(diagram)\n4-element Vector{Float64}:\n 1.0\n 3.2\n 2.0\n 1.0\n\nSee Also\n\nThe following are equivalent to PersistenceCurve with appropriately selected fun and stat arguments.\n\nBettiCurve\nLandscape\nSilhuette\nLife\nMidlife\nLifeEntropy\nMidlifeEntropy\nPDThresholding\n\nMore options listed in Table 1 on page 9 of reference.\n\nReference\n\nChung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing persistence diagrams. arXiv preprint arXiv:1904.07768.\n\n\n\n\n\n","category":"type"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"BettiCurve","category":"page"},{"location":"vectorization/#PersistenceDiagrams.BettiCurve","page":"Vectorization","title":"PersistenceDiagrams.BettiCurve","text":"BettiCurve\n\nBetti curves count the Betti numbers at each time step. Unlike most vectorization methods, they support infinite intervals.\n\nfun(_, _, _) = 1.0\nstat = sum\n\nSee also\n\nPersistenceCurve\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"Life","category":"page"},{"location":"vectorization/#PersistenceDiagrams.Life","page":"Vectorization","title":"PersistenceDiagrams.Life","text":"Life\n\nThe life curve.\n\nfun((b, d), _, _) = d - b\nstat = sum\n\nSee also\n\nPersistenceCurve\n\nReference\n\nChung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing persistence diagrams. arXiv preprint arXiv:1904.07768.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"Midlife","category":"page"},{"location":"vectorization/#PersistenceDiagrams.Midlife","page":"Vectorization","title":"PersistenceDiagrams.Midlife","text":"Midlife\n\nThe midlife curve.\n\nfun((b, d), _, _) = (b + d) / 2\nstat = sum\n\nSee also\n\nPersistenceCurve\n\nReference\n\nChung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing persistence diagrams. arXiv preprint arXiv:1904.07768.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"LifeEntropy","category":"page"},{"location":"vectorization/#PersistenceDiagrams.LifeEntropy","page":"Vectorization","title":"PersistenceDiagrams.LifeEntropy","text":"LifeEntropy\n\nThe life entropy curve.\n\nfun((b, d), diag, _) = begin\n    x = (d - b) / sum(d - b for (b, d) in diag)\n    -x * log2(x)\nend\nstat = sum\n\nSee also\n\nPersistenceCurve\n\nReference\n\nAtienza, N., González-Díaz, R., & Soriano-Trigueros, M. (2018). On the stability of persistent entropy and new summary functions for TDA. arXiv preprint arXiv:1803.08304.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"MidlifeEntropy","category":"page"},{"location":"vectorization/#PersistenceDiagrams.MidlifeEntropy","page":"Vectorization","title":"PersistenceDiagrams.MidlifeEntropy","text":"MidlifeEntropy\n\nThe midlife entropy curve.\n\nfun((b, d), diag, _) = begin\n    x = (b + d) / sum(b + d for (d, b) in diag)\n    -x * log2(x)\nend\nstat = sum\n\nSee also\n\nPersistenceCurve\n\nReference\n\nChung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing persistence diagrams. arXiv preprint arXiv:1904.07768.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"PDThresholding","category":"page"},{"location":"vectorization/#PersistenceDiagrams.PDThresholding","page":"Vectorization","title":"PersistenceDiagrams.PDThresholding","text":"PDThresholding\n\nThe persistence diagram thresholding function.\n\nfun((b, d), _, t) = (d - t) * (t - b)\nstat = mean\n\nSee also\n\nPersistenceCurve\n\nReference\n\nChung, Y. M., & Day, S. (2018). Topological fidelity and image thresholding: A persistent homology approach. Journal of Mathematical Imaging and Vision, 60(7), 1167-1179.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"Landscapes","category":"page"},{"location":"vectorization/#PersistenceDiagrams.Landscapes","page":"Vectorization","title":"PersistenceDiagrams.Landscapes","text":"Landscapes(n, args...)\n\nThe first n persistence landscapes.\n\nfun((b, d), _, t) = max(min(t - b, d - t), 0)\nstat = get(sort(values, rev=true), k, 0.0)\n\nVectorizes to a matrix where each column is a landscape.\n\nSee also\n\nPersistenceCurve\nLandscape\n\nReference\n\nBubenik, P. (2015). Statistical topological data analysis using persistence landscapes. The Journal of Machine Learning Research, 16(1), 77-102.\n\n\n\n\n\n","category":"type"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"Landscape","category":"page"},{"location":"vectorization/#PersistenceDiagrams.Landscape","page":"Vectorization","title":"PersistenceDiagrams.Landscape","text":"Landscape(k, args...)\n\nThe k-th persistence landscape.\n\nfun((b, d), _, t) = max(min(t - b, d - t), 0)\nstat = get(sort(values, rev=true), k, 0.0)\n\nSee also\n\nPersistenceCurve\nLandscapes\n\nReference\n\nBubenik, P. (2015). Statistical topological data analysis using persistence landscapes. The Journal of Machine Learning Research, 16(1), 77-102.\n\n\n\n\n\n","category":"function"},{"location":"vectorization/","page":"Vectorization","title":"Vectorization","text":"Silhuette","category":"page"},{"location":"vectorization/#PersistenceDiagrams.Silhuette","page":"Vectorization","title":"PersistenceDiagrams.Silhuette","text":"Silhuette\n\nThe sum of persistence landscapes for all values of k.\n\nfun((b, d), _, t) = max(min(t - b, d - t), 0)\nstat = sum\n\nSee also\n\nPersistenceCurve\nLandscape\nLandscapes\n\n\n\n\n\n","category":"function"},{"location":"distances/#Distances-and-Matchings","page":"Distances and Matchings","title":"Distances and Matchings","text":"","category":"section"},{"location":"distances/","page":"Distances and Matchings","title":"Distances and Matchings","text":"Bottleneck","category":"page"},{"location":"distances/#PersistenceDiagrams.Bottleneck","page":"Distances and Matchings","title":"PersistenceDiagrams.Bottleneck","text":"Bottleneck\n\nUse this object to find the bottleneck distance or matching between persistence diagrams. The distance value is equal to\n\nW_infty(X Y) = inf_etaXrightarrow Y sup_xin X x-eta(x)_infty\n\nwhere X and Y are the persistence diagrams and eta is a perfect matching between the intervals. Note the X and Y don't need to have the same number of points, as the diagonal points are considered in the matching as well.\n\nWarning\n\nComputing the bottleneck distance requires mathcalO(n^2) space. Be careful when computing distances between very large diagrams!\n\nUsage\n\nBottleneck()(left, right[; matching=false]): find the bottleneck matching (if matching=true) or distance (if matching=false) between persistence diagrams left and right\n\nExample\n\njulia> left = PersistenceDiagram([(1.0, 2.0), (5.0, 8.0)]);\n\njulia> right = PersistenceDiagram([(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)]);\n\njulia> Bottleneck()(left, right)\n2.0\n\njulia> Bottleneck()(left, right; matching=true)\nBottleneck Matching with weight 2.0:\n [5.0, 8.0) => [5.0, 10.0)\n\n\n\n\n\n\n","category":"type"},{"location":"distances/","page":"Distances and Matchings","title":"Distances and Matchings","text":"Wasserstein","category":"page"},{"location":"distances/#PersistenceDiagrams.Wasserstein","page":"Distances and Matchings","title":"PersistenceDiagrams.Wasserstein","text":"Wasserstein(q=1)\n\nUse this object to find the Wasserstein distance or matching between persistence diagrams. The distance value is equal to\n\nW_q(XY)=leftinf_etaXrightarrow Ysum_xin Xx-eta(x)_infty^qright\n\nwhere X and Y are the persistence diagrams and eta is a perfect matching between the intervals. Note the X and Y don't need to have the same number of points, as the diagonal points are considered in the matching as well.\n\nWarning\n\nComputing the Wasserstein distance requires mathcalO(n^2) space. Be careful when computing distances between very large diagrams!\n\nUsage\n\nWasserstein(q=1)(left, right[; matching=false]): find the Wasserstein matching (if matching=true) or distance (if matching=false) between persistence diagrams left and right.\n\nExample\n\njulia> left = PersistenceDiagram([(1.0, 2.0), (5.0, 8.0)]);\n\njulia> right = PersistenceDiagram([(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)]);\n\njulia> Wasserstein()(left, right)\n3.0\n\njulia> Wasserstein()(left, right; matching=true)\nMatching with weight 3.0:\n [1.0, 2.0) => [1.0, 2.0)\n [3.0, 3.0) => [3.0, 4.0)\n [5.0, 8.0) => [5.0, 10.0)\n\n\n\n\n\n\n","category":"type"},{"location":"distances/","page":"Distances and Matchings","title":"Distances and Matchings","text":"matching","category":"page"},{"location":"distances/#PersistenceDiagrams.matching","page":"Distances and Matchings","title":"PersistenceDiagrams.matching","text":"matching(::MatchingDistance, left, right)\nmatching(::Matching)\n\nGet the matching between persistence diagrams left and right.\n\nSee also\n\nweight\nBottleneck\nWasserstein\n\n\n\n\n\n","category":"function"},{"location":"distances/","page":"Distances and Matchings","title":"Distances and Matchings","text":"weight","category":"page"},{"location":"distances/#PersistenceDiagrams.weight","page":"Distances and Matchings","title":"PersistenceDiagrams.weight","text":"weight(::MatchingDistance, left, right)\nweight(::Matching)\n\nGet the weight of the matching between persistence diagrams left and right.\n\nSee also\n\nmatching\nBottleneck\nWasserstein\n\n\n\n\n\n","category":"function"},{"location":"basics/#Basics","page":"Basics","title":"Basics","text":"","category":"section"},{"location":"basics/","page":"Basics","title":"Basics","text":"PersistenceInterval","category":"page"},{"location":"basics/#PersistenceDiagrams.PersistenceInterval","page":"Basics","title":"PersistenceDiagrams.PersistenceInterval","text":"PersistenceInterval\n\nType for representing persistence intervals. It behaves exactly like a Tuple{Float64, Float64}, but can have meta data attached to it. The metadata is accessible with getproperty or the dot syntax.\n\nExample\n\njulia> interval = PersistenceInterval(1, Inf; meta1=:a, meta2=:b)\n[1.0, ∞) with:\n meta1: Symbol\n meta2: Symbol\n\njulia> birth(interval), death(interval), persistence(interval)\n(1.0, Inf, Inf)\n\njulia> isfinite(interval)\nfalse\n\njulia> propertynames(interval)\n(:birth, :death, :meta1, :meta2)\n\njulia> interval.meta1\n:a\n\n\n\n\n\n","category":"type"},{"location":"basics/","page":"Basics","title":"Basics","text":"birth","category":"page"},{"location":"basics/#PersistenceDiagrams.birth","page":"Basics","title":"PersistenceDiagrams.birth","text":"birth(interval)\n\nGet the birth time of interval.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"death","category":"page"},{"location":"basics/#PersistenceDiagrams.death","page":"Basics","title":"PersistenceDiagrams.death","text":"death(interval)\n\nGet the death time of interval.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"persistence","category":"page"},{"location":"basics/#PersistenceDiagrams.persistence","page":"Basics","title":"PersistenceDiagrams.persistence","text":"persistence(interval)\n\nGet the persistence of interval, which is equal to death - birth.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"midlife","category":"page"},{"location":"basics/#PersistenceDiagrams.midlife","page":"Basics","title":"PersistenceDiagrams.midlife","text":"midlife(interval)\n\nGet the midlife of the interval, which is equal to (birth + death) / 2.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"representative","category":"page"},{"location":"basics/#PersistenceDiagrams.representative","page":"Basics","title":"PersistenceDiagrams.representative","text":"representative(interval::PersistenceInterval)\n\nGet the representative (co)cycle attached to interval, if it has one.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"birth_simplex","category":"page"},{"location":"basics/#PersistenceDiagrams.birth_simplex","page":"Basics","title":"PersistenceDiagrams.birth_simplex","text":"birth_simplex(interval::PersistenceInterval)\n\nGet the critical birth simplex of interval, if it has one.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"death_simplex","category":"page"},{"location":"basics/#PersistenceDiagrams.death_simplex","page":"Basics","title":"PersistenceDiagrams.death_simplex","text":"death_simplex(interval::PersistenceInterval)\n\nGet the critical death simplex of interval, if it has one.\n\nnote: Note\nAn infinite interval's death simplex is nothing.\n\n\n\n\n\n","category":"function"},{"location":"basics/","page":"Basics","title":"Basics","text":"PersistenceDiagram","category":"page"},{"location":"basics/#PersistenceDiagrams.PersistenceDiagram","page":"Basics","title":"PersistenceDiagrams.PersistenceDiagram","text":"PersistenceDiagram <: AbstractVector{PersistenceInterval}\n\nType for representing persistence diagrams. Behaves exactly like a vector of PersistenceIntervals, but can have additional metadata attached to it. It supports pretty printing and plotting.\n\nCan be used as a table with any function that uses the Tables.jl interface. Note that using it as a table will only keep interval endpoints and the dim and threshold attributes.\n\nExample\n\njulia> diagram = PersistenceDiagram([(1, 3), (3, 4), (1, Inf)]; dim=1, custom_metadata=:a)\n3-element 1-dimensional PersistenceDiagram:\n [1.0, 3.0)\n [3.0, 4.0)\n [1.0, ∞)\n\njulia> diagram[1]\n[1.0, 3.0)\n\njulia> sort(diagram; by=persistence, rev=true)\n3-element 1-dimensional PersistenceDiagram:\n [1.0, ∞)\n [1.0, 3.0)\n [3.0, 4.0)\n\njulia> propertynames(diagram)\n(:intervals, :dim, :custom_metadata)\n\njulia> dim(diagram)\n1\n\njulia> diagram.custom_metadata\n:a\n\n\n\n\n\n","category":"type"},{"location":"basics/","page":"Basics","title":"Basics","text":"barcode(::Union{PersistenceDiagram, AbstractVector{<:PersistenceDiagram}})","category":"page"},{"location":"basics/#PersistenceDiagrams.barcode-Tuple{Union{PersistenceDiagram, AbstractVector{<:PersistenceDiagram}}}","page":"Basics","title":"PersistenceDiagrams.barcode","text":"barcode(diagram)\n\nPlot the barcode plot of persistence diagram or multiple diagrams in a collection. The infinity keyword argument determines where the infinity line is placed. If unset, the function tries to use threshold(diagram), or guess a good position to place the line at.\n\n\n\n\n\n","category":"method"},{"location":"#PersistenceDiagrams.jl","page":"Home","title":"PersistenceDiagrams.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package provides the PersistenceInterval and PersistenceDiagram types as well as some functions for working with them. If you want to compute persistence diagrams, please see Ripserer.jl. For examples and tutorials, see the Ripserer.jl docs.","category":"page"},{"location":"#Overview","page":"Home","title":"Overview","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package currently supports the following:","category":"page"},{"location":"","page":"Home","title":"Home","text":"persistence diagram plotting\nbottleneck and Wasserstein matching and distance computation\nvarious vectorization methods including persistence images, betti curves, landscapes, and more (see Vectorization for full list)\nintegration with MLJ.jl.","category":"page"}]
}
