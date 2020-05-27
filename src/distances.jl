# Tried to approximate the approach from
# https://mrzv.org/publications/geometry-helps-distances-persistence-diagrams/alenex/ and
# https://www2.cs.arizona.edu/~alon/papers/match.pdf with NearestNeighbors.jl but the
# allocations were so high, it was slower for moderately sized inputs. This approach is also
# much much simpler.
# TODO: try it again some time.

"""
    Matching

A matching between two persistence diagrams.

# Methods

* [`distance(::Matching)`](@ref)
* [`matching(::Matching)`](@ref)
"""
struct Matching{T, L, R}
    left::L
    right::R
    weight::T
    matching::Vector{Pair{Int, Int}}
    bottleneck::Bool
end

"""
    distance(::Matching)

Get the weight of a `Matching` object.
"""
distance(match::Matching) = match.weight

Base.length(match::Matching) = length(match.matching)
Base.isempty(match::Matching) = isempty(match.matching)

function distance(int1, int2)
    if isfinite(int1) && isfinite(int2)
        return max(abs(birth(int1) - birth(int2)), abs(death(int1) - death(int2)))
    elseif isfinite(int1) && isfinite(int2)
        return abs(birth(int1) - birth(int2))
    else
        return promote_type(eltype(int1), eltype(int2))(Inf)
    end
end

"""
    matching(m::Matching; bottleneck=m.bottleneck)

Get the matching of a `Matching` object represented by a vector of pairs of intervals. If
`bottleneck` is set to true, only return the edges with length equal to the weight of the
matching.
"""
function matching(match::Matching{T}; bottleneck=match.bottleneck) where T
    L = eltype(match.left)
    R = eltype(match.right)

    result = Pair{L, R}[]
    n = length(match.left)
    m = length(match.right)
    for (i, j) in match.matching
        if i ≤ n && j ≤ m
            push!(result, match.left[i] => match.right[j])
        elseif i ≤ n
            # left is matched to diagonal
            l = match.left[i]
            push!(result, match.left[i] => R(birth(l), birth(l)))
        elseif j ≤ m
            # right is matched to diagonal
            r = match.right[j]
            push!(result, L(birth(r), birth(r)) => r)
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

"""
    adj_matrix(left::PersistenceDiagram, right::PersistenceDiagram, power)

Get the adjacency matrix of the matching between `left` and `right`. Edge weights are equal
to distances between intervals raised to the power of `power`. Distances between diagonal
points and values that should not be matched with them are set to `typemax(T)`. The same
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
    function _to_matrix(diag, T)
        pts = Tuple{T, T}[T.((birth(i), death(i))) for i in diag if isfinite(i)]
        return reshape(reinterpret(T, pts), (2, length(pts)))
    end
    sort!(left, by=death)
    sort!(right, by=death)

    # float to handle inf correctly.
    T = promote_type(dist_type(left), dist_type(right), typeof(power))
    P = PersistenceInterval{T, Nothing}

    n = length(left)
    m = length(right)
    adj = fill(typemax(T), n + m, m + n)

    dists = pairwise(Chebyshev(), _to_matrix(right, T), _to_matrix(left, T), dims=2)
    adj[axes(dists)...] .= dists
    for i in size(dists, 2)+1:n, j in size(dists, 1)+1:m
        adj[j, i] = abs(birth(left[i]) - birth(right[j]))
    end
    for i in 1:n
        adj[i + m, i] = T(persistence(left[i]))
    end
    for j in 1:m
        adj[j, j + n] = T(persistence(right[j]))
    end
    adj[m + 1:m + n, n + 1:n + m] .= zero(T)

    if power ≠ 1
        return adj.^power
    else
        return adj
    end
end

"""
    BottleneckGraph{T}

Representation of the bipartite graph used for computing bottleneck distance via the
Hopcroft-Karp algorithm. In all the following functions, `left` and `right` refer to the
vertex sets of the graph. The graph has `n + m` vertices in each set corresponding to the
numbers of points in the diagrams plus the diagonals.

# Fields

