"""
    PersistenceDiagram{P<:AbstractInterval} <: AbstractVector{P}

Type for representing persistence diagrams. Behaves exactly like an array of
`AbstractInterval`s, but is aware of its dimension and supports pretty printing and
plotting.
"""
struct PersistenceDiagram{P<:AbstractInterval} <: AbstractVector{P}
    dim       ::Int
    intervals ::Vector{P}
    threshold ::Float64

    function PersistenceDiagram(dim, intervals::Vector{<:AbstractInterval}, threshold)
        return new{eltype(intervals)}(dim, intervals, Float64(threshold))
    end
end

function PersistenceDiagram(
    dim, intervals::AbstractVector{<:AbstractInterval}; threshold=Inf
)
    return PersistenceDiagram(dim, collect(intervals), threshold)
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
