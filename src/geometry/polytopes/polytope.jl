export Polytope, 
       Edge, 
       LineSegment, 
       QuadraticSegment, 
       Face, 
       Polygon, 
       QuadraticPolygon,
       Triangle, 
       Quadrilateral, 
       QuadraticTriangle, 
       QuadraticQuadrilateral, 
       Cell,
       Polyhedron, 
       QuadraticPolyhedron, 
       Tetrahedron, 
       Hexahedron, 
       QuadraticTetrahedron,
       QuadraticHexahedron

export vertices, 
       facets, 
       ridges, 
       peaks, 
       alias_string, vertextype, paramdim,
       isstraight

struct Polytope{K, P, N, D, T <: AbstractFloat}
    vertices::Vec{N, Point{D, T}}
end

# -- Type aliases --

# 1-polytopes
const Edge             = Polytope{1}

const LineSegment      = Edge{1, 2}
const LineSegment2     = LineSegment{2}
const LineSegment2f    = LineSegment2{Float32}
const LineSegment2d    = LineSegment2{Float64}
const LineSegment2b    = LineSegment2{BigFloat}

const QuadraticSegment = Edge{2, 3}
const QuadraticSegment2 = QuadraticSegment{2}
const QuadraticSegment2f = QuadraticSegment2{Float32}
const QuadraticSegment2d = QuadraticSegment2{Float64}
const QuadraticSegment2b = QuadraticSegment2{BigFloat}

# 2-polytopes
const Face                   = Polytope{2}
const Polygon                = Face{1}
const QuadraticPolygon       = Face{2}

const Triangle               = Polygon{3}
const Triangle2              = Triangle{2}
const Triangle2f             = Triangle2{Float32}
const Triangle2d             = Triangle2{Float64}
const Triangle2b             = Triangle2{BigFloat}

const Quadrilateral          = Polygon{4}
const Quadrilateral2         = Quadrilateral{2}
const Quadrilateral2f        = Quadrilateral2{Float32}
const Quadrilateral2d        = Quadrilateral2{Float64}
const Quadrilateral2b        = Quadrilateral2{BigFloat}

const QuadraticTriangle      = QuadraticPolygon{6}
const QuadraticTriangle2     = QuadraticTriangle{2}
const QuadraticTriangle2f    = QuadraticTriangle2{Float32}
const QuadraticTriangle2d    = Quadrilateral2{Float64}
const QuadraticTriangle2b    = Quadrilateral2{BigFloat}

const QuadraticQuadrilateral = QuadraticPolygon{8}
const QuadraticQuadrilateral2 = QuadraticQuadrilateral{2}
const QuadraticQuadrilateral2f = QuadraticQuadrilateral2{Float32}
const QuadraticQuadrilateral2d = Quadrilateral2{Float64}
const QuadraticQuadrilateral2b = Quadrilateral2{BigFloat}

# 3-polytopes
# All with D = 3.
# const Cell                 = Polytope{3}
# const Polyhedron           = Cell{1}
# const QuadraticPolyhedron  = Cell{2}
# 
# const Tetrahedron          = Polyhedron{4}
# const Hexahedron           = Polyhedron{8}
# const QuadraticTetrahedron = QuadraticPolyhedron{10}
# const QuadraticHexahedron  = QuadraticPolyhedron{20}

# Constructors
function Polytope{K, P, N, T}(vertices...) where {K, P, N, T}
    return Polytope{K, P, N, T}(Vec{N, T}(vertices))
end
Polytope{K, P, N}(vertices::Vec{N, T}) where {K, P, N, T} = Polytope{K, P, N, T}(vertices)
Polytope{K, P, N}(vertices...) where {K, P, N} = Polytope{K, P, N}(Vec(vertices))
function Polytope{K, P, N}(v::Vector{T}) where {K, P, N, T}
    return Polytope{K, P, N}(Vec{length(v), T}(v))
end
function Polytope{K, P, N, T}(v::Vector) where {K, P, N, T}
    return Polytope{K, P, N, T}(Vec{length(v), T}(v))
end
function Polytope{K, P, N, T}(v::SVector{N}) where {K, P, N, T}
    return Polytope{K, P, N, T}(Vec{N, T}(v...))
end

# Convenience constructor for LineSegments
function LineSegment(x₁::T, y₁::T, x₂::T, y₂::T) where {T}
    return LineSegment{Point{2, T}}(Point{2, T}(x₁, y₁), Point{2, T}(x₂, y₂))
