"Do an in-place free simplificaton of a, cancelling out all products of inverses"
function freesimplify!(a::Braid)
    length(a) <= 1 && return a
    
    i = 1
    for j = 2:length(a)
        #multiplies e[1:i] by e[j:end] and adjust i,j
        if i > 0 && a.els[i] + a.els[j] == 0
            i -= 1
        else
            i += 1
            a.els[i] = a.els[j]
        end
        j += 1
    end
    resize!(a.els, i)
    return a
end

"Is `i, j` a handle for `a`?"
function ishandle(a::Braid, i::Int, j::Int)
    a.els[i] + a.els[j] != 0 && return false
    x = abs(a.els[i])
    return all(abs(a.els[k]) ∉ (x-1, x) for k in i+1:j-1) 
end

"Find next *permitted* handle of `a`, return `0,0`` if `a` is already reduced"
function nexthandle(a::Braid)
    for j = 2:length(a)
        for i = j-1:-1:1
            ishandle(a, i, j) && return i,j       
        end
    end
    return 0,0
end

"One H-step of Dehornoy reduction of `a` on handle `i,j`"
function reduced(a::Braid, i::Int, j::Int)
    (xi,si), (xj,sj) = a[i], a[j]
    @assert (xi,si) == (xj,-sj)
    H = a.els[1:i-1]
    for k = i+1:j-1
        xk, sk = a[k]
        @assert xk != xi
        if xk != xi+1
            push!(H, xk * sk)
        else
            push!(H, -xk * si)
            push!(H, xi * sk)
            push!(H, xk * si)
        end
    end
    @views append!(H, a.els[j+1:end])
    freesimplify!(Braid(H))
end


"Dehornoy reduction of `a`"
function reduced(a::Braid)
    a = freesimplify!(copy(a))
    while ((i, j) = nexthandle(a)) != (0, 0)
        a = reduced(a, i, j)
    end
    a
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

"Braid equivalence, are `a` and `b` the same group element?"
Base.:(==)(a::Braid, b::Braid) = isone(reduced(a*b^-1))
