# Area
# ---------------------------------------------------------------------------------------------
# Uses the shoelace formula (https://en.wikipedia.org/wiki/Shoelace_formula)
function area(poly::Polygon{N, Dim, T}) where {N, Dim, T}
    if Dim === 2
        a = zero(T) # Scalar
    else # Dim === 3
        a = zero(Point{Dim, T}) # Vector
    end
    for i ∈ 1:N
        a += poly[(i - 1) % N + 1] × poly[i % N + 1]
    end
    return norm(a)/2
end
# We can simplify the above for triangles
area(tri::Triangle) = norm((tri[2] - tri[1]) × (tri[3] - tri[1]))/2

# Centroid
# ---------------------------------------------------------------------------------------------
# (https://en.wikipedia.org/wiki/Centroid#Of_a_polygon)
function centroid(poly::Polygon{N, Dim, T}) where {N, Dim, T}
    if Dim === 2
        a = zero(T) # Scalar
        c = SVector{2,T}(0,0)
    else
        a = zero(Point{Dim, T}) # Vector
        c = SVector{2,T}(0,0,0)
    end
    for i ∈ 1:N-1
        subarea = poly[i] × poly[i+1]
        c += subarea*(poly[i] + poly[i+1])
        a += subarea
    end
    return Point(c/(3a))
end
# Use a faster method for triangles
centroid(tri::Triangle) = Point((tri[1] + tri[2] + tri[3])/3)

# Point inside polygon
# ---------------------------------------------------------------------------------------------
# Test if a point is in a polygon for 2D points/polygons
function Base.in(p::Point2D, poly::Polygon{N, 2, T}) where {N, T}
    # Test if the point is to the left of each edge. 
    bool = true
    for i ∈ 1:N
        if !isleft(p, LineSegment2D(poly[(i - 1) % N + 1], poly[i % N + 1]))
            bool = false
            break
        end
    end
    return bool
end
## Test if a point is in a polygon for 2D points/polygons
#function Base.in(p::Point2D, poly::Polygon{N, 2, T}) where {N, T}
#    # Test if the point is to the left of each edge.
#    bool = true
#    for i ∈ 1:N
#        if !isleft(p, LineSegment2D(poly[(i - 1) % N + 1], poly[i % N + 1]))
#            bool = false
#            break
#        end
#    end
#    return bool
#end

# Intersect
# ---------------------------------------------------------------------------------------------
# Intersection of a line segment and polygon in 2D
function Base.intersect(l::LineSegment2D{T}, poly::Polygon{N, 2, T}
                       ) where {N,T <:Union{Float32, Float64}} 
    # Create the line segments that make up the polygon and intersect each one
    points = zeros(MVector{N, Point2D{T}})
    npoints = 0x0000
    for i ∈ 1:N
        hit, point = l ∩ LineSegment2D(poly[(i - 1) % N + 1], poly[i % N + 1]) 
        if hit
            npoints += 0x0001
            @inbounds points[npoints] = point
        end
    end
    return npoints, SVector(points)
end

# Cannot mutate BigFloats in an MVector, so we use a regular Vector
function Base.intersect(l::LineSegment2D{BigFloat}, poly::Polygon{N, 2, BigFloat}) where {N} 
    # Create the line segments that make up the polygon and intersect each one
    points = zeros(Point2D{BigFloat}, N)
    npoints = 0x0000
    for i ∈ 1:N
        hit, point = l ∩ LineSegment2D(poly[(i - 1) % N + 1], poly[i % N + 1]) 
        if hit
            npoints += 0x0001
            @inbounds points[npoints] = point
        end
    end
    return npoints, SVector{N,Point2D{BigFloat}}(points)
end

# Möller, T., & Trumbore, B. (1997). Fast, minimum storage ray-triangle intersection.
function intersect(l::LineSegment3D{T}, tri::Triangle3D{T}) where {T}
    p = Point3D{T}(0, 0, 0)
    𝗲₁ = tri[2] - tri[1]
    𝗲₂ = tri[3] - tri[1]
    𝗱 = l.𝘂
    𝗽 = 𝗱 × 𝗲₂
    det = 𝗽 ⋅ 𝗲₁
    (det > -1e-8 && det < 1e-8) && return (false, p) 
    inv_det = 1/det
    𝘁 = l.𝘅₁ - tri[1]
    u = (𝘁 ⋅ 𝗽)*inv_det
    (u < 0 || u > 1) && return (false, p)
    𝗾 = 𝘁 × 𝗲₁
    v = (𝗾 ⋅ 𝗱)*inv_det
    (v < 0 || u + v > 1) && return (false, p)
    t = (𝗾 ⋅ 𝗲₂)*inv_det
    (t < 0 || t > 1) && return (false, p)
    return (true, l(t))
end

