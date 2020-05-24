# # Basics

# In this section, we will show the basic usage, construction and plotting of persistence
# intervals and diagrams. We start by importing the library.

using PersistenceDiagrams

# A `PersistenceDiagram` is composed of persistence intervals, so we will introduce those
# first.

finite_interval = PersistenceInterval(1, 2)

# We can access, the birth death and persistence of the interval with the appropriately
# named functions.

birth(finite_interval), death(finite_interval), persistence(finite_interval)

# To represent infinite intervals, we introduce the type `Infinity`, which allows us to
# represent infinite intervals when the `eltype` of the interval is not a float and as such
# has no native representation of infinity.

infinite_interval = PersistenceInterval(0, ∞)

# The finiteness of the interval can be checked with the `isfinite` function from `Base`.

isfinite(infinite_interval)

# A persistence interval can also have a representative attached. There are no limitations
# on what type the representative can be, but it's intended to be used with things such as
# representative cycles.

interval_with_rep = PersistenceInterval(3, 7, [1, 2, 3])

#

representative(interval_with_rep)

# A `PersistenceDiagram` is essentially the same as a `Vector` of `PersistenceInterval`, but
# again has additional information attached. A diagram can be constructed as follows.

diagram_1 = PersistenceDiagram(0, [finite_interval, infinite_interval])

# We can access the dimension of a diagram with the `dim` function.

dim(diagram_1)

# Functions that work on arrays should all work on `PersistenceDiagram`s as well.

sort(diagram_1, by=death, rev=true)

#

diagram_1[1]

# Optionally, we can add a threshold to the diagram. The threshold is currently only used in
# plotting. We will show the effect of the `threshold` argument later.

diagram_1_thresh = PersistenceDiagram(0, [finite_interval, infinite_interval], threshold=5)

#

threshold(diagram_1_thresh)

#

threshold(diagram_1)

# Alternatively, we can also construct a diagram by passing it an array of tuples.

diagram_2 = PersistenceDiagram(1, [(0, 1), (4, 7), (5, ∞)])

# We plot a diagram by calling the `plot` function from
# [Plots.jl](https://github.com/JuliaPlots/Plots.jl).

using Plots
gr() # hide

plot(diagram_1_thresh)

# Note that the infinty line was placed at the value of the `threshold`.

# Passing `persistence=true` will plot the diagram in a birth vs. persistence coordinates.

plot(diagram_1, persistence=true)

# To plot the diagram as a barcode, we use the `barcode` function.

barcode(diagram_2)

# If we want to plot multiple diagrams on the same plot, simply pass an array of
# `PersistenceDiagram`s or multiple arguments to the functions.

plot([diagram_1_thresh, diagram_2])

#

barcode(diagram_1_thresh, diagram_2)
