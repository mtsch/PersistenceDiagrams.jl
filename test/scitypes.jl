using PersistenceDiagrams
using ScientificTypes

diagram = PersistenceDiagram([(1, Inf), (2, 3)]; dim=0)
@test scitype(diagram) == PersistenceDiagram

diagrams = [diagram, diagram, diagram]
@test scitype(diagrams) == AbstractVector{PersistenceDiagram}
