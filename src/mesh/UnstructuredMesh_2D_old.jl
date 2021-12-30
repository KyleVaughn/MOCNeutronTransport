# Return a mesh with boundary edges and all necessary prerequisites to find the boundary edges
# Not type-stable
function add_boundary_edges(mesh::UnstructuredMesh_2D{F, U}, 
                            bounding_shape::String) where {F <: AbstractFloat, U <: Unsigned}
    if 0 == length(mesh.edge_face_connectivity)
        mesh = add_connectivity(mesh)
    end
    return UnstructuredMesh_2D{F, U}(name = mesh.name,
                                     points = mesh.points,
                                     edges = mesh.edges,
                                     materialized_edges = mesh.materialized_edges,
                                     faces = mesh.faces,
                                     materialized_faces = mesh.materialized_faces,
                                     edge_face_connectivity = mesh.edge_face_connectivity,
                                     face_edge_connectivity = mesh.face_edge_connectivity,
                                     boundary_edges = boundary_edges(mesh, bounding_shape),
                                     face_sets = mesh.face_sets
                                    )
end

# Return a mesh with every field created
# Not type-stable
function add_everything(mesh::UnstructuredMesh_2D{F, U}) where {F <: AbstractFloat, U <: Unsigned}
    return add_boundary_edges(add_materialized_faces(add_materialized_edges(mesh)), "Rectangle")
end

# Axis-aligned bounding box, in 2d a rectangle.
# Type-stable, other than the error message
function bounding_box(mesh::UnstructuredMesh_2D{F, U};
                      rectangular_boundary::Bool = false) where {F <: AbstractFloat, U <: Unsigned}
    # If the mesh does not have any quadratic faces, the bounding_box may be determined entirely from the
    # points. If the mesh does have quadratic cells/faces, we need to find the bounding box of the edges
    # that border the mesh.
    if (any(x->x[1] ∈  UnstructuredMesh_2D_quadratic_cell_types, mesh.faces) &&
        !rectangular_boundary)
        @error "Cannot find bounding_box for a mesh with quadratic faces that does not have a rectangular boundary"
        return Quadrilateral_2D(Point_2D(F, 0),
                                Point_2D(F, 0),
                                Point_2D(F, 0),
                                Point_2D(F, 0))
    else # Can use points
        return bounding_box(mesh.points) 
    end
end

# Return the face containing point p.
# Not type-stable
function find_face(p::Point_2D{F}, mesh::UnstructuredMesh_2D{F, U}) where {F <: AbstractFloat,
                                                                           U <: Unsigned}
    if 0 < length(mesh.materialized_faces)
        return U(find_face_explicit(p, mesh.materialized_faces))
    else
        return U(find_face_implicit(p, mesh.faces, mesh.points))
    end
end

# Return the intersection algorithm that will be used for l ∩ mesh
# Not type-stable
function get_intersection_algorithm(mesh::UnstructuredMesh_2D)
    if length(mesh.materialized_edges) !== 0
        return "Edges - Explicit"
    elseif length(mesh.edges) !== 0
        return "Edges - Implicit"
    elseif length(mesh.materialized_faces) !== 0
        return "Faces - Explicit"
    else
        return "Faces - Implicit"
    end
end

# Intersect a line with the mesh. Returns a vector of intersection points, sorted based
# upon distance from the line's start point
# Not type-stable
function intersect(l::LineSegment_2D{F}, 
                   mesh::UnstructuredMesh_2D{F}
                  ) where {F <: AbstractFloat}
    # Edges are faster, so they are the default
    if length(mesh.edges) !== 0 
        if 0 < length(mesh.materialized_edges)
            return intersect_edges_explicit(l, mesh.materialized_edges)
        else
            return intersect_edges_implicit(l, mesh.edges, mesh.points)
        end
    else
        if 0 < length(mesh.materialized_faces)
            return intersect_faces_explicit(l, mesh.materialized_faces)
        else
            return intersect_faces_implicit(l, mesh.faces, mesh.points)
        end
    end
end

function reorder_points_to_hilbert(mesh::UnstructuredMesh_2D{F, U}
                           ) where {F <: AbstractFloat, U <: Unsigned}
    # Points
    # point_map     maps  new_points[i] == mesh.points[point_map[i]]
    # point_map_inv maps mesh.points[i] == new_points[point_map_inv[i]]
    point_map  = U.(remap_points_to_hilbert(mesh.points))
    point_map_inv = U.(sortperm(point_map))
    # new_points is the reordered point vector, reordered to resemble a hilbert curve
    new_points = mesh.points[point_map] 

    # Adjust face indices
    # Point IDs have changed, so we need to change the point IDs referenced by the faces
    new_faces_vec = [ point_map_inv[face] for face in mesh.faces]  
    for i in 1:length(mesh.faces)
        new_faces_vec[i][1] = mesh.faces[i][1]
    end
    new_faces = SVector.(new_faces_vec)
    return UnstructuredMesh_2D{F, U}(name = mesh.name,
                                     points = new_points,
                                     faces = new_faces,
                                     face_sets = mesh.face_sets
                                    )
end













































































# Return a mesh composed of the faces in the face set set_name
# Not type-stable
function submesh(mesh::UnstructuredMesh_2D{F, U},
                 set_name::String) where {F <: AbstractFloat, U <: Unsigned}
    @debug "Creating submesh for '$set_name'"
    face_ids = mesh.face_sets[set_name]
    return submesh(set_name, mesh.points, mesh.faces, mesh.face_sets, face_ids)
end
