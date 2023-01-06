using BlockArrays

# fixed braids
vori = Braid[Braid([-1, 15, 4, -2]), Braid([-1, -5, 10]), Braid([3, -12, -3, -5, 9, -6, -6, -3, -8, -3, -5, -6]), Braid([-6, 8, 4, -6, 10, 10, 4, 6, -10, 4, -12, -12, -6, 3, 10, 12, -6, -8, 2]), Braid([-3, -15, -5, -12, 15, -15, -12, 6, 4, -4, 8, 8]), Braid([2, 1, -2]), Braid([-5, 9, -9, 4, -4, -10, -2, 5, -2, -3, -4, -1, 9, -1, 4, 4, 2, 3]), Braid([-15, 2, -2, 9, -3, 12, 1, -4, 2, 9, 10]), Braid([-15, 3, 5, -10, -9, 4]), Braid([-9, -2, -12, -4, 6, 3, 12, 10, -6, -3, 6])]
vred = Braid[Braid([-1, 15, 4, -2]), Braid([-1, -5, 10]), Braid([-12, -5, 9, -6, -6, -3, -8, -3, -5, -6]), Braid([-6, 4, 10, 4, 4, -12, -6, 3, 10, -6, 2]), Braid([-3, -15, -5, -12, -12, 6, 8, 8]), Braid([2, 1, -2]), Braid([-10, -2, -2, -3, -1, 9, -1, 4, 2, 3]), Braid([-15, 9, -3, 12, 1, -4, 2, 9, 10]), Braid([-15, 3, 5, -10, -9, 4]), Braid([-9, -2, -4, 10, 6])]

@testset "Basic operations" begin
    for b in vori
        @test Braid(b.els).els == braid(b.els...).els == prod(braid.(b.els)).els
        @test length(inv(b)) == length(b)
        @test width(inv(b)) == width(b)
        @test length(b^4) == 4*length(b)
        @test width(b^4) == width(b)
        @test inv(b).els == (b^-1).els
    end
end

@testset "Reduction and equality" begin
    # check Artin's rules
    @test all(braid(i, i + 1, i) == braid(i + 1, i, i + 1) for i = 1:20)
    @test all(braid(i, i + k) == braid(i + k, i) for i = 1:20, k=2:5)

    # check fast reduction against slow
    for i=1:30
        b = Braid(rand(vcat(-5:-1, 1:5), rand((1,2,3,10,20))))
        @test BraidGroup.reduced_slow(b) == reduced(b)
    end
    for (a,b) in zip(vori, vred)
        @test a*a^-1 == one(Braid)
        @test a == b
        @test reduced(a).els == BraidGroup.reduced_slow(a).els == b.els
    end
end

@testset "Comparison and sorting" begin
    for (a,b) in zip(sort(vori), sort(vred))
        @test reduced(a).els == BraidGroup.reduced_slow(a).els == b.els
    end
end

gar(n) = Braid(mortar([1:i for i=n-1:-1:1]))

@testset "Exotic containers" begin
    for n=5:10
        gar(n).els == Braid(gar(n).els |> collect).els
    end
end

@testset "Garside" begin
    for b in vori
        n = width(b)
        @test gar(n)\b*gar(n) == garside_conjugate(b)
    end
end