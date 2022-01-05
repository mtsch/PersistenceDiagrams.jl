import ScientificTypes: DefaultConvention
const SB = ScientificTypes.ScientificTypesBase

SB.scitype(::PersistenceDiagram, ::DefaultConvention; kwargs...) = PersistenceDiagram
