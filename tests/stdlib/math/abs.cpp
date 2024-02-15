#include <um2/stdlib/math/abs.hpp>

#include <numeric> // std::numeric_limits

#include "../../test_macros.hpp"

HOSTDEV
TEST_CASE(abs_int)
{
  static_assert(um2::abs(-1) == 1);
  static_assert(um2::abs(0) == 0);
  static_assert(um2::abs(1) == 1);
}
MAKE_CUDA_KERNEL(abs_int);

HOSTDEV
TEST_CASE(abs_float)
{
  // Exact equality is important here
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wfloat-equal"
  static_assert(um2::abs(-1.0F) == 1.0F);
  static_assert(um2::abs(0.0F) == 0.0F);
  static_assert(um2::abs(-0.0F) == 0.0F);
  static_assert(um2::abs(1.0F) == 1.0F);
#ifndef __CUDA_ARCH__
  float constexpr inf = std::numeric_limits<float>::infinity();
  static_assert(um2::abs(inf) == inf);
  static_assert(um2::abs(-inf) == inf);
#endif
#pragma GCC diagnostic pop
}
MAKE_CUDA_KERNEL(abs_float);

TEST_SUITE(abs)
{
  TEST_HOSTDEV(abs_int);
  TEST_HOSTDEV(abs_float);
}

auto
main() -> int
{
  RUN_SUITE(abs);
  return 0;
}
