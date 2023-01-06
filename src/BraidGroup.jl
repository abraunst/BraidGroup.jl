module BraidGroup

export Braid, braid, reduced, reduced!, freesimiplify!, width, composed, 
    garside_conjugate!, garside_conjugate, randbraid, compress

include("braid.jl")
include("reduction.jl")
include("visualization.jl")


end
