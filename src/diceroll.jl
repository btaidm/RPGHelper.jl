abstract type AbstractDie end
abstract type NumDie <: AbstractDie end

using Statistics: mean
Base.eltype(::NumDie) = Int

function maxroll end
function minroll end

struct Die <: NumDie
    s::Int
end
maxroll(d::Die) = d.s
minroll(::Die) = 1
meanroll(d::Die) = (1+d.s)/2

struct NonUniformDie{VS} <: NumDie
    function NonUniformDie{VS}() where VS
        VS isa Tuple{Vararg{Int}} || error(ArgumentError("Must be a tuple of Ints"))
        new{VS}()
    end
end

NonUniformDie(values::Tuple{Vararg{Number}}) = NonUniformDie{(collect(Int(v) for v in values)...,)}()
NonUniformDie(vs...) = NonUniformDie(vs)
maxroll(::NonUniformDie{VS}) where VS = maximum(VS)
minroll(::NonUniformDie{VS}) where VS = minimum(VS)
meanroll(::NonUniformDie{VS}) where VS = mean(VS)
getvalues(::NonUniformDie{VS}) where VS = VS

struct ConstDie <: NumDie
    v::Int
end
maxroll(d::ConstDie) = d.v
minroll(d::ConstDie) = d.v
meanroll(d::ConstDie) = d.v

struct NegDie{D <: NumDie} <: NumDie
    d::D
end
NegDie(d::D) where D = NegDie{D}(d)
maxroll(d::NegDie) = -minroll(d.d)
minroll(d::NegDie) = -maxroll(d.d)
meanroll(d::NegDie) = -meanroll(d.d)

struct SumDie <: NumDie
    ds::Vector{NumDie}
end

maxroll(d::SumDie) = mapreduce(maxroll, +, d.ds)
minroll(d::SumDie) = mapreduce(minroll, +, d.ds)
meanroll(d::SumDie) = mapreduce(meanroll, +, d.ds)

# Math Operators
Base.:-(d::NumDie) = NegDie(d)
Base.:-(d::SumDie) = SumDie(broadcast(-, d.ds))
Base.:-(d::NegDie) = d.d
Base.:-(d::ConstDie) = ConstDie(-d.v)

Base.:+(d1::NumDie, d2::NumDie) = SumDie([d1, d2])
Base.:+(d1::SumDie, d2::NumDie) = SumDie([d1.ds; d2])
Base.:+(d1::NumDie, d2::SumDie) = SumDie([d1; d2.ds])
Base.:+(d1::SumDie, d2::SumDie) = SumDie([d1.ds; d2.ds])

Base.:-(d1::NumDie, d2::NumDie) = d1 + -(d2)

Base.:+(d1::Integer, d2::NumDie) = ConstDie(d1) + d2
Base.:+(d1::NumDie, d2::Integer) = d1 + ConstDie(d2)
Base.:-(d1::Integer, d2::NumDie) = ConstDie(d1) - d2
Base.:-(d1::NumDie, d2::Integer) = d1 - ConstDie(d2)

Base.:*(d1::Integer, d2::NumDie) = (d1 == 0 ? ConstDie(0) : reduce(+, (d1 < 0 ? -d2 : d2) for _ in 1:abs(d1)))

# Print Operations

Base.show(io::IO, d::Die) = print(io, "d", d.s)
Base.show(io::IO, d::SumDie) = join(io, d.ds, " + ")
Base.show(io::IO, d::ConstDie) = print(io, d.v)
Base.show(io::IO, d::NegDie) = print(io, "-(", d.d, ")")

# Utility
get_dice(d::AbstractDie) = [d]
function get_dice(d::SumDie)
    ds = []
    for di in d.ds
        append!(ds, get_dice(di))
    end
    ds
end
export get_dice

# Random Generation
using Random: AbstractRNG, SamplerSimple, Sampler


Random.Sampler(RNG::Type{<:AbstractRNG}, d::Die, r::Random.Repetition) = SamplerSimple(d, Sampler(RNG, 1:d.s, r))
Random.Sampler(RNG::Type{<:AbstractRNG}, d::NonUniformDie, r::Random.Repetition) = SamplerSimple(d, Sampler(RNG, getvalues(d), r))
Random.Sampler(RNG::Type{<:AbstractRNG}, d::NegDie, r::Random.Repetition) = SamplerSimple(d, Sampler(RNG, d.d, r))
Random.Sampler(RNG::Type{<:AbstractRNG}, d::ConstDie, r::Random.Repetition) = SamplerSimple(d, d.v)
Random.Sampler(RNG::Type{<:AbstractRNG}, d::SumDie, r::Random.Repetition) = SamplerSimple(d, d.ds)

Random.rand(rng::AbstractRNG, sp::SamplerSimple{Die}) = rand(rng, sp.data)
Random.rand(rng::AbstractRNG, sp::SamplerSimple{<:NonUniformDie}) = rand(rng, sp.data)
Random.rand(rng::AbstractRNG, sp::SamplerSimple{<:NegDie}) = -rand(rng, sp.data)
Random.rand(rng::AbstractRNG, sp::SamplerSimple{ConstDie}) = sp.data
Random.rand(rng::AbstractRNG, sp::SamplerSimple{SumDie}) = mapreduce(x->rand(rng, x), +, sp.data)

function roll(rng::AbstractRNG, d::AbstractDie; separate::Bool = false)
    if(separate)
        rand.(rng, get_dice(d))
    else
        rand(rng, d)
    end
end

Base.:!(d::AbstractDie) = roll(d)

# Common Dice
for d in (2, 4, 6, 8, 10, 12, 20, 100)
	@eval begin
		const $(Symbol(:d, d)) = Die($(d))
		export $(Symbol(:d, d))
	end
end
