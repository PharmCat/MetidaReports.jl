using MetidaReports
using Test
using DataFrames, CSV, TypedTables

path     = dirname(@__FILE__)
io       = IOBuffer();


@testset "  Test" begin
    ds  = CSV.File(path*"/csv/rds1.csv") |> DataFrame
    pk  = CSV.File(path*"/csv/pkdata2.csv") |> DataFrame
    tab = CSV.File(path*"/csv/rds1.csv") |> Table

    table =  MetidaReports.htmlexport(ds; io = io)

    MetidaReports.nomissing(ds, :subject)
    # DataFrame
    be = MetidaReports.bioequivalence(ds; vars = nothing, subject = :subject,
    period = :period, formulation = :treatment,
    sequence = :sequence, design = Symbol("2x2x4"))
    # TypedTable
    be = MetidaReports.bioequivalence(tab; vars = nothing, subject = :subject,
    period = :period, formulation = :treatment,
    sequence = :sequence, design = Symbol("2x2x4"))

    be = MetidaReports.bioequivalence(ds; vars = :PK, subject = :subject,
    period = :period, formulation = :treatment,
    autoseq = true)

    ber = MetidaReports.bereport(pk)
    str = MetidaReports.htmlexport(ber.data; io = nothing, body = false, strout = true)

    MetidaReports.writereport(path, ber)
    @test true

end
