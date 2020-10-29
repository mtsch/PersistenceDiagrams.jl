# PersistenceDiagrams.jl

This package provides the `PersistenceInterval` and `PersistenceDiagram` types as well as
some functions for working with them. If you want to compute persistence diagrams, please
see [Ripserer.jl](https://github.com/mtsch/Ripserer.jl). For examples and tutorials, see
the [Ripserer.jl docs](https://mtsch.github.io/Ripserer.jl/dev/).

## Overview

This package currently supports the following.

* Persistence diagram plotting.
* Bottleneck and Wasserstein matching and distance computation.
* Various vectorization methods including persistence images, betti curves, landscapes, and
  more (see [Vectorization](vectorization.md) for full list).
* Integration with [MLJ.jl](https://github.com/alan-turing-institute/MLJ.jl).
