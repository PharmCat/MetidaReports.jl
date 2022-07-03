module MetidaReports

    using StatsModels, DataFrames, Mustache, JSON
    import Base: ht_keyindex

    export htmlexport

    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
