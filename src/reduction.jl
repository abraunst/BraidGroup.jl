"Do an in-place free simplificaton of a, cancelling out consecutive inverses"
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

"In-place Dehornoy H-step"
function reduced!(a::Braid, i::Int, j::Int)
    (xi,si), (xj,sj) = a[i], a[j]
    @assert (xi,si) == (xj,-sj)
    oldb1, oldb2 = i+1:j-1, j+1:length(a)
    numk = count(x->abs(x) == xi + 1, @view a.els[oldb1])
    newb1, newb2, newb = oldb1 .+ (2numk - 1), oldb2 .+ (2numk - 2), i:j+2numk-2
    if numk > 0
        resize!(a.els, length(a) + 2numk - 2)
        a.els[newb2] = @view a.els[oldb2]
        a.els[newb1] = @view a.els[oldb1]
        replace((xk, sk)) = xk == xi + 1 ? (xk*sj, xi*sk, xk*si) : xk*sk
        a.els[newb] .= Iterators.flatten(replace(a[k]) for k in newb1)
    else # just remove i and j
        a.els[newb1] = @view a.els[oldb1]
        a.els[newb2] = @view a.els[oldb2]
        resize!(a.els, length(a) - 2)
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

reduced(a::Braid) = reduced!(copy(a))

function permutation(a::Braid)
    perm = collect(1:width(a))
    for i in eachindex(a)
        x = abs(a.els[i])
        perm[x],perm[x+1] = perm[x+1],perm[x]
    end
    perm
end

"Braid group equivalence, i.e. true if `a` and `b` represent the same group element"
function Base.:(==)(a::Braid, b::Braid)
    all(xa == xb for (xa, xb) in zip(permutation(a), permutation(b))) && 
        isempty(reduced!(a\b))
end

"Fetch the main generator of `a`"
main_generator(a::Braid) = isempty(a) ? 0 : argmin(abs, a.els)

"Braid comparison"
Base.:(<)(a::Braid, b::Braid) = main_generator(reduced!(inv(a)*b)) > 0

Base.isless(a::Braid, b::Braid) = a < b


### slow reduction methods, useful for debugging
###

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

function reduced_slow(a::Braid)
    a = freesimplify!(copy(a))
    while ((i, j) = nexthandle_slow(a)) != (0, 0)
        a = reduced_slow(a, i, j)
    end
    a
end

garside_conjugate!(a::Braid) = (a.els .= (width(a) .- abs.(a.els)) .* sign.(a.els); a)

garside_conjugate(a::Braid) = garside_conjugate!(copy(a))

function compress(a::Braid)
    a = reduced(a);
    b = reduced!(garside_conjugate(a))
    pass = 1
    while length(b) < length(a)
        a, b = b, a
        b = reduced!(garside_conjugate(a))
        pass += 1
    end
    return isodd(pass) ? a : garside_conjugate(a)
end