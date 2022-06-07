module MetidaReports

    using StatsModels, DataFrames, Mustache
    import Base: ht_keyindex

    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
