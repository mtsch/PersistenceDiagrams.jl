"""
    PersistenceCurve

Persistence curves offer a general way to transform a persistence diagram into a vector of
numbers.

This is done by first splitting the time domain into buckets. Then the intervals contained
in the bucket are collected and transformed by applying `fun` to each of them. The result is
then summarized with the `stat` function. If an interval is only parially contained in a
bucket, it is counted partially.

Once a `PersistenceCurve` is constructed (see below), it can be called to convert a
persistence diagram to a vector of floats.

# Constructors

* `PersistenceCurve(fun, stat, start, stop; length=10, integrate=true, normalize=false)`:
  `length` buckets with the first strating on `t_start` and the last ending on `t_end`.
* `PersistenceCurve(fun, stat, diagrams; length=10, integreate=true, normalize=false)`:
  learn the `start` and `stop` parameters from a collection of persistence diagrams.

## Arguments

* `length`: the length of the output. Defaults to 10.
* `fun`: the function applied to each interval. Must have the following signature.
  `fun(::AbstractPersistenceInterval, ::PersistenceDiagram, time)::T`
* `stat`: the summary function applied the results of `fun`. Must have the following
  signature. `stat(::Vector{T})::Float64`
* `normalize`: if set to `true`, normalize the result. Does not work for time-dependent
  `fun`s. Defaults to `false`. Normalization is performed by dividing all values by
  `stat(fun.(diag))`.
* `integrate`: if set to `true`, the amount of overlap between an interval and a bucket is
  considered. This prevents missing very small bars, but does not work correctly for curves
  with time-dependent `fun`s where `stat` is a selection function (such as landscapes). If
  set to `false`, the curve is simply sampled at midpoints of buckets. Defaults to `true`.

# Call

    (::PersistenceCurve)(diagram; normalize, integrate)

Transforms a diagram. `normalize` and `integrate` override defaults set in constructor.

# Example

```jldoctest
julia> diagram = PersistenceDiagram([(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)]);

julia> curve = BettiCurve(0, 2, length = 4)
PersistenceCurve(always_one, sum, 0.0, 2.0; length=4, normalize=false, integrate=true)

julia> curve(diagram)
4-element Array{Float64,1}:
 1.0
 3.2
 2.0
 1.0
```

# See Also

The following are equivalent to `PersistenceCurve` with appropriately selected `fun` and
`stat` arguments.

* [`BettiCurve`](@ref)
* [`Landscape`](@ref)
* [`Silhuette`](@ref)
* [`Life`](@ref)
* [`Midlife`](@ref)
* [`LifeEntropy`](@ref)
* [`MidlifeEntropy`](@ref)
* [`PDThresholding`](@ref)

More options listed in Table 1 on page 9 of reference.

# Reference

Chung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing
persistence diagrams. [arXiv preprint arXiv:1904.07768](https://arxiv.org/abs/1904.07768).
"""
struct PersistenceCurve{F,S}
    fun::F
    stat::S
    integrate::Bool
    normalize::Bool
    start::Float64
    stop::Float64
    step::Base.TwicePrecision{Float64}
    length::Int

    function PersistenceCurve(
        fun, stat, start, stop; length=10, integrate=true, normalize=false
    )
        step = range(start, stop; length=length + 1).step
        return new{typeof(fun),typeof(stat)}(
            fun, stat, integrate, normalize, start, stop, step, length
        )
    end
end

function PersistenceCurve(fun, stat, diagrams; length=10, integrate=true, normalize=false)
    t_min = minimum(birth(int) for int in Iterators.flatten(diagrams))
    t_max = maximum(death(int) for int in Iterators.flatten(diagrams) if isfinite(int))

    if any(!isfinite, Iterators.flatten(diagrams))
        # Infinite interval could be born after all others die.
        max_birth = maximum(birth(int) for int in Iterators.flatten(diagrams))
        t_max = max(max_birth, t_max)
        # Add additional bucket for infinite intervals.
        t_max += (t_max - t_min) / (length - 1)
    end

    return PersistenceCurve(
        fun, stat, t_min, t_max; length=length, integrate=integrate, normalize=normalize
    )
end

_nameof(f::Function) = nameof(f)
_nameof(::T) where T = nameof(T)

function Base.show(io::IO, curve::PersistenceCurve)
    fname = _nameof(curve.fun)
    sname = _nameof(curve.stat)
    print(io, "PersistenceCurve(",
          join((fname, sname, string(curve.start), string(curve.stop)), ", "),
          "; length=", curve.length,
          ", normalize=", curve.normalize,
          ", integrate=", curve.integrate,
          ")")
