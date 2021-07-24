#using MetidaReports
using Test
using DataFrames, CSV, CategoricalArrays

path     = dirname(@__FILE__)
io       = IOBuffer();




@testset "  Test" begin
    ds  = CSV.File(path*"/csv/rds1.csv") |> DataFrame

    be = MetidaReports.bioquivalence(ds; variable = nothing, subject = :subject,
    period = :period, formulation = :treatment,
    sequence = :sequence, design = Symbol("2x2x4"))

end
