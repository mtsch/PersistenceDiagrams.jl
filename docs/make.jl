@info "build started."
using Documenter
using PersistenceDiagrams

makedocs(;
    sitename="PersistenceDiagrams.jl",
    format=Documenter.HTML(
        # Use clean URLs, unless built as a "local" build;
        ;
        prettyurls=!("local" in ARGS),
        assets=["assets/favicon.ico"],
    ),
    pages=["Home" => "index.md", "API" => "api.md"],
    doctest=false, # Doctests are run as part of testing -- no need to run them twice.
)

deploydocs(; repo="github.com/mtsch/PersistenceDiagrams.jl.git")
