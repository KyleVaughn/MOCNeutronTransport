# A 2D point in Cartesian coordinates.

struct Point_2D{T <: AbstractFloat}
    x::SVector{2,T}
end

# Constructors
# -------------------------------------------------------------------------------------------------
# 2D single constructor
Point_2D(x::T, y::T) where {T <: AbstractFloat} = Point_2D(SVector(x, y))
# 1D single constructor
Point_2D(x::T) where {T <: AbstractFloat} = Point_2D(SVector(x, T(0)))
# 2D tuple constructor
Point_2D((x, y)::Tuple{T,T}) where {T <: AbstractFloat} = Point_2D(SVector(x, y))
# 2D single conversion constructor
Point_2D(type::Type{T}, x::X, y::Y) where {T <: AbstractFloat,
                                       X,Y <: Real} = Point_2D(SVector(T(x),T(y)))
# 1D single conversion constructor
Point_2D(type::Type{T}, x::X) where {T <: AbstractFloat,
                                 X <: Real} = Point_2D(SVector(T(x),T(0)))

# Base
# -------------------------------------------------------------------------------------------------
Base.broadcastable(p⃗::Point_2D) = Ref(p⃗)
Base.zero(::Point_2D{T}) where {T <: AbstractFloat} = Point_2D((T(0), T(0)))
Base.firstindex(::Point_2D) = 1
Base.lastindex(::Point_2D) = 2
Base.getindex(p⃗::Point_2D, i::Int) = p⃗.x[i]
(::Type{T})(p⃗::Point_2D) where {T <: AbstractFloat} = Point_2D(T.(p⃗.x))

# Operators
# -------------------------------------------------------------------------------------------------
==(p⃗₁::Point_2D, p⃗₂::Point_2D) = (p⃗₁.x == p⃗₂.x)
function ≈(p⃗₁::Point_2D{T}, p⃗₂::Point_2D{T}) where {T <: AbstractFloat}
    return distance(p⃗₁, p⃗₂) < 5.0e-5
end
+(p⃗₁::Point_2D, p⃗₂::Point_2D) = Point_2D(p⃗₁.x[1] + p⃗₂.x[1], p⃗₁.x[2] + p⃗₂.x[2])
-(p⃗₁::Point_2D, p⃗₂::Point_2D) = Point_2D(p⃗₁.x[1] - p⃗₂.x[1], p⃗₁.x[2] - p⃗₂.x[2])
# Note the cross product of two 2D points returns a scalar. It is assumed that the 
# desired quantity is actually the 2-norm of the cross product, since the cross product of vectors
# in the plane is a vector normal to the plane.
×(p⃗₁::Point_2D, p⃗₂::Point_2D) = p⃗₁.x[1]*p⃗₂.x[2] - p⃗₂.x[1]*p⃗₁.x[2]
⋅(p⃗₁::Point_2D, p⃗₂::Point_2D) = p⃗₁.x[1]*p⃗₂.x[1] + p⃗₁.x[2]*p⃗₂.x[2]
+(p⃗::Point_2D, n::Real) = Point_2D(p⃗.x[1] + n, p⃗.x[2] + n)
+(n::Real, p⃗::Point_2D) = p⃗ + n
-(p⃗::Point_2D, n::Real) = Point_2D(p⃗.x[1] - n, p⃗.x[2] - n)
-(n::Real, p⃗::Point_2D) = p⃗ - n
*(n::Real, p⃗::Point_2D) = Point_2D(n*p⃗.x[1], n*p⃗.x[2])
*(p⃗::Point_2D, n::Real) = n*p⃗
/(p⃗::Point_2D, n::Real) = Point_2D(p⃗.x[1]/n, p⃗.x[2]/n)
-(p⃗::Point_2D) = -1*p⃗
# SMatrix multiplication, returns a point
*(A::SMatrix{2, 2, T, 4}, p⃗::Point_2D{T}) where {T <: AbstractFloat} = Point_2D(A * p⃗.x)

# Methods
# -------------------------------------------------------------------------------------------------
norm(p⃗::Point_2D) = hypot(p⃗.x[1], p⃗.x[2])
distance(p⃗₁::Point_2D, p⃗₂::Point_2D) = hypot(p⃗₁.x[1] - p⃗₂.x[1], p⃗₁.x[2] - p⃗₂.x[2])

# Plot
# -------------------------------------------------------------------------------------------------
convert_arguments(P::Type{<:Scatter}, p::Point_2D) = convert_arguments(P, p.x)
function convert_arguments(P::Type{<:Scatter}, AP::AbstractArray{<:Point_2D})
    return convert_arguments(P, [p.x for p in AP])
end
