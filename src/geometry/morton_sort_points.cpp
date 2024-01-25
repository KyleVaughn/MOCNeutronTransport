#include <um2/geometry/morton_sort_points.hpp>

namespace um2
{

PURE HOSTDEV auto
mortonEncode(Point2 const & p) noexcept -> MortonCode
{
  return mortonEncode<MortonCode, F>(p[0], p[1]);
}

PURE HOSTDEV auto
mortonEncode(Point3 const & p) noexcept -> MortonCode
{
  return mortonEncode<MortonCode, F>(p[0], p[1], p[2]);
}

HOSTDEV void
mortonDecode(MortonCode const morton, Point2 & p) noexcept
{
  mortonDecode(morton, p[0], p[1]);
}

HOSTDEV void
mortonDecode(MortonCode const morton, Point3 & p) noexcept
{
  mortonDecode(morton, p[0], p[1], p[2]);
}

} // namespace um2
