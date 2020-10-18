struct DefaultWeightingFunction
    b::Float64
end
function (dwf::DefaultWeightingFunction)(_, y)
    if y ≤ 0
        return 0.0
    elseif 0 < y < dwf.b
        return y / dwf.b
    else
        return 1.0
    end
end

const inv2π = 1.0 / (2π)

struct Binormal
    sigma::Float64
end
function (bi::Binormal)(x, y)
    invsigma2 = 1 / abs2(bi.sigma)
    return inv2π * invsigma2 * exp(-(abs2(x) + abs2(y)) * 0.5 * invsigma2)
end

"""
    PersistenceImage

`PersistenceImage` provides a vectorization method for persistence diagrams. Each point in
the diagram is first transformed into `birth`, `persistence` coordinates. Then, it is
weighted by a weighting function and widened by a distribution (default: gaussian with σ=1).
Once all the points are transformed, their distributions are summed together and discretized
into an image.

The weighting ensures points near the diagonal have a small contribution. This ensures this
representation of the diagram is stable.

Once a `PersistenceImage` is constructed (see below), it can called like a function to
transform a diagram to an image.

Infinite intervals in the diagram are ignored.

# Constructors

    PersistenceImage(ylims, xlims; kwargs...)

Create an image ranging from `ylims[1]` to `ylims[2]` in the ``y`` direction and
equivalently for the ``x`` direction.

    PersistenceImage(diagrams; zero_start=true, margin=0.1, kwargs...)

Learn the ``x`` and ``y`` ranges from diagrams, ensuring all diagrams will fully fit in the
image. Limits are increased by the `margin`. If `zero_start` is true, set the minimum `y`
value to 0. If all intervals in diagrams have the same birth (e.g. in the zeroth dimension),
a single column image is produced.

## Keyword Arguments

* `size`: integer or tuple of two integers. Determines the size of the array containing the
  image. Defaults to 5.

* `distribution`: A function or callable object used to smear each interval in diagram.  Has
  to be callable with two `Float64`s as input and should return a `Float64`. Defaults to a
  normal distribution.

* `sigma`: The width of the normal distribution mentioned above. Only applicable when
  `distribution` is unset. Defaults to twice the size of each pixel.

* `weight`: A function or callable object used as the weighting function. Has to be callable
  with two `Float64`s as input and should return a `Float64`. Should equal 0.0 for x=0, but
  this is not enforced. Defaults to function that is zero at ``y=0``, and increases linearly
  to 1 until `slope_end` is reached.

* `slope_end`: the relative ``y`` value at which the default weight function stops
  increasing. Defaults to 1.0.

# Example

```jldoctest
julia> diag_1 = PersistenceDiagram([(0, 1), (0, 1.5), (1, 2)]);

julia> diag_2 = PersistenceDiagram([(1, 2), (1, 1.5)]);

julia> image = PersistenceImage([diag_1, diag_2])
5×5 PersistenceImage(
  distribution = PersistenceDiagrams.Binormal(0.5499999999999999),
  weight = PersistenceDiagrams.DefaultWeightingFunction(1.65),
)

julia> image(diag_1)
5×5 Array{Float64,2}:
 0.156707  0.164263  0.160452  0.149968  0.0717212
 0.344223  0.355089  0.338991  0.308795  0.145709
 0.571181  0.577527  0.535069  0.47036   0.217661
 0.723147  0.714873  0.639138  0.536823  0.241904
 0.381499  0.372649  0.32665   0.267067  0.118359

```

# Reference

Adams, H., Emerson, T., Kirby, M., Neville, R., Peterson, C., Shipman, P., ... &
Ziegelmeier, L. (2017). Persistence images: A stable vector representation of persistent
homology. [The Journal of Machine Learning Research, 18(1), 218-252]
(http://www.jmlr.org/papers/volume18/16-337/16-337.pdf).
"""
struct PersistenceImage{X<:AbstractVector{Float64},Y<:AbstractVector{Float64},D,W}
    ys::Y
    xs::X
    distribution::D
    weight::W
end

