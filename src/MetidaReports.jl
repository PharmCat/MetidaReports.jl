module MetidaReports

    using DataFrames, JSON, Mustache, Printf
    #using Mustache, JSON, Weave, GLM#, RegressionTables
    #using MetidaBase, MetidaNCA, MetidaFreq#, MetidaStats
    #using StatsModels
    #import MetidaBase: Tables, DataSet, getdata
    import Base: ht_keyindex
    #import MetidaFreq: ConTab

    export htmlexport

    path = dirname(@__FILE__)

    tplpath = joinpath(path, "jmd", "report.jmd")

    csspath = joinpath(path, "css", "main.css")

    include("json.jl")
    include("htmltpl.jl")
    include("export.jl")
    #include("bioeq.jl")

end # module
