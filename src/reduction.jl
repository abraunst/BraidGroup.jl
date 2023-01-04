"Do an in-place free simplificaton of a, cancelling out all products of inverses"
function freesimplify!(a::Braid)
    length(a) <= 1 && return a
    
    i = 1
    for j = 2:length(a)
        #multiplies a[1:i] by a[j:end] and adjust i,j
        if i > 0 && a.els[i] + a.els[j] == 0
            i -= 1
        else
            i += 1
            a.els[i] = a.els[j]
        end
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

function nexthandle_slow(a::Braid)
    for j = 2:length(a)
        for i = j-1:-1:1
            ishandle(a, i, j) && return i,j       
        end
    end
    return 0,0
end


"Find next *permitted* handle of `a`, return `0,0`` if `a` is already reduced"
function nexthandle(a::Braid, last = fill(0, width(a)))
    length(a) < 2 && return 0,0
    last .= 0
    for j = 1:length(a)
        xj,sj = a[j]
        i = last[xj] # i is a candidate
        if i >= 1 && sj != sign(a.els[i]) && (xj == 1 || last[xj - 1] < i)
            return i,j
        end
        last[xj] = j
    end
    return 0,0
end

"One H-step of Dehornoy reduction of `a` on handle `i,j`"
function reduced_slow(a::Braid, i::Int, j::Int)
    (xi,si), (xj,sj) = a[i], a[j]
    @assert (xi,si) == (xj,-sj)
    H = a.els[1:i-1]
    for k = i+1:j-1
        xk, sk = a[k]
        @assert xk != xi
        if xk != xi + 1
            push!(H, xk * sk)
        else
            push!(H,-xk * si)
            push!(H, xi * sk)
            push!(H, xk * si)
        end
    end
    @views append!(H, a.els[j+1:end])
    freesimplify!(Braid(H))
end

"in-place Dehornoy H-step"
function reduced!(a::Braid, i::Int, j::Int)
    (xi,si), (xj,sj) = a[i], a[j]
    @assert (xi,si) == (xj,-sj)
    numk = count(x->abs(x) == xi + 1, @view a.els[i+1:j-1])
    oldlen = length(a)
    newlen = oldlen + 2numk - 2
    rnew = (i+1:j-1) .+ (2numk - 1)
    if newlen >= oldlen 
        resize!(a.els, newlen)
        a.els[(j+1:oldlen) .+ (2numk - 2)] = @view a.els[j+1:oldlen]
        a.els[rnew] = @view a.els[i+1:j-1]
    else
        a.els[rnew] = @view a.els[i+1:j-1]
        a.els[(j+1:oldlen) .+ (2numk - 2)] = @view a.els[j+1:oldlen]
        resize!(a.els, newlen)
    end
    pos = i
    for k in rnew
        xk, sk = a[k]
        @assert xk != xi
        if xk != xi + 1
            a.els[pos] =  xk * sk; pos += 1
        else
            a.els[pos] =  xk * sj; pos += 1
            a.els[pos] =  xi * sk; pos += 1
            a.els[pos] =  xk * si; pos += 1
        end
    end
    freesimplify!(a)
end


"Dehornoy reduction of `a`"
function reduced!(a::Braid)
    last = fill(0, width(a))
    freesimplify!(a)
    while ((i, j) = nexthandle(a, last)) != (0, 0)
        reduced!(a, i, j)
    end
    a
end

function reduced_slow(a::Braid)
    last = fill(0, width(a))
    a = freesimplify!(copy(a))
    while ((i, j) = nexthandle(a, last)) != (0, 0)
        a = reduced_slow(a, i, j)
    end
    a
end

reduced(a::Braid) = reduced!(copy(a))

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
