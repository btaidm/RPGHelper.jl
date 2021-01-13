abstract type AbstractTable{T} end

matches(roll::Integer) = Base.Fix2(matches, roll)


const MatcherTypes = Union{Base.Callable, AbstractVector{<:Integer}, Integer}
struct Matcher{T <: MatcherTypes}
	match::T
end

matches(a::Matcher{<:Base.Callable}, roll::Integer) = a.match(roll)
matches(a::Matcher{<:AbstractVector{<:Integer}}, roll::Integer) = roll in a.match
matches(a::Matcher{<:Integer}, roll::Integer) = roll == a.match

const ItemMatchers = Union{Matcher, Nothing}
struct Item{R, M <: ItemMatchers, T}
	matcher::M
	roller::T
end

Item{R}(matcher::M, roller::T) where {R, M <: ItemMatchers, T} = Item{R,M,T}(matcher, roller)
Item{R}(matcher::MatcherTypes, roller) where R = Item{R}(Matcher(matcher), roller)
Item{R}(roller) where {R} = Item{R}(nothing, roller)
Item(matcher, roller::T) where T = Item{T}(matcher, roller)
Item(matcher, roller::AbstractTable{T}) where T = Item{T}(matcher, roller)
Item(roller::T) where {T} = Item{T}(roller)
Item(a::AbstractTable{T}) where T = Item{T}(a)
Item(::Function) = throw(ArgumentError("Item Action must specify a type"))

Base.getindex(a::Item{R, <:ItemMatchers, <:Union{AbstractTable{R},R}} where R) = a.roller
Base.getindex(a::Item{R}) where R = a.roller()::R

matches(a::Item, roll::Integer) = matches(a.matcher, roll)
matches(a::Item{<:Any, Nothing}, ::Integer) = true

function Base.show(io::IO, item::Item{R, M}) where {R, M}
	print(io, "Item(", item.matcher.match, ", ")
	show(io, item.roller)
	print(io, ")")
end

function Base.show(io::IO, item::Item{R, Nothing}) where {R, M}
	print(io, "Item(", )
	show(io, item.roller)
	print(io, ")")
end

struct MissingTableEntry <: Exception
	x::Int
end

struct Table{T, D <: AbstractDie} <: AbstractTable{T}
	name::String
	die::D
	table::Vector{Item{T}}
end

Table(name::String, die::AbstractDie, items::Vector{<:Item{T}}) where T = Table(name, die, convert(Vector{Item{T}}, items))
Table(name::String, die::AbstractDie, items::Vararg{<:Item{T}}) where T = Table(name, die, collect(items))
Table{T}(name::String, die::AbstractDie, items::Vararg{<:Item{T}}) where T = Table(name, die, collect(items))
Table(name, die, items::Base.Generator) = Table(name, die, collect(items))


function Base.show(io::IO, a::Table{T}) where T
	recur_io = IOContext(io, :SHOWN_SET => a)
	Base.show_circular(io, a) && return
	print(recur_io, "Table{", T, "}(")
	show(recur_io, a.name)
	print(recur_io, ", ", a.die, ", ")
	join(recur_io, a.table, ", ")
	print(recur_io, ")")
end

function Base.getindex(table::Table, x::Integer)
	idx = findlast(matches(x), table.table)
	if idx === nothing
		throw(MissingTableEntry(x))
	end
	return table.table[idx][]
end

struct List{T} <: AbstractTable{T}
	name::String
	table::Vector{Item{T, Nothing}}
end

function Base.show(io::IO, a::List{T}) where T
	recur_io = IOContext(io, :SHOWN_SET => a)
	Base.show_circular(io, a) && return
	print(recur_io, "List{", T, "}(")
	show(recur_io, a.name)
	print(recur_io, ", ")
	join(recur_io, a.table, ", ")
	print(recur_io, ")")
end
List(name::String, items::Vector{<:Item{T}}) where T = List(name, convert(Vector{Item{T, Nothing}}, items))
List(name::String, items::Vararg{<:Item{T}}) where T = List(name, collect(items))
List{T}(name::String, items::Vararg{<:Item{T}}) where T = List(name, collect(items))
List(name::String, items::Base.Generator) where T = List(name, collect(items))

function Base.getindex(table::List, x::Integer)
	table.table[x][]
end


add!(table::Table{T}, a::Item{T}) where T = push!(table.table, a)
add!(table::List{T}, a::Item{T,Nothing}) where T = push!(table.table, a)

function roll(rng::AbstractRNG, table::Table)
	roll(rng, table[roll(rng, table.die)[]])
end

function roll(rng::AbstractRNG, table::List)
	roll(rng, rand(rng, table.table))
end

export Table, Item, List, add!
