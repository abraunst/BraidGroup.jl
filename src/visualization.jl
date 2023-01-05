using Compose, Colors


function plot(a::Braid; compressed=false, Δt = 3mm, N=width(a), cols=HSV.(StepRangeLen(0,360/N,N),1,1), bcol="black")
    cols = copy(cols)
    
    set_default_graphic_size(Δt * (length(a) + 1), N*2mm)

    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    
    f(l; col="white", bcol="black") = compose(context(), 
        (context(), l, stroke(col), linewidth(0.2mm)),
        (context(), l, stroke(bcol), linewidth(1mm)))

    pos(j) = N == 1 ? 0.0 : (j-1)/(N-1)

    crossing(x, s, n) = compose(context(Δt*n, pos(x), Δt, 1/(N-1)), 
            s == 1 ? 
            (context(), f(l1; col=cols[x]), f(l2; col=cols[x+1], bcol)) : 
            (context(), f(l2; col=cols[x+1]), f(l1; col=cols[x], bcol)))

    hline(x, n1, n2) = compose(context(), 
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(cols[x]), linewidth(0.2mm)),
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(bcol), linewidth(1mm)))

    c = compose(context(0,0.1,1,0.8))

    T = length(a)
    T == 0 && return compose(c, hline(1, 0, 1))
    
    lastx = fill(0, N)
    for k = 1:T
        xk, sk = a[k]
        newx = compressed ? max(lastx[xk], lastx[xk + 1]) : k-1
        c = compose(c, hline(xk, lastx[xk], newx), hline(xk+1, lastx[xk+1], newx), crossing(xk, sk, newx))
        cols[xk+1],cols[xk] = cols[xk],cols[xk+1]
        lastx[xk] = newx + 1
        lastx[xk + 1] = newx + 1
    end
    endx = maximum(lastx)
    for x = 1:N
        c = compose(c, hline(x, lastx[x],  endx))
    end
    return c
end



function Base.show(io::IO, mime::MIME"text/html", a::Braid)
    N = width(a)
    cols = get(io, :cols, HSV.(StepRangeLen(0,360/N,N),1,1))
    bcol = get(io, :bcol, "black")
    compressed = get(io, :compressed, false)
    show(io, mime, plot(a; N, cols, bcol, compressed))
end