* `adj::Matrix{T}`: the adjacency matrix.
* `match_left::Vector{Int}`: matches of left vertices.
* `match_right::Vector{Int}`: matches of right vertices.
* `edges::Vector{T}`: edge lengths, unique and sorted.
* `n::Int`: number of intervals in left diagram.
* `m::Int`: number of intervals in right diagram.
"""
struct BottleneckGraph{T}
    adj::Matrix{T}

    match_left::Vector{Int}
    match_right::Vector{Int}

    edges::Vector{T}

    n_vertices::Int
end

function BottleneckGraph(left::PersistenceDiagram, right::PersistenceDiagram)
    n = length(left)
    m = length(right)
    adj = adj_matrix(left, right)
    T = eltype(adj)

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

is_exposed_left(graph::BottleneckGraph, l) = graph.match_left[l] == 0
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

Computing the bottleneck distance requires ``\\mathcal{O}(n^2)`` space!

# Methods

* [`matching(::Bottleneck, ::Any, ::Any)`](@ref): construct a bottleneck [`Matching`](@ref).
* [`distance(::Bottleneck, ::Any, ::Any)`](@ref): find the bottleneck distance.
"""
struct Bottleneck end

"""
    matching(::Bottleneck, left, right)

Find the bottleneck matching between persistence diagrams `left` and `right`. Infinite
intervals are matched to eachother.

```jldoctest
left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
matching(Bottleneck(), left, right)

# Example

# output

3-element Matching with weight 2.0:
 [1.0, 2.0) => [1.0, 2.0)
 [3.0, 3.0) => [3.0, 4.0)
 [5.0, 8.0) => [5.0, 10.0)
```

# See also

* [`Bottleneck`](@ref)
* [`distance`](@ref)
"""
function matching(::Bottleneck, left, right)
    if count(!isfinite, left) ≠ count(!isfinite, right)
        return Matching(left, right, Inf, Pair{Int, Int}[], true)
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
    T = promote_type(dist_type(left), dist_type(right))
    return Matching(left, right, T(distance), match, true)
end

"""
    distance(::Bottleneck, left, right)

Compute the bottleneck distance between persistence diagrams `left` and `right`. Infinite
intervals are matched to eachother.

# Example

```jldoctest
left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
distance(Bottleneck(), left, right)

# output

2.0
```

# See also

* [`Bottleneck`](@ref)
* [`matching`](@ref)
"""
distance(::Bottleneck, left, right) = matching(Bottleneck(), left, right).weight

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

Computing the Wasserstein distance requires ``\\mathcal{O}(n^2)`` space!

# Methods

* [`matching(::Wasserstein, ::Any, ::Any)`](@ref): construct a Wasserstein
  [`Matching`](@ref).
* [`distance(::Wasserstein, ::Any, ::Any)`](@ref): find the Wasserstein distance.
"""
struct Wasserstein
    q::Float64

    Wasserstein(q=1) = new(float(q))
end

"""
    matching(::Wasserstein, left, right)

Find the Wasserstein matching between persistence diagrams `left` and `right`. Infinite
intervals are matched to eachother.

# Example

```jldoctest
left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
matching(Wasserstein(), left, right)

# output

3-element Matching with weight 3.0:
 [1.0, 2.0) => [1.0, 2.0)
 [3.0, 3.0) => [3.0, 4.0)
 [5.0, 8.0) => [5.0, 10.0)
```

# See also

* [`Wasserstein`](@ref)
* [`distance`](@ref)
"""
function matching(w::Wasserstein, left, right)
    if count(!isfinite, left) == count(!isfinite, right)
        adj = adj_matrix(right, left, w.q)
        match = collect(i => j for (i, j) in enumerate(hungarian(adj)[1]))
        distance = sum(adj[i, j] for (i, j) in match)^(1 / w.q)

        return Matching(left, right, distance, match, false)
    else
        T = promote_type(dist_type(left), dist_type(right))
        return Matching(left, right, T(Inf), Pair{Int, Int}[], false)
    end
end

"""
    distance(::Wasserstein, left, right)

Compute the Wasserstein distance between persistence diagrams `left` and `right`. Infinite
intervals are matched to eachother.

# Example

```jldoctest
left = PersistenceDiagram(0, [(1.0, 2.0), (5.0, 8.0)])
right = PersistenceDiagram(0, [(1.0, 2.0), (3.0, 4.0), (5.0, 10.0)])
distance(Wasserstein(), left, right)

# output

3.0
```

# See also

* [`Wasserstein`](@ref)
* [`matching`](@ref)
"""
distance(w::Wasserstein, left, right) = matching(w, left, right).weight
