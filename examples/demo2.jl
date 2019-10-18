using ElectronProgressBars
using Juno
using Logging

function demo(delay; title="delay=$delay", n = 3, m = 50)
    Juno.progress(name="$title (outer)") do id
        for i in 1:n
            Juno.progress(name="$title (inner)") do id
                for j in 1:m
                    @debug "$title (inner)" progress=j/m _id=id
                    sleep(delay)
                end
            end
            @debug "$title (outer)" progress=i/n _id=id
        end
    end
end

with_logger(ElectronProgressBars.get_logger()) do
    @sync begin
        @async demo(0.01)
        @async demo(0.02)
    end
end

with_logger(ElectronProgressBars.get_logger()) do
    @sync begin
        Threads.@spawn demo(0.01)
        Threads.@spawn demo(0.02)
    end
end
