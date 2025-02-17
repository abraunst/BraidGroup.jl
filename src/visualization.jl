using Compose, Colors


function composed(a::Braid; 
        N=width(a), compressed=false,  
        lcols=(HSV(c,1,1) for c in StepRangeLen(0,360/N,N)), 
        bcol="black", lw=1/5N
    )
    N >= width(a) || throw(ArgumentError("N smaller than width(a)"))
    T = length(a)
    cols = collect(lcols)

    # dropped shadow
    function shadow(l, col)
        compose(context(), (context(), l, stroke(col), linewidth(lw)),
        isnothing(bcol) ? context() : (context(), l, stroke(bcol), linewidth(2*lw)))
    end

    # a crossing
    function crossing(x, s, t)
        con = context(t, (x-0.5), 1, 1)
        c1 = shadow(curve((0w,0h), (0.5w,0h), (0.5w,1h), (1w,1h)), cols[x])
        c2 = shadow(curve((0w,1h), (0.5w,1h), (0.5w,0h), (1w,0h)), cols[x+1])
        s == 1 ? compose(con, c1, c2) : compose(con, c2, c1)
    end

    # horizontal line
    function hline(x, t1, t2)
        shadow(line([(t1,(x-0.5)), (t2,(x-0.5))]), cols[x])
    end

    lastx = fill(0, N)

    endx = if compressed
        for k = 1:T
            xk, = a[k]
            newx = max(lastx[xk], lastx[xk + 1])
            lastx[xk] = newx + 1
            lastx[xk + 1] = newx + 1
        end
        max(maximum(lastx), 1)
    else
        T + 1 
    end

    c = context(units=UnitBox(0,0,endx,N))

    lastx .= 0

    for k = 1:T
        xk, sk = a[k]
        newx = compressed ? max(lastx[xk], lastx[xk + 1]) : k-1
        c = compose(c, hline(xk, lastx[xk], newx), hline(xk+1, lastx[xk+1], newx), crossing(xk, sk, newx))
        cols[xk+1],cols[xk] = cols[xk],cols[xk+1]
        lastx[xk] = newx + 1
        lastx[xk + 1] = newx + 1
    end

    for x in 1:N
        c = compose(c, hline(x, lastx[x],  endx))
    end
    return c, endx
end

function plot(a::Braid; N=width(a), Δt = 3mm, Δy = 2mm, lw=Δy/6, kwd...)
    c, endx = composed(a; N, lw, kwd...)
    set_default_graphic_size(Δt * endx, Δy * N)
    compose(context(), c)
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

superscripts(x) = x == 1 ? "" : replace(string(x), (a=>b for (a,b) in zip("-01234567890","⁻⁰¹²³⁴⁵⁶⁷⁸⁹"))...)

subscripts(x) = replace(string(x), (a=>b for (a,b) in zip("-01234567890","₋₀₁₂₃₄₅₆₇₈₉"))...)

function Base.show(io::IO, ::MIME"text/plain", a::Braid)
    println(io, "Braid (width=$(width(a)), length=$(length(a))):")
    p = powers(a)
    foreach(p) do (i,k)
        print(io, "σ", subscripts(i), superscripts(k))
    end
    isempty(p) && print(io, "ε")
end

function Base.show(io::IO, ::MIME"text/latex", a::Braid)
    println(io, "Braid in \$B_{$(width(a))}\$ with \$|\\cdot|=$(length(a))\$\n\n")
    p = powers(a)
    print(io, "\$")
    foreach(p) do (i,k)
        print(io, k == 1 ? "\\sigma_{$i}" : "\\sigma_{$i}^{$k}")
    end
    isempty(p) && print(io, "\\varepsilon")
    print(io, "\$")
end

function Base.show(io::IO, mime::MIME"text/html", a::Braid)
    #println(io, "<p>Braid (width=$(width(a)), length=$(length(a))):</p>")
    show(io, MIME"text/plain"(), a)
    println(io, "<p></p>")
    show(io, mime, plot(a, compressed=false))
end
