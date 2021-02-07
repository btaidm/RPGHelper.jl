import Random
using Random: AbstractRNG, SamplerTrivial
using OrderedCollections: OrderedSet

maxroll(x) = x
minroll(x) = x
default_filter(d) = ==(maxroll(d))

abstract type AbstractDie end
abstract type NumDie <: AbstractDie end

function Base.:+(d1::AbstractDie, d2::AbstractDie)
    [d1, d2]
end
Base.:+(d1::Vector{<:AbstractDie}, d2::AbstractDie) = [ d1; d2 ]

function Base.:*(c::Integer, d::AbstractDie)
    c <= 0 || ArgumentError("Multiplier must be 1 or higher")
    reduce(+, d for _ in 1:c)
end

struct RollMeta{M} end

struct RollResult
    rolls::Vector{Int}
    result::Number
end

RollResult(a::Int) = RollResult([a], a)

Base.getindex(r::RollResult) = r.result
Base.getindex(r::RollResult, idx) = r.rolls[idx]

for op in (:+, :-, :*, :/, :%, :^)
    @eval Base.$op(r1::RollResult, r2::RollResult) = RollResult([r1.rolls; r2.rolls], $(op)(r1.result,r2.result))
    @eval Base.$op(r1::Number, r2::RollResult) = RollResult(r2.rolls, $(op)(r1,r2.result))
    @eval Base.$op(r1::RollResult, r2::Number) = RollResult(r1.rolls, $(op)(r1.result,r2))
end

for op in (:-, :floor, :ceil, :round, :abs)
    @eval Base.$op(r1::RollResult) = RollResult(r1.rolls, $(op)(r1.result))
end

for op in (:floor, :ceil, :round)
    @eval Base.$op(T, r::RollResult; kwargs...) = RollResult(r.rolls, $(op)(T, r.result; kwargs...))
end

function compound(curr::RollResult, idx, newRoll::RollResult)
    newRolls = copy(curr.rolls)
    newRolls[idx] += newRoll.result
    newResult = curr.result + newRoll.result
    RollResult(newRolls, newResult)
end

function Base.replace(curr::RollResult, idx, newRoll::RollResult)
    newRolls = copy(curr.rolls)
    newResult = curr.result - newRolls[idx]
    newRolls[idx] = newRoll[]
    newResult += newRolls[idx]
    RollResult(newRolls, newResult)
end

function drop(curr::RollResult, idx)
    newRolls = copy(curr.rolls)
    newResult = curr.result - newRolls[idx]
    RollResult(deleteat!(newRolls, idx), newResult)
end

Base.eltype(::NumDie) = RollResult

function roll(rng::AbstractRNG, d::AbstractDie; separate::Bool = false)
    if(separate)
        rand.(rng, get_dice(d))
    else
        rand(rng, d)
    end
end

function roll(rng::AbstractRNG, dice::Vector{<:AbstractDie}; kwargs...)
    roll.(rng, dice; kwargs...)
end


struct SymbolDie{T} <: AbstractDie
    vs::Vector{T}
end
Base.eltype(::SymbolDie{T}) where T = T
Random.rand(rng::AbstractRNG, sp::SamplerTrivial{SymbolDie{T} where T}) = rand(rng, sp[].vs)


struct Die <: NumDie
    s::Int
end
maxroll(d::Die) = RollResult(d.s)
minroll(::Die) = RollResult(1)

Random.rand(rng::AbstractRNG, sp::SamplerTrivial{Die}) = RollResult(rand(rng, 1:sp[].s) )


struct NonUniformDie{VS} <: NumDie
    function NonUniformDie{VS}() where VS
        VS isa Tuple{Vararg{Int}} || error(ArgumentError("Must be a tuple of Ints"))
        new{VS}()
     end
end

NonUniformDie(values::Tuple{Vararg{Number}}) = NonUniformDie{(collect(Int(v) for v in values)...,)}()
NonUniformDie(vs...) = NonUniformDie(vs)
maxroll(::NonUniformDie{VS}) where VS = RollResult(maximum(VS))
minroll(::NonUniformDie{VS}) where VS = RollResult(minimum(VS))
getvalues(::NonUniformDie{VS}) where VS = VS
Random.rand(rng::AbstractRNG, ::SamplerTrivial{NonUniformDie{VS}}) where VS = RollResult(rand(rng, VS))

const BaseDice = Union{Die, NonUniformDie}
struct NDie{N,D <: BaseDice} <: NumDie
    d::D
end
NDie{N}(d::D) where {N,D} = NDie{N,D}(d)
minroll(d::NDie{N}) where N = N * minroll(d.d)
maxroll(d::NDie{N}) where N = N * maxroll(d.d)
Random.rand(rng::AbstractRNG, sp::SamplerTrivial{<:NDie{N}}) where N = reduce(+, rand(rng, sp[].d, N))
basedie(d::BaseDice) = d
basedie(d::NDie) = d.d