function PersistenceImage(
    ys::AbstractArray{Float64},
    xs::AbstractArray{Float64};
    sigma=nothing,
    distribution=nothing,
    weight=nothing,
    slope_end=nothing,
)
    if !issorted(xs) || !issorted(ys)
        throw(ArgumentError("`xs` and `ys` must be increasing"))
    end
    if !isnothing(sigma) && !isnothing(distribution)
        throw(ArgumentError("`sigma` and `distribution` can't be set at the same time"))
    elseif !isnothing(sigma)
        if sigma > 0
            distribution = Binormal(sigma)
        else
            throw(ArgumentError("`sigma` must be positive"))
        end
    elseif !isnothing(distribution)
        distribution = distribution
    else
        w = max((last(ys) - first(ys)) / length(ys), (last(xs) - first(xs)) / length(xs))
        distribution = Binormal(2 * w)
    end
    if !isnothing(weight) && !isnothing(slope_end)
        throw(ArgumentError("`weight` and `slope_end` can't be set at the same time"))
    elseif !isnothing(weight)
        weight = weight
    elseif !isnothing(slope_end)
        if 0 < slope_end ≤ 1
            weight = DefaultWeightingFunction(slope_end * last(ys))
        else
            throw(ArgumentError("`0 < slope_end ≤ 1` does not hold"))
        end
    else
        weight = DefaultWeightingFunction(last(ys))
    end

    return PersistenceImage(ys, xs, distribution, weight)
end
function PersistenceImage(ylims::Tuple, xlims::Tuple; size=5, kwargs...)
    s = length(size) == 1 ? (size, size) : size
    ys = range(ylims[1], ylims[2]; length=s[1] + 1)
    xs = range(xlims[1], xlims[2]; length=s[2] + 1)

    return PersistenceImage(ys, xs; kwargs...)
end
function PersistenceImage(
    diagrams;
    zero_start=true,
    margin=0.1,
    size=5,
    sigma=nothing,
    distribution=nothing,
    kwargs...,
)
    if margin < 0
        throw(ArgumentError("`margin` must be non-negative"))
    end
    ysize, xsize = length(size) == 1 ? (size, size) : size

    finite = Iterators.filter(isfinite, Iterators.flatten(diagrams))
    # Generator used for Julia 1.0 compatibility.
    min_persistence, max_persistence = extrema(persistence(int) for int in finite)
    min_birth, max_birth = extrema(birth(int) for int in finite)
    if min_birth == max_birth
        xsize = 1
    end

    if zero_start
        min_persistence = 0.0
    end
    ywidth = max_persistence - min_persistence
    min_persistence = max(0.0, min_persistence - margin * ywidth)
    max_persistence = max_persistence + margin * ywidth

    xwidth = max_birth - min_birth
    min_birth = min_birth - margin * xwidth
    max_birth = max_birth + margin * xwidth

    ylims = (min_persistence, max_persistence)
    xlims = (min_birth, max_birth)

    return PersistenceImage(
        ylims, xlims; size=(ysize, xsize), sigma=sigma, distribution=distribution, kwargs...
    )
end

output_size(pi::PersistenceImage) = (length(pi.ys) - 1) * (length(pi.xs) - 1)

function Base.show(io::IO, pi::PersistenceImage)
    return print(io, "$(length(pi.ys) - 1)×$(length(pi.xs) - 1) PersistenceImage")
end
function Base.show(io::IO, ::MIME"text/plain", pi::PersistenceImage)
    println(io, pi, "(")
    println(io, "  distribution = ", pi.distribution, ",")
    println(io, "  weight = ", pi.weight, ",")
    return print(io, ")")
end

function (pi::PersistenceImage)(diagram::PersistenceDiagram)
    n = length(pi.ys) - 1
    m = length(pi.xs) - 1
    result = zeros(n, m)
    distribution_buffer = zeros(n + 1, m + 1)

    @inbounds for interval in Iterators.filter(isfinite, diagram)
        b = birth(interval)
        p = persistence(interval)
        w = pi.weight(b, p)

        for j in 1:m+1, i in 1:n+1
            x = pi.xs[j]
            y = pi.ys[i]
            distribution_buffer[i, j] = w * pi.distribution(x - b, y - p) * 0.25
        end

        for j in 1:m, i in 1:n
            result[i, j] +=
                distribution_buffer[i, j] +
                distribution_buffer[i + 1, j] +
                distribution_buffer[i, j + 1] +
                distribution_buffer[i + 1, j + 1]
        end
    end
    return result
end
