# Gives generic rules for generating the strictly new vertices when splitting
#  an E-dimensional simplex with a size reducing factor of k. Subsimplices containing
#  one of the original vertices is not considered.
#
# splits the decomposition part of a SimplexSplitting output. This is a
# (k^E * (E+1) x k) array of integers. (so, ignore the orientations for now)
#
# @return
#  NewVert An array of the vertices of the splitted simplex.
function simplicial_subdivision_single(k, E)
    ##
    # OUTCOME:
    # NewVert is an array of dimension R x k. Each row contains the indices of
    # the original vertices defining the new vertices of the simplicial subdivision.
    # R = (k+E)!/(k! E!)-E-1
    # Subtriangulation is an array of dimension (E+1)k^E x 1. It consists of a
    # stack of k^E columns of dimension E+1, each one of them containing
    # the indices of the vertices generating the corresponding simplex of the subdivision in the order
    # given by [rows(OriginalVertices);rows(NewVert)]
    ##

    # Get simplex splitting rules, ignore orientations for now.
    splits = simplex_split(k, E, orientations = false)

    # Retrieve integer labels from the tensor decomposition. A way of uniquely identifying
    # the rows of splits. Each integer corresponds to a row in
    # splits (but are not necessarily in order).
    integer_labels = (splits .- 1) * ((E+1) .^ collect(0:(k-1)))

    uniquelabels = unique(integer_labels)
    n_rows = size(uniquelabels, 1)

    J = indexin(integer_labels, uniquelabels)

    # IndicesOfUnqiueIntegersinOriginal
    I = Vector{Int}(length(uniquelabels))
    for i = 1:length(uniquelabels)
        I[i] = findfirst(integer_labels, uniquelabels[i])
    end


    Aux = splits[I, :]
    V = repmat(uniquelabels, 1, E + 1)
    aux = repmat((((E+1)^k - 1) ./ E) * collect(0:E).', size(uniquelabels, 1), 1)

    aux = heaviside0(-abs.(V - aux)) .* repmat(collect(1:n_rows), 1, E + 1)
    aux = aux[find(aux)]

    aux = round.(Int, aux)
    Caux = round.(Int, complementary(aux, n_rows))
    Ipp = [aux; Caux]

    Ip = zeros(Int, size(I))

    # for any i\in Ipp, Ip(i) is the number j\in {1,...,size(Ipp,1)} such that Ipp(j)=i
    Ip[Ipp] = collect(1:size(I, 1)).'

    # Indices of the non-repeated vertices that are not part of the original simplex.
    # These are the truly new vertices generated by the splitting.
    NewVert = Aux[Caux, :]

    allverts = vcat(repmat(collect(1:(E+1)), 1, k), NewVert)

    # Subarrays of dimension E+1 x 1 vertically concatenated. Each subarray contains the
    # indices in the rows of NewVert corresponding to the vertices furnishing the corresponding
    # simplex (analogous to the output of SimplexSplitting, check notes).
    SubTriangulation = round.(Int, Ip[J])
    SubTriangulation = reshape(SubTriangulation, E + 1, k^E).'

    return allverts, SubTriangulation
end
