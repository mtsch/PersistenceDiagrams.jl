# interval =============================================================================== #
"""
    PersistenceInterval{T<:AbstractFloat, C}

The type that represents a persistence interval. It behaves exactly like a
`Tuple{T, T}`, but may have a representative cocycle attached to it.
"""
struct PersistenceInterval{T<:AbstractFloat, R}
    birth          ::T
    death          ::T
    representative ::R

    function PersistenceInterval{T, R}(birth, death, rep::R=nothing) where {T, R}
        return new{T, R}(T(birth), T(death), rep)
    end
    function PersistenceInterval{T, R}((birth, death), rep::R=nothing) where {T, R}
        return new{T, R}(T(birth), T(death), rep)
    end
end

function PersistenceInterval(birth, death, rep::R=nothing) where R
    T = float(promote_type(typeof(birth), typeof(death)))
    return PersistenceInterval{T, R}(birth, death, rep)
end
function PersistenceInterval(t::Tuple{<:Any, <:Any}, rep=nothing)
    return PersistenceInterval(t..., rep)
end
function Base.convert(::Type{P}, tp::Tuple{<:Any, <:Any}) where P<:PersistenceInterval
    return P(tp)
end

function Base.show(io::IO, int::PersistenceInterval)
    b = round(birth(int), sigdigits=3)
    d = isfinite(death(int)) ? round(death(int), sigdigits=3) : "∞"
    print(io, "[$b, $d)")
end
function Base.show(io::IO, ::MIME"text/plain", int::PersistenceInterval{T}) where T
    print(io, "PersistenceInterval{", T, "}", (birth(int), death(int)))
    if !isnothing(int.representative)
        println(io, " with representative:")
        show(io, MIME"text/plain"(), representative(int))
    end
end

"""
    birth(interval::PersistenceInterval)

Get the birth time of `interval`.
"""
birth(int::PersistenceInterval) = int.birth

"""
    death(interval::PersistenceInterval)

Get the death time of `interval`.
"""
death(int::PersistenceInterval) = int.death

"""
    death(interval::PersistenceInterval)

Get the persistence of `interval`, which is equal to `death - birth`.
"""
persistence(int::PersistenceInterval) = death(int) - birth(int)

Base.isfinite(int::PersistenceInterval) = isfinite(death(int))

"""
    representative(interval::PersistenceInterval)

Get the representative cocycle attached to `interval`. If representatives were not computed,
throw an error.
"""
function representative(int::PersistenceInterval)
    if !isnothing(int.representative)
        return int.representative
    else
        error("$int has no representative. Run ripserer with `representatives=true`")
    end
end

function Base.iterate(int::PersistenceInterval, i=1)
    if i == 1
        return birth(int), i+1
    elseif i == 2
        return death(int), i+1
    else
        return nothing
    end
end

Base.length(::PersistenceInterval) = 2
Base.IteratorSize(::Type{<:PersistenceInterval}) = Base.HasLength()
Base.IteratorEltype(::Type{<:PersistenceInterval}) = Base.HasEltype()
Base.eltype(::Type{<:PersistenceInterval{T}}) where T = T

dist_type(::Type{<:PersistenceInterval{T}}) where T = T
dist_type(::PersistenceInterval{T}) where T = T

function Base.getindex(int, i)
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

Base.:(==)(int::PersistenceInterval, (b, d)::Tuple) = birth(int) == b && death(int) == d

function Base.isless(int1::PersistenceInterval, int2::PersistenceInterval)
    if birth(int1) ≠ birth(int2)
        return isless(birth(int1), birth(int2))
    else
        return isless(death(int1), death(int2))
    end
end

# diagram ================================================================================ #
"""
    PersistenceDiagram{P<:PersistenceInterval} <: AbstractVector{P}

Type for representing persistence diagrams. Behaves exactly like an array of
`PersistenceInterval`s, but is aware of its dimension and supports pretty printing and
plotting.
"""
struct PersistenceDiagram{T, P<:PersistenceInterval{T}} <: AbstractVector{P}
    dim       ::Int
    intervals ::Vector{P}
    threshold ::T

    function PersistenceDiagram(
        dim, intervals::Vector{P}, threshold
    ) where P<:PersistenceInterval
        T = eltype(P)
        return new{T, P}(dim, intervals, T(threshold))
    end
end

function PersistenceDiagram(dim, intervals; threshold=Inf)
    return PersistenceDiagram(dim, intervals, threshold)
end
function PersistenceDiagram(dim, intervals::AbstractVector{<:Tuple}; threshold=Inf)
    return PersistenceDiagram(dim, PersistenceInterval.(intervals), threshold)
end

function show_intervals(io::IO, pd)
    limit = get(io, :limit, false) ? first(displaysize(io)) : typemax(Int)
    if length(pd) + 1 < limit
        for i in eachindex(pd)
            if isassigned(pd, i)
                print(io, "\n ", pd[i])
            else
                print(io, "\n #undef")
            end
        end
    else
        for i in 1:limit÷2-2
            if isassigned(pd, i)
                print(io, "\n ", pd[i])
            else
                print(io, "\n #undef")
            end
        end
        print(io, "\n ⋮")
        for i in lastindex(pd)-limit÷2+3:lastindex(pd)
            if isassigned(pd, i)
                print(io, "\n ", pd[i])
            else
                print(io, "\n #undef")
            end
        end
    end
end
function Base.show(io::IO, pd::PersistenceDiagram)
    print(io, length(pd), "-element ", dim(pd), "-dimensional PersistenceDiagram")
end
function Base.show(io::IO, ::MIME"text/plain", pd::PersistenceDiagram)
    print(io, pd)
    if length(pd) > 0
        print(io, ":")
        show_intervals(io, pd.intervals)
    end
end

threshold(pd::PersistenceDiagram) = pd.threshold

Base.size(pd::PersistenceDiagram) = size(pd.intervals)
Base.getindex(pd::PersistenceDiagram, i::Integer) = pd.intervals[i]
Base.setindex!(pd::PersistenceDiagram, x, i::Integer) = pd.intervals[i] = x
Base.firstindex(pd::PersistenceDiagram) = 1
Base.lastindex(pd::PersistenceDiagram) = length(pd.intervals)

function Base.similar(pd::PersistenceDiagram)
    return PersistenceDiagram(dim(pd), similar(pd.intervals), threshold(pd))
end
function Base.similar(pd::PersistenceDiagram, dims::Tuple)
    return PersistenceDiagram(dim(pd), similar(pd.intervals, dims), threshold(pd))
end

"""
    dim(::PersistenceDiagram)

Get the dimension of persistence diagram.
"""
dim(pd::PersistenceDiagram) = pd.dim

dist_type(pd::PersistenceDiagram) = dist_type(eltype(pd))
dist_type(::Type{P}) where P<:PersistenceDiagram = dist_type(eltype(P))
