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

Base.:(==)(a::Braid, b::Braid) = isone(reduced(a*b^-1))