# Triangulate
# ---------------------------------------------------------------------------------------------
# Return the vector of triangles corresponding to the polygon's triangulation
#
# Assumes polygon is convex
function triangulate(poly::Polygon{N, 3, T}) where {N, T}
    triangles = Vector{Triangle3D{T}}(undef, N-2)
    if N === 3
        return [poly]
    end
    for i = 1:N-2
        triangles[i] = Triangle(poly[1], poly[i+1], poly[i+2])
    end
    return triangles
end

# Uses the ear clipping method. 
# (https://en.wikipedia.org/wiki/Polygon_triangulation#Ear_clipping_method)
# This implementation of the ear clipping method is not efficient, but it is 
# very simple.
function triangulate_nonconvex(poly::Polygon{N, 2, T}) where {N, T}
    if N === 3
        return [poly]
    end
    triangles = Vector{Triangle2D{T}}(undef, N-2)
    V = [ i for i = 1:N ]
    nverts = N
    nt = 0
    i = 1
    while 2 < nverts
        if _vertex_is_convex(i, V, poly)
            if _vertex_is_ear(i, V, poly)
                ear = _get_ear(i, V, poly)
                nt += 1
                triangles[nt] = ear
                deleteat!(V, i)
                nverts -= 1
                i -= 1
            end
        end
        i = mod(i, nverts) + 1
    end
    return triangles
end

function _vertex_is_convex(i::Integer, V::Vector{<:Integer}, poly::Polygon{L, 2}) where {L}
    N = length(V)
    vₙ₋₁ = poly[V[mod(i - 2, N) + 1]]
    vₙ   = poly[V[i]]
    vₙ₊₁ = poly[V[mod(i, N) + 1]]
    # 𝘂 × 𝘃 = ‖𝘂‖‖𝘃‖sin(θ), so when θ ∈ [0, π], 0 ≤ sin(θ), hence 0 ≤ 𝘂 × 𝘃
    𝘂 = vₙ₊₁ - vₙ
    𝘃 = vₙ₋₁ - vₙ
    return 0 ≤ 𝘂 × 𝘃 
end

function _get_ear(i::Integer, V::Vector{<:Integer}, poly::Polygon{L, 2}) where {L}
    N = length(V)
    T = SVector(V[mod(i - 2, N) + 1], V[i], V[mod(i, N) + 1])
    return Triangle(getindex.(poly, T))
end

function _vertex_is_ear(i::Integer, V::Vector{<:Integer}, poly::Polygon{L, 2}) where {L}
    bool = true
    N = length(V)
    T = SVector(V[mod(i - 2, N) + 1], V[i], V[mod(i, N) + 1])
    ear = Triangle(getindex.(poly, T)) 
    for v in V
        if v ∉ T && poly[v] ∈ ear
            bool = false
            break
        end
    end
    return bool
end

# Interpolation
# ---------------------------------------------------------------------------------------------
# See The Visualization Toolkit: An Object-Oriented Approach to 3D Graphics, 4th Edition
# Chapter 8, Advanced Data Representation, in the interpolation functions section
function (tri::Triangle)(r, s)
    return Point((1 - r - s)*tri[1] + r*tri[2] + s*tri[3])
end

function (quad::Quadrilateral)(r, s)
    return Point(((1 - r)*(1 - s))quad[1] + 
                       (r*(1 - s))quad[2] + 
                             (r*s)quad[3] + 
                       ((1 - r)*s)quad[4])
end

# Plot
# ---------------------------------------------------------------------------------------------
if enable_visualization
    function convert_arguments(LS::Type{<:LineSegments}, poly::Polygon{N}) where {N}
        lines = [LineSegment(poly[(i-1) % N + 1],
                             poly[    i % N + 1]) for i = 1:N] 
        return convert_arguments(LS, lines)
    end

    function convert_arguments(LS::Type{<:LineSegments}, P::Vector{<:Polygon})
        point_sets = [convert_arguments(LS, poly) for poly ∈  P]
        return convert_arguments(LS, reduce(vcat, [pset[1] for pset ∈ point_sets]))
    end

    function convert_arguments(M::Type{<:Mesh}, tri::Triangle)
        points = [tri[i].coord for i = 1:3]
        face = [1 2 3]
        return convert_arguments(M, points, face)
    end

    function convert_arguments(M::Type{<:Mesh}, T::Vector{<:Triangle})
        points = reduce(vcat, [[tri[i].coord for i = 1:3] for tri ∈  T])
        faces = zeros(Int64, length(T), 3)
        k = 1
        for i in 1:length(T), j = 1:3
            faces[i, j] = k
            k += 1
        end
        return convert_arguments(M, points, faces)
    end

    function convert_arguments(M::Type{<:Mesh}, poly::Polygon)
        return convert_arguments(M, triangulate(poly)) 
    end

    function convert_arguments(M::Type{<:Mesh}, P::Vector{<:Polygon})
        return convert_arguments(M, reduce(vcat, triangulate.(P)))            
    end
end