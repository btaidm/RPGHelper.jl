import YAML
using MacroTools: prewalk

const YAML_MULTI_ENABLED = isdefined(YAML, :add_multi_constructor!)
const APPLICATION_TAG = "tag:rgphelper.jl,2019:"

baremodule EmptyModule
end

const DieConstructMod = @safeEvalModule begin
	using ..RPGHelper: d2, d4, d6, d8, d10, d12, d20, d100
	using Base: +, -, *, /
end

function RGPConstructor(generatorModule::Module)
	constructors = Dict{String, Function}(
		APPLICATION_TAG * "Die" => DieConstructor,
		APPLICATION_TAG * "die" => DieConstructor,
		APPLICATION_TAG * "table" => TableConstructor,
		APPLICATION_TAG * "Table" => TableConstructor,
		APPLICATION_TAG * "Generator" => (c, n) -> GeneratorConstructor(generatorModule, c, n),
		APPLICATION_TAG * "generator" => (c, n) -> GeneratorConstructor(generatorModule, c, n),
	)

	@static if YAML_MULTI_ENABLED
		mutli_constructors = Dict{String,Function}(
			APPLICATION_TAG * "Generator:" => (c, t, n) -> GeneratorConstructor(generatorModule, c, t, n),
			APPLICATION_TAG * "generator:" => (c, t, n) -> GeneratorConstructor(generatorModule, c, t, n)
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
	mapping = YAML.construct_mapping(constructor, node)
	name = mapping["name"]
	fields = mapping["table"] |> Dict{Int, Any}
	die = get(mapping, "die") do
		Die(length(fields))
	end
	ret = Table(name, die, fields)
	validate(ret) || YAML.ConstructorError(nothing, nothing, "Table is not fully defined", node.start_mark)
	ret
end


function GeneratorConstructor(mod::Module, constructor::YAML.Constructor, node::YAML.MappingNode)
	mapping = YAML.construct_mapping(constructor, node)
	t = mapping["type"]
	fields = mapping["fields"]
	constructgenerator(mod, type, fields)
end

function GeneratorConstructor(mod::Module, constructor::YAML.Constructor, tag::String, node::YAML.MappingNode)
	constructgenerator(mod, tag, YAML.construct_mapping(constructor, node))
end

constructgenerator(mod::Module, t::String, fields::Dict) = constructgenerator(mod, t, Dict((Symbol(k) => v for (k,v) in fields)))

function constructgenerator(mod::Module, t::String, fields::Dict{Symbol})
	T = safeeval(mod, Meta.parse(t))
	Generator{T}(fields)
end

function load(io::IO, mod::Module = EmptyModule)
	YAML.load(io, RGPConstructor(mod))
end

