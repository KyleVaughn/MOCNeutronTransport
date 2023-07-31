#include <um2/mesh/RectilinearGrid.hpp>

#include "../test_macros.hpp"

template <Size D, typename T>
HOSTDEV static constexpr auto
makeGrid() -> um2::RectilinearGrid<D, T>
{
  um2::RectilinearGrid<D, T> grid;
  if constexpr (D >= 1) {
    grid.divs[0] = {0, 1};
  }
  if constexpr (D >= 2) {
    grid.divs[1] = {0, 1, 2};
  }
  if constexpr (D >= 3) {
    grid.divs[2] = {0, 1, 2, 3};
  }
  return grid;
}

template <Size D, typename T>
HOSTDEV
TEST_CASE(clear)
{
  um2::RectilinearGrid<D, T> grid = makeGrid<D, T>();
  grid.clear();
  for (Size i = 0; i < D; ++i) {
    ASSERT(grid.divs[i].empty());
  }
}

template <Size D, typename T>
HOSTDEV
TEST_CASE(accessors)
{
  um2::RectilinearGrid<D, T> grid = makeGrid<D, T>();
  um2::Vec<D, Size> const ncells = grid.numCells();
  if constexpr (D >= 1) {
    auto const nx = 1;
    ASSERT_NEAR(grid.xMin(), grid.divs[0][0], static_cast<T>(1e-6));
    ASSERT_NEAR(grid.xMax(), grid.divs[0][nx], static_cast<T>(1e-6));
    ASSERT(grid.numXCells() == nx);
    ASSERT(ncells[0] == nx);
    ASSERT_NEAR(grid.width(), grid.divs[0][nx] - grid.divs[0][0], static_cast<T>(1e-6));
  }
  if constexpr (D >= 2) {
    auto const ny = 2;
    ASSERT_NEAR(grid.yMin(), grid.divs[1][0], static_cast<T>(1e-6));
    ASSERT_NEAR(grid.yMax(), grid.divs[1][ny], static_cast<T>(1e-6));
    ASSERT(grid.numYCells() == ny);
    ASSERT(ncells[1] == ny);
    ASSERT_NEAR(grid.height(), grid.divs[1][ny] - grid.divs[1][0], static_cast<T>(1e-6));
  }
  if constexpr (D >= 3) {
    auto const nz = 3;
    ASSERT_NEAR(grid.zMin(), grid.divs[2][0], static_cast<T>(1e-6));
    ASSERT_NEAR(grid.zMax(), grid.divs[2][nz], static_cast<T>(1e-6));
    ASSERT(grid.numZCells() == nz);
    ASSERT(ncells[2] == nz);
    ASSERT_NEAR(grid.depth(), grid.divs[2][nz] - grid.divs[2][0], static_cast<T>(1e-6));
  }
}

template <Size D, typename T>
HOSTDEV
TEST_CASE(boundingBox)
{
  um2::RectilinearGrid<D, T> grid = makeGrid<D, T>();
  um2::AxisAlignedBox<D, T> box = grid.boundingBox();
  if constexpr (D >= 1) {
    ASSERT_NEAR(box.minima[0], grid.divs[0][0], static_cast<T>(1e-6));
    ASSERT_NEAR(box.maxima[0], grid.divs[0][1], static_cast<T>(1e-6));
  }
  if constexpr (D >= 2) {
    ASSERT_NEAR(box.minima[1], grid.divs[1][0], static_cast<T>(1e-6));
    ASSERT_NEAR(box.maxima[1], grid.divs[1][2], static_cast<T>(1e-6));
  }
  if constexpr (D >= 3) {
    ASSERT_NEAR(box.minima[2], grid.divs[2][0], static_cast<T>(1e-6));
    ASSERT_NEAR(box.maxima[2], grid.divs[2][3], static_cast<T>(1e-6));
  }
}

