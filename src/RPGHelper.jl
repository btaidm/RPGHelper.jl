module RPGHelper

import Random
include("diceroll.jl")

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

export roll

end # module
