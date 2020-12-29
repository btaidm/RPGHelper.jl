using RPGHelper
using Documenter

makedocs(;
    modules=[RPGHelper],
    authors="Tim Bradt",
    repo="https://github.com/btaidm/RPGHelper.jl/blob/{commit}{path}#L{line}",
    sitename="RPGHelper.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://btaidm.github.io/RPGHelper.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/btaidm/RPGHelper.jl",
)
