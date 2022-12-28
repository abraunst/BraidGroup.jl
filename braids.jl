using Compose, Colors

struct Braid{N}
    els::Vector{Int} 
    function Braid{N}(x::Vector{Int}) where N
        @assert all(1 ≤ abs(v) ≤ N - 1 for v in x)
        new{N}(x)
    end
end

Braid{N}(x::Int) where N = Braid{N}([x])

one(::Braid{N}) where N = Braid{N}(Int[])

function Base.:^(a::Braid{N}, k::Integer) where N
    if k < 0
        Braid{N}(reduce(vcat, fill(reverse(.-a.els), abs(k))))
    elseif k > 0
        Braid{N}(reduce(vcat, fill(a.els, k)))
    else
        Braid{N}(Int[])
    end 
end

Base.:*(a::Braid{N}, b::Braid{N}) where N = Braid{N}(vcat(a.els,b.els))

Base.inv(a::Braid{N}) where N = Braid{N}(reverse(.- a.els))


function plot(a::Braid{N}; cols=HSV.((0:N-1)./(N-1)*256,1,1), bcol="black") where N
    cols = copy(cols)
    Δt = 3mm
    set_default_graphic_size(Δt * (length(a.els) + 1), N*2mm)

    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    
    f(l; col="white", bcol="black") = compose(context(), 
        compose(context(), l, stroke(col), linewidth(0.2mm)),
        compose(context(), l, stroke(bcol), linewidth(1mm)) 
    )
    
    function drawsigma!(i,n;cols=fill("white",n), bcol="black")
        i, σ = abs(i), sign(i)
        myline(j) = compose(context(), line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))]), stroke(cols[j]))
        myline2(j) = line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))])
        c = compose(context(),
            compose(context(), myline.([j for j=1:n if j ∉ (i, i + 1)])..., linewidth(0.2mm)), 
            compose(context(), myline2.([j for j=1:n if j ∉ (i, i + 1)])..., stroke(bcol), linewidth(1mm)), 
            compose(context(0,(i-1)/(n-1),1,1/(n-1)), 
                    σ == 1 ? 
                    compose(context(), f(l1; col=cols[i]), f(l2; col=cols[i+1], bcol)) : 
                    compose(context(), f(l2; col=cols[i+1]), f(l1; col=cols[i], bcol))))
        cols[i+1],cols[i] = cols[i], cols[i+1]
        c
    end

    T = length(a.els)
    strings = [compose(context((k-1)*Δt,0,Δt,1),drawsigma!(a.els[k],N;cols,bcol)) for k=1:T]
    c = compose(context(0,0.1,1,0.8), strings...)
end

function _plot(v::AbstractVector{Int}, N::Int; cols=HSV.((0:N-1)./(N-1)*256,1,1), bcol="black")
    Δt = 3mm
    isempty(v) && return context()
    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    f(l; col="white", bcol="black") = compose(context(), 
        compose(context(), l, stroke(col), linewidth(0.2mm)),
        compose(context(), l, stroke(bcol), linewidth(1mm)) 
    )
    
    i, σ = abs(v[1]), sign(v[1])
    myline(j) = compose(context(), line([(0,(j-1)/(N-1)),(1,(j-1)/(N-1))]), stroke(cols[j]))
    myline2(j) = line([(0,(j-1)/(N-1)),(1,(j-1)/(N-1))])
    c1 = compose(context(0,0,Δt,1),
        compose(context(), myline.([j for j=1:N if j ∉ (i, i + 1)])..., linewidth(0.2mm)), 
        compose(context(), myline2.([j for j=1:N if j ∉ (i, i + 1)])..., stroke(bcol), linewidth(1mm)), 
        compose(context(0,(i-1)/(N-1),1,1/(N-1)), 
                σ == 1 ? 
                compose(context(), f(l1; col=cols[i]), f(l2; col=cols[i+1], bcol)) : 
                compose(context(), f(l2; col=cols[i+1]), f(l1; col=cols[i], bcol))))
    cols[i+1], cols[i] = cols[i], cols[i+1]
    c2 = _plot((@view v[2:end]), N; cols, bcol)
    compose(c1, compose(context(Δt,0,Δt*(length(v)-1),1), c2))
end

function plot2(a::Braid{N}; cols=HSV.((0:N-1)./(N-1)*256,1,1), bcol="black") where N
    Δt = 3mm
    set_default_graphic_size(Δt * (length(a.els) + 1), N*2mm)
    cols = copy(cols)
    compose(context(0,0.1,1,0.8), _plot((@view a.els[1:end]), N; cols, bcol))
end


function Base.show(io::IO, a::Braid)
    print(io, prod("σ".*subscripts.(a.els)))
end

function subscripts(x)
    x, σ = abs(x), sign(x)
    s = prod(getindex.((("₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"),), 
                reverse(digits(x)).+1))
    σ == -1 ? s * "⁻¹" : s
 end 

 nothing
