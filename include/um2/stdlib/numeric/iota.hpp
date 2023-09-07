#pragma once

#include <um2/config.hpp>

namespace um2
{

//==============================================================================
// iota 
//==============================================================================

template <class T>
HOSTDEV constexpr
void iota(T * first, T * const last, T value)
{
  while (first != last) {
    *first++ = value;
    ++value;
  }
}

} // namespace um2
