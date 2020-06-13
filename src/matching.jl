# Tried to approximate the approach from
# https://mrzv.org/publications/geometry-helps-distances-persistence-diagrams/alenex/ and
# https://www2.cs.arizona.edu/~alon/papers/match.pdf with NearestNeighbors.jl but the
# allocations were so high, it was slower for moderately sized inputs. This approach is also
# much much simpler.
# TODO: try it again some time.

abstract type MatchingDistance end

"""
    weight(::MatchingDistance, left, right)
    weight(::Matching)

Get the weight of the matching between persistence diagrams `left` and `right`.

# See also

* [`matching`](@ref)
* [`Bottleneck`](@ref)
* [`Wasserstein`](@ref)
"""
weight(dist::MatchingDistance, left, right) = dist(left, right, matching=false)
"""
    matching(::MatchingDistance, left, right)
    matching(::Matching)

Get the matching between persistence diagrams `left` and `right`.

# See also

* [`matching`](@ref)
* [`Bottleneck`](@ref)
* [`Wasserstein`](@ref)
"""
matching(dist::MatchingDistance, left, right) = dist(left, right, matching=true)

"""
    Matching

A matching between two persistence diagrams.

# Methods

* [`weight(::Matching)`](@ref)
* [`matching(::Matching)`](@ref)
"""
struct Matching
    left::PersistenceDiagram{PersistenceInterval{Nothing}}
    right::PersistenceDiagram{PersistenceInterval{Nothing}}
    weight::Float64
    matching::Vector{Pair{Int, Int}}
    bottleneck::Bool

    function Matching(left, right, weight, matching, bottleneck)
        new(stripped(left), stripped(right), weight, matching, bottleneck)
    end
end


weight(match::Matching) = match.weight

Base.length(match::Matching) = length(match.matching)
Base.isempty(match::Matching) = isempty(match.matching)

function distance(int1, int2)
    if isfinite(int1) && isfinite(int2)
        return max(abs(birth(int1) - birth(int2)), abs(death(int1) - death(int2)))
    elseif isfinite(int1) && isfinite(int2)
        return abs(birth(int1) - birth(int2))
    else
        return Inf
    end
end

function matching(match::Matching; bottleneck=match.bottleneck)
    P = PersistenceInterval{Nothing}
    result = Pair{P, P}[]
    n = length(match.left)
    m = length(match.right)
    for (i, j) in match.matching
        if i ≤ n && j ≤ m
            push!(result, match.left[i] => match.right[j])
        elseif i ≤ n
            # left is matched to diagonal
            l = match.left[i]
            push!(result, match.left[i] => P(birth(l), birth(l)))
        elseif j ≤ m
            # right is matched to diagonal
            r = match.right[j]
            push!(result, P(birth(r), birth(r)) => r)
        end
    end
    sort!(result)

    if !bottleneck
        return result
    else
        return filter!(m -> distance(m...) == match.weight, result)
    end
end

function Base.show(io::IO, match::Matching)
    b = match.bottleneck ? "bottleneck " : ""
    print(io, "$(length(match))-element $(b)Matching with weight $(match.weight)")
end
function Base.show(io::IO, ::MIME"text/plain", match::Matching)
    print(io, match)
    if length(match) > 0
        print(io, ":")
        show_intervals(io, matching(match))
    end
end

"convert n-element diagram to 2×n matrix"
function _to_matrix(diag)
    pts = Tuple{Float64, Float64}[(birth(i), death(i)) for i in diag if isfinite(i)]
    return reshape(reinterpret(Float64, pts), (2, length(pts)))
end

"""
    adj_matrix(left::PersistenceDiagram, right::PersistenceDiagram, power)

Get the adjacency matrix of the matching between `left` and `right`. Edge weights are equal
to distances between intervals raised to the power of `power`. Distances between diagonal
points and values that should not be matched with them are set to `Inf`. The same
holds for distances between finite and infinite intervals.

For `length(left) == n` and `length(right) == m`, it returns a ``(n m) × (m n)`` matrix.

# Example

```jldoctest
left = PersistenceDiagram(0, [(0.0, 1.0), (3.0, 4.5)])
right = PersistenceDiagram(0, [(0.0, 1.0), (4.0, 5.0), (4.0, 7.0)])

adj_matrix(left, right)

# output

5×5 Array{Float64,2}:
  0.0   3.5   1.0  Inf   Inf
  4.0   1.0  Inf    1.0  Inf
  6.0   2.5  Inf   Inf    3.0
  1.0  Inf    0.0   0.0   0.0
 Inf    1.5   0.0   0.0   0.0
```
"""
function adj_matrix(left, right, power=1)
    sort!(left, by=death)
    sort!(right, by=death)

    n = length(left)
    m = length(right)
    adj = fill(Inf, n + m, m + n)

    dists = pairwise(Chebyshev(), _to_matrix(right), _to_matrix(left), dims=2)
    adj[axes(dists)...] .= dists
    for i in size(dists, 2)+1:n, j in size(dists, 1)+1:m
        adj[j, i] = abs(birth(left[i]) - birth(right[j]))
    end
    for i in 1:n
        adj[i + m, i] = persistence(left[i])
    end
    for j in 1:m
        adj[j, j + n] = persistence(right[j])
    end
    adj[m + 1:m + n, n + 1:n + m] .= 0.0

    if power ≠ 1
        return adj.^power
    else
        return adj
    end
