# BraidGroup

[![Build Status](https://github.com/abraunst/BraidGroup.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/abraunst/BraidGroup.jl/actions/workflows/CI.yml?query=branch%3Amain)

This small package implements Artin's $$B\_\infty$$ Braid group and some tools.

In particular, it implements 

* Nice Braid visualizations using `Compose`
* Normal group operations, including `*`, `inv`, `^` and `one`
* Artin's free simplification `freesimplify!`
* Dehornoy reduction `reduced`, allowing to implement Braid equivalence `==`.

It is similar in scope to `https://github.com/jwvictor/Braids.jl`. At difference with it:

* Represents the $$B_\infty$$ group rather than $$B_n$$
* Internally, this package represent braids as product of generators, whereas `Braids` stores powers of generators.
* Implements both `MIME"text/html"` and `MIME"text/plain"` output
* Operations are done in-place as much as possible
* Does not implement the matrix representation included in `Braids.jl`
