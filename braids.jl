using Compose: stroke, compose, context, linewidth, text, font
using Colors


struct Braid
    els::Vector{Int}
    function Braid(v::Vector{Int})
        @assert all(!iszero, v)
        new(v)
    end
end

braid(x...) = Braid([x...])

one(::Braid) = braid()

one(::Type{Braid}) = braid()

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

nstrands(a::Braid) = maximum(abs, a.els; init=0) + 1

function plot(a::Braid; N = nstrands(a), cols=HSV.((0:N-1)./(N-1)*256,1,1), bcol="black")
    cols = copy(cols)
    Δt = 3mm
    set_default_graphic_size(Δt * (length(a.els) + 1), N*2mm)

    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    
    f(l; col="white", bcol="black") = compose(context(), 
        (context(), l, stroke(col), linewidth(0.2mm)),
        (context(), l, stroke(bcol), linewidth(1mm)) 
    )
    
    function drawsigma!(i,n;cols=fill("white",n), bcol="black")
        i, σ = abs(i), sign(i)
        myline(j) = compose(context(), line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))]), stroke(cols[j]))
        myline2(j) = line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))])
        c = compose(context(),
                (context(), myline.([j for j=1:n if j ∉ (i, i + 1)])..., linewidth(0.2mm)), 
                (context(), myline2.([j for j=1:n if j ∉ (i, i + 1)])..., stroke(bcol), linewidth(1mm)), 
                (context(0,(i-1)/(n-1),1,1/(n-1)), 
                    σ == 1 ? 
                    compose(context(), f(l1; col=cols[i]), f(l2; col=cols[i+1], bcol)) : 
                    compose(context(), f(l2; col=cols[i+1]), f(l1; col=cols[i], bcol))))
        cols[i+1],cols[i] = cols[i], cols[i+1]
        c
    end

    T = length(a)
    strings = [compose(context((k-1)*Δt,0,Δt,1),drawsigma!(a.els[k],N;cols,bcol)) for k=1:T]
    c = compose(context(0,0.1,1,0.8), strings...)
end

function _plot(v::AbstractVector{Int}, N, cols, bcol)
    Δt = 3mm
    isempty(v) && return context()
    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    f(l, col, bcol) = compose(context(), 
        (context(), l, stroke(col), linewidth(0.2mm)),
        (context(), l, stroke(bcol), linewidth(1mm)))
    
    i, σ = abs(v[1]), sign(v[1])
    myline(j) = compose(context(), line([(0,(j-1)/(N-1)),(1,(j-1)/(N-1))]), stroke(cols[j]))
    myline2(j) = line([(0,(j-1)/(N-1)),(1,(j-1)/(N-1))])
    c1 = compose(context(0,0,Δt,1),
        (context(), myline.([j for j=1:N if j ∉ (i, i + 1)])..., linewidth(0.2mm)), 
        (context(), myline2.([j for j=1:N if j ∉ (i, i + 1)])..., stroke(bcol), linewidth(1mm)), 
        (context(0,(i-1)/(N-1),1,1/(N-1)), σ == 1 ? 
                (context(), f(l1, cols[i], bcol), f(l2, cols[i+1], bcol)) : 
                (context(), f(l2, cols[i+1], bcol), f(l1, cols[i], bcol))))
    cols[i+1], cols[i] = cols[i], cols[i+1]
    c2 = _plot((@view v[2:end]), N, cols, bcol)
    compose(c1, compose(context(Δt,0,Δt*(length(v)-1),1), c2))
end

function plot2(a::Braid; N = nstrands(a), cols=HSV.((0:256/(N-1):256),1,1), bcol="black")
    Δt = 3mm
    set_default_graphic_size(Δt * (length(a.els) + 1), N*2mm)
    cols = copy(cols)
    compose(context(0,0.1,1,0.8), _plot(a.els, N, cols, bcol))
end

