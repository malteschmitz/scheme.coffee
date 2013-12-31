scheme.coffee
=============

A Scheme interpreter written in CoffeeScript.

This little was written after reading _The Little Schemer_ an is heavily based on the ideas presented in the last chapter of this book. It does neither support all of Scheme nor is it fast.

It supports integers, booleans `#t`, `#f`, the operators `cond`, `lambda`, `quote` and the primitves
`eq?`, `atom?`, `null?`, `cons`, `car`, `cdr`, `+`, `-`, `*`, `/`, `<`. A very little library
defines the functions `y` (Y combinator), `if`, `not`, `and`, `or`, `zero?`, `add1`, `sub1`, `>=`,
`<=` and `>` based on the primitives.

License
-------

This software is released under the
[MIT License](http://www.opensource.org/licenses/MIT).