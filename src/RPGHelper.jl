module RPGHelper
import Random


include("diceroll.jl")
include("tables.jl")



roll(v, args...; kwargs...) = roll(Random.GLOBAL_RNG, v, args...; kwargs...)
roll(::AbstractRNG, x) = x
Base.:!(d) = roll(d)

export minroll, maxroll, meanroll, roll

end # module
