# TODO: support manually setting ranges?

import MLJModelInterface
const MMI = MLJModelInterface

# TODO is this ok?
MMI.ScientificTypes.scitype(::PersistenceDiagram) = PersistenceDiagram

"""
    AbstractVectorizer <: Unsupervised

To be an AbstractVectorizer, a type needs to implement `vectorizer(model, diagrams)`. It
should return a callable object that transforms diagrams to vectors and has a method for
`output_size`.
"""
abstract type AbstractVectorizer <: MMI.Unsupervised end

function MMI.fit(model::AbstractVectorizer, ::Int, X)
    vectorizers = map(Tables.columnnames(X)) do col
        col => vectorizer(model, vec(Tables.getcolumn(X, col)))
    end
    return (vectorizers, nothing, NamedTuple())
end

function MMI.transform(model::AbstractVectorizer, vectorizers, X)
    matrix = zeros(MMI.nrows(X), sum(output_size(last(v)) for v in vectorizers))
    for (i, row) in enumerate(Tables.rows(X))
        matrix[i, :] .= mapreduce(vcat, vectorizers) do (k, v)
            vec(v(Tables.getcolumn(row, k)))
        end
    end

    names = Symbol[]
    for (k, v) in vectorizers
        append!(names, Symbol(k, :_, i) for i in 1:output_size(v))
    end
    return MMI.table(matrix; names=names)
end

MMI.input_scitype(::Type{<:AbstractVectorizer}) = MMI.Table(PersistenceDiagram)
MMI.output_scitype(::Type{<:AbstractVectorizer}) = MMI.Table(MMI.Continuous)

"""
    PersistenceImageVectorizer(; kwargs...)

Converts persistence diagrams into persistence images. Each pixel in the image curve is
mapped to a column.

# Hyperparameters

* `distribution::Any = :default`: the distribution used to smear each point in the
  diagram. Can be a function, a callable object, or :default. When set to `:default`, a
  binormal distribution is used.

* `sigma::Float64 = -1`: the width of the gaussian distribution. Only applicable when
  `distribution=:default`. If set to -1, its value is learned from data.

* `weight::Any = :default`: the weighting function. Can be a function, a callable object, or
  :default. When set to `:default`, a piecewise linear function is used. To make this method
  work correctly, `weight(0.0, _) == 0.0` should always hold.

* `slope_end::Float64 = 1.0`: the (relative) position in the diagram where the default
  weight function stops decreasing. Only applicable when `weight=:default`.

* `width::Int = 3`, `height::Int = 3`: the size of the image. Note that all pixels of the
  image will be converted to columns. For example a 3×3 image will produce 9 columns per
  dimension.

# See also

* [`PersistenceImage`](@ref)

"""
mutable struct PersistenceImageVectorizer <: AbstractVectorizer
    distribution::Any
    sigma::Float64
    weight::Any
    slope_end::Float64
    width::Int
    height::Int
    margin::Float64
    zero_start::Bool
end
# TODO: replace with Base.@kwdef when 1.6 becomes LTS
function PersistenceImageVectorizer(;
    distribution=:default,
    sigma=-1,
    weight=:default,
    slope_end=1.0,
    width=5,
    height=5,
    margin=0.1,
    zero_start=true,
)
    return PersistenceImageVectorizer(
        distribution, sigma, weight, slope_end, width, height, margin, zero_start
    )
end

function _is_callable(fun)
    try
        x = fun(0.0, 0.0)
        return x isa Real
    catch e
        if e isa MethodError
            return false
        else
            rethrow()
        end
    end
end

function _clean_function_arguments!(warning, model, fun, setting, default)
    if getfield(model, fun) ≠ :default
        if _is_callable(getfield(model, fun))
            if getfield(model, setting) ≠ default
                warning *=
                    "Both `$setting` and `$fun` were set; " * "using `$setting=$default`. "
                setfield!(model, setting, default)
            end
        else
            warning *= "Invalid `$fun`; using `$fun=:default`. "
            setfield!(model, fun, :default)
        end
    end
    return warning
end

function MMI.clean!(model::PersistenceImageVectorizer)
    warning = ""
    warning = _clean_function_arguments!(warning, model, :distribution, :sigma, -1.0)
    if model.sigma ≤ 0 && model.sigma ≠ -1
        warning *= "`sigma` must be positive or -1; using `sigma=-1`. "
        model.sigma = -1
    end

    warning = _clean_function_arguments!(warning, model, :weight, :slope_end, 1.0)
    if !(0 < model.slope_end ≤ 1)
        warning *= "`0 < slope_end ≤ 1` does not hold; using `slope_end=1`. "
        model.slope_end = 1.0
    end
    if (model.width ≤ 0)
        warning *= "`width` must be positive; using `width=5`. "
        model.width = 5
    end
    if (model.height ≤ 0)
        warning *= "`height` must be positive; using `height=5`. "
        model.height = 5
    end
    if (model.margin < 0)
        warning *= "`margin` must be non-negative; using `margin=0.1`. "
        model.margin = 0.1
    end
    return warning
end

function vectorizer(model::PersistenceImageVectorizer, diagrams)
    if model.distribution == :default
        distribution = nothing
        sigma = model.sigma == -1 ? nothing : model.sigma
    else
        distribution = model.distribution
        sigma = nothing
    end
    if model.weight == :default
        weight = nothing
        slope_end = model.slope_end
    else
        weight = model.weight
        slope_end = nothing
    end
    return PersistenceImage(
        diagrams;
        size=(model.height, model.width),
        distribution=distribution,
        sigma=sigma,
        weight=weight,
        slope_end=slope_end,
        margin=model.margin,
        zero_start=model.zero_start,
    )
end

