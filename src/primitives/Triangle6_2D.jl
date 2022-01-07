# A quadratic triangle, defined in 2D.
struct Triangle6_2D <: Face_2D
    # The points are assumed to be ordered as follows
    # p₁ = vertex A
    # p₂ = vertex B
    # p₃ = vertex C
    # p₄ = point on the quadratic segment from A to B
    # p₅ = point on the quadratic segment from B to C
    # p₆ = point on the quadratic segment from C to A
    points::SVector{6, Point_2D}
end

# Constructors
# -------------------------------------------------------------------------------------------------
Triangle6_2D(p₁::Point_2D, p₂::Point_2D, p₃::Point_2D,
             p₄::Point_2D, p₅::Point_2D, p₆::Point_2D
            ) = Triangle6_2D(SVector(p₁, p₂, p₃, p₄, p₅, p₆))

# Methods
# -------------------------------------------------------------------------------------------------
# Interpolation
function (tri6::Triangle6_2D)(r::Real, s::Real)
    # See Fhe Visualization Toolkit: An Object-Oriented Approach to 3D Graphics, 4th Edition
    # Chapter 8, Advanced Data Representation, in the interpolation functions section
    rₜ = Float64(r); sₜ = Float64(s)
    return (1 - rₜ - sₜ)*(2(1 - rₜ - sₜ) - 1)*tri6[1] +
                                   rₜ*(2rₜ-1)*tri6[2] +
                                   sₜ*(2sₜ-1)*tri6[3] +
                            4rₜ*(1 - rₜ - sₜ)*tri6[4] +
                                     (4rₜ*sₜ)*tri6[5] +
                            4sₜ*(1 - rₜ - sₜ)*tri6[6]
end

# Interpolation using a point instead of (r,s)
function (tri6::Triangle6_2D)(p::Point_2D)
    r,s = p
    return (1 - r - s)*(2(1 - r - s) - 1)*tri6[1] +
                                 r*(2r-1)*tri6[2] +
                                 s*(2s-1)*tri6[3] +
                           4r*(1 - r - s)*tri6[4] +
                                   (4r*s)*tri6[5] +
                           4s*(1 - r - s)*tri6[6]
end

area(tri6::Triangle6_2D) = area(tri6, Val(3))
function area(tri6::Triangle6_2D, ::Val{N}) where {N}
    # Numerical integration required. Gauss-Legendre quadrature over a triangle is used.
    # Let F(r,s) be the interpolation function for tri6,
    #                             1 1-r                          N
    # A = ∬ ||∂F/∂r × ∂F/∂s||dA = ∫  ∫ ||∂F/∂r × ∂F/∂s|| ds dr = ∑ wᵢ||∂F/∂r(rᵢ,sᵢ) × ∂F/∂s(rᵢ,sᵢ)||
    #      D                      0  0                          i=1
    #
    # N is the number of points used in the quadrature.
    w, r, s = gauss_legendre_quadrature(tri6, Val(N))
    return sum(@. w * abs( ∇(tri6, r, s) |> x->x[1] × x[2] ))
end

centroid(tri6::Triangle6_2D) = centroid(tri6, Val(6))
function centroid(tri6::Triangle6_2D, ::Val{N}) where {N}
    # Numerical integration required. Gauss-Legendre quadrature over a triangle is used.
    # Let F(r,s) be the interpolation function for tri6,
    #                             1 1-r                          N
    # A = ∬ ||∂F/∂r × ∂F/∂s||dA = ∫  ∫ ||∂F/∂r × ∂F/∂s|| ds dr = ∑ wᵢ||∂F/∂r(rᵢ,sᵢ) × ∂F/∂s(rᵢ,sᵢ)||
    #      D                      0  0                          i=1
    #
    # C_x = (∫∫ x dA)/A, C_y = (∫∫ y dA)/A
    #         D                  D
    w, r, s = gauss_legendre_quadrature(tri6, Val(N))
    # We can reuse our computed weighted derivative cross products, since we need these
    # in the C_y, C_y, and A.
    weighted_vals = @. w * abs( ∇(tri6, r, s) |> x->x[1] × x[2] )
    points = tri6.(r, s)
    A = sum(weighted_vals)
    C_x = sum(getindex.(points, 1) .* weighted_vals)
    C_y = sum(getindex.(points, 2) .* weighted_vals)
    return Point_2D(C_x/A, C_y/A)
end

function gradient(tri6::Triangle6_2D, r::Real, s::Real)
    # Let F(r,s) be the interpolation function for tri6
    # Returns ∂F/∂r, ∂F/∂s
    rₜ = Float64(r); sₜ = Float64(s)
    ∂F_∂r = (4rₜ + 4sₜ - 3)*tri6[1] +
                  (4rₜ - 1)*tri6[2] +
            4(1 - 2rₜ - sₜ)*tri6[4] +
                      (4sₜ)*tri6[5] +
                     (-4sₜ)*tri6[6]

    ∂F_∂s = (4rₜ + 4sₜ - 3)*tri6[1] +
                  (4sₜ - 1)*tri6[3] +
                     (-4rₜ)*tri6[4] +
                      (4rₜ)*tri6[5] +
            4(1 - rₜ - 2sₜ)*tri6[6]
    return ∂F_∂r, ∂F_∂s
end

function in(p::Point_2D, tri6::Triangle6_2D)
    # If the point is to the left of every edge
    #  3<-----2
    #  |     ^
    #  | p  /
    #  |   /
    #  |  /
    #  v /
    #  1
    return isleft(p, QuadraticSegment_2D(tri6[1], tri6[2], tri6[4])) &&
           isleft(p, QuadraticSegment_2D(tri6[2], tri6[3], tri6[5])) &&
           isleft(p, QuadraticSegment_2D(tri6[3], tri6[1], tri6[6]))
