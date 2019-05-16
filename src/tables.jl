const TableDict{T} = Dict{Int, T}

struct Table{D <: AbstractDie,T}
	name::String
	die::D
	table::TableDict{T}
end

Table{T}(name::String, die::AbstractDie) where T = Table(name, die, TableDict{T}())

hasallrolls(tab::Table) = all(x->haskey(tab.table, x), minroll(tab.die):maxroll(tab.die))

add!(tab::Table, idx::Int, el) = (setindex!(tab.table, el, idx); tab)
add!(tab::Table, idxs::AbstractArray{Int}, el) = (foreach(x->add!(tab, x, el),idxs); tab)
add!(f::Base.Callable, tab::Table, el) = add!(tab, filter(f, minroll(tab.die):maxroll(tab.die)) |> collect, el)


export hasallrolls, add!, Table
