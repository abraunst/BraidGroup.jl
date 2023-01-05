using Compose, Colors


function composed(a::Braid; compressed=true, Δt = 3mm, Δy = 2mm, cols=nothing, bcol="black")
    T,N = length(a), width(a)
    cols = isnothing(cols) ? HSV.(StepRangeLen(0,360/N,N),1,1) : copy(cols)
    set_default_graphic_size(Δt * max(T, 1), Δy * N)

    l1 = curve((0,0), (0.5,0), (0.5,1),(1,1))
    l2 = curve((0,1), (0.5,1), (0.5,0),(1,0))
    
    f(l, col) = compose(context(), 
        (context(), l, stroke(col), linewidth(0.2mm)),
        (context(), l, stroke(bcol), linewidth(1mm)))

    pos(j) = (j-0.5)/N

    crossing(x, s, n) = compose(context(Δt*n, pos(x), Δt, 1/N), 
            s == 1 ? 
            (context(), f(l1, cols[x]), f(l2, cols[x+1])) : 
            (context(), f(l2, cols[x+1]), f(l1, cols[x])))

    hline(x, n1, n2) = compose(context(), 
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(cols[x]), linewidth(0.2mm)),
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(bcol), linewidth(1mm)))

    c = compose(context(0,0,1,1))

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
    show(io, mime, composed(a, compressed=false))
end
