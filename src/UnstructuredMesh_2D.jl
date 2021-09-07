Base.@kwdef struct UnstructuredMesh_2D{T <: AbstractFloat}
    points::Vector{Point_2D{T}}
    faces::Vector{Union{
                        NTuple{4, Int64},
                        NTuple{5, Int64},
                        NTuple{7, Int64},
                        NTuple{9, Int64}
                       }}
    name::String = "DefaultMeshName"
    face_sets::Dict{String, Set{Int64}} = Dict{String, Set{Int64}}()
end

#    edges::NTuple{E, Tuple{Vararg{Int64}}}

# Cell types are the same as VTK
const UnstructuredMesh_2D_linear_cell_types = [5, # Triangle 
                                               9  # Quadrilateral
                                              ]
const UnstructuredMesh_2D_quadratic_cell_types = [22, # Triangle6
                                                  23  # Quadrilateral8
                                                 ]
const UnstructuredMesh_2D_cell_types = vcat(UnstructuredMesh_2D_linear_cell_types,
                                            UnstructuredMesh_2D_quadratic_cell_types)

# Return each edge for a face
# Note, this returns a vector of vectors because we want to mutate the elements of the edge vectors
function edges(face::Tuple{Vararg{Int64}})
    cell_type = face[1]
    n_vertices = length(face) - 1
    if face[1] ∈  UnstructuredMesh_2D_linear_cell_types 
        edges = [ [face[i], face[i+1]] for i = 2:n_vertices]
        # Add the final edge that connects first and last vertices
        push!(edges, [face[n_vertices + 1], face[2]])
    elseif face[1] ∈  UnstructuredMesh_2D_quadratic_cell_types
        # There are N linear vertices and N quadratic vertices
        N = n_vertices ÷ 2
        edges = [ [face[i], face[i+1], face[N + i]] for i = 2:N]
        # Add the final edge that connects first and last vertices
        push!(edges, [face[N+1], face[2], face[2N+1]])
    else
        error("Unsupported cell type.")
        edges = [[-1, -1]]
    end
    return edges
end

# Create the edges for each face
function edges(faces::NTuple{F, Tuple{Vararg{Int64}}}) where F
    edges_unfiltered = Vector{Int64}[]
    for face in faces
        # Get the edges for each face
        face_edges = edges(face)
        # Order the linear edge vertices by ID
        for edge in face_edges 
            if edge[2] < edge[1]
                e1 = edge[1]
                edge[1] = edge[2]
                edge[2] = e1
            end
            # Add the edge to the list of edges
            push!(edges_unfiltered, edge)
        end
    end
    # Filter the duplicate edges
    edges_filtered = sort(collect(Set(edges_unfiltered)))
    return Tuple([ Tuple(v) for v in edges_filtered ])
end

function submesh(mesh::UnstructuredMesh_2D, 
                 face_ids::Set{Int64};
                 name::String = "DefaultMeshName")
    # Setup faces and get all vertex ids
    faces = Vector{Vector{Int64}}(undef, length(face_ids))
    vertex_ids = Set{Int64}()
    for (i, face_id) in enumerate(face_ids)
        face = collect(mesh.faces[face_id])
        faces[i] = face
        union!(vertex_ids, Set(face[2:length(face)]))
    end
    # Need to remap vertex ids in faces to new ids
    vertex_ids_sorted = sort(collect(vertex_ids))
    vertex_map = Dict{Int64, Int64}()
    for (i,v) in enumerate(vertex_ids_sorted)
        vertex_map[v] = i
    end
    points = Vector{Point_2D{typeof(mesh.points[1].x[1])}}(undef, length(vertex_ids_sorted))
    for (i, v) in enumerate(vertex_ids_sorted)
        points[i] = mesh.points[v]
    end
    # remap vertex ids in faces
    for face in faces
        for (i, v) in enumerate(face[2:length(face)])
            face[i + 1] = vertex_map[v] 
        end
    end
    # At this point we have points, faces, & name.
    # Just need to get the face sets
    face_sets = Dict{String, Set{Int64}}()
    for face_set_name in keys(mesh.face_sets)
        set_intersection = intersect(mesh.face_sets[face_set_name], face_ids)
        if length(set_intersection) !== 0
            face_sets[face_set_name] = set_intersection
        end
    end
    # Need to remap face ids in face sets
    face_map = Dict{Int64, Int64}()
    for (i,f) in enumerate(face_ids)
        face_map[f] = i
    end
    for face_set_name in keys(face_sets)                                       
        new_set = Set{Int64}()
        for fid in face_sets[face_set_name]
            union!(new_set, face_map[fid])
        end
        face_sets[face_set_name] = new_set
    end
    return UnstructuredMesh_2D(points = Tuple(points),
                               faces = Tuple([Tuple(face) for face in faces]),
                               name = name,
                               face_sets = face_sets
                              )
