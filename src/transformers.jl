abstract type AbstractDiagramTransformer end

"""
    destination(transformer::AbstractDiagramTransformer, diagrams)

If `transformer` has an inplace method, `destination` needs to be implemented. It should
return a destination for the inplace `transform!` will be able to use.
"""
destination(::AbstractDiagramTransformer, ::Any)

"""
    transform(::AbstractDiagramTransformer, diagrams)

Transform a diagram or collection of diagrams. Return value depends on the transformer used.
"""
function transform(transformer::AbstractDiagramTransformer, diagram)
    dst = destination(transformer, diagram)

    return transform!(dst, transformer, diagram)
end

"""
    transform!(dst, ::AbstractDiagramTransformer, diagrams)

Transform a diagram or collection of diagrams. Write the results to `dst`.
"""
transform!(dst, ::AbstractDiagramTransformer, ::Any)