function Base.show(io::IO, mime::MIME"text/html", a::Braid)
    N = nstrands(a)
    cols = get(io, :cols, HSV.(0:256/(N-1):256,1,1))
    bcol = get(io, :bcol, "black")
    show(io, mime, plot(a; N, cols, bcol))
end

"Do an in-place free simplificaton of a, cancelling out all products of inverses"
function freesimplify!(a::Braid)
    e = a.els
    length(e) <= 1 && return a
    i, j = 1, 2
    
    #multiplies e[1:i] by e[j:end] and adjust i,j
    while j ≤ length(e)
        if i > 0 && e[i] + e[j] == 0
            i -= 1
        else
            i += 1
            e[i] = e[j]
        end
        j += 1
    end
    resize!(e, i)
    return a
end

"Is `i, j` a handle for `a`?"
function ishandle(a::Braid, i::Int, j::Int)
    a.els[i] + a.els[j] != 0 && return false
    x = abs(a.els[i])
    return all(abs(a.els[k]) ∉ (x-1, x) for k in i+1:j-1) 
end

"""
Find next permitted handle of `a`, return `0,0`` if `a` is already reduced 
"""
function nexthandle(a::Braid)
    for j = 2:length(a.els)
        for i = j-1:-1:1
            ishandle(a, i, j) && return i,j       
        end
    end
    return 0,0
end

"""
One H-step of Dehornoy reduction of `a` on handle `i,j`
"""
function reduced(a::Braid, i::Int, j::Int)
    xi,si = abs(a.els[i]), sign(a.els[i])
    @assert (xi,si) == (abs(a.els[j]),-sign(a.els[j]))
    H = a.els[1:i-1]
    for k = i+1:j-1
        xk, sk = abs(a.els[k]), sign(a.els[k])
        @assert xk != xi
        if xk != xi+1
            push!(H, xk * sk)
        else
            push!(H, -xk * si)
            push!(H, xi * sk)
            push!(H, xk * si)
        end
    end
    append!(H, @view a.els[j+1:end])
    freesimplify!(Braid(H))
end

"""
Dehornoy reduction of `a`
"""
function reduced(a::Braid)
    a = freesimplify!(Braid(copy(a.els)))
    while true
        i, j = nexthandle(a)
        i == 0 && return a
        a = reduced(a, i, j)
    end
end

"Fetch the main generator of `a`"
main_generator(a::Braid) = minimum(abs, a.els)

"Is `i,j` a main handle for `a`?"
ismainhandle(a::Braid, i::Int, j::Int) = ishandle(a, i, j) && abs(a.els[i]) == main_generator(a)

"Is `a` reduced?"
function isreduced(a::Braid)
    isempty(a.els) && return true
    maingen = main_generator(a)
    return all(!=(maingen), a.els) || all(!=(-maingen), a.els)
end

Base.:(==)(a::Braid, b::Braid) = isempty(reduced(a*b^-1).els)

Base.length(a::Braid) = length(a.els)

"Produce an expression of `a` in powers of generators, in the form of a Vector of tuples (generator, power)"
function powers(a::Braid)
    w = Tuple{Int,Int}[]
    for x in a.els
        i, σ = abs(x), sign(x)
        if !isempty(w) && w[end][1] == i
            if w[end][2]+σ == 0
                pop!(w)
            else
                w[end] = (w[end][1],w[end][2]+σ)
            end
        else
            push!(w, (i,σ))
        end
    end
    w
end

function Base.show(io::IO, a::Braid)
    isempty(a.els) && print(io, "ε")
    v = get(io, :compact, false) ? powers(a) : [(abs(x), sign(x)) for x in a.els]
    print(io, prod("σ"*subscripts(i)*superscripts(k) for (i,k) in v; init=""))
end

superscripts(x) = x == 1 ? "" : replace(string(x), (a=>b for (a,b) in zip("-01234567890","⁻⁰¹²³⁴⁵⁶⁷⁸⁹"))...)
subscripts(x) = replace(string(x), (a=>b for (a,b) in zip("-01234567890","₋₀₁₂₃₄₅₆₇₈₉"))...)

nothing