struct OpDie{OP, A, K} <: NumDie
    op::OP
    args::A
    kwargs::K
end

OpDie(op, args) = OpDie(op, args, ())

_calculate(f, op::OpDie) = op.op(f.(op.args)...; op.kwargs...)
_oprand(::AbstractRNG, x) = x
_oprand(rng::AbstractRNG, x::AbstractDie) = rand(rng, x)
_oprand(rng::AbstractRNG) = x -> _oprand(rng,x)
maxroll(d::OpDie) = _calculate(maxroll, d)
minroll(d::OpDie) = _calculate(minroll, d)
Random.rand(rng::AbstractRNG, sp::SamplerTrivial{<:OpDie}) = _calculate(_oprand(rng), sp[])
Base.convert(::Type{Expr}, op::OpDie{O,A,Tuple{}} where {O,A}) = :($(Symbol(op.op))($(op.args...)))
function Base.convert(::Type{Expr}, op::OpDie)
    if isempty(op.kwargs)
        :($(Symbol(op.op))($(op.args...)))
    else
        :($(Symbol(op.op))($(op.args...); $(op.kwargs...)))
    end
end

function Base.show_unquoted(io::IO, op::OpDie, ::Int, prec::Int)
	if Base.operator_precedence(Symbol(op.op)) < prec
        print(io, "(")
        show(io, op)
        print(io, ")")
    else
        show(io, op)
    end
end

# Math Operators
for op in (:+, :-, :*, :/, :%, :^)
    @eval Base.$op(r1::NumDie, r2::NumDie) = OpDie($op,(r1, r2))
    @eval Base.$op(r1::NumDie, r2::Number) = OpDie($op,(r1, r2))
    @eval Base.$op(r1::Number, r2::NumDie) = OpDie($op,(r1, r2))
    @eval Base.$op(r1::Integer, r2::NumDie) = OpDie($op,(r1, r2))
end

function Base.:*(r1::Integer, r2::BaseDice)
    r = NDie{abs(r1)}(r2)
    if r1 < 0
        -r
    elseif r1 == 0
        0
    else
        r
    end
end

for op in (:-, :floor, :ceil, :round, :abs)
    @eval Base.$op(r1::NumDie) = OpDie($op, (r1,))
end

for op in (:floor, :ceil, :round)
    @eval Base.$op(T, r::NumDie; kwargs...) = OpDie($op, (T, r), kwargs)
end

# Print Operations

Base.show(io::IO, d::Die) = print(io, "d", d.s)
Base.show(io::IO, d::NDie{N}) where N = print(io, N, d.d)
function Base.show(io::IO, op::OpDie)
    print(io, convert(Expr, op::OpDie))
end


# Utility
get_dice(_) = []
get_dice(d::AbstractDie) = [d]
get_dice(d::NDie{N}) where N = collect(d.d for _ in 1:N)
function get_dice(d::OpDie)
    ds = []
    for di in d.args
        append!(ds, get_dice(di))
    end
    ds
end
export get_dice

# Common Dice
for d in (2, 4, 6, 8, 10, 12, 20, 100)
	@eval begin
		const $(Symbol(:d, d)) = Die($(d))
		export $(Symbol(:d, d))
	end
end

const dF = NonUniformDie{(-1,-1,0,0,1,1)}()
export dF

const dTrueFalse = SymbolDie([true, false])
export dTrueFalse

# Modifiers
const ModDice = Union{BaseDice, NDie}

abstract type Modifier end

modifier_order(::T) where {T <: Modifier} = modifier_order(T)

struct DieModifier{D <: ModDice}
    d::D
    mods::OrderedSet{Modifier}
    function DieModifier(d::D, mods::Vector{Modifier}) where D
        new{D}(d, OrderedSet(sort(mods, alg = Base.Sort.DEFAULT_STABLE, by = modifier_order)))
    end
end

function Base.show(io::IO, d::DieModifier)
    show(io, d.d)
    print(io, " |> ")
    join(io, d.mods, " |> ")
end

function roll(rng::AbstractRNG, d::DieModifier)
    initialResults = roll(rng, d.d)
    foldl(d.mods; init = roll(rng, d.d)) do results, mod
        results
        roll(rng, mod, results, basedie(d.d))
    end
end

(m::Modifier)(d::ModDice) = DieModifier(d, Modifier[m])
(m::Modifier)(d::DieModifier) = DieModifier(d.d, Modifier[m;d.mods...])

struct Explode{F} <: Modifier
    filter::F
    compounding::Bool
    penetrating::Bool
    count::Int

    function Explode(f::F; compounding::Bool = false, penetrating::Bool = false, once::Bool = false, maxRolls::Int = typemax(Int)) where {F}
        new{F}(f, compounding, penetrating, once ? 1 : maxRolls)
    end
