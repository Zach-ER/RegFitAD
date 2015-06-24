function  paramVals  = direct_fit_DT_AD( DW,W,bMat,initParams,sig,riceInd)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

% if ~riceInd
f = @(x)obj_func_direct_fit(x,DW,W,bMat,sig);
% else
%     f = @(x)obj_func_rician(x,DW,W,bMat,sig);
% end

options = optimoptions(@lsqnonlin,...
    'display','none',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',5000);

lb = 1e-9.*ones(size(initParams));
ub = 3.5e-3 * ones(size(initParams));

[paramVals,finalDiff] = lsqnonlin(f,initParams,lb,...
    ub,options);

end

%note: paramVals = a 3 x N  matrix, and we're only going to deal with the
%diagonals, because in every voxel we've pre-accounted for the directions. 


function differences = obj_func_direct_fit(paramVals,DW,W,bMat,sig)

%paramMat = vals_to_mat(paramVals);

voxParams = W * paramVals;
sigGuess = DT_diag_forward( bMat,voxParams);
differences = double(DW - sqrt(sigGuess.^2 + sig.^2));

end




