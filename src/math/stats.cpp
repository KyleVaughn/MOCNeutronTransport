#include <um2/math/stats.hpp>

namespace um2
{

//=============================================================================
// mean
//=============================================================================

PURE HOSTDEV auto
mean(F const * begin, F const * end) noexcept -> F
{
  ASSERT_ASSUME(begin != end);
  F const n = static_cast<F>(end - begin);
  F result = 0;
  while (begin != end) {
    result += *begin;
    ++begin;
  }
  return result / n;
}

//=============================================================================
// median
//=============================================================================

PURE HOSTDEV auto
median(F const * begin, F const * end) noexcept -> F
{
  ASSERT_ASSUME(begin != end);
  ASSERT(um2::is_sorted(begin, end));
  auto const size = end - begin;
  auto const * const mid = begin + size / 2;
  // If the size is odd, return the middle element.
  if (size % 2 == 1) {
    return *mid;
  }
  // Otherwise, return the average of the two middle elements.
  return (*mid + *(mid - 1)) / 2;
}

//=============================================================================
// variance
//=============================================================================

PURE HOSTDEV auto
variance(F const * begin, F const * end) noexcept -> F
{
  ASSERT_ASSUME(begin != end);
  F const n_minus_1 = static_cast<F>(end - begin - 1);
  ASSERT(n_minus_1 > 0);
  auto const xbar = um2::mean(begin, end);
  F result = 0;
  while (begin != end) {
    F const x_minus_xbar = *begin - xbar;
    result += x_minus_xbar * x_minus_xbar;
    ++begin;
  }
  return result / n_minus_1;
}

//=============================================================================
// stdDev
//=============================================================================

PURE HOSTDEV auto
stdDev(F const * begin, F const * end) noexcept -> F
{
  return um2::sqrt(um2::variance(begin, end));
}

} // namespace um2