end
Explode(;kwargs...) = Explode(nothing; kwargs...)
Explode(filter::Int; kwargs...) = Explode(==(filter); kwargs...)
Explode(d::Union{<:ModDice,<:DieModifier}, args...; kwargs...) = Explode(args...; kwargs...)(d)

export Explode

modifier_order(::Type{<:Explode}) = 30

function roll(rng::AbstractRNG, ex::Explode, results::RollResult, d::NumDie)
    filter = isnothing(ex.filter) ? ==(maxroll(d)[]) : ex.filter
    idxs = findall(filter, results.rolls)
    for idx in idxs
        currentExplosion = RollResult(Int[],0)
        stopRolling = false
        while !stopRolling
            newRoll = roll(rng, d)
            reroll = filter(newRoll[])
            if(ex.penetrating)
                newRoll -= -1
            end
            currentExplosion += newRoll
            stopRolling = length(currentExplosion.rolls) == ex.count || !(filter(newRoll[]))
        end
        if(ex.compounding)
            results = compound(results, idx, currentExplosion)
        else
            results += currentExplosion
        end
    end
    return results
end


struct Reroll{F} <: Modifier
    filter::F
    count::Int

    function Reroll(f::F; once::Bool = false, maxRolls::Int = typemax(Int))  where {F}
        new{F}(f, once ? 1 : maxRolls)
    end
end
Reroll(;kwargs...) = Reroll(nothing; kwargs...)
Reroll(filter::Int; kwargs...) = Reroll(==(filter); kwargs...)
Reroll(d::Union{<:ModDice,<:DieModifier}, args...; kwargs...) = Reroll(args...; kwargs...)(d)
export Reroll

modifier_order(::Type{<:Reroll}) = 40

function roll(rng::AbstractRNG, ex::Reroll, results::RollResult, d::NumDie)
    filter = isnothing(ex.filter) ? ==(minroll(d)[]) : ex.filter
    idxs = findall(filter, results.rolls)
    for idx in idxs
        rollCount = 0
        newRoll = nothing
        stopRolling = false
        while !stopRolling
            newRoll = roll(rng, d)
            rollCount += 1
            stopRolling = rollCount >= ex.count || !(filter(newRoll[]))
        end
        results = replace(results, idx, newRoll)
    end
    return results
end

struct Min <: Modifier
    min::Int
end
Min(d::Union{<:ModDice, <: DieModifier}, args...; kwargs...) = Min(args...;kwargs...)(d)
export Min

modifier_order(::Type{Min}) = 10

function roll(rng::AbstractRNG, ex::Min, results::RollResult, d::NumDie)
    filter = <(ex.min)
    idxs = findall(filter, results.rolls)
    for idx in idxs
        results = replace(results, idx, RollResult(ex.min))
    end
    return results
end

struct Max <: Modifier
    max::Int
end
Max(d::Union{<:ModDice, <: DieModifier}, args...; kwargs...) = Max(args...;kwargs...)(d)
export Max

modifier_order(::Type{Max}) = 20

function roll(rng::AbstractRNG, ex::Max, results::RollResult, d::NumDie)
    filter = >(ex.max)
    idxs = findall(filter, results.rolls)
    for idx in idxs
        results = replace(results, idx, RollResult(ex.max))
    end
    return results
end

struct Keep{S} <: Modifier
    count::Int
    function Keep(s::Symbol, count::Int)
        s in (:high, :low) || error(ArgumentError("Must be :high or :low"))
        new{s}(count)
    end
end
Keep(count::Int) = Keep(:high, count)
export Keep
modifier_order(::Type{<:Keep}) = 50
drop_count(total::Int, keep::Keep) = total - keep.count
drop_func(::Keep{:high}) = argmin
drop_func(::Keep{:low}) = argmax

struct Drop{S} <: Modifier
    count::Int
    function Drop(s::Symbol, count::Int)
        s in (:high, :low) || error(ArgumentError("Must be :high or :low"))
        new{s}(count)
    end
end
Drop(count::Int) = Drop(:low, count)
export Drop
modifier_order(::Type{<:Drop}) = 60
drop_count(::Int, drop::Drop) = drop.count
drop_func(::Drop{:high}) = argmax
drop_func(::Drop{:low}) = argmin

function roll(::AbstractRNG, ex::Union{Keep, Drop}, results::RollResult, ::NumDie)
    isempty(results.rolls) && return results
    count = drop_count(length(results.rolls), ex)
    func = drop_func(ex)
    for _ in 1:count
        isempty(results.rolls) && break
        idx = func(results.rolls)
        results = drop(results, idx)
    end
    return results
end

const Advantage = Keep(:high, 1)
const Disadvantage = Keep(:low, 1)
export Advantage, Disadvantage
