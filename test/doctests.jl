using Documenter
using PersistenceDiagrams
using Test

if VERSION ≥ v"1.6-DEV" || VERSION < v"1.5-DEV"
    @warn "Doctests were set up on Julia v1.5. Skipping."
else
    DocMeta.setdocmeta!(
        PersistenceDiagrams,
        :DocTestSetup,
        :(using PersistenceDiagrams);
        recursive=true,
    )
    doctest(PersistenceDiagrams)
end
