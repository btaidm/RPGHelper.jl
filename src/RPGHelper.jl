module RPGHelper

import Random
export roll
include("diceroll.jl")
include("tables.jl")

for d in (2, 4, 6, 8, 10, 12, 20, 100)
	@eval begin
		const $(Symbol(:d, d)) = Die($(d))
		export $(Symbol(:d, d))
	end
end

roll(v, args...) = roll(Random.GLOBAL_RNG, v, args...)
roll(rng::Random.AbstractRNG, v) = v
roll(rng::Random.AbstractRNG, d::AbstractDie, sum::Bool = true) = roll(rng, d, Val{sum}())
roll(rng::Random.AbstractRNG, d::AbstractDie, ::Val{true}) = sum(roll(rng, d, Val{false}()))
roll(rng::Random.AbstractRNG, d::AbstractDie, ::Val{false}) = rand(rng, d)

roll(rng::Random.AbstractRNG, tab::Table) = roll(rng, tab.table[roll(rng, tab.die)[1]])

end # module