end

function submesh(mesh::UnstructuredMesh_2D, set_name::String)
    @debug "Creating submesh for '$set_name'"
    face_ids = mesh.face_sets[set_name]
    return submesh(mesh, face_ids, name = set_name) 
end

# Axis-aligned bounding box, in 2d a rectangle.
function AABB(mesh::UnstructuredMesh_2D; rectangular_boundary=false)
    # If the mesh does not have any quadratic faces, the AABB may be determined entirely from the 
    # points. If the mesh does have quadratic cells/faces, we need to find the bounding box of the edges
    # that border the mesh.
    if (any(x->x ∈  UnstructuredMesh_2D_quadratic_cell_types, getindex.(mesh.faces, 1)) && 
        !rectangular_boundary)
        error("Cannot find AABB for a mesh with quadratic faces that does not have a rectangular boundary")
    else # Can use points
        x = map(p->p[1], mesh.points)
        y = map(p->p[2], mesh.points)
        xmin = minimum(x)
        xmax = maximum(x)
        ymin = minimum(y)
        ymax = maximum(y)
        return Quadrilateral_2D(Point_2D(xmin, ymin), 
                                Point_2D(xmax, ymin),
                                Point_2D(xmax, ymax),
                                Point_2D(xmin, ymax))
    end
end

function get_face_points(mesh::UnstructuredMesh_2D, 
                         face::Union{
                                       NTuple{4, Int64},
                                       NTuple{5, Int64},
                                       NTuple{7, Int64},
                                       NTuple{9, Int64}
                                     })
    T = typeof(mesh.points[1].x[1])
    points = Vector{Point_2D{T}}(undef, length(face) - 1)
    i = 1
    for pt in face[2:length(face)]
        points[i] = mesh.points[pt]
        i += 1
    end
    return Tuple(points)
end

function area(mesh::UnstructuredMesh_2D, face_set::Set{Int64}) 
    return mapreduce(x->area(mesh, mesh.faces[x]), +, face_set)
end

function area(mesh::UnstructuredMesh_2D, set_name::String)
    return area(mesh, mesh.face_sets[set_name])
end

function area(mesh::UnstructuredMesh_2D, face::NTuple{4, Int64})
    T = typeof(mesh.points[1].x[1])
    the_area = T(0)
    type_id = face[1]
    if type_id == 5 # Triangle
        the_area = area(Triangle_2D(get_face_points(mesh, face)))
    else
        @warn "Mesh element has unsupported type $type_id"
    end
    return the_area
end

function area(mesh::UnstructuredMesh_2D, face::NTuple{5, Int64})
    T = typeof(mesh.points[1].x[1])
    the_area = T(0)
    type_id = face[1]
    if type_id == 9 # Quadrilateral
        the_area = area(Quadrilateral_2D(get_face_points(mesh, face)))
    else
        @warn "Mesh element has unsupported type $type_id"
    end
    return the_area
end

function area(mesh::UnstructuredMesh_2D, face::NTuple{7, Int64})
    T = typeof(mesh.points[1].x[1])
    the_area = T(0)
    type_id = face[1]
    if type_id == 22 # Triangle6
        the_area = area(Triangle6_2D(get_face_points(mesh, face)))
    else
        @warn "Mesh element has unsupported type $type_id"
    end
    return the_area
end

function area(mesh::UnstructuredMesh_2D, face::NTuple{9, Int64})
    T = typeof(mesh.points[1].x[1])
    the_area = T(0)
    type_id = face[1]
    if type_id == 23 # Quadrilateral8
        the_area = area(Quadrilateral8_2D(get_face_points(mesh, face)))
    else
        @warn "Mesh element has unsupported type $type_id"
    end
    return the_area
end

function Base.show(io::IO, mesh::UnstructuredMesh_2D)
    println(mesh.name)
    size_MB = Base.summarysize(mesh)/1E6
    println("  ├─ Size (MB) : $size_MB")
    type = typeof(mesh.points[1].x[1])
    println("  ├─ Type      : $type")
    npoints = length(mesh.points)
    println("  ├─ Points    : $npoints")
    nfaces = length(mesh.faces)
    println("  ├─ Faces     : $nfaces")
    ntri   = sum(x->x[1] == 5,  mesh.faces)
    nquad  = sum(x->x[1] == 9,  mesh.faces)
    ntri6  = sum(x->x[1] == 22, mesh.faces)
    nquad8 = sum(x->x[1] == 23, mesh.faces)
    println("  │  ├─ Triangle       : $ntri")
    println("  │  ├─ Quadrilateral  : $nquad")
    println("  │  ├─ Triangle6      : $ntri6")
    println("  │  └─ Quadrilateral8 : $nquad8")
    nface_sets = length(keys(mesh.face_sets))
    println("  └─ Face sets : $nface_sets")
end
