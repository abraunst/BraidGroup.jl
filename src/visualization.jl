using Compose, Colors


function composed(a::Braid; compressed=true, Δt = 3mm, Δy = 2mm, cols=nothing, bcol="black")
    T,N = length(a), width(a)
    cols = isnothing(cols) ? HSV.(StepRangeLen(0,360/N,N),1,1) : copy(cols)

    # dropped shadow
    shadow(l, col) = compose(context(), 
        (context(), l, stroke(col), linewidth(Δy/10)),
        bcol == nothing ? context() : (context(), l, stroke(bcol), linewidth(Δy/3)))

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

    set_default_graphic_size(Δt * (endx + 2), Δy * N)

    return c
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
    println(io, "<p>Braid (width=$(width(a)), length=$(length(a))):</p>")
    show(io, mime, composed(a, compressed=false))
end

function Base.show(io::IO, mime::MIME"image/svg+xml", a::Braid)
    show(io, mime, composed(a, compressed=false))
end
