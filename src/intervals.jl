abstract type AbstractInterval end

"""
    birth(interval)

Get the birth time of `interval`.
"""
birth
"""
    death(interval)

Get the death time of `interval`.
"""
death
"""
    persistence(interval)

Get the persistence of `interval`, which is equal to `death - birth`.
"""
persistence(int::AbstractInterval) = death(int) - birth(int)

Base.isfinite(int::AbstractInterval) = isfinite(death(int))

function Base.iterate(int::AbstractInterval, i=1)
    if i == 1
        return birth(int), i+1
    elseif i == 2
        return death(int), i+1
    else
        return nothing
    end
end

Base.length(::AbstractInterval) = 2
Base.IteratorSize(::Type{<:AbstractInterval}) = Base.HasLength()
Base.IteratorEltype(::Type{<:AbstractInterval}) = Base.HasEltype()
Base.eltype(::Type{<:AbstractInterval}) = Float64

function Base.getindex(int::AbstractInterval, i)
    if i == 1
        return birth(int)
    elseif i == 2
        return death(int)
    else
        throw(BoundsError(int, i))
    end
end

Base.firstindex(int::AbstractInterval) = 1
Base.lastindex(int::AbstractInterval) = 2

function Base.:(==)(int1::AbstractInterval, int2::AbstractInterval)
    birth(int1) == birth(int2) && death(int1) == death(int2)
end
Base.:(==)(int::AbstractInterval, (b, d)::Tuple) = birth(int) == b && death(int) == d
Base.:(==)((b, d)::Tuple, int::AbstractInterval) = birth(int) == b && death(int) == d

function Base.isless(int1::AbstractInterval, int2::AbstractInterval)
    if birth(int1) ≠ birth(int2)
        return isless(birth(int1), birth(int2))
    else
        return isless(death(int1), death(int2))
    end
end


"""
    PersistenceInterval{T<:AbstractFloat, C}

The type that represents a persistence interval. It behaves exactly like a `Tuple{Float64,
Float64}`.
"""
struct PersistenceInterval <: AbstractInterval
    birth::Float64
    death::Float64

    PersistenceInterval(birth, death) = new(Float64(birth), Float64(death))
end

function PersistenceInterval(t::Tuple{<:Any, <:Any})
    return PersistenceInterval(t[1], t[2])
end

function Base.convert(::Type{PersistenceInterval}, t::Tuple{<:Any, <:Any})
    return PersistenceInterval(t[1], t[2])
end

birth(int::PersistenceInterval) = int.birth
death(int::PersistenceInterval) = int.death

function Base.show(io::IO, int::PersistenceInterval)
    b = round(birth(int), sigdigits=3)
    d = isfinite(death(int)) ? round(death(int), sigdigits=3) : "∞"
    print(io, "[$b, $d)")
end

"""
    RepresentativeInterval{P<:AbstractInterval, B, D, R} <: AbstractInterval

A persistence interval with a representative (co)cycles and critical simplices attached.
"""
struct RepresentativeInterval{P<:AbstractInterval, B, D, R} <: AbstractInterval
    # This is done to allow e.g. adding a representative to an interval with an error bar
    # with minimal fuss.
    interval::P
    birth_simplex::B
    death_simplex::D
    representative::R
end

function RepresentativeInterval(birth, death, birth_simplex, death_simplex, rep)
    return RepresentativeInterval(
        PersistenceInterval(birth, death), birth_simplex, death_simplex, rep
    )
end

birth(int::RepresentativeInterval) = birth(int.interval)
death(int::RepresentativeInterval) = death(int.interval)

function Base.show(io::IO, int::RepresentativeInterval)
    print(io, int.interval)
    print(io, " with ", length(representative(int)), "-element representative")
end
function Base.show(io::IO, ::MIME"text/plain", int::RepresentativeInterval)
    println(io, int.interval)
    println(io, " birth_simplex: ", int.birth_simplex)
    println(io, " death_simplex: ", int.death_simplex)
    print(io, " representative: ")
    show(io, MIME"text/plain"(), representative(int))
end

"""
    representative(interval::RepresentativeInterval)

Get the representative (co)cycle attached to `interval`.
"""
representative(int::RepresentativeInterval) = int.representative

"""
    birth_simplex(interval::RepresentativeInterval)

Get the critical birth simplex of `interval`.
"""
birth_simplex(int::RepresentativeInterval) = int.birth_simplex

"""
    death_simplex(interval::RepresentativeInterval)

Get the critical death simplex of `interval`.
"""
death_simplex(int::RepresentativeInterval) = int.death_simplex

"""
    stripped(int::PersistenceInterval)

Return the an interval with the same birth and death times, but without any additional
information attached.
"""
stripped(int::AbstractInterval) = PersistenceInterval(birth(int), death(int))
