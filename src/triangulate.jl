using Parameters

"""
    triangulate(points::Array{Float64, 2})

Triangulate a set of vertices in N dimensions. `points` is an array of vertices, where
each row of the array is a point.
"""
function triangulate(points::Array{Float64, 2})
    indices = Simplices.Delaunay.delaunayn(points)
    return indices
end

"""
    Triangulation(points::Array{Float64, 2}, impoints::Array{Float64, 2},
                simplex_inds::Array{Int, 2})
"""
@with_kw mutable struct Triangulation
    # The vertices of the triangulation
    points::Array{Float64, 2} = Array{Float64, 2}()

    # The image vertices of the triangulation
    impoints::Array{Float64, 2} = Array{Float64, 2}()

    # Array of indices referencing the vertices furnishing each simplex
    simplex_inds::Array{Int, 2} = Array{Float64, 2}()

    # Some properties of the simplices furnishing the triangulation
    centroids::Array{Float64, 2} = Array{Float64, 2}()
    radii::Vector{Float64} = Float64[]
    centroids_im::Array{Float64, 2}  = Array{Float64, 2}()
    radii_im::Vector{Float64} = Float64[]
    orientations::Vector{Float64} = Float64[]
    orientations_im::Vector{Float64} = Float64[]
    volumes::Vector{Float64} = Float64[]
    volumes_im::Vector{Float64} = Float64[]
end

todict(t::Triangulation) = Dict([fn => getfield(t, fn) for fn = fieldnames(t)])
export todict

"""
Returns the allocated memory in Mb for a triangulation of `n_simplices` which are given
by `n_verts` points in dimension `dim`. Assumes integers are stored as Int64
"""
function triang_malloc(n_simplices::Int, dim::Int, n_verts::Int)
    n_numbers = (n_simplices * (dim + 1)) + # simplex indices
                2*(n_verts * dim) + # vertices
                6*n_simplices + # radii, orientations, volumes
                2*(n_simplices*dim) # centroids
    # Each number takes 64 bit = (64 bit) * (1 byte / 8 bit) = 8 bytes of memory.
    n_numbers / 8
end

"""
    invariant_triangulation(embedding::Array{Float64, 2})

Create a `Triangulation` from an invariant `embedding`. Note: this function does not check
for invariance. This must have been done beforehand.
"""
function triang_from_embedding(e::SimplexSplitting.Embedding)
    points = e.embedding[1:end-1, :]
    simplex_inds = triangulate(points)
    impoints = e.embedding[2:end, :]
    c, r = SimplexSplitting.centroids_radii2(points, simplex_inds)
    cim, rim = SimplexSplitting.centroids_radii2(impoints, simplex_inds)
    vol = SimplexSplitting.simplex_volumes(points, simplex_inds)
    volim = SimplexSplitting.simplex_volumes(impoints, simplex_inds)
    orientations = SimplexSplitting.orientations(points, simplex_inds)
    orientations_im = SimplexSplitting.orientations(impoints, simplex_inds)

    Triangulation(
        points = points,
        impoints = impoints,
        simplex_inds = simplex_inds,
        centroids = c,
        radii = r,
        volumes = vol,
        centroids_im = cim,
        radii_im = rim,
        volumes_im = volim,
        orientations = orientations,
        orientations_im = orientations_im)
end



"""
    invariant_triangulation(embedding::Array{Float64, 2})

Create a `Triangulation` from an invariant `embedding`. Note: this function does not check
for invariance. This must have been done beforehand.
"""
function example_triangulation(n_simplices::Int)
    embedding = gaussian_embedding(n_simplices).embedding
    points = embedding[1:end-1, :]
    impoints = embedding[2:end, :]

    simplex_inds = triangulate(points)
    c, r = SimplexSplitting.centroids_radii2(points, simplex_inds)
    cim, rim = SimplexSplitting.centroids_radii2(impoints, simplex_inds)
    vol = SimplexSplitting.simplex_volumes(points, simplex_inds)
    volim = SimplexSplitting.simplex_volumes(impoints, simplex_inds)
    Triangulation(points, impoints, simplex_inds, c, r, vol, cim, rim, volim)
end




struct Simplex
    v::Vector{Vector{Float64}}
end


"""
Find the simplex with index i
"""
function find_simplex(t::Triangulation, i::Int)
    s = Vector{Vector{Float64}}(4)
    n_vertices = size(t.simplex_inds, 2)
    for j in 1:n_vertices
        s[j] = t.points[t.simplex_inds[i, j], :]
    end
    return Simplex(s)
end


"""
Find the image simplex with index i
"""
function find_imsimplex(t::Triangulation, i::Int)
    s = Vector{Vector{Float64}}(4)
    n_vertices = size(t.simplex_inds, 2)
    for j in 1:n_vertices
        s[j] = t.impoints[t.simplex_inds[i, j], :]
    end
    return Simplex(s)
end

function get_simplices(t::Triangulation)
    n_simplices = size(t.simplex_inds, 1)
    simplices = Vector{Simplex}(n_simplices)
    for i = 1:n_simplices
        simplices[i] = find_simplex(t, i)
    end
    simplices
end

function get_imagesimplices(t::Triangulation)
    n_simplices = size(t.simplex_inds, 1)
    simplices = Vector{Simplex}(n_simplices)
    for i = 1:n_simplices
        simplices[i] = find_imsimplex(t, i)
    end
    simplices
end



function newpoint!(pt::Array{Float64, 1}, s::Simplex, coeffs)
    pt .= 0.0
    for i in 1:length(s.v)
        pt .= pt .+ coeffs[i] * s.v[i]
    end
    pt
end
