# A line segment, defined as the set of all points such that 𝗹(r) = 𝘅₁ + r𝘂, 
# where r ∈ [0, 1]. 𝘅₁ is the line segment start and 𝘅₂ = 𝘅₁ + 𝘂 is the line 
# segment end.
#
# We store 𝘂 instead of 𝘅₂, since 𝘅₂ is needed infrequently, but 𝘂 is needed often.
struct LineSegment{Dim, T} <:Edge{Dim, 1, T}
    𝘅₁::Point{Dim, T} 
    𝘂::SVector{Dim, T}
end

const LineSegment2D = LineSegment{2}

function Base.getproperty(l::LineSegment, sym::Symbol)
    if sym === :𝘅₂
        return Point(l.𝘅₁ + l.𝘂)
    else # fallback to getfield
        return getfield(l, sym)
    end
end

# Constructors
# ---------------------------------------------------------------------------------------------
# Points
LineSegment{Dim, T}(𝘅₁::Point{Dim, T}, 
                    𝘅₂::Point{Dim, T}) where {Dim, T} = LineSegment{Dim, T}(𝘅₁, 𝘅₂ - 𝘅₁) 
LineSegment{Dim}(𝘅₁::Point{Dim, T}, 
                 𝘅₂::Point{Dim, T}) where {Dim, T} = LineSegment{Dim, T}(𝘅₁, 𝘅₂ - 𝘅₁) 
LineSegment(𝘅₁::Point{Dim, T}, 
            𝘅₂::Point{Dim, T}) where {Dim, T} = LineSegment{Dim, T}(𝘅₁, 𝘅₂ - 𝘅₁) 
# Vector
LineSegment{Dim, T}(pts::SVector{2, Point{Dim, T}}
                   ) where {Dim, T} = LineSegment{Dim, T}(pts[1], pts[2] - pts[1]) 
LineSegment{Dim}(pts::SVector{2, Point{Dim, T}}
                ) where {Dim, T} = LineSegment{Dim, T}(pts[1], pts[2] - pts[1]) 
LineSegment(pts::SVector{2, Point{Dim, T}}
           ) where {Dim, T} = LineSegment{Dim, T}(pts[1], pts[2] - pts[1]) 

# Methods
# ---------------------------------------------------------------------------------------------
# Interpolation
# Note: 𝗹(0) = 𝘅₁, 𝗹(1) = 𝘅₂
@inline (l::LineSegment)(r) = Point(l.𝘅₁.coord + r*l.𝘂)
@inline arclength(l::LineSegment) = distance(l.𝘅₁.coord, l.𝘅₁.coord + l.𝘂)

