function  paramVals  = direct_fit_DT_AD( DW,W,bMat,initParams,sig,riceInd)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

% if ~riceInd
f = @(x)obj_func_direct_fit(x,DW,W,bMat);
% else
%     f = @(x)obj_func_rician(x,DW,W,bMat,sig);
% end

options = optimoptions(@lsqnonlin,...
    'display','none',...
    'tolfun',1e-30',...
    'tolx',1e-30,...
    'diffMinChange',1e-4,...
    'UseParallel',false,...
    'MaxFunEvals',5000);

lb = zeros(size(initParams))-eps;
ub = 3.5 * ones(size(initParams));

[paramVals,finalDiff] = fmincon(f,initParams,[],[],[],[],lb,...
    ub,[],options);

end

%note: paramVals = a 3 x N  matrix, and we're only going to deal with the
%diagonals, because in every voxel we've pre-accounted for the directions. 


function SSD = obj_func_direct_fit(paramVals,DW,W,bMat)

%paramMat = vals_to_mat(paramVals);

voxelParameters = W *paramVals;
sigGuess = DT_diag_forward; 
differences = DW(:) - sigGuess(:);
SSD = double(sum(differences .^2));


end


function lse = obj_func_rician(paramVals,DW,W,bvals,bvecs,sig)
%see ferizi, 2013 ish 
%note, noise should really vary with sigma, right? 

% paramMat = vals_to_mat(paramVals);

Phi = DT_forward( bMat,paramVals');
sigGuess = W * Phi; 

lse = sum((DW(:) - sqrt(sigGuess(:).^2 + sig.^2)).^2);
lse = double(lse);

if sig > 0
    lse = lse /sig.^2;
end
end


