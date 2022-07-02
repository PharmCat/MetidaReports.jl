module MetidaReports

    using StatsModels, DataFrames, Mustache, JSON
    import Base: ht_keyindex

    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
