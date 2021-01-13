import Random
using Random: AbstractRNG, SamplerTrivial

maxroll(x) = x
minroll(x) = x

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

struct RollResult
    rolls::Vector{Int}
    result::Number
end

RollResult(a::Int) = RollResult([a], a)

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

Random.rand(rng::AbstractRNG, sp::SamplerTrivial{Die}) = RollResult(rand(rng, 1:sp[].s))


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

# Container roll




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
