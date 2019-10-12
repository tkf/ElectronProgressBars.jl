module ElectronProgressBars

import JSON
import Logging
using ArgCheck: @argcheck
using Electron: Window, load
using Printf: @sprintf

function locking(f, l)
    lock(l)
    try
        return f()
    finally
        unlock(l)
    end
end

struct Vault{T, L}
    value::Base.RefValue{T}
    lock::L
end

Vault(ref::Ref) = Vault(ref, ReentrantLock())
Vault(value) = Vault(Ref(value))
Vault{T}() where T = Vault(Ref{T}())
Vault{T}(value) where T = Vault(Ref{T}(value))

locking(f, v::Vault) = locking(() -> f(v.value), v.lock)
Base.getindex(v::Vault) = locking(value -> value[], v)
Base.setindex!(v::Vault, x) = locking(value -> value[] = x, v)

_taskid() = objectid(current_task())

const TaskID = UInt64
const LogID = Symbol

struct ProgressBarWindow
    bars::Dict{TaskID, Vector{LogID}}
    window::Window
end

ProgressBarWindow() = ProgressBarWindow(
    Dict(),
    Window(
        main_html(),
        options = Dict(
            "title" => "Progress bars",
            "webPreferences" => Dict("webSecurity" => false),
        )
    ),
)

_isopen(::Nothing) = false
_isopen(w::ProgressBarWindow) = w.window.exists

mutable struct ElectronProgressBarLogger <: Logging.AbstractLogger
    window::ProgressBarWindow
    channel::Channel{Any}
end

function message_handler(ch)
    for f in ch
        try
            f()
        catch err
            @error "Error from function: $f" exception=(err, catch_backtrace())
        end
    end
end

inloggingtask(f, logger::ElectronProgressBarLogger) = put!(logger.channel, f)

ElectronProgressBarLogger() = ElectronProgressBarLogger(
    ProgressBarWindow(),
    Channel(message_handler),  # buffered?
)

function reopen!(logger::ElectronProgressBarLogger)
    new = ElectronProgressBarLogger()
    logger.window = new.window
    logger.channel = new.channel
    return logger
end

function Base.close(logger::ElectronProgressBarLogger)
    close(logger.window.window)
    close(logger.channel)
end

const _singleton_logger = Vault{Union{Nothing, ElectronProgressBarLogger}}(nothing)

singleton_logger() = locking(_singleton_logger) do value
    logger = value[]
    if logger === nothing
        value[] = logger = ElectronProgressBarLogger()
    elseif !_isopen(logger.window)
        reopen!(logger)
    end
    return logger
end

get_logger() = singleton_logger()

close_singleton_logger() = locking(_singleton_logger) do value
    logger = value[]
    if logger !== nothing && _isopen(logger.window)
        close(logger)
    end
end

function reopen_singleton_logger()
    close_singleton_logger()
    return singleton_logger()
end

_reload() =
    load(singleton_logger().window.window, main_html())

function main_html()
    main_json = joinpath(@__DIR__, "main.js")
    main_css = joinpath(@__DIR__, "main.css")
    return """
    <html>
        <head>
            <link rel="stylesheet" href="file://$main_css">
        </head>
        <body>
            <div id="container"></div>
            <script src="file://$main_json"></script>
        </body>
    </html>
    """
end

barid(taskid::TaskID, logid::LogID) = "bar-$taskid-$logid"

# for debugging
_gset_progress(
    progress::Real,
    logid::LogID = :dummy;
    title::AbstractString = "title",
    message::Union{AbstractString, Nothing} = nothing,
    kwargs...,
) =
    _set_progress(singleton_logger(), logid, title, progress, message; kwargs...)

function _set_progress(
    logger::ElectronProgressBarLogger,
    logid::LogID,
    title::AbstractString,
    progress::Real,
    message::Union{AbstractString, Nothing};
    taskid::TaskID = _taskid(),
)
    @argcheck 0 <= progress <= 1

    inloggingtask(logger) do
        w = logger.window
        param = (
            logid = logid,
            taskid = taskid,
            barid = barid(taskid, logid),
            title = title,
            message = message,
            progress = progress,
            progresstext = (@sprintf "%02.1f %%" 100 * progress),
        )

        bars = get!(w.bars, taskid, [])
        if isempty(bars)
            push!(bars, logid)
            p = JSON.json(param)
            run(w.window, "newRootBar($p)")
            return
        end

        idx = findfirst(==(logid), bars)
        if idx === nothing
            param = (
                parentid = barid(taskid, bars[end]),
                param...,
            )
            push!(bars, logid)
            p = JSON.json(param)
            run(w.window, "newSubBar($p)")
        else
            param = (
                finished = barid.(taskid, bars[idx + 1:end]),
                param...,
            )
            deleteat!(bars, idx + 1:length(bars))
            p = JSON.json(param)
            run(w.window, "setProgress($p)")
        end
    end
    return
end

# for debugging
_gremove_progress(logid::LogID = :dummy; kwargs...) =
    _remove_progress(singleton_logger(), logid; kwargs...)

function _remove_progress(
    logger::ElectronProgressBarLogger,
    logid::LogID;
    taskid::TaskID = _taskid(),
)
    inloggingtask(logger) do
        w = logger.window
        bars = get!(w.bars, taskid, [])
        isempty(bars) && return
        idx = findfirst(==(logid), bars)
        idx === nothing && return
        param = (
            logid = logid,
            taskid = taskid,
            barid = barid(taskid, logid),
            finished = barid.(taskid, bars[idx:end]),
        )
        deleteat!(bars, idx:length(bars))
        p = JSON.json(param)
        run(w.window, "removeFinished($p)")
    end
    return
end

# https://docs.julialang.org/en/latest/stdlib/Logging/#AbstractLogger-interface-1

function Logging.handle_message(
    logger::ElectronProgressBarLogger,
    level, title, _module, group, id, file, line;
    progress = nothing,
    message = nothing,
    _...
)
    if progress isa Real && progress <= 1
        _set_progress(logger, id, title, max(0.0, progress), message)
    elseif progress == "done" || (progress isa Real && progress > 1)
        _remove_progress(logger, id)
    end
    return nothing
end

Logging.shouldlog(::ElectronProgressBarLogger, level, _module, group, id) =
    true

Logging.min_enabled_level(::ElectronProgressBarLogger) = Logging.BelowMinLevel

end # module
