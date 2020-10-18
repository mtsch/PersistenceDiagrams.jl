import MLJModelInterface
const MMI = MLJModelInterface

MMI.ScientificTypes.scitype(::PersistenceDiagram) = PersistenceDiagram

abstract type AbstractVectorizer <: MMI.Unsupervised end

function MMI.transform(vectorizer::AbstractVectorizer, vectorizers, X)
    matrix = mapreduce(vcat, Tables.rows(X)) do row
        mapreduce(hcat, vectorizers) do (k, v)
            transpose(vec(v(Tables.getcolumn(row, k))))
        end
    end
    names = [
        Symbol(k, :_, i) for k in first.(vectorizers) for i in 1:_output_size(vectorizer)
    ]
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
end
# TODO: replace with Base.@kwdef when 1.6 becomes LTS
function PersistenceImageVectorizer(;
    distribution=:default, sigma=nothing, weight=:default, slope_end=1.0, width=3, height=3
)
    return PersistenceImageVectorizer(distribution, sigma, weight, slope_end, width, height)
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

function _clean_function_arguments!(warning, v, fun, setting, default)
    if getfield(v, fun) ≠ :default
        if _is_callable(getfield(v, fun))
            if getfield(v, setting) ≠ default
                warning *= "Both `$setting` and `$fun` were set; ignoring `$setting`. "
                setfield!(v, setting, default)
            end
        else
            warning *= "Invalid `$fun`; using `$fun=:default`"
            setfield!(v, fun, :default)
        end
    end
    return warning
end

function MMI.clean!(v::PersistenceImageVectorizer)
    warning = ""
    warning = _clean_function_arguments!(warning, v, :distribution, :sigma, -1)
    if v.sigma ≤ 0 && v.sigma ≠ -1
        warning *= "`sigma` must be positive or -1; using `sigma=-1`."
        v.sigma = 0.0
    end

    warning = _clean_function_arguments!(warning, v, :weight, :slope_end, 1.0)
    if !(0 < v.slope_end ≤ 1)
        warning *= "`0 < slope_end ≤ 1` does not hold; using `slope_end=1`"
        v.slope_end = 1.0
    end
    return warning
end

_output_size(v::PersistenceImageVectorizer) = v.width * v.height

function _image(v::PersistenceImageVectorizer, diagrams)
    if v.distribution == :default
        distribution = nothing
        sigma = v.sigma == -1 ? nothing : v.sigma
    else
        distribution = v.distribution
        sigma = nothing
    end
    if v.weight == :default
        weight = nothing
        slope_end = v.slope_end
    else
        weight = v.weight
        slope_end = nothing
    end
    return PersistenceImage(
        diagrams;
        size=(v.height, v.width),
        distribution=distribution,
        sigma=sigma,
        weight=weight,
        slope_end=slope_end,
    )
end

function MMI.fit(v::PersistenceImageVectorizer, ::Int, X)
    images = map(Tables.columnnames(X)) do col
        col => _image(v, vec(Tables.getcolumn(X, col)))
    end
    return (images, nothing, NamedTuple())
end

abstract type AbstractCurveVectorizer <: AbstractVectorizer end

_output_size(v::AbstractCurveVectorizer) = v.length

function MMI.fit(v::AbstractCurveVectorizer, ::Int, X)
    curves = map(Tables.columnnames(X)) do col
        col => _curve(v, vec(Tables.getcolumn(X, col)))
    end
    return (curves, nothing, NamedTuple())
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
  `:betti_curve`, `:silhuette`, `:life`, `:midlife`, `:life_entropy`, `:midlife_entropy`,
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
mutable struct PersistenceCurveVectorizer <: AbstractCurveVectorizer
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

function MMI.clean!(v::PersistenceCurveVectorizer)
    warning = ""
    if v.curve == :custom
        fun = v.fun
        stat = v.stat
    elseif v.curve == :betti_curve
        fun = always_one
        stat = sum
    elseif v.curve == :silhuette
        fun = landscape
        stat = sum
    elseif v.curve == :life
        fun = life
        stat = sum
    elseif v.curve == :midlife
        fun = midlife
        stat = sum
    elseif v.curve == :life_entropy
        fun = life_entropy
        stat = sum
    elseif v.curve == :midlife_entropy
        fun = midlife_entropy
        stat = sum
    elseif v.curve == :pd_thresholding
        fun = thresholding
        stat = sum
    else
        warning *= "Unrecognized curve $(v.curve); using default :custom. "
    end
    if v.curve ≠ :custom && v.fun ≢ always_one && v.fun ≢ fun
        warning *= "Both curve and fun were set; using fun=$fun. "
    end
    if v.curve ≠ :custom && v.stat ≢ always_one && v.stat ≢ stat
        warning *= "Both curve and stat were set; using stat=$stat. "
    end
    v.fun = fun
    v.stat = stat
    if v.normalize && v.curve == :silhuette
        warning *= "Normalizing :silhuette is not supported; using normalize=false. "
        v.normalize = false
    end
    if v.length < 1
        warning *= "Non-positive length given; using length=5. "
        v.length = 5
    end
    return warning
end

function _curve(v::PersistenceCurveVectorizer, diagrams)
    return PersistenceCurve(
        v.fun,
        v.stat,
        diagrams;
        length=v.length,
        integrate=v.integrate,
        normalize=v.normalize,
    )
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
MMI.@mlj_model mutable struct PersistenceLandscapeVectorizer <: AbstractCurveVectorizer
    n_landscapes::Int = 1::(_ > 0)
    length::Int = 5::(_ > 0)
end

_output_size(v::PersistenceLandscapeVectorizer) = v.n_landscapes * v.length

function _curve(v::PersistenceLandscapeVectorizer, diagrams)
    return Landscapes(v.n_landscapes, diagrams; length=v.length)
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
