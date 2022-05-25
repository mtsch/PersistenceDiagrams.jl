"""
    PersistenceDiagram <: AbstractVector{PersistenceInterval}

Type for representing persistence diagrams. Behaves exactly like a vector of
`PersistenceInterval`s, but can have additional metadata attached to it. It supports pretty
printing and plotting.

Can be used as a table with any function that uses the
[`Tables.jl`](https://github.com/JuliaData/Tables.jl) interface. Note that using it as a
table will only keep interval endpoints and the `dim` and `threshold` attributes.

# Example

```jldoctest
julia> diagram = PersistenceDiagram([(1, 3), (3, 4), (1, Inf)]; dim=1, custom_metadata=:a)
3-element 1-dimensional PersistenceDiagram:
 [1.0, 3.0)
 [3.0, 4.0)
 [1.0, ∞)

julia> diagram[1]
[1.0, 3.0)

julia> sort(diagram; by=persistence, rev=true)
3-element 1-dimensional PersistenceDiagram:
 [1.0, ∞)
 [1.0, 3.0)
 [3.0, 4.0)

julia> propertynames(diagram)
(:dim, :custom_metadata)

julia> dim(diagram)
1

julia> diagram.custom_metadata
:a
```
"""
struct PersistenceDiagram <: AbstractVector{PersistenceInterval}
    intervals::Vector{PersistenceInterval}
    meta::NamedTuple
end

function PersistenceDiagram(intervals::Vector{PersistenceInterval}; kwargs...)
    meta = (; kwargs...)
    return PersistenceDiagram(intervals, meta)
end
function PersistenceDiagram(intervals::AbstractVector{PersistenceInterval}; kwargs...)
    return PersistenceDiagram(collect(intervals); kwargs...)
end
function PersistenceDiagram(pairs::AbstractVector{<:Tuple}; kwargs...)
    return PersistenceDiagram(PersistenceInterval.(pairs); kwargs...)
end
function PersistenceDiagram(table)
    rows = Tables.rows(table)
    if isempty(rows)
        return PersistenceDiagram(PersistenceInterval[])
    else
        firstrow = first(rows)
        dim = hasproperty(firstrow, :dim) ? firstrow.dim : missing
        threshold = hasproperty(firstrow, :threshold) ? firstrow.threshold : missing
        intervals = map(rows) do row
            d = hasproperty(row, :dim) ? row.dim : missing
            t = hasproperty(row, :threshold) ? row.threshold : missing
            if !isequal(d, dim)
                error("different `dim`s detected. Try splitting the table first.")
            end
            if !isequal(t, threshold)
                error("different `threshold`s detected. Try splitting the table first.")
            end
            PersistenceInterval(row.birth, row.death)
        end
        return PersistenceDiagram(intervals; dim=dim, threshold=threshold)
    end
end

function Base.show(io::IO, diag::PersistenceDiagram)
    return summary(io, diag)
end
function Base.summary(io::IO, diag::PersistenceDiagram)
    if haskey(diag.meta, :dim)
        print(io, length(diag), "-element ", dim(diag), "-dimensional PersistenceDiagram")
    else
        print(io, length(diag), "-element PersistenceDiagram")
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
function Base.propertynames(diag::PersistenceDiagram, private::Bool=false)
    if private
        return tuple(:intervals, :meta, propertynames(diag.meta)...)
    else
        return tuple(:intervals, propertynames(diag.meta)...)
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