# Intersection of two 2D line segments
#
# Doesn't work for colinear/parallel lines. (𝘂 × 𝘃 = 𝟬).
# For 𝗹₁(r) = 𝘅₁ + r𝘂 and 𝗹₂(s) = 𝘅₂ + s𝘃
# 1) 𝘅₁ + r𝘂 = 𝘅₂ + s𝘃                  subtracting 𝘅₁ from both sides
# 2) r𝘂 = (𝘅₂-𝘅₁) + s𝘃                  𝘄 = 𝘅₂-𝘅₁
# 3) r𝘂 = 𝘄 + s𝘃                        cross product with 𝘃 (distributive)
# 4) r(𝘂 × 𝘃) = 𝘄 × 𝘃 + s(𝘃 × 𝘃)        𝘃 × 𝘃 = 𝟬
# 5) r(𝘂 × 𝘃) = 𝘄 × 𝘃                   let 𝘄 × 𝘃 = 𝘅 and 𝘂 × 𝘃 = 𝘇
# 6) r𝘇 = 𝘅                             dot product 𝘇 to each side
# 7) r𝘇 ⋅ 𝘇 = 𝘅 ⋅ 𝘇                     divide by 𝘇 ⋅ 𝘇
# 8) r = (𝘅 ⋅ 𝘇)/(𝘇 ⋅ 𝘇)
# We need to ensure r, s ∈ [0, 1], hence we need to solve for s too.
# 1) 𝘅₂ + s𝘃 = 𝘅₁ + r𝘂                     subtracting 𝘅₂ from both sides
# 2) s𝘃 = -𝘄 + r𝘂                          cross product with 𝘄
# 3) s(𝘃 × 𝘄) = -𝘄 × 𝘄 + r(𝘂 × 𝘄)          𝘄 × 𝘄 = 𝟬 
# 4) s(𝘃 × 𝘄) = r(𝘂 × 𝘄)                   using 𝘂 × 𝘄 = -(𝘄 × 𝘂), likewise for 𝘃 × 𝘄
# 5) s(𝘄 × 𝘃) = r(𝘄 × 𝘂)                   let 𝘄 × 𝘂 = 𝘆. use 𝘄 × 𝘃 = 𝘅
# 6) s𝘅 = r𝘆                               dot product 𝘅 to each side
# 7) s(𝘅 ⋅ 𝘅) = r(𝘆 ⋅ 𝘅)                   divide by (𝘅 ⋅ 𝘅)
# 9) s = r(𝘅 ⋅ 𝘆)/(𝘅 ⋅ 𝘅)
# The cross product of two vectors in the plane is a vector of the form (0, 0, k),
# hence:
# r = (𝘅 ⋅ 𝘇)/(𝘇 ⋅ 𝘇) = x₃/z₃ 
# s = r(𝘅 ⋅ 𝘆)/(𝘅 ⋅ 𝘅) = y₃/z₃ 
function Base.intersect(l₁::LineSegment2D{T}, l₂::LineSegment2D{T}) where {T}
    ϵ = T(5e-6) # Tolerance on r,s ∈ [-ϵ, 1 + ϵ]
    𝘄 = l₂.𝘅₁ - l₁.𝘅₁
    z = l₁.𝘂 × l₂.𝘂
    r = (𝘄 × l₂.𝘂)/z
    s = (𝘄 × l₁.𝘂)/z
    return (T(1e-8) < abs(z) && -ϵ ≤ r ≤ 1 + ϵ 
                             && -ϵ ≤ s ≤ 1 + ϵ, l₂(s)) # (hit, point)
end

# If the point is left of the line segment in the 2D plane. 
#
# The segment's direction is from 𝘅₁ to 𝘅₂. Let 𝘂 = 𝘅₂ - 𝘅₁ and 𝘃 = 𝗽 - 𝘅₁ 
# We may determine if the angle θ between the point and segment is in [0, π] based on the 
# sign of 𝘂 × 𝘃, since 𝘂 × 𝘃 = ‖𝘂‖‖𝘃‖sin(θ). 
#   𝗽    ^
#   ^   /
# 𝘃 |  / 𝘂
#   | /
#   o
# We allow points on the line (𝘂 × 𝘃 = 0) to be left, since this test is primarily 
# used to determine if a point is inside a polygon. A mesh is supposed to partition
# its domain, so if we do not allow points on the line, there will exist points in the 
# mesh which will not be in any face, violating that rule.
@inline function isleft(p::Point2D, l::LineSegment2D)
    return 0 ≤ l.𝘂 × (p - l.𝘅₁) 
end

# Random line in the Dim-dimensional unit hypercube
function Base.rand(::Type{LineSegment{Dim, F}}) where {Dim, F} 
    points = rand(Point{Dim, F}, 2)
    return LineSegment{Dim, F}(points[1], points[2])
end

# N random lines in the Dim-dimensional unit hypercube
function Base.rand(::Type{LineSegment{Dim, F}}, N::Int64) where {Dim, F}
    return [ rand(LineSegment{Dim, F}) for i ∈ 1:N ]
end

# Sort points on a line segment based on their distance from the segment's start point. 
#function sort!(l::LineSegment, points::Vector{<:Point})
#
#end

