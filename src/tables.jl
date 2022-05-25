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
    return PersistenceDiagramRowIterator(diagram)
end
function Tables.schema(it::PersistenceDiagramRowIterator)
    diagram = it.diagram
    D = hasproperty(diagram, :dim) ? Int : Missing
    T = hasproperty(diagram, :threshold) ? Float64 : Missing
    return Tables.Schema((:birth, :death, :dim, :threshold), (Float64, Float64, D, T))
end

Tables.materializer(::PersistenceDiagram) = PersistenceDiagram
