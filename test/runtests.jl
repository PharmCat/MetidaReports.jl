using MetidaReports
using Test
using DataFrames, CSV, TypedTables

path     = dirname(@__FILE__)
io       = IOBuffer();


@testset "  Test" begin
    ds  = CSV.File(path*"/csv/rds1.csv") |> DataFrame
    #pk  = CSV.File(path*"/csv/pkdata2.csv") |> DataFrame
    #tab = CSV.File(path*"/csv/rds1.csv") |> Table

    @test_nowarn table =  MetidaReports.htmlexport(ds; io = io)

end
