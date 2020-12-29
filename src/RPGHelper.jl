module RPGHelper
import Random


include("diceroll.jl")



roll(v, args...) = roll(Random.GLOBAL_RNG, v, args...)
export minroll, maxroll, meanroll, roll

end # module
