// Free functions
#include <um2/geometry/polygon/boundingBox.inl>
#include <um2/geometry/polygon/centroid.inl>
#include <um2/geometry/polygon/flipFace.inl>
#include <um2/geometry/polygon/isCCW.inl>
#include <um2/geometry/polygon/isConvex.inl>
#include <um2/geometry/polygon/linearPolygon.inl>

namespace um2
{

//==============================================================================
//==============================================================================
// Free functions 
//==============================================================================
//==============================================================================

//==============================================================================
// interpolation
//==============================================================================

template <Size D, typename T, typename R, typename S>    
PURE HOSTDEV constexpr auto    
interpolate(Triangle<D, T> const & tri, R const r, S const s) noexcept -> Point<D, T>    
{    
  // (1 - r - s) v0 + r v1 + s v2    
  T const rr = static_cast<T>(r);    
  T const ss = static_cast<T>(s);    
  T const w0 = 1 - rr - ss;    
  // T const w1 = rr;    
  // T const w2 = ss;    
  Point<D, T> result;    
  for (Size i = 0; i < D; ++i) {    
    result[i] = w0 * tri[0][i] + rr * tri[1][i] + ss * tri[2][i];    
  }    
  return result;    
} 

template <Size D, typename T, typename R, typename S>
PURE HOSTDEV constexpr auto
interpolate(Quadrilateral<D, T> const & quad, R const r, S const s) noexcept
    -> Point<D, T>
{
  // (1 - r) (1 - s) v0 +
  // (    r) (1 - s) v1 +
  // (    r) (    s) v2 +
  // (1 - r) (    s) v3
  T const rr = static_cast<T>(r);
  T const ss = static_cast<T>(s);
  T const w0 = (1 - rr) * (1 - ss);
  T const w1 = rr * (1 - ss);
  T const w2 = rr * ss;
  T const w3 = (1 - rr) * ss;
  Point<D, T> result;
  for (Size i = 0; i < D; ++i) {
    result[i] = w0 * quad[0][i] + w1 * quad[1][i] + w2 * quad[2][i] + w3 * quad[3][i];
  }
  return result;
}

template <Size D, typename T, typename R, typename S>
PURE HOSTDEV constexpr auto
interpolate(QuadraticTriangle<D, T> const & tri6, R const r, S const s) noexcept
    -> Point<D, T>
{
  T const rr = static_cast<T>(r);
  T const ss = static_cast<T>(s);
  // Factoring out the common terms
  T const tt = 1 - rr - ss;
  T const w0 = tt * (2 * tt - 1);
  T const w1 = rr * (2 * rr - 1);
  T const w2 = ss * (2 * ss - 1);
  T const w3 = 4 * rr * tt;
  T const w4 = 4 * rr * ss;
  T const w5 = 4 * ss * tt;
  Point<D, T> result;
  for (Size i = 0; i < D; ++i) {
    result[i] = w0 * tri6[0][i] + w1 * tri6[1][i] + w2 * tri6[2][i] + w3 * tri6[3][i] +
                w4 * tri6[4][i] + w5 * tri6[5][i];
  }
  return result;
}

template <Size D, typename T, typename R, typename S>
PURE HOSTDEV constexpr auto
interpolate(QuadraticQuadrilateral<D, T> const & quad8, R const r, S const s) noexcept
    -> Point<D, T>
{
  T const xi = 2 * static_cast<T>(r) - 1;
  T const eta = 2 * static_cast<T>(s) - 1;
  T const w[8] = {(1 - xi) * (1 - eta) * (-xi - eta - 1) / 4,
                  (1 + xi) * (1 - eta) * (xi - eta - 1) / 4,
                  (1 + xi) * (1 + eta) * (xi + eta - 1) / 4,
                  (1 - xi) * (1 + eta) * (-xi + eta - 1) / 4,
                  (1 - xi * xi) * (1 - eta) / 2,
                  (1 - eta * eta) * (1 + xi) / 2,
                  (1 - xi * xi) * (1 + eta) / 2,
                  (1 - eta * eta) * (1 - xi) / 2};
  Point<D, T> result;
  for (Size i = 0; i < D; ++i) {
    result[i] = w[0] * quad8[0][i] + w[1] * quad8[1][i] + w[2] * quad8[2][i] +
                w[3] * quad8[3][i] + w[4] * quad8[4][i] + w[5] * quad8[5][i] +
                w[6] * quad8[6][i] + w[7] * quad8[7][i];
  }
  return result;
}

//==============================================================================
// jacobian
//==============================================================================

template <Size D, typename T, typename R, typename S>    
PURE HOSTDEV constexpr auto    
jacobian(Triangle<D, T> const & t, R /*r*/, S /*s*/) noexcept -> Mat<D, 2, T>    
{    
  return Mat<D, 2, T>(t[1] - t[0], t[2] - t[0]);    
}

template <Size D, typename T, typename R, typename S>    
PURE HOSTDEV constexpr auto    
jacobian(Quadrilateral<D, T> const & q, R const r, S const s) noexcept -> Mat<D, 2, T>    
{    
  // jac.col(0) = (v1 - v0) - s (v3 - v2)    
  // jac.col(1) = (v3 - v0) - r (v1 - v2)    
  T const rr = static_cast<T>(r);    
  T const ss = static_cast<T>(s);
  T const w0 = 1 - ss;
  // T const w1 = ss;
  T const w2 = 1 - rr;
  // T const w3 = rr;
  Mat<D, 2, T> jac;
  for (Size i = 0; i < D; ++i) {
    jac(i, 0) = w0 * (q[1][i] - q[0][i]) - ss * (q[3][i] - q[2][i]);
    jac(i, 1) = w2 * (q[3][i] - q[0][i]) - rr * (q[1][i] - q[2][i]);
  }
  return jac;
}

template <Size D, typename T, typename R, typename S>
PURE HOSTDEV constexpr auto
jacobian(QuadraticTriangle<D, T> const & t6, R const r, S const s) noexcept
    -> Mat<D, 2, T>
{
  T const rr = static_cast<T>(4 * r);
  T const ss = static_cast<T>(4 * s);
  T const tt = rr + ss - 3;
  Mat<D, 2, T> result;
  for (Size i = 0; i < D; ++i) {
    result.col(0)[i] = tt * (t6[0][i] - t6[3][i]) + (rr - 1) * (t6[1][i] - t6[3][i]) +
                       ss * (t6[4][i] - t6[5][i]);
    result.col(1)[i] = tt * (t6[0][i] - t6[5][i]) + (ss - 1) * (t6[2][i] - t6[5][i]) +
                       rr * (t6[4][i] - t6[3][i]);
  }
  return result;
}

template <Size D, typename T, typename R, typename S>
PURE HOSTDEV constexpr auto
jacobian(QuadraticQuadrilateral<D, T> const & q, R const r, S const s) noexcept
    -> Mat<D, 2, T>
{
  T const xi = 2 * static_cast<T>(r) - 1;
  T const eta = 2 * static_cast<T>(s) - 1;
  T const xi_eta = xi * eta;
  T const xi_xi = xi * xi;
  T const eta_eta = eta * eta;
  T const w0 = (eta - eta_eta) / 2;
  T const w1 = (eta + eta_eta) / 2;
  T const w2 = (xi - xi_eta);
  T const w3 = (xi + xi_eta);
  T const w4 = 1 - eta_eta;
  T const w5 = (xi - xi_xi) / 2;
  T const w6 = (xi + xi_xi) / 2;
  T const w7 = eta - xi_eta;
  T const w8 = eta + xi_eta;
  T const w9 = 1 - xi_xi;
  Mat<D, 2, T> result;
  for (Size i = 0; i < D; ++i) {
    result.col(0)[i] = w0 * (q[0][i] - q[1][i]) + w1 * (q[2][i] - q[3][i]) +
                       w2 * (q[0][i] + q[1][i] - 2 * q[4][i]) +
                       w3 * (q[2][i] + q[3][i] - 2 * q[6][i]) + w4 * (q[5][i] - q[7][i]);
    result.col(1)[i] = w5 * (q[0][i] - q[3][i]) + w6 * (q[2][i] - q[1][i]) +
                       w7 * (q[0][i] + q[3][i] - 2 * q[7][i]) +
                       w8 * (q[1][i] + q[2][i] - 2 * q[5][i]) + w9 * (q[6][i] - q[4][i]);
  }
  return result;
}

//==============================================================================
// getEdge
//==============================================================================

template <Size N, Size D, typename T>    
PURE HOSTDEV constexpr auto    
getEdge(LinearPolygon<N, D, T> const & p, Size const i) noexcept -> LineSegment<D, T>    
{                       
  assert(0 <= i && i < N);    
  return (i < N - 1) ? LineSegment<D, T>(p[i], p[i + 1])    
                     : LineSegment<D, T>(p[N - 1], p[0]);    
}                       
                        
template <Size N, Size D, typename T>    
PURE HOSTDEV constexpr auto    
getEdge(QuadraticPolygon<N, D, T> const & p, Size const i) noexcept    
    -> QuadraticSegment<D, T>    
{                       
  assert(0 <= i && i < N);    
  constexpr Size m = N / 2;    
  return (i < m - 1) ? QuadraticSegment<D, T>(p[i], p[i + 1], p[i + m])    
                     : QuadraticSegment<D, T>(p[m - 1], p[0], p[N - 1]);    
}

//==============================================================================
// contains
//==============================================================================

template <typename T>
PURE HOSTDEV constexpr auto
contains(Triangle2<T> const & tri, Point2<T> const & p) noexcept -> bool
{
  // Benchmarking shows it is faster to compute the areCCW() test for each 
  // edge, then return based on the AND of the results, rather than compute
  // the areCCW one at a time and return as soon as one is false.
  bool const b0 = areCCW(tri[0], tri[1], p);
  bool const b1 = areCCW(tri[1], tri[2], p);
  bool const b2 = areCCW(tri[2], tri[0], p);
  return b0 && b1 && b2;
}

template <typename T>
PURE HOSTDEV constexpr auto
contains(Quadrilateral2<T> const & tri, Point2<T> const & p) noexcept -> bool
{
  bool const b0 = areCCW(tri[0], tri[1], p);
  bool const b1 = areCCW(tri[1], tri[2], p);
  bool const b2 = areCCW(tri[2], tri[3], p);    
  bool const b3 = areCCW(tri[3], tri[0], p);
  return b0 && b1 && b2 && b3;
}

template <Size N, typename T>
PURE HOSTDEV constexpr auto
contains(PlanarQuadraticPolygon<N, T> const & q, Point2<T> const & p) noexcept -> bool
{
  // Benchmarking shows that the opposite conclusion is true for quadratic
  // polygons: it is faster to compute the areCCW() test for each edge, short
  // circuiting as soon as one is false, rather than compute all of them.
  Size const num_edges = polygonNumEdges<1, N>();
  for (Size i = 0; i < num_edges; ++i) {
    if (!getEdge(q, i).isLeft(p)) {
      return false;
    }
  }
  return true;
}

//==============================================================================
// area
//==============================================================================

template <typename T>
PURE HOSTDEV constexpr auto
area(Triangle2<T> const & tri) noexcept -> T
{
  Vec2<T> const v10 = tri[1] - tri[0];
  Vec2<T> const v20 = tri[2] - tri[0];
  return v10.cross(v20) / 2; // this is the signed area
}

template <typename T>
PURE HOSTDEV constexpr auto
area(Triangle3<T> const & tri) noexcept -> T
{
  Vec3<T> const v10 = tri[1] - tri[0];
  Vec3<T> const v20 = tri[2] - tri[0];
  return v10.cross(v20).norm() / 2; // this is the unsigned area
}

template <typename T>
PURE HOSTDEV constexpr auto
area(Quadrilateral2<T> const & q) noexcept -> T
{
  assert(isConvex(q));
  // (v2 - v0).cross(v3 - v1) / 2 
  Vec2<T> const v20 = q[2] - q[0];
  Vec2<T> const v31 = q[3] - q[1];
  return v20.cross(v31) / 2;
}

// Area of a planar linear polygon
template <Size N, typename T>
PURE HOSTDEV constexpr auto
area(PlanarLinearPolygon<N, T> const & p) noexcept -> T
{
  // Shoelace forumla A = 1/2 * sum_{i=0}^{n-1} cross(p_i, p_{i+1})
  // p_n = p_0
  T sum = (p[N - 1]).cross(p[0]); // cross(p_{n-1}, p_0), the last term
  for (Size i = 0; i < N - 1; ++i) {
    sum += (p[i]).cross(p[i + 1]);
  }
  return sum / 2;
}

//==============================================================================
// QuadraticPolygon
//==============================================================================

template <Size N, typename T>
PURE HOSTDEV constexpr auto
area(PlanarQuadraticPolygon<N, T> const & q) noexcept -> T
{
  T result = area(linearPolygon(q));
  Size const num_edges = polygonNumEdges<2, N>();
  for (Size i = 0; i < num_edges; ++i) {
    result += enclosedArea(getEdge(q, i));
  }
  return result;
}

//==============================================================================
//==============================================================================
// Member functions
//==============================================================================
//==============================================================================

//==============================================================================
// Accessors
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::operator[](Size i) noexcept -> Point<D, T> &
{
  return v[i];
}

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::operator[](Size i) const noexcept -> Point<D, T> const &
{
  return v[i];
}

//==============================================================================
// Interpolation
//==============================================================================

template <Size P, Size N, Size D, typename T>
template <typename R, typename S>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::operator()(R const r, S const s) const noexcept -> Point<D, T>
{
  return interpolate(*this, r, s);
}

//==============================================================================
// jacobian
//==============================================================================

template <Size P, Size N, Size D, typename T>
template <typename R, typename S>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::jacobian(R r, S s) const noexcept -> Mat<D, 2, T>
{
  return um2::jacobian(*this, r, s);
}

//==============================================================================
// edge
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::getEdge(Size i) const noexcept -> Edge
{
  return um2::getEdge(*this, i);
}

//==============================================================================
// contains
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::contains(Point<D, T> const & p) const noexcept -> bool
{
  return um2::contains(*this, p);
}

//==============================================================================
// area
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::area() const noexcept -> T
{
  return um2::area(*this);
}

//==============================================================================
// centroid
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::centroid() const noexcept -> Point<D, T>
{
  return um2::centroid(*this);
}

//==============================================================================
// boundingBox
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::boundingBox() const noexcept -> AxisAlignedBox<D, T>
{
  return um2::boundingBox(*this);
}

//==============================================================================
// isCCW
//==============================================================================

template <Size P, Size N, Size D, typename T>
PURE HOSTDEV constexpr auto
Polygon<P, N, D, T>::isCCW() const noexcept -> bool
{
  return um2::isCCW(*this);
}

} // namespace um2
