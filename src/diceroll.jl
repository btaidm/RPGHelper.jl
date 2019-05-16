export maxroll, minroll


# Define the Dice Rolling Math
abstract type AbstractDie end

struct Die <: AbstractDie
	n::Int
end

maxroll(d::Die) = d.n
minroll(::Die) = 1

# struct NDie{N,S} <: AbstractDie end

struct ConstDie <: AbstractDie
	v::Int
end
maxroll(d::ConstDie) = d.v
minroll(d::ConstDie) = d.v


struct NegDie{D <: AbstractDie} <: AbstractDie
	d::D
end
maxroll(d::NegDie) = -minroll(d.d)
minroll(d::NegDie) = -maxroll(d.d)


struct MultiDie{N, Ds} <: AbstractDie
	ds::Ds
	function MultiDie(ds::Tuple{Vararg{AbstractDie}})
		new{length(ds), typeof(ds)}(ds)
	end
end
maxroll(d::MultiDie) = mapreduce(maxroll, +, d.ds)
minroll(d::MultiDie) = mapreduce(minroll, +, d.ds)


Random.gentype(::Type{<:AbstractDie}) = Int
Random.gentype(::Type{MultiDie{N, Ds}}) where {N, Ds} = NTuple{N,Int}

NegDie(d::MultiDie) = MultiDie(NegDie.(d.ds))
NegDie(a::ConstDie) = ConstDie(-a.v)
NegDie(a::NegDie) = a.d
Base.:-(a::AbstractDie) = NegDie(a)

Base.:+(i::Integer, b::AbstractDie) = ConstDie(i) + b
Base.:+(a::AbstractDie, i::Integer) = a + ConstDie(i)
Base.:-(i::Integer, b::AbstractDie) = ConstDie(i) - b
Base.:-(a::AbstractDie, i::Integer) = a - ConstDie(i)

function Base.:*(i::Integer, d::Die) where S
	i == 0 && return ConstDie(0)
	neg = i < 0
	if neg
		i = -i
	end
	ret = mapreduce(_->d, +, 2:i; init = d)
	neg ? NegDie(ret) : ret 
end

Base.:+(d1::AbstractDie, d2::AbstractDie) = MultiDie((d1, d2))
Base.:+(md::MultiDie, d::AbstractDie) = MultiDie((md.ds..., d))
Base.:+(d::AbstractDie, md::MultiDie) = MultiDie((d, md.ds...))
Base.:+(md1::MultiDie, md2::MultiDie) = MultiDie((md1.ds..., md2.ds...))
Base.:-(a::AbstractDie, b::AbstractDie) = a + (-b)

Base.show(io::IO, d::Die) = print(io, "d", d.n)
Base.show(io::IO, r::ConstDie) = print(io, r.v)
# Base.show(io::IO, ::NDie{N, S}) where {N, S} = print(io, N, "d", S)
Base.show(io::IO, d::NegDie) = print(io, "-", d.d)

Base.show(io::IO, d::MultiDie) = join(io, d.ds, " + ")

# Now the actual Dice roller
using Random: Sampler, AbstractRNG


struct ConstDieRoll <: Sampler{Int}
	d::ConstDie
end

Sampler(RNG::Type{<:AbstractRNG}, die::ConstDie, r::Random.Repetition)= ConstDieRoll(die)

Random.rand(rng::AbstractRNG, roller::ConstDieRoll) = roller.d.v

struct SingleDieRoll <: Sampler{Int}
	d::Die
	sp::Sampler{Int}
end

Sampler(RNG::Type{<:AbstractRNG}, die::Die, r::Random.Repetition) = SingleDieRoll(die, Sampler(RNG, 1:die.n, r))

Random.rand(rng::AbstractRNG, roller::SingleDieRoll) = rand(rng, roller.sp)::Int

struct NegDieRoll <: Sampler{Int}
	roller::SingleDieRoll
end

Sampler(RNG::Type{<:AbstractRNG}, die::NegDie, r::Random.Repetition) = NegDieRoll(Sampler(RNG, die.d, r))

Random.rand(rng::AbstractRNG, roller::NegDieRoll) = -rand(rng, roller.roller)::Int

struct MultiDieRoll{N, Ds, Rs} <: Sampler{NTuple{N,Int}}
	d::MultiDie{N, Ds}
	rollers::Rs
end

Sampler(RNG::Type{<:AbstractRNG}, die::MultiDie, r::Random.Repetition) = MultiDieRoll(die, map(x->Sampler(RNG, x, r), die.ds))

Random.rand(rng::AbstractRNG, roller::MultiDieRoll) = map(r->rand(rng, r), roller.rollers)