# interval =============================================================================== #
"""
    PersistenceInterval{T<:AbstractFloat, C}

The type that represents a persistence interval. It behaves exactly like a
`Tuple{T, T}`, but may have a representative cocycle attached to it.
"""
struct PersistenceInterval{R}
    birth::Float64
    death::Float64
    representative::R
end

function PersistenceInterval{Nothing}(birth::Real, death::Real)
    return PersistenceInterval{Nothing}(Float64(birth), Float64(death), nothing)
end
function PersistenceInterval(birth::Real, death::Real, rep::R=nothing) where R
    return PersistenceInterval{R}(Float64(birth), Float64(death), rep)
end
function PersistenceInterval(t::Tuple{<:Any, <:Any}, rep=nothing)
    return PersistenceInterval(t[1], t[2], rep)
end
function Base.convert(::Type{P}, t::Tuple{<:Any, <:Any}) where P<:PersistenceInterval
    return P(t[1], t[2], nothing)
end

function Base.show(io::IO, int::PersistenceInterval)
    b = round(birth(int), sigdigits=3)
    d = isfinite(death(int)) ? round(death(int), sigdigits=3) : "∞"
    print(io, "[$b, $d)")
end
function Base.show(io::IO, ::MIME"text/plain", int::PersistenceInterval)
    print(io, "PersistenceInterval", (birth(int), death(int)))
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
        error("$int has no representative.")
    end
end

"""
    stripped(int::PersistenceInterval)

Return the same interval, without a representative.
"""
function stripped(int::PersistenceInterval)
    PersistenceInterval{Nothing}(birth(int), death(int))
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
Base.eltype(::Type{<:PersistenceInterval}) = Float64

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
struct PersistenceDiagram{P<:PersistenceInterval} <: AbstractVector{P}
    dim       ::Int
    intervals ::Vector{P}
    threshold ::Float64

    function PersistenceDiagram(dim, intervals::Vector{<:PersistenceInterval}, threshold)
        return new{eltype(intervals)}(dim, intervals, Float64(threshold))
    end
end

function PersistenceDiagram(dim, intervals; threshold=Inf)
    return PersistenceDiagram(dim, intervals, threshold)
end
function PersistenceDiagram(dim, intervals::AbstractVector{<:Tuple}; threshold=Inf)
    return PersistenceDiagram(dim, PersistenceInterval.(intervals), threshold)
end

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
    print(io, length(diag), "-element ", dim(diag), "-dimensional PersistenceDiagram")
end
function Base.show(io::IO, ::MIME"text/plain", diag::PersistenceDiagram)
    print(io, diag)
    if length(diag) > 0
        print(io, ":")
        show_intervals(io, diag.intervals)
    end
end

threshold(diag::PersistenceDiagram) = diag.threshold

Base.size(diag::PersistenceDiagram) = size(diag.intervals)
Base.getindex(diag::PersistenceDiagram, i::Integer) = diag.intervals[i]
Base.setindex!(diag::PersistenceDiagram, x, i::Integer) = diag.intervals[i] = x
Base.firstindex(diag::PersistenceDiagram) = 1
Base.lastindex(diag::PersistenceDiagram) = length(diag.intervals)

function Base.similar(diag::PersistenceDiagram)
    return PersistenceDiagram(dim(diag), similar(diag.intervals), threshold(diag))
end
function Base.similar(diag::PersistenceDiagram, dims::Tuple)
    return PersistenceDiagram(dim(diag), similar(diag.intervals, dims), threshold(diag))
end

"""
    dim(::PersistenceDiagram)

Get the dimension of persistence diagram.
"""
dim(diag::PersistenceDiagram) = diag.dim

function stripped(diag::PersistenceDiagram)
    return PersistenceDiagram(dim(diag), stripped.(diag), threshold=threshold(diag))
end
