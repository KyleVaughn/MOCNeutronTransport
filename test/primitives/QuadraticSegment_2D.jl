using MOCNeutronTransport
@testset "QuadraticSegment_2D" begin
    for F in [Float32, Float64]
        @testset "Constructors" begin
            # Constructor
            x⃗₁ = Point_2D(F, 0, 0)
            x⃗₂ = Point_2D(F, 2, 0)
            x⃗₃ = Point_2D(F, 1, 1)
            q = QuadraticSegment_2D(x⃗₁, x⃗₂, x⃗₃)
            @test q.points == SVector(x⃗₁, x⃗₂, x⃗₃)
        end

        @testset "Methods" begin
            # interpolation
            x⃗₁ = Point_2D(F, 0, 0)
            x⃗₂ = Point_2D(F, 2, 0)
            x⃗₃ = Point_2D(F, 1, 1)

            q = QuadraticSegment_2D(x⃗₁, x⃗₂, x⃗₃)
            @test q.points == SVector(x⃗₁, x⃗₂, x⃗₃)
            for t = LinRange{F}(0, 1, 11)
                @test q(t) ≈ Point_2D(F, 2t, -(2t)^2 + 4t)
            end

            # arc_length
            x⃗₁ = Point_2D(F, 0, 0,)
            x⃗₂ = Point_2D(F, 2, 0,)
            x⃗₃ = Point_2D(F, 1, 0,)
            q = QuadraticSegment_2D(x⃗₁, x⃗₂, x⃗₃)

            # straight edge
            @test abs(arc_length(q) - 2) < 1.0e-6
            # curved
            x⃗₃ = Point_2D(F, 1, 1)
            q = QuadraticSegment_2D(x⃗₁, x⃗₂, x⃗₃)
            @test abs(arc_length(q) - 2.9578857151786138) < 1.0e-6

            # intersect
            x⃗₁ = Point_2D(F, 0, 0)
            x⃗₂ = Point_2D(F, 2, 0)
            x⃗₃ = Point_2D(F, 1, 1)
            x⃗₄ = Point_2D(F, 1, 0)
            x⃗₅ = Point_2D(F, 1, 2)

            # 1 intersection
            q = QuadraticSegment_2D(x⃗₁, x⃗₂, x⃗₃)
            l = LineSegment_2D(x⃗₄, x⃗₅)
            npoints, (point1, point2) = intersect(l, q)
            @test npoints == 1
            @test point1 ≈ Point_2D(F, 1, 1)

            # 2 intersections
            x⃗₄ = Point_2D(F, 0, 3//4)
            x⃗₅ = Point_2D(F, 2, 3//4)
            l = LineSegment_2D(x⃗₄, x⃗₅)
            npoints, (point1, point2) = l ∩ q
            @test npoints == 2
            @test point1 ≈ Point_2D(F, 1//2, 3//4)
            @test point2 ≈ Point_2D(F, 3//2, 3//4)

            # 0 intersections
            x⃗₄ = Point_2D(F, 0, 3)
            x⃗₅ = Point_2D(F, 2, 3)
            l = LineSegment_2D(x⃗₄, x⃗₅)
            npoints, (point1, point2) = intersect(l, q)
            @test npoints == 0
            @test point1 ≈ Point_2D(F, 0)
            @test point2 ≈ Point_2D(F, 0)
        end
    end
end