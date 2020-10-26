using MLJBase
using PersistenceDiagrams
using PersistenceDiagrams.MLJPersistenceDiagrams
using Suppressor
using Tables
using Test

diagrams = (
    dim_0=[
        PersistenceDiagram([(0.0, Inf), (0.0, 1.0)]),
        PersistenceDiagram([(0.0, Inf), (0.0, 1.5)]),
    ],
    dim_1=[
        PersistenceDiagram([(0.0, 1.0), (1.2, 2.0)]),
        PersistenceDiagram([(1.0, 1.1), (1.3, 1.9)]),
    ],
)
table = MLJBase.table(diagrams)

n_rows(x) = length(Tables.rows(x))
n_cols(x) = length(Tables.columnnames(x))

"""
    test_clean(model_type, kwargs; expect_warning=true)

Tests that for given model and kwargs:

* cleaning shows warning if `expect_warning=true`.
* cleaning the second time does not change anything and does not give warnings.
"""
function test_clean(model_type, kwargs; expect_warning=true)
    @testset "`clean!` with $kwargs" begin
        # Does clean warn?
        local model
        warning = @capture_err begin
            model = model_type(; kwargs...)
        end
        if expect_warning
            @test warning ≠ ""
        else
            @test warning == ""
        end

        # Cleaning again should not warn and should not change anything.
        prev_model = deepcopy(model)
        warning = clean!(model)
        @test warning == ""
        for field in fieldnames(model_type)
            @test getfield(model, field) == getfield(prev_model, field)
        end
    end
end

@testset "PersistenceImageVectorizer" begin
    for kwargs in (NamedTuple(), (sigma=0.1, slope_end=0.5, height=7), (sigma=0.1, width=6))
        model = PersistenceImageVectorizer(; kwargs...)
        mach = machine(model, table)
        fit!(mach; verbosity=0)
        res = transform(mach, table)

        @test n_rows(res) == 2
        @test n_cols(res) == model.width * model.height + model.height
    end

    for faulty_kwargs in (
        (; width=0),
        (; height=0),
        (; distribution="a"),
        (; weight=1),
        (; sigma=0),
        (; slope_end=2),
        (; margin=-1),
        (; sigma=1, distribution=(+)),
        (; weight=(_, _) -> 0, slope_end=0.5),
        (; distribution=(_, _) -> 0, sigma=1),
    )
        test_clean(PersistenceImageVectorizer, faulty_kwargs; expect_warning=true)
    end
    for good_kwargs in (
        NamedTuple(),
        (; width=5, height=10),
        (; sigma=1, slope_end=0.2),
        (; distribution=(_, _) -> 0, slope_end=0.001),
        (; weight=(_, _) -> 0, sigma=0.9, width=13),
        (; zero_start=true),
        (; margin=0),
    )
        test_clean(PersistenceImageVectorizer, good_kwargs; expect_warning=false)
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
    birth_fun(i, _, _) = birth(i)
    for faulty_kwargs in (
        (; curve=:betti, fun=birth_fun),
        (; curve=:life, stat=mean),
        (; curve=:midlife, fun=birth_fun, stat=mean),
        (; curve=:life_entropy, fun=birth_fun),
        (; curve=:midlife_entropy, stat=mean),
        (; curve=:pd_thresholding, normalize=true),
        (; curve=:silhuette, normalize=true),
        (; curve=:something),
        (; length=0),
        (; length=-1),
    )
        test_clean(PersistenceCurveVectorizer, faulty_kwargs; expect_warning=true)
    end
    for good_kwargs in (
        NamedTuple(),
        (; curve=:custom),
        (; curve=:betti, length=100),
        (; curve=:life),
        (; curve=:midlife, normalize=false),
        (; curve=:life_entropy, normalize=true),
        (; curve=:midlife_entropy, integrate=false),
        (; curve=:pd_thresholding, integrate=true),
        (; curve=:silhuette, length=10),
        (; fun=birth_fun),
        (; stat=mean),
        (; fun=birth_fun, stat=mean, curve=:custom),
    )
        test_clean(PersistenceCurveVectorizer, good_kwargs; expect_warning=false)
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
    for faulty_kwargs in ((; length=-1), (; n_landscapes=0), (; length=0, n_landscapes=-1))
        test_clean(PersistenceLandscapeVectorizer, faulty_kwargs; expect_warning=true)
    end
    for good_kwargs in
        (NamedTuple(), (; length=100), (; n_landscapes=4), (; n_landscapes=3, length=15))
        test_clean(PersistenceLandscapeVectorizer, good_kwargs; expect_warning=false)
    end
end
