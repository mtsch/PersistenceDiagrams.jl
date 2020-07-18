"""
    PersistenceCurves

Persistence curves offer a general way to transform a persistence diagram into a vector of
numbers.

This is done by first splitting the time domain into buckets. Then the intervals contained
in the bucket are collected and transformed by applying `fun` to each of them. The result is
then summarized with the `stat` function. If an interval is only parially contained in a
bucket, it is counted partially.

Once a `PersistenceCurve` is constructed (see below), it can be called to convert a
persistence diagram to a vector of floats.

# Constructors

* `PersistenceCurve(fun, stat, start, stop; length=10, integrate=true)`: `length` buckets
  with the first strating on `t_start` and the last ending on `t_end`.
* `PersistenceCurve(fun, stat, diagrams; length=10, integreate=true)`: learn the `start` and
  `stop` parameters from a collection of persistence diagrams.

`fun` and `stat` must have the following signatures:

* `fun(::AbstractPersistenceInterval, ::PersistenceDiagram, time::Float64)::T`
* `stat(::Vector{T})::Float64`

Use `integrate=true` when `stat` for a fixed collection of intervals is monotonous with
respect to time. For exaple, this is not the case for persistence landscapes.

# See Also

* [BettiCurve](@ref)
* [LifeEntropy](@ref)
* [DiagramThresholding](@ref)
* [Landscape](@ref)
* [Silhuette](@ref)
* [Life](@ref)
* [NormLife](@ref)
* [Midlife](@ref)
* [NormMidlife](@ref)

More options listed in Table 1 in reference.

# Reference

Chung, Y. M., & Lawson, A. (2019). Persistence curves: A canonical framework for summarizing
persistence diagrams. [arXiv preprint arXiv:1904.07768](https://arxiv.org/abs/1904.07768).
"""
struct PersistenceCurve{F, S}
    fun::F
    stat::S
    integrate::Bool
    start::Float64
    stop::Float64
    step::Base.TwicePrecision{Float64}
    length::Int

    function PersistenceCurve(fun, stat, start, stop; length=10, integrate=true)
        step = range(start, stop, length=length + 1).step
        return new{typeof(fun), typeof(stat)}(
            fun, stat, integrate, start, stop, step, length
        )
    end
end

function PersistenceCurve(fun, stat, diagrams; length=10, integrate=true)
    t_min = minimum(birth(int) for int in Iterators.flatten(diagrams))
    t_max = maximum(death(int) for int in Iterators.flatten(diagrams) if isfinite(int))

    if any(!isfinite, Iterators.flatten(diagrams))
        # Infinite interval could be born after all others die.
        max_birth = maximum(birth(int) for int in Iterators.flatten(diagrams))
        t_max = max(max_birth, t_max)
        # Add additional bucket for infinite intervals.
        t_max += (t_max - t_min) / (length - 1)
    end

    return PersistenceCurve(fun, stat, t_min, t_max; length=length, integrate=integrate)
end

Base.firstindex(bc::PersistenceCurve) = 1
Base.lastindex(bc::PersistenceCurve) = bc.length
Base.length(bc::PersistenceCurve) = bc.length
Base.eachindex(bc::PersistenceCurve) = Base.OneTo(bc.length)
function Base.getindex(bc::PersistenceCurve, i::Integer)
    0 < i ≤ bc.length || throw(BoundsError(bc, i))
    return Float64(bc.start + i * bc.step - bc.step/2)
end
function Base.getindex(bc::PersistenceCurve, is)
    return [bc[i] for i in is]
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

function (curve::PersistenceCurve)(diag; integrate=curve.integrate)
    integrate ? _integrate(curve, diag) : _sample(curve, diag)
end

function _sample(curve, diag)
    buff = Float64[]
    return map(eachindex(curve)) do i
        _value_at!(buff, curve.fun, curve.stat, diag, curve[i])
    end
end

function _integrate(curve, diag)
    ts = unique!(sort!(collect(Iterators.flatten(diag)), rev=true))
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

Equivalent to [PersistenceCurve](@ref) with `fun = _ -> 1` and `stat = sum`.

# Example

```jldoctest
diagram = PersistenceDiagram(0, [(0, 1), (0.5, 1), (0.5, 0.6), (1, 1.5), (0.5, Inf)])
curve = BettiCurve(0, 2, length = 4)
curve(diagram)

# output

4-element Array{Float64,1}:
 1.0
 3.2
 2.0
 1.0
```
"""
function BettiCurve(args...; kwargs...)
    return PersistenceCurve(always_one, sum, args...; kwargs...)
end

always_one(_...) = 1.0

"""
    Landscape(k, args...)

The k-th persistence landscape.

Equivalent to [PersistenceCurve](@ref) with `fun = ((b, d), _, t) -> min(t - b, d - t)` and
`stat = k_max`.

# Reference

Bubenik, P. (2015). Statistical topological data analysis using persistence landscapes. [The
Journal of Machine Learning Research, 16(1),
77-102](http://www.jmlr.org/papers/volume16/bubenik15a/bubenik15a.pdf).

# Example

```jldoctest
```
"""
function Landscape(k, args...; kwargs...)
    return PersistenceCurve(landscape_fun, k_max(k), args...; integrate=false, kwargs...)
end

landscape_fun(int, _, t) = max(min(t - birth(int), death(int) - t), 0)
struct k_max
    k::Int
end
(m::k_max)(values) = get(sort(values, rev=true), m.k, 0.0)

"""
    Silhuette

The sum of persistence landscapes for all values of `k`.

Equivalent to [PersistenceCurve](@ref) with `fun = ((b, d), _, t) -> min(t - b, d - t)` and
`stat = sum`.

# See also

[Landscape](@ref)
"""
function Silhuette(args...; kwargs...)
    return PersistenceCurve(landscape_fun, sum, args...; kwargs...)
end

# TODO:
# LifeEntropy
# Atienza, N., González-Díaz, R., & Soriano-Trigueros, M. (2018). On the stability of persistent entropy and new summary functions for TDA. [arXiv preprint arXiv:1803.08304](https://arxiv.org/abs/1803.08304).

# DiagramThresholding
# Chung, Y. M., & Day, S. (2018). Topological fidelity and image thresholding: A persistent homology approach. Journal of Mathematical Imaging and Vision, 60(7), 1167-1179.

#Life
#NormLife
#Midlife
#NormMidlife
