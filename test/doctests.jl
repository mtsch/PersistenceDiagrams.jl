using Documenter
using PersistenceDiagrams
using Test

if VERSION ≥ v"1.8-DEV" || VERSION < v"1.7-DEV"
    @warn "Doctests were set up on Julia v1.7. Skipping."
else
    DocMeta.setdocmeta!(
        PersistenceDiagrams, :DocTestSetup, :(using PersistenceDiagrams); recursive=true
    )
    doctest(PersistenceDiagrams)
end
