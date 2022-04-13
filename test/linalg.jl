@testset "linalg" begin
    for T ∈ Floats
        a = SVector{3, T}(1,2,3)
        b = SVector{3, T}(2,4,6)
        @test a ⊙ b ≈ [2, 8, 18]
        @test b ⊘ a ≈ [2, 2, 2]
        @test inv(a)*a ≈ 1
        @test norm²(a) ≈ 1 + 4 + 9
    end
end