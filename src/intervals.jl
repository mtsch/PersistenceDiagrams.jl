"""
    PersistenceInterval

Type for representing persistence intervals. It behaves exactly like a `Tuple{Float64,
Float64}`, but can have meta data attached to it. The metadata is accessible with
`getproperty` or the dot syntax.

# Example

```jldoctest
julia> interval = PersistenceInterval(1, Inf; meta1=:a, meta2=:b)
[1.0, ∞) with:
 meta1: Symbol
 meta2: Symbol

julia> birth(interval), death(interval), persistence(interval)
(1.0, Inf, Inf)

julia> isfinite(interval)
false

julia> propertynames(interval)
(:birth, :death, :meta1, :meta2)

julia> interval.meta1
:a
```
"""
struct PersistenceInterval
    birth::Float64
    death::Float64
    meta::NamedTuple
end
function PersistenceInterval(birth, death; kwargs...)
    meta = (; kwargs...)
    return PersistenceInterval(Float64(birth), Float64(death), meta)
end
function PersistenceInterval(t::Tuple{<:Any,<:Any}; kwargs...)
    meta = (; kwargs...)
    return PersistenceInterval(Float64(t[1]), Float64(t[2]), meta)
end
function PersistenceInterval(int::PersistenceInterval; kwargs...)
    meta = (; kwargs...)
    return PersistenceInterval(Float64(int[1]), Float64(int[2]), meta)
end

"""
    birth(interval)

Get the birth time of `interval`.
"""
birth(int::PersistenceInterval) = getfield(int, 1)
"""
    death(interval)

Get the death time of `interval`.
"""
death(int::PersistenceInterval) = getfield(int, 2)
"""
    persistence(interval)

Get the persistence of `interval`, which is equal to `death - birth`.
"""
persistence(int::PersistenceInterval) = death(int) - birth(int)

"""
    midlife(interval)

Get the midlife of the `interval`, which is equal to `(birth + death) / 2`.
"""
midlife(int::PersistenceInterval) = (birth(int) + death(int)) / 2

Base.isfinite(int::PersistenceInterval) = isfinite(death(int))

###
### Iteration
###
function Base.iterate(int::PersistenceInterval, i=1)
    if i == 1
        return birth(int), i + 1
    elseif i == 2
        return death(int), i + 1
    else
        return nothing
    end
end

Base.length(::PersistenceInterval) = 2
Base.IteratorSize(::Type{<:PersistenceInterval}) = Base.HasLength()
Base.IteratorEltype(::Type{<:PersistenceInterval}) = Base.HasEltype()
Base.eltype(::Type{<:PersistenceInterval}) = Float64

function Base.getindex(int::PersistenceInterval, i)
    if i == 1
        return birth(int)
    elseif i == 2
        return death(int)
    else
        throw(BoundsError(int, i))
    end
end

Base.firstindex(int::PersistenceInterval) = 1
Base.lastindex(int::PersistenceInterval) = 2

###
### Equality and ordering
###
function Base.:(==)(int1::PersistenceInterval, int2::PersistenceInterval)
    return birth(int1) == birth(int2) && death(int1) == death(int2)
end
Base.:(==)(int::PersistenceInterval, (b, d)::Tuple) = birth(int) == b && death(int) == d
Base.:(==)((b, d)::Tuple, int::PersistenceInterval) = birth(int) == b && death(int) == d

function Base.isless(int1::PersistenceInterval, int2::PersistenceInterval)
    return (birth(int1), death(int1)) < (birth(int2), death(int2))
end

###
### Printing
###
function Base.show(io::IO, int::PersistenceInterval)
    b = round(birth(int); sigdigits=3)
    d = isfinite(death(int)) ? round(death(int); sigdigits=3) : "∞"
    return print(io, "[$b, $d)")
end

function Base.show(io::IO, ::MIME"text/plain", int::PersistenceInterval)
    b = round(birth(int); sigdigits=3)
    d = isfinite(death(int)) ? round(death(int); sigdigits=3) : "∞"
    print(io, "[$b, $d)")
    if !isempty(int.meta)
        print(io, " with:")
        for (k, v) in zip(keys(int.meta), int.meta)
            print(io, "\n ", k, ": ", summary(v))
        end
    end
end

###
### Metadata
###
function Base.getproperty(int::PersistenceInterval, key::Symbol)
    if hasfield(typeof(int), key)
        return getfield(int, key)
    elseif haskey(int.meta, key)
        return int.meta[key]
    else
        error("interval $int has no $key")
    end
end
function Base.propertynames(int::PersistenceInterval, private::Bool=false)
    if private
        return tuple(:birth, :death, propertynames(int.meta)..., :meta)
    else
        return (:birth, :death, propertynames(int.meta)...)
    end
end

"""
    representative(interval::PersistenceInterval)

Get the representative (co)cycle attached to `interval`, if it has one.
"""
representative(int::PersistenceInterval) = int.representative

"""
    birth_simplex(interval::PersistenceInterval)

Get the critical birth simplex of `interval`, if it has one.
"""
birth_simplex(int::PersistenceInterval) = int.birth_simplex

"""
    death_simplex(interval::PersistenceInterval)

Get the critical death simplex of `interval`, if it has one.

!!! note
    An infinite interval's death simplex is `nothing`.
"""
death_simplex(int::PersistenceInterval) = int.death_simplex
