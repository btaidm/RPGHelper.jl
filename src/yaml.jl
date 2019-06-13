import YAML
using MacroTools: prewalk

YAML_MULTI_ENABLED = isdefined(YAML, :add_multi_constructor!)
APPLICATION_TAG = "tag:rgphelper.jl,d2019:"

function safeeval(mod::Module, expr)
	function issafe(x::Expr)
		disallowed_heads = (
			:block, :module, :baremodule, :toplevel, :using, :import
		)
		!(x.head in disallowed_heads || (x.head == :. && (x.args[d1] == :Core || x.args[d1] == :Main)))
	end
	issafe(x) = x != :Main
	safe_expr = prewalk(expr) do x
		issafe(x) ? x : nothing
	end
	mod.eval(safe_expr)
end

baremodule DieConstructMod
	using ..RPGHelper: d2, d4, d6, d8, d10, d12, d20, d100
	using Base: +, -, *, /

	eval(expr) = Core.eval(DieConstructMod, expr)
end

function RGPConstructor()
	constructors = Dict{AbstractString, Function}(
		APPLICATION_TAG * "Die" => DieConstructor,
		APPLICATION_TAG * "Table" => TableConstructor,
		APPLICATION_TAG * "Generator" => GeneratorConstructor,
	)

	@static if YAML_MULTI_ENABLED
		mutli_constructors = Dict(
			APPLICATION_TAG * "Generator:" => GeneratorConstructor
		)
		YAML.SafeConstructor(constructors, mutli_constructors)
	else
		constructors
	end
end


function DieConstructor(constructor::YAML.Constructor, node::YAML.ScalarNode)
	str = YAML.construct_yaml_str(constructor, node)
	safeeval(DieConstructMod, Meta.parse(str))
end

function TableConstructor(constructor::YAML.Constructor, node::YAML.MappingNode)
end

function GeneratorConstructor(constructor::YAML.Constructor, node::YAML.MappingNode)

end

function GeneratorConstructor(constructor::YAML.Constructor, tag::String, node::YAML.MappingNode)
end 