template <typename T>
HOSTDEV
TEST_CASE(getBox)
{
  // Declare some variables to avoid a bunch of static casts.
  T const three = static_cast<T>(3);
  T const two = static_cast<T>(2);
  T const one = static_cast<T>(1);
  T const half = static_cast<T>(0.5);
  T const forth = static_cast<T>(0.25);
  um2::RectilinearGrid2<T> grid;
  grid.divs[0] = {1.0, 1.5, 2.0, 2.5, 3.0};
  grid.divs[1] = {-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0};
  um2::AxisAlignedBox2<T> box = grid.getBox(0, 0);
  um2::AxisAlignedBox2<T> box_ref = {
      {         1,             -1},
      {one + half, -three * forth}
  };
  ASSERT(um2::isApprox(box, box_ref));
  box = grid.getBox(1, 0);
  //{ { 1.5, -1.0 }, { 2.0, -0.75 } };
  box_ref = {
      {one + half,           -one},
      {       two, -three * forth}
  };
  ASSERT(um2::isApprox(box, box_ref));
  box = grid.getBox(3, 0);
  // box_ref = { { 2.5, -1.0 }, { 3.0, -0.75 } };
  box_ref = {
      {two + half,           -one},
      {     three, -three * forth}
  };
  ASSERT(um2::isApprox(box, box_ref));
  box = grid.getBox(0, 1);
  // box_ref = { { 1.0, -0.75 }, { 1.5, -0.5 } };
  box_ref = {
      {       one, -three * forth},
      {one + half,          -half}
  };
  ASSERT(um2::isApprox(box, box_ref));
  box = grid.getBox(0, 7);
  // box_ref = { { 1.0, 0.75 }, { 1.5, 1.0 } };
  box_ref = {
      {       one, three * forth},
      {one + half,           one}
  };
  ASSERT(um2::isApprox(box, box_ref));
  box = grid.getBox(3, 7);
  // box_ref = { { 2.5, 0.75 }, { 3.0, 1.0 } };
  box_ref = {
      {two + half, three * forth},
      {     three,           one}
  };
  ASSERT(um2::isApprox(box, box_ref));
}
//
// template <typename T>
// HOSTDEV TEST(aabb2_constructor)
//    um2::AxisAlignedBox2<T> b00(um2::Point2<T>(0, 0), um2::Point2<T>(1, 1));
//    um2::AxisAlignedBox2<T> b10(um2::Point2<T>(1, 0), um2::Point2<T>(2, 1));
//    um2::AxisAlignedBox2<T> b01(um2::Point2<T>(0, 1), um2::Point2<T>(1, 2));
//    um2::AxisAlignedBox2<T> b11(um2::Point2<T>(1, 1), um2::Point2<T>(2, 2));
//    um2::AxisAlignedBox2<T> b02(um2::Point2<T>(0, 2), um2::Point2<T>(1, 3));
//    um2::AxisAlignedBox2<T> b12(um2::Point2<T>(1, 2), um2::Point2<T>(2, 3));
//    um2::Vector<um2::AxisAlignedBox2<T>> boxes = { b00, b10, b01, b11, b02, b12 };
//    um2::RectilinearGrid2<T> grid(boxes);
//
//    ASSERT(grid.divs[0].size() == 3, "x divs");
//    T xref[3] = { 0, 1, 2 };
//    for (Size i = 0; i < 3; ++i) {
//        ASSERT_NEAR(grid.divs[0][i], xref[i], 1e-6, "x divs");
//    }
//    ASSERT(grid.divs[1].size() == 4, "y divs");
//
//    T yref[4] = { 0, 1, 2, 3 };
//    for (Size i = 0; i < 4; ++i) {
//        ASSERT_NEAR(grid.divs[1][i], yref[i], 1e-6, "y divs");
//    }
//
//    um2::RectilinearGrid2<T> grid2(b01);
//    ASSERT(grid2.divs[0].size() == 2, "x divs");
//    ASSERT(grid2.divs[1].size() == 2, "y divs");
//    ASSERT_NEAR(grid2.divs[0][0], 0, 1e-6, "x divs");
//    ASSERT_NEAR(grid2.divs[0][1], 1, 1e-6, "x divs");
//    ASSERT_NEAR(grid2.divs[1][0], 1, 1e-6, "y divs");
//    ASSERT_NEAR(grid2.divs[1][1], 2, 1e-6, "y divs");
// END_TEST
//
// template <typename T>
// TEST(id_array_constructor)
//    std::vector<std::vector<int>> ids = {
//        { 0, 1, 2, 0 },
//        { 0, 2, 0, 2 },
//        { 0, 1, 0, 1 },
//    };
//    std::vector<um2::Vec2<T>> dxdy = {
//        { 2, 1 },
//        { 2, 1 },
//        { 2, 1 },
//        { 2, 1 },
//    };
//    um2::RectilinearGrid2<T> grid(dxdy, ids);
//
//    ASSERT(grid.divs[0].size() == 5, "x divs");
//    T xref[5] = { 0, 2, 4, 6, 8 };
//    for (Size i = 0; i < 5; ++i) {
//        ASSERT_NEAR(grid.divs[0][i], xref[i], 1e-6, "x divs");
//    }
//    ASSERT(grid.divs[1].size() == 4, "y divs");
//    T yref[4] = { 0, 1, 2, 3 };
//    for (Size i = 0; i < 4; ++i) {
//        ASSERT_NEAR(grid.divs[1][i], yref[i], 1e-6, "y divs");
//    }
// END_TEST
//
////#if HAS_CUDA
////template <Size D, typename T>
////ADD_TEMPLATED_CUDA_KERNEL(clear, clear_kernel, D, T)
////template <Size D, typename T>
////ADD_TEMPLATED_KERNEL_TEST(clear_kernel, clear_cuda, D, T)
////
////template <Size D, typename T>
////ADD_TEMPLATED_CUDA_KERNEL(accessors, accessors_kernel, D, T)
////template <Size D, typename T>
////ADD_TEMPLATED_KERNEL_TEST(accessors_kernel, accessors_cuda, D, T)
////
////template <Size D, typename T>
////ADD_TEMPLATED_CUDA_KERNEL(bounding_box, bounding_box_kernel, D, T)
////template <Size D, typename T>
////ADD_TEMPLATED_KERNEL_TEST(bounding_box_kernel, bounding_box_cuda, D, T)
////
////template <typename T>
////ADD_TEMPLATED_CUDA_KERNEL(getBox, getBox_kernel, T)
////template <typename T>
////ADD_TEMPLATED_KERNEL_TEST(getBox_kernel, getBox_cuda, T)
////
////template <typename T>
////ADD_TEMPLATED_CUDA_KERNEL(aabb2_constructor, aabb2_constructor_kernel, T)
////template <typename T>
////ADD_TEMPLATED_KERNEL_TEST(aabb2_constructor_kernel, aabb2_constructor_cuda, T)
////#endif

template <Size D, typename T>
TEST_SUITE(RectilinearGrid)
{
  TEST((clear<D, T>));
  TEST((accessors<D, T>));
  TEST((boundingBox<D, T>));
  if constexpr (D == 2) {
    TEST((getBox<T>));
    //    RUN_TEST("aabb2_constructor", (aabb2_constructor<T>)  );
    //    RUN_TEST("id_array_constructor", (id_array_constructor<T>)  );
  }
}

auto
main() -> int
{
  RUN_SUITE((RectilinearGrid<1, float>));
  RUN_SUITE((RectilinearGrid<1, double>));
  RUN_SUITE((RectilinearGrid<2, float>));
  RUN_SUITE((RectilinearGrid<2, double>));
  RUN_SUITE((RectilinearGrid<3, float>));
  RUN_SUITE((RectilinearGrid<3, double>));
  return 0;
}
