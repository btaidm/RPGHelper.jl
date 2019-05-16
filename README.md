
# RPG Helper

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

(sumOfRoll, eachRoll) = roll(d10)
```

Multiple of the same type of die:
```julia
using RPGHelper

(sumOfRoll, eachRoll) = roll(2d4)
```

Multiple different types of dice:
```julia
using RPGHelper

# Add the results
(sumOfRoll, eachRoll) = roll(d4 + d8)

# Subtract the results
(sumOfRoll, eachRoll) = roll(d8 - d4)

# Any Combination
(sumOfRoll, eachRoll) = roll(2d10 - d4 + d8)
```

Add Integer Constants:
```julia
using RPGHelper

# Add a constant
(sumOfRoll, eachRoll) = roll(d4 + 2)

# Subtract a constant
(sumOfRoll, eachRoll) = roll(d10 - 3)
```

Each of the standard dice have been defined:
- `d2`
- `d4`
- `d8`
- `d10`
- `d12`
- `d20`
- `d100`

To create a die of any side count, `N`:
```julia
const weirdDie = RPGHelper.Die(15)
```

### Random Tables

To be created.

