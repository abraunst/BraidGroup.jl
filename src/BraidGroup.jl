module BraidGroup

export Braid, braid, reduced, reduced!, freesimplify!, width, composed, 
    garside_conjugate!, garside_conjugate, randbraid, compress, permutation

include("braid.jl")
include("reduction.jl")
include("visualization.jl")


end
