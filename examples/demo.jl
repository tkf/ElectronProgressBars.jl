using ElectronProgressBars
using Juno
using Logging

with_logger(ElectronProgressBars.get_logger()) do
    n = 3
    m = 50
    Juno.progress(name="outer") do id
        for i in 1:n
            @debug "outer" progress=i/n _id=id
            Juno.progress(name="outer") do id
                for j in 1:m
                    @debug "inner" progress=j/m _id=id
                    sleep(0.01)
                end
            end
        end
    end
end
