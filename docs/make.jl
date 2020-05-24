@info "build started."
using Documenter
using Literate
using PersistenceDiagrams
using Plots
gr()
ENV["GKSwstype"] = "100"

EXAMPLES_INPUT = joinpath(@__DIR__, "src/examples")
EXAMPLES_OUTPUT = joinpath(@__DIR__, "src/generated")

for example in readdir(EXAMPLES_INPUT, join=true)
    endswith(example, ".jl") || continue
    Literate.markdown(example, EXAMPLES_OUTPUT, documenter=true)
end

makedocs(sitename="PersistenceDiagrams.jl",
         format = Documenter.HTML(
             # Use clean URLs, unless built as a "local" build
             prettyurls = !("local" in ARGS),
             assets = ["assets/favicon.ico"],
         ),
         pages=[
             "Home" => "index.md",
             "API" => "api/diagrams.md",
         ])

deploydocs(
    repo = "github.com/mtsch/Ripserer.jl.git",
)
