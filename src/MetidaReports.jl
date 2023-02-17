module MetidaReports

    using DataFrames, Mustache, JSON, Weave, GLM#, RegressionTables
    using MetidaBase, MetidaNCA#, MetidaStats
    using StatsModels
    import MetidaBase: Tables
    import Base: ht_keyindex

    export htmlexport

    path = dirname(@__FILE__)

    tplpath = joinpath(path, "jmd", "report.jmd")

    csspath = joinpath(path, "css", "main.css")

    include("json.jl")
    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
