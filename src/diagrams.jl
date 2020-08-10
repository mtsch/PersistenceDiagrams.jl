"""
    PersistenceDiagram{P<:PersistenceInterval} <: AbstractVector{P}

Type for representing persistence diagrams. Behaves exactly like an array of
`PersistenceInterval`s, but is can have metadata attached to it and supports pretty printing
and plotting.

# Example

```jldoctest
julia> diag = PersistenceDiagram(
    [(1, 3), (3, 4), (1, Inf)], [(;a=1), (;a=2), (;a=3)], dim=1, meta1=:a
)
3-element 1-dimensional PersistenceDiagram:
 [1.0, 3.0)
 [3.0, 4.0)
 [1.0, ∞)

julia> diag[1]
[1.0, 3.0) with:
  a: Int64

julia> diag[1].a
[1.0, 3.0) with:
  1

julia> sort(diag, by=persistence, rev=true)
3-element 1-dimensional PersistenceDiagram:
 [1.0, ∞)
 [1.0, 3.0)
 [3.0, 4.0)

julia> propertynames(diag)
(:dim, :meta1)

julia> dim(diag)
1

julia> diag.meta1
:a
```
"""
struct PersistenceDiagram{P<:PersistenceInterval, M<:NamedTuple} <: AbstractVector{P}
    intervals::Vector{P}
    meta::M
end

function PersistenceDiagram(intervals::Vector{<:PersistenceInterval}; kwargs...)
    meta = (;kwargs...)
    return PersistenceDiagram(intervals, meta)
end
function PersistenceDiagram(intervals::AbstractVector{<:PersistenceInterval}; kwargs...)
    return PersistenceDiagram(collect(intervals); kwargs...)
end
function PersistenceDiagram(
    pairs::AbstractVector{<:Tuple}, metas=Iterators.cycle((NamedTuple(),)); kwargs...
)
    intervals = map(pairs, metas) do t, m
        PersistenceInterval(t; m...)
    end
    return PersistenceDiagram(intervals; kwargs...)
end

###
### Printing
###
function show_intervals(io::IO, diag)
    limit = get(io, :limit, false) ? first(displaysize(io)) : typemax(Int)
    if length(diag) + 1 < limit
        for i in eachindex(diag)
            if isassigned(diag, i)
                print(io, "\n ", diag[i])
            else
                print(io, "\n #undef")
            end
        end
    else
        for i in 1:limit÷2-2
            if isassigned(diag, i)
                print(io, "\n ", diag[i])
            else
                print(io, "\n #undef")
            end
        end
        print(io, "\n ⋮")
        for i in lastindex(diag)-limit÷2+3:lastindex(diag)
            if isassigned(diag, i)
                print(io, "\n ", diag[i])
            else
                print(io, "\n #undef")
            end
        end
    end
end
function Base.show(io::IO, diag::PersistenceDiagram)
    if haskey(diag.meta, :dim)
        print(io, length(diag), "-element ", dim(diag), "-dimensional PersistenceDiagram")
    else
        print(io, length(diag), "-element PersistenceDiagram")
    end
end
function Base.show(io::IO, ::MIME"text/plain", diag::PersistenceDiagram)
    print(io, diag)
    if length(diag) > 0
        print(io, ":")
        show_intervals(io, diag.intervals)
    end
end

###
### Array interface
###
Base.size(diag::PersistenceDiagram) = size(diag.intervals)
Base.getindex(diag::PersistenceDiagram, i::Integer) = diag.intervals[i]
Base.setindex!(diag::PersistenceDiagram, x, i::Integer) = diag.intervals[i] = x
Base.firstindex(diag::PersistenceDiagram) = 1
Base.lastindex(diag::PersistenceDiagram) = length(diag.intervals)

function Base.similar(diag::PersistenceDiagram)
    return PersistenceDiagram(similar(diag.intervals); diag.meta...)
end
function Base.similar(diag::PersistenceDiagram, dims::Tuple)
    return PersistenceDiagram(similar(diag.intervals, dims); diag.meta...)
end

###
### Meta
###
function Base.getproperty(diag::PersistenceDiagram, key::Symbol)
    if hasfield(typeof(diag), key)
        return getfield(diag, key)
    elseif haskey(diag.meta, key)
        return diag.meta[key]
    else
        error("$diag has no $key")
    end
end
function Base.propertynames(diag::PersistenceDiagram, private=false)
    if private
        return tuple(propertynames(diag.meta)..., fieldnames(typeof(diag))...)
    else
        return propertynames(diag.meta)
    end
end

"""
    threshold(diagram::PersistenceDiagram)

Get the threshold of persistence diagram. Equivalent to `diagram.threshold`.
"""
threshold(diag::PersistenceDiagram) = diag.threshold

"""
    dim(diagram::PersistenceDiagram)

Get the dimension of persistence diagram. Equivalent to `diagram.dim`.
"""
dim(diag::PersistenceDiagram) = diag.dim
