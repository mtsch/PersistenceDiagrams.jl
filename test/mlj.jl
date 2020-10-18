using MLJBase
using PersistenceDiagrams
using PersistenceDiagrams.MLJPersistenceDiagrams
using Tables
using Test

diagrams = (
    dim_0=[PersistenceDiagram([(0, Inf), (0, 1)]), PersistenceDiagram([(0, Inf), (0, 1.5)])],
    dim_1=[
        PersistenceDiagram([(0, 1), (1.2, 2)]), PersistenceDiagram([(1, 1.1), (1.3, 1.9)])
    ],
)
table = MLJBase.table(diagrams)

n_rows(x) = length(Tables.rows(x))
n_cols(x) = length(Tables.columnnames(x))

@testset "PersistenceImageVectorizer" begin
    for kwargs in (NamedTuple(), (sigma=0.1, slope_end=0.5, height=7), (sigma=0.1, width=6))
        model = PersistenceImageVectorizer(; kwargs...)
        mach = machine(model, table)
        fit!(mach; verbosity=0)
        res = transform(mach, table)

        @test n_rows(res) == 2
        @test n_cols(res) == model.width * model.height * 2
    end
end

@testset "PersistenceCurveVectorizer" begin
    for kwargs in (
        NamedTuple(),
        (length=15, normalize=true),
        (integrate=false, curve=:midlife),
        (length=3, curve=:midlife_entropy),
    )
        model = PersistenceCurveVectorizer(; kwargs...)
        mach = machine(model, table)
        fit!(mach; verbosity=0)
        res = transform(mach, table)

        @test n_rows(res) == 2
        @test n_cols(res) == model.length * 2
    end
end

@testset "PersistenceLandscapeVectorizer" begin
    for kwargs in (NamedTuple(), (length=15, n_landscapes=5), (; n_landscapes=3))
        model = PersistenceLandscapeVectorizer(; kwargs...)
        mach = machine(model, table)
        fit!(mach; verbosity=0)
        res = transform(mach, table)

        @test n_rows(res) == 2
        @test n_cols(res) == model.length * model.n_landscapes * 2
    end
end
