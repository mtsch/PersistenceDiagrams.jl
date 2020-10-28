# v0.8.0

* Split base functionality into
  [PersistenceDiagramsBase.jl](https://github.com/mtsch/PersistenceDiagramsBase.jl).
* `PersistenceDiagram`s and `PersistenceInterval`s are no longer specialized on metadata
  types. This generally makes them easier to work with.
* `PersistenceImage` changes:
  - `slope_end` is now relative to maximum persistence shown in image,
  - default value of `sigma` changed to 2× pixel size (in the larger direction),
  - improved performance.
* Added `Landscapes`.
* Experimental integration with [MLJ.jl](https://github.com/alan-turing-institute/MLJ.jl).
