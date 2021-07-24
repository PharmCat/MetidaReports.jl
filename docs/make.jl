using Documenter, Metida
#using DocumenterLaTeX

makedocs(
    modules = [MetidaReports],
    sitename = "MetidaReports.jl",
    authors = "Vladimir Arnautov",
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(repo = "github.com/PharmCat/MetidaReports.jl.git", push_preview = true,
)
