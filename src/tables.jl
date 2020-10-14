struct PersistenceDiagramRowIterator{D}
    diagram::D
end

function Base.iterate(it::PersistenceDiagramRowIterator, i=1)
    if i > length(it.diagram)
        return nothing
    else
        int = it.diagram[i]
        dim = get(it.diagram.meta, :dim, missing)
        threshold = get(it.diagram.meta, :threshold, missing)
        return (birth=int.birth, death=int.death, dim=dim, threshold=threshold), i + 1
    end
end

Base.IteratorSize(::PersistenceDiagramRowIterator) = Base.HasLength()
Base.length(it::PersistenceDiagramRowIterator) = length(it.diagram)

Tables.istable(::Type{<:PersistenceDiagram}) = true
Tables.rowaccess(::Type{<:PersistenceDiagram}) = true
function Tables.rows(diagram::PersistenceDiagram)
    PersistenceDiagramRowIterator(diagram)
end
function Tables.schema(diagram::PersistenceDiagram)
    D = hasproperty(diagram, :dim) ? Int : Missing
    T = hasproperty(threshold, :dim) ? Float64 : Missing
    return Schema(
        (:birth, :death, :dim, :threshold),
        (Float64, Float64, D, T),
    )
end

Tables.materializer(::PersistenceDiagram) = PersistenceDiagram

struct PersistenceDiagramTable{V<:AbstractVector{<:PersistenceDiagram}}
    diagrams::V
end

"""
    PersistenceDiagrams.table(::AbstractVector{<:PersistenceDiagram})

Wrap a vector of `PersistenceDiagram`s in a `PersistenceDiagramTable`, which satisfies the
Tables.jl interface.
"""
table(ds::AbstractVector{<:PersistenceDiagram}) = PersistenceDiagramTable(ds)

Tables.istable(::Type{<:PersistenceDiagramTable}) = true
Tables.rowaccess(::Type{<:PersistenceDiagramTable}) = true
function Tables.rows(table::PersistenceDiagramTable)
    Iterators.flatten(PersistenceDiagramRowIterator.(table.diagrams))
end
function Tables.schema(table::PersistenceDiagramTable)
    return Schema(
        (:birth, :death, :dim, :threshold),
        (Float64, Float64, Union{Int, Missing}, Union{Float64, Missing}),
    )
end
