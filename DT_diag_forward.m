function outSigs = DT_diag_forward( bMat,paramVals)
%FUNCTION DT_forward will generate the signal from the principal
%eigenvalues, given bMat: the pre-computed b-matrix on a per-voxel level,
%and the 'paramVals'
outSigs = zeros(length(bMat),size(bMat{1},1));
for ii = 1:length(bMat)
    outSigs(ii,:) = exp(-bMat{ii} * paramVals(ii,:)'); 

end

end
