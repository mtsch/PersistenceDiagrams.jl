"""
    BettiCurve

A betti curve is a simple way of transforming a persistence diagram to a vector of real
numbers. A `BettiCurve` `bc` splits the barcode of a diagram into `length(bc)` buckets,
counting the number of bars in each bucket. If only a part of a bar is contained in a
bucket, it is only partially counted.

Once a `BettiCurve` is constructed (see below), it can be called to convert a persistence
diagram to a vector of floats.

Unlike most diagram vectorization methods, `BettiCurve` can handle infinite intervals.

# Constructors

* `BettiCurve(t_start, t_end; length=10)`: `length` buckets with the first strating on
  `t_start` and the last ending on `t_end`.
* `BettiCurve(diagrams; length=10)`: learn the `t_start` and `t_end` parameters from a
  collection of persistence diagrams.
* `BettiCurve(buckets)`: manually select the buckets. `buckets` should be an
  `AbstractVector` of length one higher than the desired output size.

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
struct BettiCurve{V<:AbstractVector{Float64}}
    buckets::V
end

function BettiCurve(t_start, t_end; length=10)
    return BettiCurve(range(t_start, t_end, length=length + 1))
end
function BettiCurve(diagrams; length=10)
    t_min = minimum(birth(int) for int in Iterators.flatten(diagrams))
    t_max = maximum(death(int) for int in Iterators.flatten(diagrams) if isfinite(int))

    if any(!isfinite, Iterators.flatten(diagrams))
        # Infinite interval could be born after all others die.
        max_birth = maximum(birth(int) for int in Iterators.flatten(diagrams))
        t_max = max(max_birth, t_max)
        # Add additional bucket for infinite intervals.
        t_max += (t_max - t_min) / (length - 1)
    end

    return BettiCurve(range(t_min, t_max, length=length + 1))
end

Base.length(bc::BettiCurve) = length(bc.buckets) - 1
Base.getindex(bc::BettiCurve, i) = (bc.buckets[i], bc.buckets[i + 1])

function (bc::BettiCurve)(diag)
    result = zeros(length(bc))

    for (birth, death) in diag
        for i in eachindex(result)
            lo, hi = bc[i]
            width = hi - lo
            if hi > birth && death > lo
                overlap = width - max(birth - lo, 0) - max(hi - death, 0)
                result[i] += overlap / width
            end
        end
    end
    return result
end
