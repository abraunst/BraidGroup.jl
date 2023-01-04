using Compose, Colors


function plot(a::Braid; N = width(a), cols=HSV.((0:N-1)./(N-1)*256,1,1), bcol="black")
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
        linefg(j) = compose(context(), line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))]), stroke(cols[j]))
        linebg(j) = compose(context(), line([(0,(j-1)/(n-1)),(1,(j-1)/(n-1))]), stroke(bcol))
        c = compose(context(),
                (context(), linefg.(j for j=1:n if j ∉ (i, i + 1))..., linewidth(0.2mm)), 
                (context(), linebg.(j for j=1:n if j ∉ (i, i + 1))..., linewidth(1mm)), 
                (context(0,(i-1)/(n-1),1,1/(n-1)), 
                    σ == 1 ? 
                    (context(), f(l1; col=cols[i]), f(l2; col=cols[i+1], bcol)) : 
                    (context(), f(l2; col=cols[i+1]), f(l1; col=cols[i], bcol))))
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

function plot2(a::Braid; N = width(a), cols=HSV.((0:256/(N-1):256),1,1), bcol="black")
    Δt = 3mm
    set_default_graphic_size(Δt * (length(a.els) + 1), N*2mm)
    cols = copy(cols)
    compose(context(0,0.1,1,0.8), _plot(a.els, N, cols, bcol))
end

function Base.show(io::IO, mime::MIME"text/html", a::Braid)
    N = width(a)
    cols = get(io, :cols, HSV.(0:256/(N-1):256,1,1))
    bcol = get(io, :bcol, "black")
    show(io, mime, plot(a; N, cols, bcol))
end
