import YAML

YAML_MULTI_ENABLED = isdefined(YAML, :add_multi_constructor!)
APPLICATION_TAG = "!tag:rgphelper.jl,2019:"

function safeeval(mod::Module, expr)
	function issafe(x::Expr)
		disallowed_heads = (
			:block, :module, :baremodule, :toplevel, :using, :import
		)
		!(x.head in disallowed_heads || (x.head == :. && (x.args[1] == :Core || x.args[1] == :Main)))
	end
	issafe(x) = x != :Main
	safe_expr = prewalk(expr) do x
		issafe(x) ? x : nothing
	end
	mod.parse(safe_expr)
end

# baremodule DieConstructMod
	# using ..RPGHelper: 
# end

function RGPConstructor()
	constructors = Dict(
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

end

function TableConstructor(constructor::YAML.Constructor, node::YAML.MappingNode)
end

function GeneratorConstructor(constructor::YAML.Constructor, node::YAML.MappingNode)

end

function GeneratorConstructor(constructor::YAML.Constructor, tag::String, node::YAML.MappingNode)
end 
