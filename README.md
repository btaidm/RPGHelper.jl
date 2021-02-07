
# RPG Helper
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://btaidm.github.io/RPGHelper.jl/stable)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://btaidm.github.io/RPGHelper.jl/dev)

This is a package that will with the various random aspects of 
Table Top Roll Play Games

To install:
```julia
]add https://github.com/btaidm/RPGHelper.jl.git
```

## Features

### Dice Rolling

Dice rolling is very simple:

Single Die:
```julia
using RPGHelper

result = roll(d10)
sumOfRoll = result[]
```

Multiple of the same type of die:
```julia
using RPGHelper

result = roll(2d4)
sumOfRoll = result[]

```

Multiple different types of dice:
```julia
using RPGHelper

# Add the results
result = roll(d4 + d8)
sumOfRoll = result[]

# Subtract the results
result = roll(d8 - d4)
sumOfRoll = result[]

# Any Combination
result = roll(2d10 - d4 + d8)
sumOfRoll = result[]
```

Other simple operators: `*, /, ^, %, abs, floor, ceil, abs`

Add Integer Constants:
```julia
using RPGHelper

# Add a constant
result = roll(d4 + 2)
sumOfRoll = result[]

# Subtract a constant
result = roll(d10 - 3)
sumOfRoll = result[]
```

Each of the standard dice have been defined:
- `d2`
- `d4`
- `d8`
- `d10`
- `d12`
- `d20`
- `d100`
- `dF`

To create a die of any side count, `N`:
```julia
const weirdDie = RPGHelper.Die(15)
```

To create non-uniform dies:

``` julia
const dNonUnifrom = NonUniformDie(1,2,2,3,3,0)
```

#### Modifiers

A standard set of roll modifiers are available.
Modifiers only affect Single Dies or multiples of the Same Die Type

Explode:

```julia
# Explode on highest roll
results = 3d6 |> Explode() |> roll
sumOfRoll = results[]

# Explode on number
results = 3d8 |> Explode(5) |> roll

# Explode on condition
results = 3d10 |> Explode(x->3 <= x <= 5) |> roll

# Explode Chaining
results = 3d20 |> Explode(1) |> Explode(2) |> roll

# Explode Once
results = 3d4 |> Explode(once = true) |> roll
```

There are explode variants: 

- Compounding: `Explode(compounding = true)`
- Penetrating: `Explode(penetrating = true)`

They variants can be combined

Reroll:
```julia
# Reroll on lowest roll
results = 3d6 |> Reroll() |> roll
sumOfRoll = results[]

# Reroll on number
results = 3d8 |> Reroll(5) |> roll

# Reroll on condition
results = 3d10 |> Reroll(x->3 <= x <= 5) |> roll

# Reroll Chaining
results = 3d20 |> Reroll(1) |> Reroll(2) |> roll

# Reroll Once
results = 3d4 |> Reroll(once = true) |> roll
```

Keep:

``` julia
# Keep the 4 highest rolls
results = 8d6 |> Keep(4) |> roll
results = 8d6 |> Keep(:high, 4) |> roll

# Keep the 4 lowest rolls
results = 8d6 |> Keep(:low, 4) |> roll
```

Drop:

``` julia
# Drop the 4 lowest rolls
results = 8d6 |> Drop(4) |> roll
results = 8d6 |> Drop(:low, 4) |> roll

# Drop the 4 highest rolls
results = 8d6 |> Drop(:high, 4) |> roll
```

Modifiers can be chained together. They follow
the order of:

1. Explode, Penetrating, Compounding
2. Reroll
3. Keep
4. Drop


### Random Tables

To be created.

