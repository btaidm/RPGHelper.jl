module RPGHelper

import Random
export roll, meanroll, Generator

include("diceroll.jl")
include("tables.jl")

struct Generator{T,TA}
	tables::TA
	function Generator{T}(v::NamedTuple) where T
		tables = merge(NamedTuple(), Dict(map(fieldnames(T)) do f
			f => v[f]
		end))
		new{T,typeof(tables)}(tables)
	end
end

Generator{T}(dict::Dict{Symbol}) where T = Generator{T}(merge(NamedTuple(),dict))
Generator{T}(;kwargs...) where T = Generator{T}(Dict(kwargs))

Base.propertynames(gen::Generator) = collect(keys(getfield(gen,:tables)))
Base.getproperty(gen::Generator, f::Symbol) = getproperty(getfield(gen,:tables), f)

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
roll(rng::Random.AbstractRNG, gen::Generator{T}) where T = T(map(x->roll(rng,x), getfield(gen,:tables))...,)

meanroll(v) = v
meanroll(d::AbstractDie; roundFunc = x->floor(Int,x)) = roundFunc( (maxroll(d) + minroll(d)) / 2 )

meanroll(tab::Table) = meanroll(tab.table[meanroll(tab.die)])

meanroll(gen::Generator{T}) where T = T(map(meanroll, getfield(gen,:tables))...,)

include("yaml.jl")

end # module