"""
    PersistenceCurveVectorizer(; kwargs...)

Converts persistence diagrams into persistence curves. Each value of the curve is mapped to
a column.

# Hyperparameters

* `fun::Function = always_one`: The function used to construct the curve. See also
  [`PersistenceCurve`](@ref). Note: the `curve` argument must be `:custom` if this argument
  is set.

* `stat::Function = sum`: The statistic used to construct the curve. See also
  [`PersistenceCurve`](@ref). Note: the `curve` argument must be `:custom` if this argument
  is set.

* `curve::Symbol = :custom`: The type of curve used. Available options are `:custom`,
  `:betti`, `:silhuette`, `:life`, `:midlife`, `:life_entropy`, `:midlife_entropy`,
  and `:pd_thresholding`.

* `integrate::Bool = true`: If set to `true`, the curve is integrated. If set to `false`,
  the curve is simply sampled at specified points.

* `normalize::Bool = false`: Normalize the curve by dividing all values by
  `stat(fun.(diagram))`.

* `length::Int = 5`: The number of columns per dimension to output.

# See also

* [`PersistenceCurve`](@ref)
* [`BettiCurve`](@ref)
* [`Silhuette`](@ref)
* [`Life`](@ref)
* [`Midlife`](@ref)
* [`LifeEntropy`](@ref)
* [`MidlifeEntropy`](@ref)
* [`PDThresholding`](@ref)

"""
mutable struct PersistenceCurveVectorizer <: AbstractVectorizer
    fun::Function
    stat::Function
    curve::Symbol
    integrate::Bool
    normalize::Bool
    length::Int
end
# TODO: replace with Base.@kwdef when 1.6 becomes LTS
function PersistenceCurveVectorizer(;
    fun=always_one, stat=sum, curve=:custom, integrate=true, normalize=false, length=5
)
    return PersistenceCurveVectorizer(fun, stat, curve, integrate, normalize, length)
end

function vectorizer(model::PersistenceCurveVectorizer, diagrams)
    return PersistenceCurve(
        model.fun,
        model.stat,
        diagrams;
        length=model.length,
        integrate=model.integrate,
        normalize=model.normalize,
    )
end

function MMI.clean!(model::PersistenceCurveVectorizer)
    warning = ""
    if model.curve == :custom
        fun = model.fun
        stat = model.stat
    elseif model.curve == :betti
        fun = always_one
        stat = sum
    elseif model.curve == :silhuette
        fun = landscape
        stat = sum
    elseif model.curve == :life
        fun = life
        stat = sum
    elseif model.curve == :midlife
        fun = midlife
        stat = sum
    elseif model.curve == :life_entropy
        fun = life_entropy
        stat = sum
    elseif model.curve == :midlife_entropy
        fun = midlife_entropy
        stat = sum
    elseif model.curve == :pd_thresholding
        fun = thresholding
        stat = sum
    else
        warning *= "Unrecognized curve `$(model.curve)`; using `curve=:custom`. "
        model.curve = :custom
        fun = model.fun
        stat = model.stat
    end
    if model.curve ≠ :custom && model.fun ≢ always_one && model.fun ≢ fun
        warning *= "Both `curve` and `fun` were set; using `fun=$fun`. "
    end
    if model.curve ≠ :custom && model.stat ≢ always_one && model.stat ≢ stat
        warning *= "Both `curve` and `stat` were set; using `stat=$stat`. "
    end
    model.fun = fun
    model.stat = stat
    if model.normalize && model.curve == :silhuette
        warning *=
            "Normalizing `curve=:silhuette` is not supported; " *
            "using `normalize=false`. "
        model.normalize = false
    end
    if model.normalize && model.curve == :pd_thresholding
        warning *=
            "Normalizing `curve=:pd_thresholding` is not supported; " *
            "using `normalize=false`. "
        model.normalize = false
    end
    if model.length ≤ 0
        warning *= "`length` must be positive; using `length=5`. "
        model.length = 5
    end
    return warning
end

"""
    PersistenceLandscapeVectorizer

Converts persistence diagrams into persistence landscapes. Each value of the curve is mapped
to a column.

# Hyperparameters

* `n_landscapes = 1`: use the top ``n`` landscapes.

* `length = 5`: the number of columns per dimension per landscape to output. For example,
  for `n_landscapes=3`, `length=5`, and two persistence diagrams, the vectorization will
  produce 30 columns.

# See also

* [`Landscapes`](@ref)
* [`Landscape`](@ref)

"""
mutable struct PersistenceLandscapeVectorizer <: AbstractVectorizer
    n_landscapes::Int
    length::Int
end

function PersistenceLandscapeVectorizer(; n_landscapes=1, length=10)
    return PersistenceLandscapeVectorizer(n_landscapes, length)
end

function vectorizer(model::PersistenceLandscapeVectorizer, diagrams)
    return Landscapes(model.n_landscapes, diagrams; length=model.length)
end

function MMI.clean!(model::PersistenceLandscapeVectorizer)
    warning = ""
    if model.length ≤ 0
        warning *= "`length` must be positive; using `length=10`. "
        model.length = 10
    end
    if model.n_landscapes ≤ 0
        warning *= "`n_landscapes` must be positive; using `n_landscapes=1`. "
        model.n_landscapes = 1
    end
    return warning
end

MMI.metadata_pkg.(
    (
        PersistenceImageVectorizer,
        PersistenceCurveVectorizer,
        PersistenceLandscapeVectorizer,
    ),
    name="PersistenceDiagrams",
    uuid="90b4794c-894b-4756-a0f8-5efeb5ddf7ae",
    url="https://github.com/mtsch/PersistenceDiagrams.jl",
    license="MIT",
    julia=true,
    is_wrapper=false,
)
