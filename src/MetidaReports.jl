module MetidaReports

    using DataFrames, Mustache, JSON
    using MetidaBase
    using StatsModels
    import Base: ht_keyindex

    export htmlexport

    path = dirname(@__FILE__)
    
    include("json.jl")
    include("htmltpl.jl")
    include("export.jl")
    include("bioeq.jl")

end # module
