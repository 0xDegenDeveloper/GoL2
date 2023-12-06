## Changes from initial code base:

- camelCase ERC20 functions -> snake_case ERC20 functions
- simpler packing/unpacking logic for gamestate <-> felt
  - dropped recursion for loops
  - u256 instead of cairo primative cuts out manual bit arrangement
