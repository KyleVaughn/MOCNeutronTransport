# Angular quadrature defined on the unit sphere octant in the upper right, closest to the viewer.
# The angles and weights are transformed to the other octants by symmetry.
#     +----+----+
#    /    /    /|
#   +----+----+ |
#  /    /    /| +
# +----+----+ |/|
# |    |this| + |
# |    | one|/| +
# +----+----+ |/
# |    |    | +
# |    |    |/
# +----+----+
#
# The spherical coordinates are defined in the following manner
# Ω̂ = (Ω_i, Ω_j, Ω_k) = (cos(θ),  sin(θ)cos(γ),  sin(θ)sin(γ))
#                     = (     μ, √(1-μ²)cos(γ), √(1-μ²)sin(γ))
#
#        j
#        ^
#        |   θ is the polar angle about the i-axis (x-direction)
#        |   γ is the azimuthal angle in the j-k plane, from the j-axis
#        |
#        |
#        |
#       /|
#      (γ|
#       \|--------------------> i
#       / \θ)
#      /   \
#     /     \
#    /       \ Ω̂
#   /         v
#  𝘷
#  k
abstract type AngularQuadrature end

#struct GeneralAngularQuadrature{T <: AbstractFloat} <: AngularQuadrature
#    Ω̂::Tuple{Point{T}} # Points on the unit sphere satisfying θ ∈ (0, π/2), γ ∈ (0, π/2)
#    w::Tuple{T} # Weights for each point
#end

struct ProductAngularQuadrature{M, P, T <: AbstractFloat} <: AngularQuadrature
    γ::NTuple{M, T}    # Azimuthal angles, γ ∈ (0, π/2)
    w_γ::NTuple{M, T}  # Weights for the azimuthal angles
    θ::NTuple{P, T}    # Polar angles, θ ∈ (0, π/2)
    w_θ::NTuple{P, T}  # Weights for the polar angles
end

ProductAngularQuadrature((γ, w_γ), (θ, w_θ)) = ProductAngularQuadrature(γ, w_γ, θ, w_θ)

function chebyshev_angular_quadrature(M::Int, T::DataType)
    # A Chebyshev-type quadrature for a given weight function is a quadrature formula with equal
    # weights. This function produces evenly spaced angles with equal weights.
    angles = Tuple([T(π)*T(2m-1)/T(4M) for m = 1:M])
    weights = Tuple([T(1)/T(M) for m = 1:M])
    return angles, weights
end

function AngularQuadrature(quadrature_type::String, M::Int, P::Int; T::DataType=Float64)
    if quadrature_type == "Chebyshev-Chebyshev"
        quadrature = ProductAngularQuadrature(chebyshev_angular_quadrature(M, T),
                                              chebyshev_angular_quadrature(P, T),
                                            )
    else
        ArgumentError("Unsupported quadrature type.")
    end
    return quadrature
end

# TODO: Function to convert product into general quadrature