end

"""
    BottleneckGraph

Representation of the bipartite graph used for computing bottleneck distance via the
Hopcroft-Karp algorithm. In all the following functions, `left` and `right` refer to the
vertex sets of the graph. The graph has `n + m` vertices in each set corresponding to the
numbers of points in the diagrams plus the diagonals.

# Fields

* `adj::Matrix{Float64}`: the adjacency matrix.
* `match_left::Vector{Int}`: matches of left vertices.
* `match_right::Vector{Int}`: matches of right vertices.
* `edges::Vector{Float64}`: edge lengths, unique and sorted.
* `n::Int`: number of intervals in left diagram.
* `m::Int`: number of intervals in right diagram.
"""
struct BottleneckGraph
    adj::Matrix{Float64}

    match_left::Vector{Int}
    match_right::Vector{Int}

    edges::Vector{Float64}

    n_vertices::Int
end

function BottleneckGraph(left::PersistenceDiagram, right::PersistenceDiagram)
    n = length(left)
    m = length(right)
    adj = adj_matrix(left, right)

    edges = filter!(isfinite, sort!(unique!(copy(vec(adj)))))

    return BottleneckGraph(adj, fill(0, n + m), fill(0, m + n), edges, n + m)
end

function left_neighbors!(buff, graph::BottleneckGraph, vertices, ε, pred)
    empty!(buff)
    for l in vertices
        for r in axes(graph.adj, 1)
            graph.adj[r, l] ≤ ε && pred(r) && push!(buff, r)
        end
    end
    return unique!(buff)
end

function right_neighbors!(buff, graph::BottleneckGraph, vertices)
    empty!(buff)
    for r in vertices
        push!(buff, graph.match_right[r])
    end
    return buff
end

is_exposed_right(graph::BottleneckGraph, r) = graph.match_right[r] == 0
exposed_left(graph::BottleneckGraph) = findall(iszero, graph.match_left)

"""
    depths(graph::BottleneckGraph, ε)

Split `graph` into layers by how deep they are from a bfs starting at exposed left
vertices in `graph` only taking into account edges of length smaller than or equal to `ε`.
Return depts of right vertices and maximum depth reached.
"""
function depth_layers(graph::BottleneckGraph, ε)
    depths = fill(0, graph.n_vertices)
    visited = fill(false, graph.n_vertices)
    lefts = exposed_left(graph)
    rights = Int[]
    i = 1
    while true
        left_neighbors!(rights, graph, lefts, ε, r -> !visited[r])
        visited[rights] .= true
        depths[rights] .= i
        if isempty(rights)
            # no augmenting path exists
            return nothing, nothing
        elseif any(r -> is_exposed_right(graph, r), rights)
            return depths, i
        else
            right_neighbors!(lefts, graph, rights)
        end
        i += 1
    end
end

"""
    augmenting_paths(graph::BottleneckGraph, ε)

find a maximal set of augmenting paths in graph, taking only edges with weight less than or
equal to `ε` into account.
"""
function augmenting_paths(graph::BottleneckGraph, ε)
    depths, max_depth = depth_layers(graph, ε)
    paths = Vector{Int}[]
    isnothing(depths) && return paths

    prev = fill(0, graph.n_vertices)
    rights = Int[]
    lefts = Int[]
    stack = Tuple{Int, Int}[]

    for l_start in exposed_left(graph)
        empty!(stack)
        push!(stack, (l_start, 1))
        prev .= 0

        while !isempty(stack)
            l, i = pop!(stack)
            parent = graph.match_left[l]
            left_neighbors!(rights, graph, l, ε, r -> depths[r] == i)
            if i < max_depth
                prev[rights] .= l
                right_neighbors!(lefts, graph, rights)
                append!(stack, (l, i + 1) for l in lefts)
            else
                found_path = false
                for r in rights
                    if is_exposed_right(graph, r)
                        prev[r] = l
                        path = Int[r]
                        depths[r] = 0

                        while (l = prev[r]) ≠ l_start
                            @assert prev[r] ≠ 0
                            r = graph.match_left[l]
                            depths[r] = 0
                            append!(path, (l, r))
                        end
                        push!(path, l_start)
                        reverse!(path)
                        push!(paths, path)
                        found_path = true
                        break
                    end
                end
                found_path && break
            end
        end
    end

    return paths