end

Base.firstindex(bc::PersistenceCurve) = 1
Base.lastindex(bc::PersistenceCurve) = bc.length
Base.length(bc::PersistenceCurve) = bc.length
Base.eachindex(bc::PersistenceCurve) = Base.OneTo(bc.length)
function Base.getindex(bc::PersistenceCurve, i::Integer)
    0 < i ≤ bc.length || throw(BoundsError(bc, i))
    return Float64(bc.start + i * bc.step - bc.step / 2)
end
function Base.getindex(bc::PersistenceCurve, is)
    return [bc[i] for i in is]
end

function Base.iterate(bc::PersistenceCurve, i=1)
    if i ≤ length(bc)
        return bc[i], i + 1
    else
        return nothing
    end
end

function _value_at!(buff, f, s, diag, t)
    empty!(buff)
    for int in diag
        if birth(int) ≤ t < death(int)
            val = f(int, diag, t)
            if isfinite(val)
                push!(buff, val)
            else
                error("Invalid value $val produced. Please remove infinite intervals")
            end
        end
    end
    if isempty(buff)
        return 0.0
    else
        return s(buff)
    end
end

function (curve::PersistenceCurve)(
    diag; integrate=curve.integrate, normalize=curve.normalize
)
    result = integrate ? _integrate(curve, diag) : _sample(curve, diag)
    if normalize
        norm = curve.stat([curve.fun(int, diag, nothing) for int in diag])
        return result ./ norm
    else
        return result
    end
end

function _sample(curve, diag)
    buff = Float64[]
    return map(eachindex(curve)) do i
        _value_at!(buff, curve.fun, curve.stat, diag, curve[i])
    end
end

function _integrate(curve, diag)
    ts = unique!(sort!(collect(Iterators.flatten(diag)); rev=true))
    pushfirst!(ts, Inf)
    buff = Float64[]
    lo_exact = curve.start
    hi_exact = curve.start + curve.step
    return map(eachindex(curve)) do i
        lo, hi = Float64(lo_exact), Float64(hi_exact)
        t1, t2 = lo, min(hi, last(ts))
        δ = (t2 - t1) / (hi - lo)
        result = _value_at!(buff, curve.fun, curve.stat, diag, (t1 + t2) / 2) * δ
        while !isempty(ts) && last(ts) < Float64(hi)
            t1 = pop!(ts)
            t2 = min(last(ts), Float64(hi))
            δ = (t2 - t1) / (hi - lo)
            result += _value_at!(buff, curve.fun, curve.stat, diag, (t1 + t2) / 2) * δ
        end
        lo_exact += curve.step
        hi_exact += curve.step
        return result
    end
end

"""
    BettiCurve

Betti curves count the Betti numbers at each time step. Unlike most vectorization methods,
they support infinite intervals.

    fun(_, _, _) = 1.0
    stat = sum

# See also

[`PersistenceCurve`](@ref)
"""
function BettiCurve(args...; kwargs...)
    return PersistenceCurve(always_one, sum, args...; kwargs...)
end
always_one(_...) = 1.0

"""
    Life

The life curve.

    fun((b, d), _, _) = d - b
    stat = sum

# See also

[`PersistenceCurve`](@ref)

# Reference

Chung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing
persistence diagrams. [arXiv preprint arXiv:1904.07768](https://arxiv.org/abs/1904.07768).
"""
function Life(args...; kwargs...)
    return PersistenceCurve(life, sum, args...; kwargs...)
end
life((b, d), _, _) = d - b

"""
    Midlife

The midlife curve.

    fun((b, d), _, _) = (b + d) / 2
    stat = sum

# See also

[`PersistenceCurve`](@ref)

# Reference

Chung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing
persistence diagrams. [arXiv preprint arXiv:1904.07768](https://arxiv.org/abs/1904.07768).
"""
function Midlife(args...; kwargs...)
    return PersistenceCurve(midlife, sum, args...; kwargs...)
end
midlife((b, d), _, _) = (b + d) / 2

"""
    LifeEntropy

The life entropy curve.

    fun((b, d), diag, _) = begin
        x = (d - b) / sum(d - b for (b, d) in diag)
        -x * log2(x)
    end
    stat = sum

# See also

[`PersistenceCurve`](@ref)

# Reference

Atienza, N., González-Díaz, R., & Soriano-Trigueros, M. (2018). On the stability of
persistent entropy and new summary functions for TDA. [arXiv preprint
arXiv:1803.08304](https://arxiv.org/abs/1803.08304).
"""
function LifeEntropy(args...; kwargs...)
    return PersistenceCurve(life_entropy, sum, args...; kwargs...)
