using Compose, Colors


function composed(a::Braid; compressed=true, Δt = 3mm, Δy = 2mm, cols=nothing, bcol="black")
    T,N = length(a), width(a)
    cols = isnothing(cols) ? HSV.(StepRangeLen(0,360/N,N),1,1) : copy(cols)
    set_default_graphic_size(Δt * max(T, 1), Δy * N)

    # dropped shadow
    shadow(l, col) = compose(context(), 
        (context(), l, stroke(col), linewidth(Δy/10)),
        (context(), l, stroke(bcol), linewidth(Δy/2)))

    function crossing(x, s, t)
        con = context(Δt*t, (x-0.5)/N, Δt, 1/N)
        c1 = shadow(curve((0,0), (0.5,0), (0.5,1), (1,1)), cols[x])
        c2 = shadow(curve((0,1), (0.5,1), (0.5,0), (1,0)), cols[x+1])
        s == 1 ? compose(con, c1, c2) : compose(con, c2, c1)
    end

    hline(x, t1, t2) = shadow(line([(Δt*t1,(x-0.5)/N), (Δt*t2,(x-0.5)/N)]), cols[x]) 

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

function Base.show(io::IO, ::MIME"text/plain", a::Braid)
    p = powers(a)
    foreach(p) do (i,k)
        print(io, "σ"*subscripts(i)*superscripts(k))
    end
    isempty(p) && print(io, "ε")
end