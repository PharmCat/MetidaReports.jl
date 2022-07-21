module MetidaReports

    using DataFrames, Mustache, JSON
    using MetidaBase
    using StatsModels
    import MetidaBase: Tables
    import Base: ht_keyindex

    export htmlexport

    path = dirname(@__FILE__)

    tplpath = joinpath(path, "jmd", "report.jmd")

    include("json.jl")
    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