end
function life_entropy((b, d), diag, _)
    x = (d - b) / sum(d - b for (b, d) in diag)
    return x == 0 ? 0.0 : -x * log2(x)
end

"""
    MidlifeEntropy

The midlife entropy curve.

    fun((b, d), diag, _) = begin
        x = (b + d) / sum(b + d for (d, b) in diag)
        -x * log2(x)
    end
    stat = sum

# See also

[`PersistenceCurve`](@ref)

# Reference

Chung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing
persistence diagrams. [arXiv preprint arXiv:1904.07768](https://arxiv.org/abs/1904.07768).
"""
function MidlifeEntropy(args...; kwargs...)
    return PersistenceCurve(midlife_entropy, sum, args...; kwargs...)
end
function midlife_entropy((b, d), diag, _)
    x = (d + b) / sum((d + b) for (d, b) in diag)
    return x == 0 ? 0.0 : -x * log2(x)
end

"""
    PDThresholding

The persistence diagram thresholding function.

    fun((b, d), _, t) = (d - t) * (t - b)
    stat = mean

# See also

[`PersistenceCurve`](@ref)

# Reference

Chung, Y. M., & Day, S. (2018). Topological fidelity and image thresholding: A persistent
homology approach. Journal of Mathematical Imaging and Vision, 60(7), 1167-1179.
"""
function PDThresholding(args...; kwargs...)
    return PersistenceCurve(thresholding, mean, args...; kwargs...)
end
thresholding((b, d), _, t) = (d - t) * (t - b)

"""
    Landscape(k, args...)

The `k`-th persistence landscape.

    fun((b, d), _, t) = max(min(t - b, d - t), 0)
    stat = get(sort(values, rev=true), k, 0.0)

# See also

[`PersistenceCurve`](@ref)
[`Landscapes`](@ref)

# Reference

Bubenik, P. (2015). Statistical topological data analysis using persistence landscapes. [The
Journal of Machine Learning Research, 16(1),
77-102](http://www.jmlr.org/papers/volume16/bubenik15a/bubenik15a.pdf).
"""
function Landscape(k, args...; length=10)
    if k < 1
        throw(ArgumentError("`k` must be positive"))
    end
    return PersistenceCurve(
        landscape, k_max(k), args...; length=10, integrate=false, normalize=false
    )
end
landscape((b, d), _, t) = max(min(t - b, d - t), 0)
struct k_max
    k::Int
end
(m::k_max)(values) = get(sort(values, rev=true), m.k, 0.0)

"""
    Landscapes(n, args...)

The first `n` persistence landscapes.

    fun((b, d), _, t) = max(min(t - b, d - t), 0)
    stat = get(sort(values, rev=true), k, 0.0)

Vectorizes to a matrix where each column is a landscape.

# See also

[`PersistenceCurve`](@ref)
[`Landscape`](@ref)

# Reference

Bubenik, P. (2015). Statistical topological data analysis using persistence landscapes. [The
Journal of Machine Learning Research, 16(1),
77-102](http://www.jmlr.org/papers/volume16/bubenik15a/bubenik15a.pdf).
"""
struct Landscapes
    landscapes::Vector{PersistenceCurve{typeof(landscape), k_max}}

    function Landscapes(n::Int, args...; kwargs...)
        if n < 1
            throw(ArgumentError("`n` must be positive"))
        end
        landscapes = map(1:n) do i
            Landscape(i, args...; kwargs...)
        end
        return new(landscapes)
    end
end

function Base.show(io::IO, ls::Landscapes)
    l = first(ls.landscapes)
    print(io, "Landscapes(",
          join((length(ls.landscapes), string(l.start), string(l.stop)), ", "),
          "; length=", l.length, ")")
end

function (ls::Landscapes)(diagram)
    return mapreduce(l -> l(diagram), hcat, ls.landscapes)
end

"""
    Silhuette

The sum of persistence landscapes for all values of `k`.

    fun((b, d), _, t) = max(min(t - b, d - t), 0)
    stat = sum

# See also

[`PersistenceCurve`](@ref)
[`Landscape`](@ref)
[`Landscapes`](@ref)
"""
function Silhuette(args...; length=10, integrate=true)
    return PersistenceCurve(landscape, sum, args...; length=length, integrate=integrate)
end
