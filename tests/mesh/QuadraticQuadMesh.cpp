#include <um2/mesh/QuadraticQuadMesh.hpp>

#include "./helpers/setup_mesh.hpp"

#include "../test_macros.hpp"

template <std::floating_point T, std::signed_integral I>
HOSTDEV
TEST_CASE(accessors)
{
  um2::QuadraticQuadMesh<2, T, I> mesh = makeQuad6ReferenceMesh<2, T, I>();
  ASSERT(mesh.numVertices() == 9);
  ASSERT(mesh.numFaces() == 2);
  // face
  um2::QuadraticQuadrilateral<2, T> quad0_ref(mesh.vertices[0], mesh.vertices[1],
                                        mesh.vertices[2], mesh.vertices[3],
                                        mesh.vertices[4], mesh.vertices[5]);
  auto const quad0 = mesh.face(0);
  ASSERT(um2::isApprox(quad0[0], quad0_ref[0]));
  ASSERT(um2::isApprox(quad0[1], quad0_ref[1]));
  ASSERT(um2::isApprox(quad0[2], quad0_ref[2]));
  ASSERT(um2::isApprox(quad0[3], quad0_ref[3]));
  ASSERT(um2::isApprox(quad0[4], quad0_ref[4]));
  ASSERT(um2::isApprox(quad0[5], quad0_ref[5]));
  um2::Quadrilateral<2, T> quad1_ref(mesh.vertices[1], mesh.vertices[6], mesh.vertices[2],
                               mesh.vertices[7], mesh.vertices[8], mesh.vertices[4]);
  auto const quad1 = mesh.face(1);
  ASSERT(um2::isApprox(quad1[0], quad1_ref[0]));
  ASSERT(um2::isApprox(quad1[1], quad1_ref[1]));
  ASSERT(um2::isApprox(quad1[2], quad1_ref[2]));
  ASSERT(um2::isApprox(quad1[3], quad1_ref[3]));
  ASSERT(um2::isApprox(quad1[4], quad1_ref[4]));
  ASSERT(um2::isApprox(quad1[5], quad1_ref[5]));
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(boundingBox)
{
  um2::QuadraticQuadMesh<2, T, I> const mesh = makeQuad6ReferenceMesh<2, T, I>();
  auto const box = mesh.boundingBox();
  ASSERT_NEAR(box.xMin(), static_cast<T>(0), static_cast<T>(1e-6));
  ASSERT_NEAR(box.xMax(), static_cast<T>(1), static_cast<T>(1e-6));
  ASSERT_NEAR(box.yMin(), static_cast<T>(0), static_cast<T>(1e-6));
  ASSERT_NEAR(box.yMax(), static_cast<T>(1), static_cast<T>(1e-6));
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(faceContaining)
{
  um2::QuadraticQuadMesh<2, T, I> const mesh = makeQuad6ReferenceMesh<2, T, I>();
  um2::Point2<T> p(static_cast<T>(0.6), static_cast<T>(0.5));
  ASSERT(mesh.faceContaining(p) == 0);
  p = um2::Point2<T>(static_cast<T>(0.8), static_cast<T>(0.5));
  ASSERT(mesh.faceContaining(p) == 1);
}

#if UM2_ENABLE_CUDA
template <std::floating_point T, std::signed_integral I>
MAKE_CUDA_KERNEL(accessors, T, I)
#endif

template <std::floating_point T, std::signed_integral I>
TEST_SUITE(QuadraticQuadMesh)
{
  TEST_HOSTDEV(accessors, 1, 1, T, I);
  TEST((boundingBox<T, I>));
  TEST((faceContaining<T, I>));
}

auto
main() -> int
{
  RUN_SUITE((QuadraticQuadMesh<float, int16_t>));
  RUN_SUITE((QuadraticQuadMesh<float, int32_t>));
  RUN_SUITE((QuadraticQuadMesh<float, int64_t>));
  RUN_SUITE((QuadraticQuadMesh<double, int16_t>));
  RUN_SUITE((QuadraticQuadMesh<double, int32_t>));
  RUN_SUITE((QuadraticQuadMesh<double, int64_t>));
  return 0;
}