end

# Convert SVector vals
function Base.convert(::Type{Polytope{K, P, N, T}}, v::SVector{N}) where {K, P, N, T}
    return Polytope{K, P, N, T}(v...)
end
# Convert Polytope vals
function Base.convert(::Type{Polytope{K, P, N, T}},
                      p::Polytope{K, P, N}) where {K, P, N, T}
    return Polytope{K, P, N, T}(p.vertices...)
end
# Convert SVector to general polytope
# Primarily for non-homogenous meshes
function Base.convert(::Type{Polytope{K, P, N, T} where {N}},
                      v::SVector{V}) where {K, P, T, V}
    return Polytope{K, P, V, T}(v...)
end

Base.getindex(poly::Polytope, i::Int) = Base.getindex(poly.vertices, i)

paramdim(::Type{<:Polytope{K}}) where {K} = K
vertextype(::Type{Polytope{K, P, N, T}}) where {K, P, N, T} = T
vertextype(::Polytope{K, P, N, T}) where {K, P, N, T} = T

vertices(p::Polytope) = p.vertices

peaks(p::Polytope{3}) = vertices(p)

ridges(p::Polytope{2}) = vertices(p)
ridges(p::Polytope{3}) = edges(p)

facets(p::Polytope{1}) = vertices(p)
facets(p::Polytope{2}) = edges(p)
facets(p::Polytope{3}) = faces(p)

function alias_string(::Type{P}) where {P <: Polytope}
    P <: LineSegment && return "LineSegment"
    P <: QuadraticSegment && return "QuadraticSegment"
    P <: Triangle && return "Triangle"
    P <: Quadrilateral && return "Quadrilateral"
    P <: QuadraticTriangle && return "QuadraticTriangle"
    P <: QuadraticQuadrilateral && return "QuadraticQuadrilateral"
    P <: Tetrahedron && return "Tetrahedron"
    P <: Hexahedron && return "Hexahedron"
    P <: QuadraticTetrahedron && return "QuadraticTetrahedron"
    P <: QuadraticHexahedron && return "QuadraticHexahedron"
    # fallback on default
    return "$(P)"
end

# If we think of the polytopes as sets, p₁ ∩ p₂ = p₁ and p₁ ∩ p₂ = p₂ implies p₁ = p₂
function Base.:(==)(l₁::LineSegment{T}, l₂::LineSegment{T}) where {T}
    return (l₁[1] === l₂[1] && l₁[2] === l₂[2]) ||
           (l₁[1] === l₂[2] && l₁[2] === l₂[1])
end
Base.:(==)(t₁::Triangle, t₂::Triangle) = return all(v -> v ∈ t₂.vertices, t₁.vertices)
Base.:(==)(t₁::Tetrahedron, t₂::Tetrahedron) = return all(v -> v ∈ t₂.vertices, t₁.vertices)
function Base.:(==)(q₁::QuadraticSegment{T}, q₂::QuadraticSegment{T}) where {T}
    return q₁[3] === q₂[3] &&
           (q₁[1] === q₂[1] && q₁[2] === q₂[2]) ||
           (q₁[1] === q₂[2] && q₁[2] === q₂[1])
end

isstraight(::LineSegment) = true

"""
    isstraight(q::QuadraticSegment)

Return if the quadratic segment is effectively straight.
(If P₃ is at most EPS_POINT distance from LineSegment(P₁,P₂))
"""
function isstraight(q::QuadraticSegment{T}) where {T <: Point}
    # Project P₃ onto the line from P₁ to P₂, call it P₄
    𝘃₁₃ = q[3] - q[1]
    𝘃₁₂ = q[2] - q[1]
    v₁₂ = norm²(𝘃₁₂)
    𝘃₁₄ = (𝘃₁₃ ⋅ 𝘃₁₂) * inv(v₁₂) * 𝘃₁₂
    # Determine the distance from P₃ to P₄ (P₄ - P₃ = P₁ + 𝘃₁₄ - P₃ = 𝘃₁₄ - 𝘃₁₃)
    d² = norm²(𝘃₁₄ - 𝘃₁₃)
    return d² < T(EPS_POINT^2)
end

# Show aliases when printing
function Base.show(io::IO, poly::Polytope)
    return print(io, alias_string(typeof(poly)), "(", vertices(poly), ")")
end
