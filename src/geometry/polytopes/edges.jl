export edges

@generated function edges(p::Polygon{N,T}) where {N,T}
    exprs = [begin
                id₁ = (i - 1) % N + 1
                id₂ = i % N + 1
                :(LineSegment(p[$id₁], p[$id₂]))
             end
             for i in 1:N
            ]
    return quote
        Base.@_inline_meta
        @inbounds return Vec{$N, LineSegment{$T}}(tuple($(exprs...)))
    end
end

@generated function edges(p::QuadraticPolygon{N,T}) where {N,T}
    M = N ÷ 2
    exprs = [begin
                id₁ = (i - 1) % M + 1
                id₂ = i % M + 1
                id₃ = i + M
                :(QuadraticSegment(p[$id₁], p[$id₂], p[$id₃]))
             end
             for i in 1:M
            ]
    return quote
        Base.@_inline_meta
        @inbounds return Vec{$M, QuadraticSegment{$T}}(tuple($(exprs...)))
    end
end

function edges(p::Tetrahedron)
    v = vertices(p)
    return Vec(LineSegment(v[1], v[2]),
               LineSegment(v[2], v[3]),
               LineSegment(v[3], v[1]),
               LineSegment(v[1], v[4]),
               LineSegment(v[2], v[4]),
               LineSegment(v[3], v[4]))
end

function edges(p::Hexahedron)
    v = vertices(p)
    return Vec(LineSegment(v[1], v[2]), # lower z
               LineSegment(v[2], v[3]),
               LineSegment(v[3], v[4]),
               LineSegment(v[4], v[1]),
               LineSegment(v[5], v[6]), # upper z
               LineSegment(v[6], v[7]),
               LineSegment(v[7], v[8]),
               LineSegment(v[8], v[5]),
               LineSegment(v[1], v[5]), # lower, upper connections
               LineSegment(v[2], v[6]),
               LineSegment(v[3], v[7]),
               LineSegment(v[4], v[8])) 
end

function edges(p::QuadraticTetrahedron)
    v = vertices(p)
    return Vec(QuadraticSegment(v[1], v[2], v[5]),
               QuadraticSegment(v[2], v[3], v[6]),
               QuadraticSegment(v[3], v[1], v[7]),
               QuadraticSegment(v[1], v[4], v[8]),
               QuadraticSegment(v[2], v[4], v[9]),
               QuadraticSegment(v[3], v[4], v[10]))
end