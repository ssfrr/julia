## Triangular
type Triangular{T<:Number} <: AbstractMatrix{T}
    UL::Matrix{T}
    uplo::Char
    unitdiag::Char
end
function Triangular{T<:Number}(A::Matrix{T}, uplo::Symbol, unitdiag::Bool)
    if size(A, 1) != size(A, 2) throw(DimensionMismatch("matrix must be square")) end
    return Triangular(A, string(uplo)[1], unitdiag ? 'U' : 'N')
end
Triangular(A::Matrix, uplo::Symbol) = Triangular(A, uplo, all(diag(A) .== 1) ? true : false)
function Triangular(A::Matrix)
    if istriu(A) return Triangular(A, :U) end
    if istril(A) return Triangular(A, :L) end
    error("matrix is not triangular")
end

size(A::Triangular, args...) = size(A.UL, args...)

#Converting from Triangular to dense Matrix
convert(::Type{Matrix}, A::Triangular) = full(A)
full(A::Triangular) = istril(A) ? tril(A.UL) : triu(A.UL)

print_matrix(io::IO, A::Triangular, rows::Integer, cols::Integer) = print_matrix(io, full(A), rows, cols)

istril(A::Triangular) = A.uplo == 'L'
istriu(A::Triangular) = A.uplo == 'U'

# Vector multiplication
*{T<:BlasFloat}(A::Triangular{T}, b::Vector{T}) = BLAS.trmv(A.uplo, 'N', A.unitdiag, A.UL, b)
Ac_mul_B{T<:BlasComplex}(A::Triangular{T}, b::Vector{T}) = BLAS.trmv(A.uplo, 'C', A.unitdiag, A.UL, b)
At_mul_B{T<:BlasReal}(A::Triangular{T}, b::Vector{T}) = BLAS.trmv(A.uplo, 'T', A.unitdiag, A.UL, b)

# Matrix multiplication
*{T<:BlasFloat}(A::Triangular{T}, B::StridedMatrix{T}) = BLAS.trmm('L', A.uplo, 'N', A.unitdiag, one(T), A.UL, B)
*{T<:BlasFloat}(A::StridedMatrix{T}, B::Triangular{T}) = BLAS.trmm('R', B.uplo, 'N', B.unitdiag, one(T), A, B.UL)
Ac_mul_B{T<:BlasComplex}(A::Triangular{T}, B::StridedMatrix{T}) = BLAS.trmm('L', A.uplo, 'C', A.unitdiag, one(T), A.UL, B)
Ac_mul_B{T<:BlasReal}(A::Triangular{T}, B::StridedMatrix{T}) = BLAS.trmm('L', A.uplo, 'T', A.unitdiag, one(T), A.UL, B)
A_mul_Bc{T<:BlasComplex}(A::StridedMatrix{T}, B::Triangular{T}) = BLAS.trmm('R', B.uplo, 'C', B.unitdiag, one(T), B.UL, A)
A_mul_Bc{T<:BlasReal}(A::StridedMatrix{T}, B::Triangular{T}) = BLAS.trmm('R', B.uplo, 'T', B.unitdiag, one(T), B.UL, A)

function \{T<:BlasFloat}(A::Triangular{T}, B::StridedVecOrMat{T})
    r, info = LAPACK.trtrs!(A.uplo, 'N', A.unitdiag, A.UL, copy(B))
    if info > 0 throw(SingularException(info)) end
    return r
end
function Ac_ldiv_B{T<:BlasReal}(A::Triangular{T}, B::StridedVecOrMat{T}) 
    r, info = LAPACK.trtrs!(A.uplo, 'T', A.unitdiag, A.UL, copy(B))
    if info > 0 throw(SingularException(info)) end
    return r
end
function Ac_ldiv_B{T<:BlasComplex}(A::Triangular{T}, B::StridedVecOrMat{T})
    r, info = LAPACK.trtrs!(A.uplo, 'C', A.unitdiag, A.UL, copy(B))
    if info > 0 throw(SingularException(info)) end
    return r
end
/{T<:BlasFloat}(A::StridedVecOrMat{T}, B::Triangular{T}) = BLAS.trsm!('R', B.uplo, 'N', B.unitdiag, one(T), B.UL, copy(A))
A_rdiv_Bc{T<:BlasReal}(A::StridedVecOrMat{T}, B::Triangular{T}) = BLAS.trsm!('R', B.uplo, 'T', B.unitdiag, one(T), B.UL, copy(A))
A_rdiv_Bc{T<:BlasComplex}(A::StridedVecOrMat{T}, B::Triangular{T}) = BLAS.trsm!('R', B.uplo, 'C', B.unitdiag, one(T), B.UL, copy(A))

det(A::Triangular) = prod(diag(A.UL))

function inv{T<:BlasFloat}(A::Triangular{T})
    Ainv, info = LAPACK.trtri!(A.uplo, A.unitdiag, copy(A.UL))
    if info > 0 throw(LinAlg.SingularException(info)) end
    return Ainv
end
inv(A::Triangular) = inv(Triangular(float(A.UL), A.uplo, A.unitdiag))
diag(A::Triangular) = diag(A.UL)
getindex(A::Triangular,m::Int,n::Int) = getindex(A.UL, m, n)

#######################
# Eigenvalues/vectors #
#######################

eigvals(A::Triangular) = A.uplo=='U' ? diag(A) : reverse(diag(A))
function eigvecs{T<:BlasFloat}(A::Triangular{T})
  V = LAPACK.trevc!('R', 'A', Array(Bool,1), A.uplo=='U' ? A.UL : transpose(A.UL),
    Array(T,size(A)), Array(T, size(A)))
  if A.uplo=='L' #This is the transpose of the Schur form
    #The eigenvectors must be transformed
    VV = inv(Triangular(transpose(V)))
    N = size(V,2)
    for i=1:N #Reorder eigenvectors to follow LAPACK convention
      V[:,i]=VV[:,N+1-i]
    end
  end
  #Need to normalize
  for i=1:size(V,2)
    V[:,i] /= norm(V[:,i])
  end
  V
end
eig(M::Triangular) = eigvals(M), eigvecs(M)
eigfact(M::Triangular) = Eigen(eigvals(M), eigvecs(M))

#############################
# Singular values / vectors #
#############################

svd(M::Triangular) = svd(full(M))
svdfact(M::Triangular) = svdfact(full(M))
svdfact!(M::Triangular) = svdfact!(full(M))
svdvals(M::Triangular) = svdvals(full(M))
svdvecs(M::Triangular) = svdvecs(full(M))

