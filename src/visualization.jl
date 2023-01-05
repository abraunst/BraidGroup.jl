using Compose, Colors


function composed(a::Braid; compressed=true, Δt = 3mm, Δy = 2mm, cols=nothing, bcol="black")
    T,N = length(a), width(a)
    cols = isnothing(cols) ? HSV.(StepRangeLen(0,360/N,N),1,1) : copy(cols)
    set_default_graphic_size(Δt * max(T, 1), Δy * N)
    
    cline(l, col) = compose(context(), 
        (context(), l, stroke(col), linewidth(0.2mm)),
        (context(), l, stroke(bcol), linewidth(1mm)))

    pos(j) = (j-0.5)/N

    function crossing(x, s, n)
        con = context(Δt*n, pos(x), Δt, 1/N)
        c1 = cline(curve((0,0), (0.5,0), (0.5,1),(1,1)), cols[x])
        c2 = cline(curve((0,1), (0.5,1), (0.5,0),(1,0)), cols[x+1])
        s == 1 ? compose(con, c1, c2) : compose(con, c2, c1)
    end

    hline(x, n1, n2) = compose(context(), 
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(cols[x]), linewidth(0.2mm)),
        (context(), line([(Δt*n1,pos(x)), (Δt*n2,pos(x))]), stroke(bcol), linewidth(1mm)))

    c = context()

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
