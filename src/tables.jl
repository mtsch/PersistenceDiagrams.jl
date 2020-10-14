struct PersistenceDiagramRowIterator{D}
    diagram::D
end

function Base.iterate(it::PersistenceDiagramRowIterator, i=1)
    if i > length(it.diagram)
        return nothing
    else
        int = it.diagram[i]
        return (birth=int.birth, death=int.death, int.meta..., it.diagram.meta...), i + 1
    end
end

Base.IteratorSize(::PersistenceDiagramRowIterator) = Base.HasLength()
Base.length(it::PersistenceDiagramRowIterator) = length(it.diagram)
Base.eltype(it::PersistenceDiagramRowIterator) = NamedTuple

Tables.istable(::Type{<:PersistenceDiagram}) = true
Tables.rowaccess(::Type{<:PersistenceDiagram}) = true
function Tables.rows(diagram::PersistenceDiagram)
    PersistenceDiagramRowIterator(diagram)
end

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
