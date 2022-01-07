# Triangle in 2D defined by its 3 vertices.
struct Triangle_2D <: Face_2D
    points::SVector{3, Point_2D}
end

# Constructors
# -------------------------------------------------------------------------------------------------
Triangle_2D(p₁::Point_2D, p₂::Point_2D, p₃::Point_2D) = Triangle_2D(SVector(p₁, p₂, p₃))

# Methods
# -------------------------------------------------------------------------------------------------
# Interpolation
function (tri::Triangle_2D)(r::Real, s::Real)
    # See The Visualization Toolkit: An Object-Oriented Approach to 3D Graphics, 4th Edition
    # Chapter 8, Advanced Data Representation, in the interpolation functions section
    rₜ = Float64(r); sₜ = Float64(s)
    return (1 - rₜ - sₜ)*tri[1] + rₜ*tri[2] + sₜ*tri[3]
end

function area(tri::Triangle_2D)
    # A = bh/2
    # Let u⃗ = (v₂ - v₁), v⃗ = (v₃ - v₁)
    # b = |u⃗|
    # h = |sin(θ) v⃗|, where θ is the angle between u⃗ and v⃗
    # u⃗ × v⃗ = |u⃗||v⃗| sin(θ), hence
    # A = |u⃗ × v⃗|/2 = bh/2
    u⃗ = tri[2] - tri[1]
    v⃗ = tri[3] - tri[1]
    # 2D cross product returns a scalar
    return abs(u⃗ × v⃗)/2
end

centroid(tri::Triangle_2D) = tri(0.3333333333333333, 0.3333333333333333)

function in(p::Point_2D, tri::Triangle_2D)
    # If the point is to the left of every edge
    #  3<-----2
    #  |     ^
    #  | p  /
    #  |   /
    #  |  /
    #  v /
    #  1
    return isleft(p, LineSegment_2D(tri[1], tri[2])) &&
           isleft(p, LineSegment_2D(tri[2], tri[3])) &&
           isleft(p, LineSegment_2D(tri[3], tri[1]))
end

function intersect(l::LineSegment_2D, tri::Triangle_2D)
    # Create the 3 line segments that make up the triangle and intersect each one
    edges = SVector(LineSegment_2D(tri[1], tri[2]),
                    LineSegment_2D(tri[2], tri[3]),
                    LineSegment_2D(tri[3], tri[1]))
    ipoints = MVector(Point_2D(), Point_2D(), Point_2D())
    n_ipoints = 0x00000000
    # We need to account for 3 points returned due to vertex intersection
    for k ∈ 1:3
        npoints, point = l ∩ edges[k]
        if npoints === 0x00000001
            n_ipoints += 0x00000001
            ipoints[n_ipoints] = point
        end
    end
    return n_ipoints, SVector(ipoints)
end

# Plot
# -------------------------------------------------------------------------------------------------
if enable_visualization
    function convert_arguments(LS::Type{<:LineSegments}, tri::Triangle_2D)
        l₁ = LineSegment_2D(tri[1], tri[2])
        l₂ = LineSegment_2D(tri[2], tri[3])
        l₃ = LineSegment_2D(tri[3], tri[1])
        lines = [l₁, l₂, l₃]
        return convert_arguments(LS, lines)
    end

    function convert_arguments(LS::Type{<:LineSegments}, T::Vector{Triangle_2D})
        point_sets = [convert_arguments(LS, tri) for tri ∈  T]
        return convert_arguments(LS, reduce(vcat, [pset[1] for pset ∈ point_sets]))
    end

    function convert_arguments(M::Type{<:Mesh}, tri::Triangle_2D)
        points = [tri[i] for i = 1:3]
        face = [1 2 3]
        return convert_arguments(M, points, face)
    end

    function convert_arguments(M::Type{<:Mesh}, T::Vector{Triangle_2D})
        points = reduce(vcat, [[tri[i] for i = 1:3] for tri ∈  T])
        faces = zeros(Int64, length(T), 3)
        k = 1
        for i in 1:length(T), j = 1:3
            faces[i, j] = k
            k += 1
        end
        return convert_arguments(M, points, faces)
    end
end
