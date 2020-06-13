struct DefaultWeightingFunction
    b::Float64
end
function (dwf::DefaultWeightingFunction)(_, y)
    if y ≤ 0
        return 0.0
    elseif 0 < y < dwf.b
        return y/dwf.b
    else
        return 1.0
    end
end

struct Binormal
    sigma::Float64
end
function (bi::Binormal)(x, y)
    exp(-(x^2 + y^2) / (2bi.sigma^2)) / (bi.sigma^2 * 2π)
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

* `PersistenceImage(ylims, xlims; size=5, kwargs...)`
* `PersistenceImage(diagrams; size=5, kwargs...)`

## Arguments

* `ylims`, `xlims`: Limits of the square on which the image is created, both 2-tuples. Note
  that y comes first as this is the way arrays are indexed.
* `diagrams`: Collection of persistence diagrams. This constructor sets `ylims` and `xlims`
  according to minimum and maximum birth time and persistence time. Sets `slope_end` to
  maximum persistence time.

## Keyword Arguments

* `distribution`: A function or callable object used to smear each interval in diagram.  Has
  to be callable with two `Float64`s as input and should return a `Float64`. Defaults to a
  normal distribution with `sigma` equal to 1.
* `sigma`: The width of the gaussian distribution. Only applicable when `distribution` is
  unset.
* `weight`: A function or callable object used as the weighting function. Has to be callable
  with two `Float64`s as input and should return a `Float64`. Should equal 0.0 for x=0, but
  this is not enforced.
* `slope_end`: the ``y`` value at which the default weight function stops increasing.
* `size`: integer or tuple of two integers. Determines the size of the array containing the
  image. Defaults to 5.

# Example

```jldoctest
diag_1 = PersistenceDiagram(0, [(0, 1), (0, 1.5), (1, 2)])
diag_2 = PersistenceDiagram(0, [(1, 2), (1, 1.5)])
image = PersistenceImage([diag_1, diag_2])

# output

5×5 PersistenceImage(
  distribution = PersistenceDiagrams.Binormal(1.0),
  weight = PersistenceDiagrams.DefaultWeightingFunction(1.5)
)
```
```jldoctest
image(diag_1)

# output

5×5 Array{Float64,2}:
 0.266562  0.269891  0.264744  0.251762  0.232227
 0.294472  0.297554  0.291244  0.276314  0.254244
 0.31342   0.316057  0.308664  0.292136  0.268117
 0.32141   0.323446  0.315164  0.297554  0.272373
 0.31758   0.318928  0.310047  0.29199   0.266562
```
"""
struct PersistenceImage{X<:AbstractVector{Float64}, Y<:AbstractVector{Float64}, D, W}
    ys::Y
    xs::X
    distribution::D
    weight::W
end

function PersistenceImage(
    ys::AbstractArray{Float64}, xs::AbstractArray{Float64};
    sigma=nothing, distribution=nothing, weight=nothing, slope_end=nothing
)
    if !isnothing(sigma) && !isnothing(distribution)
        throw(ArgumentError(
            "`sigma` and `distribution` can't be specified at the same time"
        ))
    elseif !isnothing(sigma)
        distribution = Binormal(sigma)
    elseif !isnothing(distribution)
        distribution = distribution
    else
        distribution = Binormal(1)
    end
    if !isnothing(weight) && !isnothing(slope_end)
        throw(ArgumentError(
            "`weight` and `slope_end` can't be specified at the same time"
        ))
    elseif !isnothing(weight)
        weight = weight
    elseif !isnothing(slope_end)
        weight = DefaultWeightingFunction(slope_end)
    else
        weight = DefaultWeightingFunction(1)
    end

    return PersistenceImage(ys, xs, distribution, weight)
end
function PersistenceImage(ylims::Tuple, xlims::Tuple; size=5, kwargs...)
    s = length(size) == 1 ? (size, size) : size
    ys = range(ylims[1], ylims[2], length=s[1] + 1)
    xs = range(xlims[1], xlims[2], length=s[2] + 1)

    return PersistenceImage(ys, xs; kwargs...)
end
function PersistenceImage(diagrams; kwargs...)
    min_persistence = minimum(persistence(int) for int in Iterators.flatten(diagrams)
                              if isfinite(int))
    max_persistence = maximum(persistence(int) for int in Iterators.flatten(diagrams)
                              if isfinite(int))
    min_birth = minimum(birth(int) for int in Iterators.flatten(diagrams)
                        if isfinite(int))
    max_birth = maximum(birth(int) for int in Iterators.flatten(diagrams)
                        if isfinite(int))
    ylims = (min_persistence, max_persistence)
    xlims = (min_birth, max_birth)
    if :weight in keys(kwargs)
        PersistenceImage(ylims, xlims; kwargs...)
    else
        PersistenceImage(ylims, xlims; slope_end=max_persistence, kwargs...)
    end
end

function Base.show(io::IO, pi::PersistenceImage)
    print(io, "$(length(pi.ys) - 1)×$(length(pi.xs) - 1) PersistenceImage")
end
function Base.show(io::IO, ::MIME"text/plain", pi::PersistenceImage)
    println(io, pi, "(")
    println(io, "  distribution = ", pi.distribution, ",")
    println(io, "  weight = ", pi.weight)
    print(io, ")")
end

function (pi::PersistenceImage)(diagram::PersistenceDiagram)
    diagram = filter(isfinite, diagram)
    n = length(pi.ys) - 1
    m = length(pi.xs) - 1
    result = zeros(n, m)

    @inbounds for i in 1:m, j in 1:n
        for interval in diagram
            x_lo = pi.xs[i]
            x_hi = pi.xs[i + 1]
            y_lo = pi.ys[j]
            y_hi = pi.ys[j + 1]
            b = birth(interval)
            p = persistence(interval)
            w = pi.weight(b, p)

            pixel = (pi.distribution(x_lo - b, y_lo - p) * w +
                     pi.distribution(x_lo - b, y_hi - p) * w +
                     pi.distribution(x_hi - b, y_lo - p) * w +
                     pi.distribution(x_hi - b, y_hi - p) * w) / 4

            result[j, i] += pixel
        end
    end
    return result
end
