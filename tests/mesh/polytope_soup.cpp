#include <um2/mesh/polytope_soup.hpp>

#include "./helpers/setup_polytope_soup.hpp"

#include "../test_macros.hpp"

#include <fstream>

template <std::floating_point T, std::signed_integral I>
TEST_CASE(addVertex)
{
  um2::PolytopeSoup<T, I> soup;
  ASSERT(soup.addVertex(1, 2, 3) == 0);
  ASSERT(soup.addVertex(2, 3, 4) == 1);

  um2::Point3<T> const p0 = soup.getVertex(0);
  ASSERT(um2::isApprox(p0, um2::Point3<T>(1, 2, 3)));
  um2::Point3<T> const p1 = soup.getVertex(1);
  ASSERT(um2::isApprox(p1, um2::Point3<T>(2, 3, 4)));
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(addElement)
{
  um2::PolytopeSoup<T, I> soup;
  um2::Vector<I> conn = {0};
  ASSERT(soup.addVertex(0, 0) == 0);
  ASSERT(soup.addVertex(1, 0) == 1);
  ASSERT(soup.addVertex(0, 1) == 2);
  ASSERT(soup.addElement(um2::VTKElemType::Vertex, conn) == 0);
  conn = {0, 1};
  ASSERT(soup.addElement(um2::VTKElemType::Line, conn) == 1);
  conn = {0, 1, 2};
  ASSERT(soup.addElement(um2::VTKElemType::Triangle, conn) == 2);

  um2::VTKElemType elem_type = um2::VTKElemType::None;
  soup.getElement(0, elem_type, conn);
  ASSERT(elem_type == um2::VTKElemType::Vertex);
  um2::Vector<I> conn_ref = {0};
  ASSERT(conn == conn_ref);

  soup.getElement(1, elem_type, conn);
  ASSERT(elem_type == um2::VTKElemType::Line);
  conn_ref = {0, 1};
  ASSERT(conn == conn_ref);

  soup.getElement(2, elem_type, conn);
  ASSERT(elem_type == um2::VTKElemType::Triangle);
  conn_ref = {0, 1, 2};
  ASSERT(conn == conn_ref);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(addElset)
{
  um2::PolytopeSoup<T, I> soup;
  soup.addVertex(0, 0);
  soup.addVertex(1, 0);
  soup.addVertex(0, 1);
  soup.addVertex(1, 1);
  um2::Vector<I> conn = {0};
  soup.addElement(um2::VTKElemType::Vertex, conn);
  conn = {0, 1};
  soup.addElement(um2::VTKElemType::Line, conn);
  conn = {0, 1, 2};
  soup.addElement(um2::VTKElemType::Triangle, conn);
  conn = {0, 1, 2, 3};
  soup.addElement(um2::VTKElemType::Quad, conn);

  soup.addElset("all", {0, 1, 2, 3}, {11, 12, 13, 14});
  soup.addElset("tri", {2});
  ASSERT(soup.numElsets() == 2);

  um2::String name;
  um2::Vector<I> ids;
  um2::Vector<T> elset_data;
  soup.getElset(0, name, ids, elset_data);
  ASSERT(name == "all");
  ASSERT(ids == um2::Vector<I>({0, 1, 2, 3}));
  ASSERT(elset_data == um2::Vector<T>({11, 12, 13, 14}));
  elset_data.clear();
  soup.getElset(1, name, ids, elset_data);
  ASSERT(name == "tri");
  ASSERT(ids == um2::Vector<I>({2}));
  ASSERT(elset_data.empty());
}

TEST_CASE(verticesPerElem)
{
  static_assert(um2::verticesPerElem(um2::VTKElemType::Vertex) == 1);
  static_assert(um2::verticesPerElem(um2::VTKElemType::Line) == 2);
  static_assert(um2::verticesPerElem(um2::VTKElemType::Triangle) == 3);
  static_assert(um2::verticesPerElem(um2::VTKElemType::Quad) == 4);
  static_assert(um2::verticesPerElem(um2::VTKElemType::QuadraticEdge) == 3);
  static_assert(um2::verticesPerElem(um2::VTKElemType::QuadraticTriangle) == 6);
  static_assert(um2::verticesPerElem(um2::VTKElemType::QuadraticQuad) == 8);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(getMeshType)
{
  um2::PolytopeSoup<T, I> tri;
  makeReferenceTriPolytopeSoup(tri);
  ASSERT(tri.getMeshType() == um2::MeshType::Tri);

  um2::PolytopeSoup<T, I> quad;
  makeReferenceQuadPolytopeSoup(quad);
  ASSERT(quad.getMeshType() == um2::MeshType::Quad);

  um2::PolytopeSoup<T, I> tri_quad;
  makeReferenceTriQuadPolytopeSoup(tri_quad);
  ASSERT(tri_quad.getMeshType() == um2::MeshType::TriQuad);

  um2::PolytopeSoup<T, I> tri6;
  makeReferenceTri6PolytopeSoup(tri6);
  ASSERT(tri6.getMeshType() == um2::MeshType::QuadraticTri);

  um2::PolytopeSoup<T, I> quad8;
  makeReferenceQuad8PolytopeSoup(quad8);
  ASSERT(quad8.getMeshType() == um2::MeshType::QuadraticQuad);

  um2::PolytopeSoup<T, I> tri6_quad8;
  makeReferenceTri6Quad8PolytopeSoup(tri6_quad8);
  ASSERT(tri6_quad8.getMeshType() == um2::MeshType::QuadraticTriQuad);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(sortElsets)
{
  um2::PolytopeSoup<T, I> tri;
  um2::PolytopeSoup<T, I> tri_ref;

  tri.addVertex(0, 0);
  tri.addVertex(1, 0);
  tri.addVertex(0, 1);
  tri.addVertex(1, 1);
  tri_ref.addVertex(0, 0);
  tri_ref.addVertex(1, 0);
  tri_ref.addVertex(0, 1);
  tri_ref.addVertex(1, 1);

  um2::Vector<I> conn = {0, 1, 2};
  tri.addElement(um2::VTKElemType::Triangle, conn);
  tri_ref.addElement(um2::VTKElemType::Triangle, conn);
  conn = {1, 3, 2};
  tri.addElement(um2::VTKElemType::Triangle, conn);
  tri_ref.addElement(um2::VTKElemType::Triangle, conn);

  tri_ref.addElset("A", {0, 1}, {10, 2});
  tri_ref.addElset("B", {1});
  tri_ref.addElset("Material_H2O", {1});
  tri_ref.addElset("Material_UO2", {0});

  tri.addElset("Material_H2O", {1});
  tri.addElset("B", {1});
  tri.addElset("Material_UO2", {0});
  tri.addElset("A", {0, 1}, {10, 2});

  tri.sortElsets();

  um2::String name;
  um2::Vector<I> ids;
  um2::Vector<T> elset_data;
  tri.getElset(0, name, ids, elset_data);
  ASSERT(name == "A");
  ASSERT(ids == um2::Vector<I>({0, 1}));
  ASSERT(elset_data == um2::Vector<T>({10, 2}));
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(mortonSortVertices)
{
  um2::PolytopeSoup<T, I> soup;
  for (Size j = 0; j < 3; ++j) {
    for (Size i = 0; i < 3; ++i) {
      soup.addVertex(
          um2::Point3<T>(static_cast<T>(i), static_cast<T>(j), static_cast<T>(0)));
    }
  }
  soup.addElement(um2::VTKElemType::Quad, {0, 1, 4, 3});
  soup.addElement(um2::VTKElemType::Quad, {1, 2, 5, 4});
  soup.addElement(um2::VTKElemType::Quad, {4, 5, 8, 7});
  soup.addElement(um2::VTKElemType::Quad, {3, 4, 7, 6});
  soup.mortonSortVertices();
  ASSERT(um2::isApprox(soup.getVertex(0), um2::Point3<T>(0, 0, 0)));
  ASSERT(um2::isApprox(soup.getVertex(1), um2::Point3<T>(1, 0, 0)));
  ASSERT(um2::isApprox(soup.getVertex(2), um2::Point3<T>(0, 1, 0)));
  ASSERT(um2::isApprox(soup.getVertex(3), um2::Point3<T>(1, 1, 0)));
  ASSERT(um2::isApprox(soup.getVertex(4), um2::Point3<T>(2, 0, 0)));
  ASSERT(um2::isApprox(soup.getVertex(5), um2::Point3<T>(2, 1, 0)));
  ASSERT(um2::isApprox(soup.getVertex(6), um2::Point3<T>(0, 2, 0)));
  ASSERT(um2::isApprox(soup.getVertex(7), um2::Point3<T>(1, 2, 0)));
  ASSERT(um2::isApprox(soup.getVertex(8), um2::Point3<T>(2, 2, 0)));
  um2::Vector<I> conn;
  um2::VTKElemType type = um2::VTKElemType::Triangle;
  soup.getElement(0, type, conn);
  ASSERT(type == um2::VTKElemType::Quad);
  ASSERT(conn == um2::Vector<I>({0, 1, 3, 2}));
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(mortonSortElements)
{
  um2::PolytopeSoup<T, I> soup;
  for (Size j = 0; j < 3; ++j) {
    for (Size i = 0; i < 3; ++i) {
      soup.addVertex(
          um2::Point3<T>(static_cast<T>(i), static_cast<T>(j), static_cast<T>(0)));
    }
  }
  soup.addElement(um2::VTKElemType::Triangle, {0, 1, 3});
  soup.addElement(um2::VTKElemType::Triangle, {1, 4, 3});
  soup.addElement(um2::VTKElemType::Triangle, {4, 5, 7});
  soup.addElement(um2::VTKElemType::Triangle, {5, 8, 7});
  soup.addElement(um2::VTKElemType::Quad, {1, 2, 5, 4});
  soup.addElement(um2::VTKElemType::Quad, {3, 4, 7, 6});

  soup.addElset("Triangles", {0, 1, 2, 3});
  soup.addElset("Quads", {4, 5});

  um2::VTKElemType type = um2::VTKElemType::None;
  um2::Vector<I> conn;
  um2::Point3<T> p;

  T const zero = static_cast<T>(0);
  T const third = static_cast<T>(1) / static_cast<T>(3);
  T const two_thirds = static_cast<T>(2) / static_cast<T>(3);

  soup.getElement(0, type, conn);
  p = um2::Point3<T>(third, third, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({0, 1, 3}));
  ASSERT(um2::isApprox(soup.getElementCentroid(0), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(1, type, conn);
  p = um2::Point3<T>(two_thirds, two_thirds, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({1, 4, 3}));
  ASSERT(um2::isApprox(soup.getElementCentroid(1), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(2, type, conn);
  p = um2::Point3<T>(third + 1, third + 1, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({4, 5, 7}));
  ASSERT(um2::isApprox(soup.getElementCentroid(2), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(3, type, conn);
  p = um2::Point3<T>(two_thirds + 1, two_thirds + 1, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({5, 8, 7}));
  ASSERT(um2::isApprox(soup.getElementCentroid(3), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(4, type, conn);
  p = um2::Point3<T>(static_cast<T>(1.5), static_cast<T>(0.5), zero);
  ASSERT(type == um2::VTKElemType::Quad);
  ASSERT(conn == um2::Vector<I>({1, 2, 5, 4}));
  ASSERT(um2::isApprox(soup.getElementCentroid(4), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(5, type, conn);
  p = um2::Point3<T>(static_cast<T>(0.5), static_cast<T>(1.5), zero);
  ASSERT(type == um2::VTKElemType::Quad);
  ASSERT(conn == um2::Vector<I>({3, 4, 7, 6}));
  ASSERT(um2::isApprox(soup.getElementCentroid(5), p));

  soup.mortonSortElements();

  soup.getElement(0, type, conn);
  p = um2::Point3<T>(third, third, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({0, 1, 3}));
  ASSERT(um2::isApprox(soup.getElementCentroid(0), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(1, type, conn);
  p = um2::Point3<T>(two_thirds, two_thirds, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({1, 4, 3}));
  ASSERT(um2::isApprox(soup.getElementCentroid(1), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(2, type, conn);
  p = um2::Point3<T>(static_cast<T>(1.5), static_cast<T>(0.5), zero);
  ASSERT(type == um2::VTKElemType::Quad);
  ASSERT(conn == um2::Vector<I>({1, 2, 5, 4}));
  ASSERT(um2::isApprox(soup.getElementCentroid(2), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(3, type, conn);
  p = um2::Point3<T>(static_cast<T>(0.5), static_cast<T>(1.5), zero);
  ASSERT(type == um2::VTKElemType::Quad);
  ASSERT(conn == um2::Vector<I>({3, 4, 7, 6}));
  ASSERT(um2::isApprox(soup.getElementCentroid(3), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(4, type, conn);
  p = um2::Point3<T>(third + 1, third + 1, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({4, 5, 7}));
  ASSERT(um2::isApprox(soup.getElementCentroid(4), p));
  type = um2::VTKElemType::None;
  conn.clear();

  soup.getElement(5, type, conn);
  p = um2::Point3<T>(two_thirds + 1, two_thirds + 1, zero);
  ASSERT(type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({5, 8, 7}));
  ASSERT(um2::isApprox(soup.getElementCentroid(5), p));

  // Check elsets
  um2::String name;
  um2::Vector<I> ids;
  um2::Vector<T> elset_data;
  soup.getElset(0, name, ids, elset_data);
  ASSERT(name == "Triangles");
  ASSERT(ids == um2::Vector<I>({0, 1, 4, 5}));
  ASSERT(elset_data.empty());

  soup.getElset(1, name, ids, elset_data);
  ASSERT(name == "Quads");
  ASSERT(ids == um2::Vector<I>({2, 3}));
  ASSERT(elset_data.empty());
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(getSubmesh)
{
  um2::PolytopeSoup<T, I> tri_quad;
  makeReferenceTriQuadPolytopeSoup(tri_quad);
  um2::PolytopeSoup<T, I> tri_quad_a;

  tri_quad.getSubmesh("A", tri_quad_a);
  ASSERT(tri_quad.compareTo(tri_quad_a) == 10);
  um2::String name;
  um2::Vector<I> ids;
  um2::Vector<T> elset_data;
  tri_quad_a.getElset(0, name, ids, elset_data);
  ASSERT(name == "B");
  ASSERT(ids == um2::Vector<I>({1}));
  ASSERT(elset_data.empty());
  tri_quad_a.getElset(1, name, ids, elset_data);
  ASSERT(name == "Material_H2O");
  ASSERT(ids == um2::Vector<I>({1}));
  ASSERT(elset_data.empty());
  tri_quad_a.getElset(2, name, ids, elset_data);
  ASSERT(name == "Material_UO2");
  ASSERT(ids == um2::Vector<I>({0}));
  ASSERT(elset_data.empty());

  um2::PolytopeSoup<T, I> tri_quad_h2o;
  tri_quad.getSubmesh("Material_H2O", tri_quad_h2o);

  // (1,0), (1,1), (2,0)
  ASSERT(tri_quad_h2o.numVerts() == 3);
  ASSERT(um2::isApprox(tri_quad_h2o.getVertex(0), um2::Point3<T>(1, 0, 0)));
  ASSERT(um2::isApprox(tri_quad_h2o.getVertex(1), um2::Point3<T>(1, 1, 0)));
  ASSERT(um2::isApprox(tri_quad_h2o.getVertex(2), um2::Point3<T>(2, 0, 0)));

  ASSERT(tri_quad_h2o.numElems() == 1);
  um2::VTKElemType elem_type = um2::VTKElemType::None;
  um2::Vector<I> conn;
  tri_quad_h2o.getElement(0, elem_type, conn);
  ASSERT(elem_type == um2::VTKElemType::Triangle);
  ASSERT(conn == um2::Vector<I>({0, 2, 1}));

  ASSERT(tri_quad_h2o.numElsets() == 2);
  tri_quad_h2o.getElset(0, name, ids, elset_data);
  ASSERT(name == "A");
  ASSERT(ids == um2::Vector<I>({0}));
  ASSERT(elset_data.size() == 1);
  ASSERT_NEAR(elset_data[0], 2, static_cast<T>(1e-6));

  elset_data.clear();
  tri_quad_h2o.getElset(1, name, ids, elset_data);
  ASSERT(name == "B");
  ASSERT(ids == um2::Vector<I>({0}));
  ASSERT(elset_data.empty());
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(getMaterialNames)
{
  um2::PolytopeSoup<T, I> tri_ref;
  makeReferenceTriPolytopeSoup(tri_ref);
  um2::Vector<um2::String> const mat_names_ref = {"Material_H2O", "Material_UO2"};
  um2::Vector<um2::String> mat_names;
  tri_ref.getMaterialNames(mat_names);
  ASSERT(mat_names == mat_names_ref);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(getMaterialIDs)
{
  um2::PolytopeSoup<T, I> tri_ref;
  makeReferenceTriPolytopeSoup(tri_ref);
  um2::Vector<MaterialID> mat_ids;
  tri_ref.getMaterialIDs(mat_ids, {"Material_H2O", "Material_UO2"});
  um2::Vector<MaterialID> const mat_ids_ref = {1, 0};
  ASSERT(mat_ids == mat_ids_ref);
  mat_ids.clear();
  tri_ref.getMaterialIDs(mat_ids, {"Material_UO2", "Material_H2O"});
  um2::Vector<MaterialID> const mat_ids_ref2 = {0, 1};
  ASSERT(mat_ids == mat_ids_ref2);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_tri_mesh)
{
  um2::String const filename = "./mesh_files/tri.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTriPolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_quad_mesh)
{
  um2::String const filename = "./mesh_files/quad.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceQuadPolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_tri_quad_mesh)
{
  um2::String const filename = "./mesh_files/tri_quad.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTriQuadPolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_tri6_mesh)
{
  um2::String const filename = "./mesh_files/tri6.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTri6PolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_quad8_mesh)
{
  um2::String const filename = "./mesh_files/quad8.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceQuad8PolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_abaqus_tri6_quad8_mesh)
{
  um2::String const filename = "./mesh_files/tri6_quad8.inp";
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTri6Quad8PolytopeSoup(mesh_ref);

  um2::PolytopeSoup<T, I> mesh;
  mesh.read(filename);

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Only missing data
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_tri_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTriPolytopeSoup(mesh_ref);
  mesh_ref.write("./tri.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./tri.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./tri.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./tri.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_quad_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceQuadPolytopeSoup(mesh_ref);
  mesh_ref.write("./quad.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./quad.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./quad.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./quad.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_tri_quad_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTriQuadPolytopeSoup(mesh_ref);
  mesh_ref.write("./tri_quad.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./tri_quad.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./tri_quad.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./tri_quad.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_tri6_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTri6PolytopeSoup(mesh_ref);
  mesh_ref.write("./tri6.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./tri6.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./tri6.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./tri6.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_quad8_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceQuad8PolytopeSoup(mesh_ref);
  mesh_ref.write("./quad8.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./quad8.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./quad8.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./quad8.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_CASE(io_xdmf_tri6_quad8_mesh)
{
  um2::PolytopeSoup<T, I> mesh_ref;
  makeReferenceTri6Quad8PolytopeSoup(mesh_ref);
  mesh_ref.write("./tri6_quad8.xdmf");

  um2::PolytopeSoup<T, I> mesh;
  mesh.read("./tri6_quad8.xdmf");

  ASSERT(mesh.compareTo(mesh_ref) == 17); // Don't read elset data

  int stat = std::remove("./tri6_quad8.xdmf");
  ASSERT(stat == 0);
  stat = std::remove("./tri6_quad8.h5");
  ASSERT(stat == 0);
}

template <std::floating_point T, std::signed_integral I>
TEST_SUITE(PolytopeSoup)
{
  TEST((addVertex<T, I>));
  TEST((addElement<T, I>));
  TEST((addElset<T, I>));
  TEST(verticesPerElem);
  TEST((getMeshType<T, I>));
  TEST((sortElsets<T, I>));
  TEST((mortonSortVertices<T, I>));
  TEST((mortonSortElements<T, I>));
  TEST((getSubmesh<T, I>));
  TEST((getMaterialNames<T, I>));
  TEST((getMaterialIDs<T, I>));
  TEST((io_abaqus_tri_mesh<T, I>));
  TEST((io_abaqus_quad_mesh<T, I>));
  TEST((io_abaqus_tri_quad_mesh<T, I>));
  TEST((io_abaqus_tri6_mesh<T, I>));
  TEST((io_abaqus_quad8_mesh<T, I>));
  TEST((io_abaqus_tri6_quad8_mesh<T, I>));
  TEST((io_xdmf_tri_mesh<T, I>));
  TEST((io_xdmf_quad_mesh<T, I>));
  TEST((io_xdmf_tri_quad_mesh<T, I>));
  TEST((io_xdmf_tri6_mesh<T, I>));
  TEST((io_xdmf_quad8_mesh<T, I>));
  TEST((io_xdmf_tri6_quad8_mesh<T, I>));
}

auto
main() -> int
{
  RUN_SUITE((PolytopeSoup<float, int16_t>));
  RUN_SUITE((PolytopeSoup<float, int32_t>));
  RUN_SUITE((PolytopeSoup<float, int64_t>));
  RUN_SUITE((PolytopeSoup<double, int16_t>));
  RUN_SUITE((PolytopeSoup<double, int32_t>));
  RUN_SUITE((PolytopeSoup<double, int64_t>));
  return 0;
}
