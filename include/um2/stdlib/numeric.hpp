#pragma once

#include <um2/config.hpp>

//==============================================================================
// NUMERIC
//==============================================================================
// Implementation of a subset of <numeric> which is compatible with CUDA.
// See https://en.cppreference.com/w/cpp/numeric for details.
// The following functions are implemented:
//  iota

namespace um2
{

//==============================================================================
// iota
//==============================================================================

template <class T>
HOSTDEV constexpr void
iota(T * first, T const * const last, T value) noexcept
{
  for (; first != last; ++first, ++value) {
    *first = value;
  }
}

} // namespace um2
