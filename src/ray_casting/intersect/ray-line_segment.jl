# Returns the value r such that r(r) = l(s). 
# If such a value does not exist, INF_POINT is returned instead.
# 1) P₁ + s(P₂ - P₁) = O + r𝗱           subtracting P₁ from both sides
# 2) s(P₂ - P₁) = (O - P₁) + r𝗱         let 𝘂 = O - P₁, 𝘃 = P₂-P₁
# 3) s𝘃 = 𝘂 + r𝗱                        cross product with 𝗱 (distributive)
# 4) s(𝘃 × 𝗱) = 𝘂 × 𝗱  + r(𝗱 × 𝗱)       𝗱 × 𝗱 = 𝟬   
# 5) s(𝘃 × 𝗱) = 𝘂 × 𝗱                   let 𝘃 × 𝗱 = 𝘇 and 𝘂 × 𝗱 = 𝘅
# 6) s𝘇 = 𝘅                             dot product 𝘇 to each side
# 7) s𝘇 ⋅ 𝘇 = 𝘅 ⋅ 𝘇                     divide by 𝘇 ⋅ 𝘇
# 8) s = (𝘅 ⋅ 𝘇)/(𝘇 ⋅ 𝘇)
# If s ∉ [0, 1] the intersections is invalid. If s ∈ [0, 1],
# 1) O + r𝗱 = P₁ + s𝘃                   subtracting O from both sides    
# 2) r𝗱 = -𝘂 + s𝘃                       cross product with 𝘃    
# 3) r(𝗱 × 𝘃) = -𝘂 × 𝘃 + s(𝘃 × 𝘃)       𝘃  × 𝘃 = 𝟬     
# 4) r(𝗱 × 𝘃) = -𝘂 × 𝘃                  using 𝗱 × 𝘃 = -(𝘃 × 𝗱)
# 5) r(𝘃 × 𝗱) = 𝘂 × 𝘃                   let 𝘂 × 𝘃 = 𝘆
# 6) r𝘇 = 𝘆                             dot product 𝘇 to each side    
# 7) r(𝘇 ⋅ 𝘇) = 𝘆 ⋅ 𝘇                   divide by (𝘇 ⋅ 𝘇)
# 9) r = (𝘆 ⋅ 𝘇)/(𝘇 ⋅ 𝘇)
#
# The cross product of two vectors in the plane is a vector of the form (0, 0, k),    
# hence, in 2D:    
# s = (𝘅 ⋅ 𝘇)/(𝘇 ⋅ 𝘇) = x₃/z₃ 
# r = (𝘆 ⋅ 𝘇)/(𝘇 ⋅ 𝘇) = y₃/z₃ 
# This result is valid if s ∈ [0, 1]
function Base.intersect(r::Ray2{T}, l::LineSegment2{T}) where {T}
    # Could rearrange and test z for an early exit, but this case is infrequent,
    # so we settle for smaller code/one less branch that could be mispredicted.
    𝘃 = l[2]     - l[1]
    𝘂 = r.origin - l[1]
    x = 𝘂 × r.direction
    z = 𝘃 × r.direction
    y = 𝘂 × 𝘃
    s = x / z
    r = y / z
    return 0 ≤ s && s ≤ 1 ? r : T(INF_POINT)
end
