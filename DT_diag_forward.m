function outSigs = DT_diag_forward( bMat,paramVals)
%FUNCTION DT_forward will generate the signal from the principal
%eigenvalues, given bMat: the pre-computed b-matrix on a per-voxel level,
%and the 'paramVals'

exponent = multiprod(bMat,paramVals,[2 3],2);
outSigs = exp(-exponent);

end
