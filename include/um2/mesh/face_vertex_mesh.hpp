#pragma once

#include <um2/mesh/polytope_soup.hpp>
#include <um2/geometry/triangle.hpp>
#include <um2/geometry/quadrilateral.hpp>
#include <um2/geometry/quadratic_triangle.hpp>
#include <um2/geometry/quadratic_quadrilateral.hpp>

//=============================================================================
// FACE-VERTEX MESH
//=============================================================================
// A 2D volumetric mesh composed of polygons of polynomial order P.
// Each polygon (face) is composed of N vertices. Each vertex is a 2-dimensional
// point of floating point type F.
//  - P = 1, N = 3: Triangular mesh
//  - P = 1, N = 4: Quadrilateral mesh
//  - P = 2, N = 6: Quadratic triangular mesh
//  - P = 2, N = 8: Quadratic quadrilateral mesh
//
// Let Int be the signed integer type used to index vertices and faces.
// We will use some simple meshes to explain the data structure. A more detailed
// explanation of each member follows.
//  - A TriMesh (FaceVertexMesh<1, 3>) with two triangles:
//      3---2
//      | / |
//      0---1
//      vertices = { {0, 0}, {1, 0}, {1, 1}, {0, 1} }
//          4 vertices on the unit square
//      fv = { {0, 1, 2}, {2, 3, 0} }
//          The 6 vertex indices composing the two triangles {0, 1, 2} and {2, 3, 0}
//      vf = { 0, 1, 0, 0, 1, 1 }
//          The face indices to which each vertex belongs. More precisely, vertex
//          0 belongs to faces 0 and 1, vertex 1 belongs to face 0 only, etc.
//          Face IDs are ordered least to greatest.
//      vf_offsets = { 0, 2, 3, 5, 6}
//          vf_offsets[i] is the index of the smallest face ID to which vertex i
//          belongs. There is an additional element at the end, which is the length
//          of the vf vector. Used to calculate the number of faces to which each
//          vertex belongs.
//

namespace um2
{

template <Int P, Int N>
class FaceVertexMesh
{

public:
  using FaceConn = Vec<N, Int>;
  using Face = Polygon<P, N, 2>;
  using Edge = typename Polygon<P, N, 2>::Edge;

private:
  bool _is_morton_sorted = false;
  bool _has_vf = false;
  Vector<Point2> _v;        // vertices
  Vector<FaceConn> _fv;     // face-vertex connectivity
  Vector<Int> _vf_offsets;  // A prefix sum of the number of faces to which each
                            // vertex belongs. size = num_vertices + 1
  Vector<Int> _vf;          // vertex-face connectivity

public:
  //===========================================================================
  // Constructors
  //===========================================================================

  constexpr FaceVertexMesh() noexcept = default;

  HOSTDEV
  constexpr FaceVertexMesh(Vector<Point2> const & v,
                           Vector<FaceConn> const & fv) noexcept;

  explicit FaceVertexMesh(PolytopeSoup const & soup);

  //==============================================================================
  // Accessors
  //==============================================================================

  PURE HOSTDEV [[nodiscard]] constexpr auto
  numVertices() const noexcept -> Int;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  numFaces() const noexcept -> Int;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  getVertex(Int i) const noexcept -> Point2;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  getFace(Int i) const noexcept -> Face;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  vertices() noexcept -> Vector<Point2> &;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  faceVertexConn() const noexcept -> Vector<FaceConn> const &;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  vertexFaceOffsets() const noexcept -> Vector<Int> const &;

  PURE HOSTDEV [[nodiscard]] constexpr auto
  vertexFaceConn() const noexcept -> Vector<Int> const &;

  //===========================================================================
  // Methods
  //===========================================================================

  constexpr void
  addVertex(Point2 const & v) noexcept;

  constexpr void
  addFace(FaceConn const & conn) noexcept;

  PURE [[nodiscard]] constexpr auto
  boundingBox() const noexcept -> AxisAlignedBox2;

  PURE [[nodiscard]] constexpr auto
  faceContaining(Point2 const & p) const noexcept -> Int;

  void
  flipFace(Int i) noexcept;

//  void
//  mortonSort();
//
//  void
//  mortonSortFaces();
//
//  void
//  mortonSortVertices();

  void
  populateVF() noexcept;

