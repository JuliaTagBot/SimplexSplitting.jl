
@testset "Embedding" begin
    ex1 = embedding_example(10, 3, 1)
    @test size(ex1)[1] == 8
    @test size(ex1)[2] == 3
end