end

# # Slower method than above.
# function in(p::Point_2D, tri6::Triangle6_2D)
#     return in(p, tri6, 30)
# end
#
# function in(p::Point_2D, tri6::Triangle6_2D, N::Int64)
#     # Determine if the point is in the triangle using the Newton-Raphson method
#     # N is the max number of iterations of the method.
#     p_rs = real_to_parametric(p, tri6, N)
#     ϵ = parametric_coordinate_ϵ
#     # Check that the r coordinate and s coordinate are in [-ϵ,  1 + ϵ] and
#     # r + s ≤ 1 + ϵ
#     # These are the conditions for a valid point in the triangle ± some ϵ
#     if (-ϵ ≤ p_rs[1] ≤ 1 + ϵ) &&
#        (-ϵ ≤ p_rs[2] ≤ 1 + ϵ) &&
#        (p_rs[1] + p_rs[2] ≤ 1 + ϵ)
#         return true
#     else
#         return false
#     end
# end

function intersect(l::LineSegment_2D, tri6::Triangle6_2D)
    # Create the 3 quadratic segments that make up the triangle and intersect each one
    edges = SVector(QuadraticSegment_2D(tri6[1], tri6[2], tri6[4]),
                    QuadraticSegment_2D(tri6[2], tri6[3], tri6[5]),
                    QuadraticSegment_2D(tri6[3], tri6[1], tri6[6]))
    ipoints = MVector(Point_2D(), Point_2D(), Point_2D(),
                      Point_2D(), Point_2D(), Point_2D())
    n_ipoints = 0x00000000
    # We need to account for 6 points returned
    for k ∈ 1:3
        npoints, points = l ∩ edges[k]
        for i ∈ 1:npoints
            n_ipoints += 0x00000001
            ipoints[n_ipoints] = points[i]
        end
    end
    return n_ipoints, SVector(ipoints)
end

function jacobian(tri6::Triangle6_2D, r::Real, s::Real)
    # Return the 2 x 2 Jacobian matrix
    ∂F_∂r, ∂F_∂s = ∇(tri6, r, s)
    return SMatrix{2, 2}(∂F_∂r.x, ∂F_∂r.y,
                         ∂F_∂s.x, ∂F_∂s.y)
end

function real_to_parametric(p::Point_2D, tri6::Triangle6_2D)
    return real_to_parametric(p, tri6, 30)
end

function real_to_parametric(p::Point_2D, tri6::Triangle6_2D, N::Int64)
    # Convert from real coordinates to the triangle's local parametric coordinates using the
    # the Newton-Raphson method. N is the max number of iterations
    # If a conversion doesn't exist, the minimizer is returned.
    r = 0.3333333333333333 # Initial guess at triangle centroid
    s = 0.3333333333333333
    for i ∈ 1:N
        err = p - tri6(r, s)
        # Inversion is faster for 2 by 2 than \
        Δr, Δs = inv(jacobian(tri6, r, s)) * err
        r += Δr
        s += Δs
        if abs(Δr) + abs(Δs) < 1e-6
            break
        end
    end
    return Point_2D(r, s)
end

function triangulate(tri6::Triangle6_2D, N::Int64)
    # N is the number of divisions of each edge
    triangles = Vector{Triangle_2D}(undef, (N+1)*(N+1))
    if N === 0
        triangles[1] = Triangle_2D(tri6[1], tri6[2], tri6[3])
    else
        i = 1
        for S = 1:N, R = 0:N-S
            triangles[i]   = Triangle_2D(tri6(    R/(N+1),     S/(N+1)),
                                         tri6((R+1)/(N+1),     S/(N+1)),
                                         tri6(    R/(N+1), (S+1)/(N+1)))
            triangles[i+1] = Triangle_2D(tri6(    R/(N+1),     S/(N+1)),
                                         tri6((R+1)/(N+1), (S-1)/(N+1)),
                                         tri6((R+1)/(N+1),     S/(N+1)))
            i += 2
        end
        j = (N+1)*N + 1
        for S = 0:0, R = 0:N-S
            triangles[j] = Triangle_2D(tri6(    R/(N+1),     S/(N+1)),
                                       tri6((R+1)/(N+1),     S/(N+1)),
                                       tri6(    R/(N+1), (S+1)/(N+1)))
            j += 1
        end
    end
    return triangles
end

# Plot
# -------------------------------------------------------------------------------------------------
if enable_visualization
    function convert_arguments(LS::Type{<:LineSegments}, tri6::Triangle6_2D)
        q₁ = QuadraticSegment_2D(tri6[1], tri6[2], tri6[4])
        q₂ = QuadraticSegment_2D(tri6[2], tri6[3], tri6[5])
        q₃ = QuadraticSegment_2D(tri6[3], tri6[1], tri6[6])
        qsegs = [q₁, q₂, q₃]
        return convert_arguments(LS, qsegs)
    end

    function convert_arguments(LS::Type{<:LineSegments}, T::Vector{Triangle6_2D})
        point_sets = [convert_arguments(LS, tri6) for tri6 ∈ T]
        return convert_arguments(LS, reduce(vcat, [pset[1] for pset ∈ point_sets]))
    end

    function convert_arguments(P::Type{<:Mesh}, tri6::Triangle6_2D)
        triangles = triangulate(tri6, 13)
        return convert_arguments(P, triangles)
    end

    function convert_arguments(M::Type{<:Mesh}, T::Vector{Triangle6_2D})
        triangles = reduce(vcat, triangulate.(T, 13))
        return convert_arguments(M, triangles)
    end
end
