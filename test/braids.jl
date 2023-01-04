σ = braid.(1:10);

x = rand(1:10, 10) .* rand((-1,1), 10)
b = Braid(x)

@testset "Basic operations" begin
    @test Braid(x).els == braid(x...).els == prod(braid(i) for i in x).els
    @test length(inv(b)) == length(b)
    @test width(inv(b)) == width(b)
    @test length(b^4) == 4*length(b)
    @test width(b^4) == width(b)
    @test inv(b).els == (b^-1).els
end


@testset "Reduction and equality" begin
    @test all(braid(i, i+1, i) == braid(i + 1, i, i + 1) for i = 1:20)
    @test b*b^-1 == one(Braid)
end