"""
    dim_str(diag)

Get `dim` as subscript string.
"""
function dim_str(diag)
    sub_digits = ("₀", "₁", "₂", "₃", "₄", "₅", "₆", "₇", "₈", "₉")
    return join(reverse(sub_digits[digits(dim(diag)) .+ 1]))
end
function clamp_death(int::PersistenceInterval, t_max)
    return isfinite(int) ? death(int) : t_max
end
function clamp_persistence(int::PersistenceInterval, t_max)
    return isfinite(int) ? persistence(int) : t_max
end

struct InfinityLine
    vertical::Bool
end

@recipe function f(::Type{InfinityLine}, infline::InfinityLine)
    if haskey(plotattributes, :infinity)
        if infline.vertical
            seriestype := :vline
        else
            seriestype := :hline
        end
        seriescolor := :grey
        line := :dot
        label := "∞"
        linewidth := 1

        [plotattributes[:infinity]]
    else
        label := ""
        [NaN]
    end
end

struct ZeroPersistenceLine end

@recipe function f(::Type{ZeroPersistenceLine}, ::ZeroPersistenceLine)
    seriescolor := :black

    if get(plotattributes, :persistence, false)
        seriestype := :hline
        [0]
    else
        seriestype := :line
        identity
    end
end

@recipe function f(::Type{D}, diag::D) where D<:AbstractArray{<:PersistenceInterval}
    if plotattributes[:letter] == :x
        return birth.(diag)
    elseif get(plotattributes, :persistence, false)
        return clamp_persistence.(diag, get(plotattributes, :infinity, Inf))
    else
        return clamp_death.(diag, get(plotattributes, :infinity, Inf))
    end
end

@recipe function f(::Type{Val{:persistencediagram}}, x, y, z)
    seriestype := :scatter
    markerstrokecolor --> :auto
    markeralpha --> 0.5
    x, y
end

function limits(diags, pers)
    xs = map.(birth, diags)
    if pers
        ys = map.(persistence, diags)
    else
        ys = map.(death, diags)
    end
    t_lo = min(minimum(t for t in Iterators.flatten((xs..., ys...))), 0.0)
    t_hi = maximum(t for t in Iterators.flatten((xs..., ys...)) if t < ∞)

    threshes = filter(isfinite, threshold.(diags))
    if !isempty(threshes)
        infinity = maximum(threshes)
    else
        infinity = t_hi * 1.25
    end
    if any(!isfinite, Iterators.flatten(ys))
        t_hi = infinity
    end

    return t_lo, t_hi, infinity
end

function set_default!(d, key, value)
    d[key] = get(d, key, value)
    return d
end

function setup_diagram_plot!(d, diags)
    set_default!(d, :persistence, false)
    t_lo, t_hi, infinity = limits(diags, d[:persistence])
    # Zero persistence line messes up the limits, so we attempt to reset them here.
    gap = (t_hi - t_lo) * 0.05
    if gap > 0
        set_default!(d, :xlims, (t_lo - gap, t_hi + gap))
        set_default!(d, :ylims, (t_lo - gap, t_hi + gap))
        set_default!(d, :aspect_ratio, 1)
    end
    set_default!(d, :infinity, infinity)

    set_default!(d, :xguide, "birth")
    set_default!(d, :yguide, d[:persistence] ? "persistence" : "death")
    set_default!(d, :legend, d[:persistence] ? :topright : :bottomright)
    set_default!(d, :title, "Persistence Diagram")
end

@recipe function f(diags::NTuple{<:Any, PersistenceDiagram})
    setup_diagram_plot!(plotattributes, diags)

    @series begin
        primary := false
        ZeroPersistenceLine()
    end
    @series begin
        InfinityLine(false)
    end

    different_dims = allunique(dim.(diags))
    for (i, diag) in enumerate(diags)
        @series begin
            seriestype := :persistencediagram
            if different_dims
                label --> "H$(dim_str(diag))"
                markercolor --> dim(diag)+1
            else
                label --> "H$(dim_str(diag)) ($i)"
            end
            diag, diag
        end
    end
end

function RecipesBase.plot(diags::Vararg{<:PersistenceDiagram}; kwargs...)
    return RecipesBase.plot(diags; kwargs...)
end
function RecipesBase.plot(diag::PersistenceDiagram; kwargs...)
    return RecipesBase.plot((diag,); kwargs...)
end

@recipe function f(match::Matching)
    left = match.left
    right = match.right
    setup_diagram_plot!(plotattributes, (left, right))
    inf = plotattributes[:infinity]

    @series begin
        label --> "matching"

        xs = Float64[]
        ys = Float64[]
        for (l, r) in matching(match, bottleneck=get(plotattributes, :bottleneck, false))
            append!(xs, (birth(l), birth(r), NaN))
            if plotattributes[:persistence]
                append!(ys, (clamp_persistence(l, inf), clamp_persistence(r, inf), NaN))
            else
                append!(ys, (clamp_death(l, inf), clamp_death(r, inf), NaN))
            end
        end
        xs, ys
    end

    @series begin
        primary := false
        InfinityLine(false)
    end
    @series begin
        primary := false
        ZeroPersistenceLine()
    end
    @series begin
        seriestype := :persistencediagram
        label --> "left"
        left, left
    end
    @series begin
        seriestype := :persistencediagram
        label --> "right"
        right, right
    end
end

struct Barcode
    diags::NTuple{<:Any, <:PersistenceDiagram}
end

@recipe function f(bc::Barcode)
    diags = bc.diags

    t_lo, t_hi, infinity = limits(diags, false)
    infinity --> infinity
    yticks --> []
    xguide --> "t"
    legend --> :outertopright
    title --> "Persistence Barcode"

    _bar_offset --> 0
    bar_offset = plotattributes[:_bar_offset]
    # Infinity line series messes up the limits.
    n_intervals = sum(length, diags) + bar_offset
    ylims --> (1 - n_intervals * 0.05, n_intervals * 1.05)

    @series begin
        InfinityLine(true)
    end
    different_dims = allunique(dim.(diags))
    for (i, diag) in enumerate(diags)
        @series begin
            seriestype := :path
            linewidth --> 1
            if different_dims
                label --> "H$(dim_str(diag))"
                markercolor --> dim(diag)+1
            else
                label --> "H$(dim_str(diag)) ($i)"
            end

            xs = Float64[]
            ys = Float64[]
            for int in diag
                bar_offset += 1
                b, d = birth(int), clamp_death(int, t_hi)
                append!(xs, (b, d, NaN))
                append!(ys, (bar_offset, bar_offset, NaN))
            end
            xs, ys
        end
    end
end


"""
    barcode(diagram)

Plot the barcode plot of persistence diagram or multiple diagrams diagrams. The `infinity`
keyword argument determines where the infinity line is placed. If unset, the function tries
to use `threshold(diagram)` or guess a good position to place the line at.
"""
barcode(args...; kwargs...) = RecipesBase.plot(Barcode(tuple(args...)); kwargs...)
"""
    barcode!(diagram)

Plot the barcode plot of persistence diagram or multiple diagrams diagrams. The `infinity`
keyword argument determines where the infinity line is placed. If unset, the function tries
to use `threshold(diagram)` or guess a good position to place the line at.
"""
barcode!(args...; kwargs...) = RecipesBase.plot!(Barcode(tuple(args...)); kwargs...)
