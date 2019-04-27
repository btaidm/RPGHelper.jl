import Random

# Define the Dice Rolling Math

abstract type AbstractDie end

struct Die{S} <: AbstractDie end
# struct NDie{N,S} <: AbstractDie end

struct ConstDie <: AbstractDie
	v::Int
end

struct NegDie{D <: AbstractDie} <: AbstractDie
	d::D
end

struct MultiDie{N, Ds} <: AbstractDie end

Random.gentype(::Type{<:AbstractDie}) = Int
Random.gentype(::Type{MultiDie{N, Ds}}) where {N, Ds} = NTuple{N,Int}

NegDie(::MultiDie{Ds}) where Ds = MultiDie{NegDie.(Ds)}()
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

Base.:+(d1::AbstractDie, d2::AbstractDie) = MultiDie{2, (d1, d2)}()
Base.:+(::MultiDie{N, Ds}, d::AbstractDie) where {N, Ds} = MultiDie{N + 1, (Ds..., d)}()
Base.:+(d::AbstractDie, ::MultiDie{N, D2s}) where {N, D2s} = MultiDie{N + 1, (d, D2s...)}()
Base.:+(::MultiDie{N1, D1s}, ::MultiDie{N2, D2s}) where {N1, D1s, N2, D2s} = MultiDie{N1 + N2, (D1s..., D2s...)}()
Base.:-(a::AbstractDie, b::AbstractDie) = a + (-b)

Base.show(io::IO, ::Die{S}) where S = print(io, "d", S)
Base.show(io::IO, r::ConstDie) = print(io, r.v)
# Base.show(io::IO, ::NDie{N, S}) where {N, S} = print(io, N, "d", S)
Base.show(io::IO, d::NegDie) = print(io, "-", d.d)

Base.show(io::IO, d::MultiDie{N, Ds}) where {N, Ds} = join(io, Ds, " + ")


for d in (4, 6, 8, 10, 12, 20, 100)
	@eval begin
		const $(Symbol(:d, d)) = Die{$(d)}()
		export $(Symbol(:d, d))
	end
end

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

Sampler(RNG::Type{<:AbstractRNG}, die::Die{N}, r::Random.Repetition) where N = SingleDieRoll(die, Sampler(RNG, 1:N, r))

Random.rand(rng::AbstractRNG, roller::SingleDieRoll) = rand(rng, roller.sp)::Int

struct NegDieRoll <: Sampler{Int}
	roller::SingleDieRoll
end

Sampler(RNG::Type{<:AbstractRNG}, die::NegDie, r::Random.Repetition) = NegDieRoll(Sampler(RNG, die.d, r))

Random.rand(rng::AbstractRNG, roller::NegDieRoll) = -rand(rng, roller.roller)::Int

struct MultiDieRoll{N, Ds} <: Sampler{NTuple{N,Int}}
	d::MultiDie{N, Ds}
	rollers::NTuple{N,Union{NegDieRoll, SingleDieRoll, ConstDieRoll}}
end

Sampler(RNG::Type{<:AbstractRNG}, die::MultiDie{N, Ds}, r::Random.Repetition) where {N,Ds} = MultiDieRoll(die, map(x->Sampler(RNG, x, r), Ds))

Random.rand(rng::AbstractRNG, roller::MultiDieRoll{N}) where N = map(r->rand(rng, r), roller.rollers)