struct Braid
    els::Vector{Int}
    function Braid(v::Vector{Int})
        @assert all(!iszero, v)
        new(v)
    end
end

braid(x...) = Braid(Int[x...])

Base.one(::Braid) = braid()

Base.one(::Type{Braid}) = braid()

Base.isone(a::Braid) = isempty(a.els)

Base.eachindex(a::Braid) = eachindex(a.els)

Base.getindex(a::Braid, i::Int) = (abs(a.els[i]), sign(a.els[i]))

Base.copy(a::Braid) = Braid(copy(a.els))

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

Base.inv(a::Braid) = Braid(reverse(.- a.els))

width(a::Braid) = maximum(abs, a.els; init=0) + 1

Base.length(a::Braid) = length(a.els)

"Produce an expression of `a` in powers of generators, in the form of a Vector of tuples (generator, power)"
function powers(a::Braid)
    w = Tuple{Int,Int}[]
    for k in eachindex(a)
        i, σ = a[k]
        if !isempty(w) && w[end][1] == i
            if w[end][2] + σ == 0
                pop!(w)
            else
                w[end] = (w[end][1], w[end][2] + σ)
            end
        else
            push!(w, (i,σ))
        end
    end
    w
end

function Base.show(io::IO, a::Braid)
    if isempty(a.els)
        print(io, "ε")
        return
    end
    if get(io, :compact, false)
        print(io, prod("σ"*subscripts(i)*superscripts(k) for (i,k) in powers(a); init=""))
        return
    end 
    print(io, "Braid(", a.els, ")")
end

superscripts(x) = x == 1 ? "" : replace(string(x), (a=>b for (a,b) in zip("-01234567890","⁻⁰¹²³⁴⁵⁶⁷⁸⁹"))...)
subscripts(x) = replace(string(x), (a=>b for (a,b) in zip("-01234567890","₋₀₁₂₃₄₅₆₇₈₉"))...)