end

function unmatch_all!(graph::BottleneckGraph)
    graph.match_left .= 0
    graph.match_right .= 0
    return (0, 0)
end

function augment!(graph, p)
    for i in 1:2:length(p) - 1
        l, r = p[i], p[i + 1]
        graph.match_left[l] = r
        graph.match_right[r] = l
    end
end

function hopcroft_karp!(graph, ε)
    unmatch_all!(graph)
    paths = augmenting_paths(graph, ε)
    while !isempty(paths)
        for p in paths
            augment!(graph, p)
        end
        paths = augmenting_paths(graph, ε)
    end
    matching = [i => graph.match_left[i]
                for i in 1:graph.n_vertices if graph.match_left[i] ≠ 0]
    is_perfect = length(matching) == graph.n_vertices

    return matching, is_perfect
end

"""
    Bottleneck

Use this object to find the bottleneck distance or matching between persistence diagrams.
The distance value is equal to

```math
W_\\infty(X, Y) = \\inf_{\\eta:X\\rightarrow Y} \\sup_{x\\in X} ||x-\\eta(x)||_\\infty,
```

where ``X`` and ``Y`` are the persistence diagrams and ``\\eta`` is a perfect matching
between the intervals. Note the ``X`` and ``Y`` don't need to have the same number of
points, as the diagonal points are considered in the matching as well.

# Warning

Computing the bottleneck distance requires ``\\mathcal{O}(n^2)`` space. Be careful when
computing distances between very large diagrams!

# Usage

* `Bottleneck()(left, right[; matching=false])`: find the bottleneck matching (if
  `matching=true`) or distance (if `matching=false`) between persistence diagrams `left` and
  `right`

# Example

left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
Bottleneck()(left, right)

# output

2.0
```
"""
struct Bottleneck <: MatchingDistance end

function (::Bottleneck)(left, right; matching=false)
    if count(!isfinite, left) ≠ count(!isfinite, right)
        if matching
            return Matching(left, right, Inf, Pair{Int, Int}[], true)
        else
            return Inf
        end
    end

    graph = BottleneckGraph(left, right)
    edges = graph.edges

    lo = 1
    hi = length(edges)
    while lo < hi - 1
        m = lo + ((hi - lo) >>> 0x01)
        _, succ = hopcroft_karp!(graph, edges[m])
        if succ
            hi = m
        else
            lo = m
        end
    end
    match, succ = hopcroft_karp!(graph, edges[lo])
    distance = edges[lo]
    if !succ
        distance = edges[hi]
        match, _ = hopcroft_karp!(graph, edges[hi])
    end
    @assert length(match) == length(left) + length(right)
    if matching
        return Matching(left, right, distance, match, true)
    else
        return distance
    end
end

"""
    Wasserstein(q=1)

Use this object to find the Wasserstein distance or matching between persistence diagrams.
The distance value is equal to

```math
W_q(X,Y)=\\left[\\inf_{\\eta:X\\rightarrow Y}\\sum_{x\\in X}||x-\\eta(x)||_\\infty^q\\right],
```

where ``X`` and ``Y`` are the persistence diagrams and ``\\eta`` is a perfect matching
between the intervals. Note the ``X`` and ``Y`` don't need to have the same number of
points, as the diagonal points are considered in the matching as well.

# Warning

Computing the Wasserstein distance requires ``\\mathcal{O}(n^2)`` space. Be careful when
computing distances between very large diagrams!

# Usage

* `Wasserstein(q=1)(left, right[; matching=false])`: find the Wasserstein matching (if
  `matching=true`) or distance (if `matching=false`) between persistence diagrams `left` and
  `right`.

# Example

```jldoctest
left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
Wasserstein()(left, right)

# output

3.0
```
"""
struct Wasserstein <: MatchingDistance
    q::Float64

    Wasserstein(q=1) = new(Float64(q))
end

function (w::Wasserstein)(left, right; matching=false)
    if count(!isfinite, left) == count(!isfinite, right)
        adj = adj_matrix(right, left, w.q)
        match = collect(i => j for (i, j) in enumerate(hungarian(adj)[1]))
        distance = sum(adj[i, j] for (i, j) in match)^(1 / w.q)

        if matching
            return Matching(left, right, distance, match, false)
        else
            return distance
        end
    else
        if matching
            return Matching(left, right, Inf, Pair{Int, Int}[], false)
        else
            return Inf
        end
    end
end
