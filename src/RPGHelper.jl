module RPGHelper

include("diceroll.jl")

for d in (4, 6, 8, 10, 12, 20, 100)
	@eval begin
		const $(Symbol(:d, d)) = Die{$(d)}()
		export $(Symbol(:d, d))
	end
end

function roll(d::AbstractDie)
	vs = rand(d)
	(sum(vs), vs)
end
export roll

end # module
