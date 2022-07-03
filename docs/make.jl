using Documenter, MetidaReports, DataFrames, CSV
#using DocumenterLaTeX

makedocs(
    modules = [MetidaReports],
    sitename = "MetidaReports.jl",
    authors = "Vladimir Arnautov",
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ],
)

deploydocs(repo = "github.com/PharmCat/MetidaReports.jl.git", push_preview = true,
)
