HOSTDEV inline auto
makeTriReferenceMesh() -> um2::TriFVM
{
  um2::Vector<um2::Point2> const v = {
      {0, 0},
      {1, 0},
      {1, 1},
      {0, 1}
  };
  um2::Vector<um2::Vec<3, I>> const fv = {
      {0, 1, 2},
      {2, 3, 0}
  };
  //  mesh.vf_offsets = {0, 2, 3, 5, 6};
  //  mesh.vf = {0, 1, 0, 0, 1, 1};
  return {v, fv};
}

HOSTDEV inline auto
makeQuadReferenceMesh() -> um2::QuadFVM
{
  um2::Vector<um2::Point2> const v = {
      {0, 0},
      {1, 0},
      {1, 1},
      {0, 1},
      {2, 0},
      {2, 1}
  };
  um2::Vector<um2::Vec<4, I>> const fv = {
      {0, 1, 2, 3},
      {1, 4, 5, 2}
  };
  //  mesh.vf_offsets = {0, 1, 3, 5, 6, 7, 8};
  //  mesh.vf = {0, 0, 1, 0, 1, 0, 1, 1};
  return {v, fv};
}
////
//// template <std::floating_point T, std::signed_integral I>
//// HOSTDEV void makeTriQuadReferenceMesh(um2::TriQuadMesh & mesh)
////{
////   mesh.vertices = {
////       {0, 0},
////       {1, 0},
////       {1, 1},
////       {0, 1},
////       {2, 0}
////   };
////   mesh.fv_offsets = {0, 4, 7};
////   mesh.fv = {0, 1, 2, 3, 1, 4, 2};
////   mesh.vf_offsets = {0, 1, 3, 5, 6, 7};
////   mesh.vf = {0, 0, 1, 0, 1, 0, 1};
//// }
////
HOSTDEV inline auto
makeTri6ReferenceMesh() -> um2::Tri6FVM
{
  um2::Vector<um2::Point2> const v = {
      {               0,                0},
      {               1,                0},
      {               0,                1},
      {condCast<F>(0.5), condCast<F>(0.0)},
      {condCast<F>(0.7), condCast<F>(0.5)},
      {condCast<F>(0.0), condCast<F>(0.5)},
      {               1,                1},
      {condCast<F>(1.0), condCast<F>(0.5)},
      {condCast<F>(0.5), condCast<F>(1.0)}
  };
  um2::Vector<um2::Vec<6, I>> const fv = {
      {0, 1, 2, 3, 4, 5},
      {1, 6, 2, 7, 8, 4}
  };
  //  mesh.vf_offsets = {0, 1, 3, 5, 6, 8, 9, 10, 11, 12};
  //  mesh.vf = {0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1};
  return {v, fv};
}

HOSTDEV inline auto
makeQuad8ReferenceMesh() -> um2::Quad8FVM
{
  um2::Vector<um2::Point2> const v = {
      {condCast<F>(0.0), condCast<F>(0.0)},
      {condCast<F>(1.0), condCast<F>(0.0)},
      {condCast<F>(1.0), condCast<F>(1.0)},
      {condCast<F>(0.0), condCast<F>(1.0)},
      {condCast<F>(2.0), condCast<F>(0.0)},
      {condCast<F>(2.0), condCast<F>(1.0)},
      {condCast<F>(0.5), condCast<F>(0.0)},
      {condCast<F>(1.1), condCast<F>(0.6)},
      {condCast<F>(0.5), condCast<F>(1.0)},
      {condCast<F>(0.0), condCast<F>(0.5)},
      {condCast<F>(1.5), condCast<F>(0.0)},
      {condCast<F>(2.0), condCast<F>(0.5)},
      {condCast<F>(1.5), condCast<F>(1.0)}
  };
  um2::Vector<um2::Vec<8, I>> const fv = {
      {0, 1, 2, 3,  6,  7,  8, 9},
      {1, 4, 5, 2, 10, 11, 12, 7}
  };
  //  mesh.vf_offsets = {0, 1, 3, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16};
  //  mesh.vf = {0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1};
  return {v, fv};
}

// template <std::floating_point T, std::signed_integral I>
// HOSTDEV void makeTri6Quad8ReferenceMesh(um2::QuadraticTriQuadMesh &
// mesh)
//{
//   mesh.vertices = {
//       {condCast<F>(0.0), condCast<F>(0.0)},
//       {condCast<F>(1.0), condCast<F>(0.0)},
//       {condCast<F>(1.0), condCast<F>(1.0)},
//       {condCast<F>(0.0), condCast<F>(1.0)},
//       {condCast<F>(2.0), condCast<F>(0.0)},
//       {condCast<F>(0.5), condCast<F>(0.0)},
//       {condCast<F>(0.7), condCast<F>(0.6)},
//       {condCast<F>(0.5), condCast<F>(1.0)},
//       {condCast<F>(0.0), condCast<F>(0.5)},
//       {condCast<F>(1.5), condCast<F>(0.0)},
//       {condCast<F>(1.5), condCast<F>(0.5)}
//   };
//   mesh.fv_offsets = {0, 8, 14};
//   mesh.fv = {0, 1, 2, 3, 5, 6, 7, 8, 1, 4, 2, 9, 10, 6};
//   mesh.vf_offsets = {0, 1, 3, 5, 6, 7, 8, 10, 11, 12, 13, 14};
//   mesh.vf = {0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1};
// }
