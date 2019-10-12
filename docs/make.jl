using Documenter, ElectronProgressBars

makedocs(;
    modules=[ElectronProgressBars],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/tkf/ElectronProgressBars.jl/blob/{commit}{path}#L{line}",
    sitename="ElectronProgressBars.jl",
    authors="Takafumi Arakaki <aka.tkf@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/tkf/ElectronProgressBars.jl",
)
