macro safeEvalModule(allowed::Expr)
	modName = esc(gensym(:safemodule))
	quote
		$(Expr(:toplevel,
			:(baremodule $(modName)
				$(esc(allowed))
				$(esc(:eval))(expr) = $(esc(Core)).eval($(modName), expr)
			end)
		))
		$(modName)
	end
end

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