#defalg(v::Vector{<:Point}) = Base.Sort.InsertionSort
#function sort!(l::LineSegment, points::Vector{<:Point}; alg::Base.Sort.Algorithm=defalg(points))
#    sort!(l, points, firstindex(points), lastindex(points), alg)
#end
#
#function sort(l::LineSegment, points::Vector{<:Point})
#    # Insertion sort
#    points_copy = similar(points)
#    @. points_copy = points
#    sort!(l, points_copy)
#    return points_copy
#end
#
function sort!(p::Point, v::Vector{<:Point}, lo::Integer, hi::Integer, 
               ::Base.Sort.InsertionSortAlg, o::Base.Ordering)
    @inbounds for i ∈ lo+1:hi
        j = i
        dist = distance²(p, v[i])
        pt = v[i]
        while j > lo
            if Base.lt(o, dist, distance²(p, v[j-1]))
                v[j] = v[j-1]
                j -= 1
                continue
            end
            break
        end
        v[j] = pt
    end
    return v
end

@inline function selectpivot!(p::Point, v::Vector{<:Point}, lo::Integer, hi::Integer,
    o::Base.Ordering)
    @inbounds begin
        mi = Base.Sort.midpoint(lo, hi)

        # sort v[mi] <= v[lo] <= v[hi] such that the pivot is immediately in place
        dlo = distance²(p, v[lo])
        dmi = distance²(p, v[mi])
        dhi = distance²(p, v[hi])
        if Base.lt(o, dlo, dmi)
            v[mi], v[lo] = v[lo], v[mi]
            dmi, dlo = dlo, dmi
        end

        if Base.lt(o, dhi, dlo)
            if Base.lt(o, dhi, dmi)
                v[hi], v[lo], v[mi] = v[lo], v[mi], v[hi]
            else
                v[hi], v[lo] = v[lo], v[hi]
            end
        end

        # return the pivot
        return v[lo]
    end
end

function partition!(p::Point, v::Vector{<:Point}, lo::Integer, hi::Integer, o::Base.Ordering)
    pivot = selectpivot!(p, v, lo, hi, o)
    dpivot = distance²(p, pivot)
    # pivot == v[lo], v[hi] > pivot
    i, j = lo, hi
    @inbounds while true
        i += 1; j -= 1
        while Base.lt(o, distance²(p, v[i]), dpivot); i += 1; end;
        while Base.lt(o, dpivot, distance²(p, v[j])); j -= 1; end;
        i >= j && break
        v[i], v[j] = v[j], v[i]
    end
    v[j], v[lo] = pivot, v[j]

    # v[j] == pivot
    # v[k] >= pivot for k > j
    # v[i] <= pivot for i < j
    return j
end

#function sort!(p::Point, points::Vector{<:Point}, lo::Integer, hi::Integer,
#               a::Base.Sort.QuickSort, o::Base.Ordering)
#    @inbounds while lo < hi
#        if hi-lo ≤ Base.Sort.SMALL_THRESHOLD
#            return sort!(l, points, lo, hi, Base.Sort.SMALL_ALGORITHM)
#        end
#        j = partition!(v, lo, hi, o)
#        if j-lo < hi-j
#            # recurse on the smaller chunk
#            # this is necessary to preserve O(log(n))
#            # stack space in the worst case (rather than O(n))
#            lo < (j-1) && sort!(l, points, lo, j-1, a)
#            lo = j+1
#        else
#            j+1 < hi && sort!(l, points, j+1, hi, a)
#            hi = j-1
#        end
#    end
#    return points
#end


## Sort intersection points along a line segment, deleting points that are less than 
## the minimum_segment_length apart
#function sort_intersection_points!(l::LineSegment, points::Vector{<:Point})
#    sortpoints!(l, points)
#    id_start = 1 
#    id_stop = 2 
#    npoints = length(points)
#    while id_stop <= npoints
#        if distance²(points[id_start], points[id_stop]) < minimum_segment_length^2
#            deleteat!(points, id_stop)
#            npoints -= 1
#        else
#            id_start = id_stop
#            id_stop += 1
#        end
#    end
#end

# Plot
# ---------------------------------------------------------------------------------------------
if enable_visualization
    function convert_arguments(LS::Type{<:LineSegments}, l::LineSegment)
        return convert_arguments(LS, [l.𝘅₁, l.𝘅₂])
    end

    function convert_arguments(LS::Type{<:LineSegments}, L::Vector{<:LineSegment})
        return convert_arguments(LS, reduce(vcat, [[l.𝘅₁, l.𝘅₂] for l in L]))
    end
end
