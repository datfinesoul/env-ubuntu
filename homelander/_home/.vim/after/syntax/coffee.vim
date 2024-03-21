syntax match coffeescriptArrow "->"
highlight def link coffeescriptArrow Special

syn region coffeeFunction start=/\S\s*[a-zA-Z0-9_]\+ = \((.*) \)\?->/ end=// oneline transparent
syn match coffeeFunctionName /\S\s*[a-zA-Z0-9]\+ / contained containedin=coffeeFunction
hi def link coffeeFunctionName Special

hi def link coffeeSpecialIdent Identifier
