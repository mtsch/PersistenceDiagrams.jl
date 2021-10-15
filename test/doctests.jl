using Documenter
using PersistenceDiagrams
using Test

if VERSION ≥ v"1.7-DEV" || VERSION < v"1.6-DEV"
    @warn "Doctests were set up on Julia v1.6. Skipping."
else
    DocMeta.setdocmeta!(
        PersistenceDiagrams, :DocTestSetup, :(using PersistenceDiagrams); recursive=true
    )
    doctest(PersistenceDiagrams)
end
