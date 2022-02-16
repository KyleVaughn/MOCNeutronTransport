using MOCNeutronTransport
@testset "LineSegment1D" begin
    for F in [Float32, Float64, BigFloat]
        @testset "Constructors" begin
            p₁ = Point(F(1))
            p₂ = Point(F(2))
            l = LineSegment1D(p₁, p₂)
            @test l.𝘅₁== p₁
            @test l.𝘂 == p₂ - p₁
        end
        @testset "Methods" begin
            # interpolation
            p₁ = Point(F(1))
            p₂ = Point(F(3))
            l = LineSegment1D(p₁, p₂)
            @test l(0) ≈ p₁
            @test l(1) ≈ p₂
            @test l(1//2) ≈ Point(F(2))

            # arclength
            p₁ = Point(F(1))
            p₂ = Point(F(2))
            l = LineSegment1D(p₁, p₂)
            @test arclength(l) ≈ 1
            @test typeof(arclength(l)) == F

            # intersect
            # (₂--(₁------₂)--₁)
            l₁ = LineSegment1D(Point(F(1)), Point(F(3)))
            l₂ = LineSegment1D(Point(F(0)), Point(F(2)))
            bool, l = intersect(l₁, l₂)
            @test bool
            @test l(0) ≈ Point(F(1))
            @test l(1) ≈ Point(F(2))
            # (₁--(₂------₁)--₂)
            l₂ = LineSegment1D(Point(F(1)), Point(F(3)))
            l₁ = LineSegment1D(Point(F(0)), Point(F(2)))
            bool, l = intersect(l₁, l₂)
            @test bool
            @test l(0) ≈ Point(F(1))
            @test l(1) ≈ Point(F(2))
            # (₁--(₂------₂)--₁)
            l₁ = LineSegment1D(Point(F(0)), Point(F(3)))
            l₂ = LineSegment1D(Point(F(1)), Point(F(2)))
            bool, l = intersect(l₁, l₂)
            @test bool
            @test l(0) ≈ Point(F(1))
            @test l(1) ≈ Point(F(2))
            # (₂--(₁------₁)--₂)
            l₂ = LineSegment1D(Point(F(0)), Point(F(3)))
            l₁ = LineSegment1D(Point(F(1)), Point(F(2)))
            bool, l = intersect(l₁, l₂)
            @test bool
            @test l(0) ≈ Point(F(1))
            @test l(1) ≈ Point(F(2))
        end
    end
end

@testset "LineSegment2D" begin
    for F in [Float32, Float64, BigFloat]
        @testset "Constructors" begin
            p₁ = Point2D{F}(1, 0)
            p₂ = Point2D{F}(2, 0)
            l = LineSegment2D(p₁, p₂)
            @test l.𝘅₁== p₁
            @test l.𝘂 == p₂ - p₁
        end
        @testset "Methods" begin
            # interpolation
            p₁ = Point2D{F}(1, 1)
            p₂ = Point2D{F}(3, 3)
            l = LineSegment2D(p₁, p₂)
            @test l(0) ≈ p₁
            @test l(1) ≈ p₂
            @test l(1//2) ≈ Point2D{F}(2, 2)

            # arclength
            p₁ = Point2D{F}(1, 2)
            p₂ = Point2D{F}(2, 4)
            l = LineSegment2D(p₁, p₂)
            @test arclength(l) ≈ sqrt(5)
            @test typeof(arclength(l)) == F

            # intersect
            # -------------------------------------------
            # basic intersection
            l₁ = LineSegment2D(Point2D{F}(0,  1), Point2D{F}(2, -1))
            l₂ = LineSegment2D(Point2D{F}(0, -1), Point2D{F}(2,  1))
            hit, p₁ = intersect(l₁, l₂)
            @test hit
            @test p₁ ≈ Point2D{F}(1, 0)
            @test typeof(p₁) == Point2D{F}

            # vertex intersection
            l₂ = LineSegment2D(Point2D{F}(0, -1), Point2D{F}(2, -1))
            hit, p₁ = l₁ ∩ l₂
            @test hit
            @test p₁ ≈ Point2D{F}(2, -1)

            # vertical
            l₁ = LineSegment2D(Point2D{F}(0,  1), Point2D{F}(2,   1))
            l₂ = LineSegment2D(Point2D{F}(1, 10), Point2D{F}(1, -10))
            hit, p₁ = intersect(l₁, l₂)
            @test hit
            @test p₁ ≈ Point2D{F}(1, 1)

            # nearly vertical
            l₁ = LineSegment2D(Point2D{F}(-1, -100000), Point2D{F}(1,  100000))
            l₂ = LineSegment2D(Point2D{F}(-1,   10000), Point2D{F}(1,  -10000))
            hit, p₁ = l₁ ∩ l₂
            @test hit
            @test p₁ ≈ Point2D{F}(0, 0)

            # parallel
            l₁ = LineSegment2D(Point2D{F}(0, 1), Point2D{F}(1, 1))
            l₂ = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(1, 0))
            hit, p₁ = intersect(l₁, l₂)
            @test !hit

            # collinear
            l₁ = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(2, 0))
            l₂ = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(1, 0))
            hit, p₁ = intersect(l₁, l₂)
            @test !hit

            # line intersects, not segment (invalid s)
            l₁ = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(2, 0    ))
            l₂ = LineSegment2D(Point2D{F}(1, 2), Point2D{F}(1, 1//10))
            hit, p₁ = l₁ ∩ l₂
            @test !hit

            # line intersects, not segment (invalid r)
            l₂ = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(2, 0    ))
            l₁ = LineSegment2D(Point2D{F}(1, 2), Point2D{F}(1, 1//10))
            hit, p₁ = intersect(l₁, l₂)
            @test !hit

            # isleft
            l = LineSegment2D(Point2D{F}(0, 0), Point2D{F}(1, 0))
            @test isleft(Point2D{F}(0, 1) , l)
            @test !isleft(Point2D{F}(0, -1) , l)
            @test !isleft(Point2D{F}(0, -1e-6) , l)
            @test isleft(Point2D{F}(0, 1e-6) , l)
            @test isleft(Point2D{F}(0.5, 0) , l)

            # sort_intersection_points
            l = LineSegment2D(Point2D{F}(0,0), Point2D{F}(10,0))
            p₁ = Point2D{F}(1, 0)
            p₂ = Point2D{F}(2, 0)
            p₃ = Point2D{F}(3, 0)
            points = [p₃, p₁, p₂, Point2D{F}(1 + 1//1000000, 0)]
            sort_intersection_points!(l, points)
            @test points[1] == p₁
            @test points[2] == p₂
            @test points[3] == p₃
        end
    end
end

@testset "LineSegment3D" begin
    for F in [Float32, Float64, BigFloat]
        @testset "Constructors" begin
            p₁ = Point3D{F}(1, 0, 1)
            p₂ = Point3D{F}(2, 0, -1)
            l = LineSegment3D(p₁, p₂)
            @test l.𝘅₁== p₁
            @test l.𝘂 == p₂ - p₁
        end
        @testset "Methods" begin
            # interpolation
            p₁ = Point3D{F}(1, 1, 1)
            p₂ = Point3D{F}(3, 3, 3)
            l = LineSegment3D(p₁, p₂)
            @test l(0) ≈ p₁
            @test l(1) ≈ p₂
            @test l(1//2) ≈ Point3D{F}(2, 2, 2)

            # arclength
            p₁ = Point3D{F}(1, 2, 3)
            p₂ = Point3D{F}(2, 4, 6)
            l = LineSegment3D(p₁, p₂)
            @test arclength(l) ≈ sqrt(14)

            # intersect
            l₁ = LineSegment3D(Point3D{F}(0,  1, 0), Point3D{F}(2, -1, 0))
            l₂ = LineSegment3D(Point3D{F}(0, -1, 0), Point3D{F}(2,  1, 0))
            hit, p₁ = intersect(l₁, l₂)
            @test hit
            @test p₁ ≈ Point3D{F}(1, 0, 0)
            @test typeof(p₁) == Point3D{F}

            # sort_intersection_points
            l = LineSegment3D(Point3D{F}(0,0,0), Point3D{F}(10,0,0))
            p₁ = Point3D{F}(1, 0, 0)
            p₂ = Point3D{F}(2, 0, 0)
            p₃ = Point3D{F}(3, 0, 0)
            points = [p₃, p₁, p₂, Point3D{F}(1 + 1//1000000, 0, 0)]
            sort_intersection_points!(l, points)
            @test points[1] == p₁
            @test points[2] == p₂
            @test points[3] == p₃
        end
    end
end