  void
  validate();

//  //  //  void
//  //  //  toPolytopeSoup(PolytopeSoup & soup) const noexcept;
//
//  void
//  intersect(Ray2 const & ray, Vector<F> & intersections) const noexcept;
};

//==============================================================================
// Aliases
//==============================================================================

template <Int P, Int N>
using FVM = FaceVertexMesh<P, N>;

// Polynomial order
template <Int N>
using LinearFVM = FVM<1, N>;
template <Int N>
using QuadraticFVM = FVM<2, N>;

// Number of vertices per face
using TriFVM = LinearFVM<3>;
using QuadFVM = LinearFVM<4>;
using Tri6FVM = QuadraticFVM<6>;
using Quad8FVM = QuadraticFVM<8>;

//==============================================================================
// Constructors
//==============================================================================

template <Int P, Int N>
constexpr FaceVertexMesh<P, N>::FaceVertexMesh(Vector<Point2> const & v,
                                               Vector<FaceConn> const & fv) noexcept
    : _v(v),
      _fv(fv)
{
}

//==============================================================================
// Accessors
//==============================================================================

template <Int P, Int N>
PURE HOSTDEV [[nodiscard]] constexpr auto
FaceVertexMesh<P, N>::numVertices() const noexcept -> Int
{
  return _v.size();
}

template <Int P, Int N>
PURE HOSTDEV [[nodiscard]] constexpr auto
FaceVertexMesh<P, N>::numFaces() const noexcept -> Int
{
  return _fv.size();
}

template <Int P, Int N>
PURE HOSTDEV [[nodiscard]] constexpr auto
FaceVertexMesh<P, N>::getVertex(Int i) const noexcept -> Point2
{
  return _v[i];
}

template <Int P, Int N>
PURE HOSTDEV [[nodiscard]] constexpr auto
FaceVertexMesh<P, N>::getFace(Int i) const noexcept -> Face
{
  ASSERT_ASSUME(0 <= i);
  ASSERT(i < numFaces());
  if constexpr (P == 1 && N == 3) {
    return Triangle2(_v[_fv[i][0]], _v[_fv[i][1]], _v[_fv[i][2]]);
  } else if constexpr (P == 1 && N == 4) {
    return Quadrilateral2(_v[_fv[i][0]], _v[_fv[i][1]], _v[_fv[i][2]], _v[_fv[i][3]]);
  } else if constexpr (P == 2 && N == 6) {
    return QuadraticTriangle2(_v[_fv[i][0]], _v[_fv[i][1]], _v[_fv[i][2]], _v[_fv[i][3]],
                              _v[_fv[i][4]], _v[_fv[i][5]]);
  } else if constexpr (P == 2 && N == 8) {
    return QuadraticQuadrilateral2(_v[_fv[i][0]], _v[_fv[i][1]], _v[_fv[i][2]],
                                   _v[_fv[i][3]], _v[_fv[i][4]], _v[_fv[i][5]],
                                   _v[_fv[i][6]], _v[_fv[i][7]]);
  } else {
    __builtin_unreachable();
  }
}

template <Int P, Int N>
HOSTDEV [[nodiscard]] constexpr auto
FaceVertexMesh<P, N>::vertices() noexcept -> Vector<Point2> &
{
  return _v;
}

template <Int P, Int N>
PURE HOSTDEV constexpr auto
FaceVertexMesh<P, N>::vertexFaceOffsets() const noexcept -> Vector<Int> const &
{
  return _vf_offsets;
}

template <Int P, Int N>
PURE HOSTDEV constexpr auto
FaceVertexMesh<P, N>::vertexFaceConn() const noexcept -> Vector<Int> const &
{
  return _vf;
}

template <Int P, Int N>
PURE HOSTDEV constexpr auto
FaceVertexMesh<P, N>::faceVertexConn() const noexcept -> Vector<FaceConn> const &
{
  return _fv;
}

//==============================================================================
// Methods
//==============================================================================

template <Int P, Int N>
constexpr void
FaceVertexMesh<P, N>::addVertex(Point2 const & v) noexcept
{
  _v.emplace_back(v);
}

template <Int P, Int N>
constexpr void
FaceVertexMesh<P, N>::addFace(FaceConn const & conn) noexcept
{
  _fv.emplace_back(conn);
}

template <Int P, Int N>
PURE constexpr auto
FaceVertexMesh<P, N>::boundingBox() const noexcept -> AxisAlignedBox2
{
  if constexpr (P == 1) {
    return um2::boundingBox(_v.cbegin(), _v.cend());
  } else if constexpr (P == 2) {
    auto box = getFace(0).boundingBox();
    for (Int i = 1; i < numFaces(); ++i) {
      box += getFace(i).boundingBox();
    }
    return box;
  } else {
    __builtin_unreachable();
  }
}

template <Int P, Int N>
PURE constexpr auto
FaceVertexMesh<P, N>::faceContaining(Point2 const & p) const noexcept -> Int
{
  for (Int i = 0; i < numFaces(); ++i) {
    if (getFace(i).contains(p)) {
      return i;
    }
  }
  return -1;
}

} // namespace um2
