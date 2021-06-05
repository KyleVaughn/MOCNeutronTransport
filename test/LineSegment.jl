using MOCNeutronTransport
@testset "LineSegment" begin
    for type in [Float32, Float64, BigFloat]
        @testset "Constructors" begin
            p₁ = Point( type(1) )
            p₂ = Point( type(2) )
            l = LineSegment(p₁,p₂)
            @test l.points[1] == p₁
            @test l.points[2] == p₂
        end
        @testset "Methods" begin
            # arc_length
            p₁ = Point( type.((1, 2, 3)) )
            p₂ = Point( type.((2, 4, 6)) )
            l = LineSegment(p₁, p₂)
            @test arc_length(l) == sqrt(type(14))
            @test typeof(arc_length(l)) == typeof(type(14))

            # evaluation
            p₁ = Point( type.((1, 1, 3)) )
            p₂ = Point( type.((3, 3, 3)) )
            l = LineSegment(p₁, p₂)
            @test l(0.0) == p₁
            @test l(1.0) == p₂
            p₃ = Point( type.((2, 2, 3)) )
            @test l(0.5) == p₃
            typeof(l(0.5).coord) == typeof(type.((2, 4, 6)))

            # intersect
            # -------------------------------------------
            # basic intersection
            l₁ = LineSegment(Point( type.((0, 1)) ), Point( type.((2, -1)) ))
            l₂ = LineSegment(Point( type.((0, -1)) ), Point( type.((2, 1)) ))
            bool, p = intersect(l₁, l₂)
            @test bool
            @test p == Point(type.((1, 0)))
            @test typeof(p.coord) == typeof(SVector(type.((1, 0, 0))))

            # vertex intersection
            l₂ = LineSegment(Point( type.((0, -1)) ), Point( type.((2, -1)) ))
            bool, p = l₁ ∩ l₂
            @test bool
            @test p == Point(2.0, -1.0)

            # basic 3D intersection
            l₁ = LineSegment(Point( type.((1, 0,  1)) ), Point( type.((1,  0, -1)) ))
            l₂ = LineSegment(Point( type.((0, 1, -1)) ), Point( type.((2, -1,  1)) ))
            bool, p = l₁ ∩ l₂
            @test bool
            @test p == Point(1.0, 0.0, 0.0)

            # vertical
            l₁ = LineSegment(Point( type.((0,  1)) ), Point(type.((2,   1))))
            l₂ = LineSegment(Point( type.((1, 10)) ), Point(type.((1, -10))))
            bool, p = intersect(l₁, l₂)
            @test bool
            @test p == Point(1.0, 1.0)

            # nearly vertical
            l₁ = LineSegment(Point( type.((-1, -100000)) ), Point( type.((1,  100000)) ))
            l₂ = LineSegment(Point( type.((-1,   10000)) ), Point( type.((1,  -10000)) ))
            bool, p = l₁ ∩ l₂
            @test bool
            @test p == Point(0.0, 0.0)

            # parallel
            l₁ = LineSegment(Point( type.((0, 1)) ), Point(type.((1, 1))))
            l₂ = LineSegment(Point( type.((0, 0)) ), Point(type.((1, 0))))
            bool, p = intersect(l₁, l₂)
            @test !bool

            # collinear
            l₁ = LineSegment(Point( type.((0, 0)) ), Point( type.((2, 0)) ))
            l₂ = LineSegment(Point( type.((0, 0)) ), Point( type.((1, 0)) ))
            bool, p = intersect(l₁, l₂)
            @test !bool

            # line intersects, not segment (invalid t)
            l₁ = LineSegment(Point( type.((0, 0)) ), Point(type.((2, 0)) ))
            l₂ = LineSegment(Point( type.((1, 2)) ), Point(type.((1, 0.1)) ))
            bool, p = l₁ ∩ l₂
            @test !bool
            @test p ≈ Point(type.((1, 0))) # the closest point on line 1

            # line intersects, not segment (invalid s)
            l₂ = LineSegment(Point( type.((0, 0)) ), Point( type.((2, 0)) ))
            l₁ = LineSegment(Point( type.((1, 2)) ), Point( type.((1, 0.1)) ))
            bool, p = intersect(l₁, l₂)
            @test !bool
            @test p ≈ Point(type.((1, 0))) # the closest point on line 1

            # AABB
            l = LineSegment(Point( type.((-1, 0)) ), Point( type.((2, 3)) ))
            @test AABB(l) == type.((-1, 0, 2, 3))
            l = LineSegment(Point( type.((-1, 0)) ), Point( type.((2, 0)) ))
            @test AABB(l) == type.((-1, 0, 2, 0))
        end
    end
end
