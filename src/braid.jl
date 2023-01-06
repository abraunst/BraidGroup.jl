struct Braid{V<:AbstractVector{Int}}
    els::V
    function Braid(v::V) where V<:AbstractVector{Int}
        @assert all(!iszero, v)
        new{V}(v)
    end
end

Braid(v) = Braid(collect(v))

braid(x...) = Braid(Int[x...])

Base.one(::Braid) = braid()

Base.one(::Type{Braid}) = braid()

Base.isone(a::Braid) = isempty(a.els)

Base.eachindex(a::Braid) = eachindex(a.els)

Base.getindex(a::Braid, i::Int) = (abs(a.els[i]), sign(a.els[i]))

Base.copy(a::Braid) = Braid(collect(a.els))

function Base.:^(a::Braid, k::Integer)
    if k < 0
        Braid(reduce(vcat, fill(reverse(.-a.els), -k)))
    elseif k > 0
        Braid(reduce(vcat, fill(a.els, k)))
    else
        Braid(Int[])
    end 
end

Base.:*(a::Braid, b::Braid) = Braid(vcat(a.els, b.els))

Base.:/(a::Braid, b::Braid) = Braid(vcat(a.els, reverse(.- b.els)))

Base.:\(a::Braid, b::Braid) = Braid(vcat(reverse(.- a.els), b.els))

Base.inv(a::Braid) = Braid(reverse(.- a.els))

width(a::Braid) = maximum(abs, a.els; init=0) + 1

Base.length(a::Braid) = length(a.els)

function Base.show(io::IO, a::Braid)
    print(io, "Braid(", a.els, ")")
end

superscripts(x) = x == 1 ? "" : replace(string(x), (a=>b for (a,b) in zip("-01234567890","⁻⁰¹²³⁴⁵⁶⁷⁸⁹"))...)

subscripts(x) = replace(string(x), (a=>b for (a,b) in zip("-01234567890","₋₀₁₂₃₄₅₆₇₈₉"))...)
