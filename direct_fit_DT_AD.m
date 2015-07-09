function  paramVals  = direct_fit_DT_AD(S0,DW,W,bMat,initParams,sig,SSDind)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

f = @(x)obj_func_direct_fit(x,S0,DW,W,bMat,sig,SSDind);

if SSDind
options = optimoptions(@fmincon,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',1000);
else
options = optimoptions(@lsqnonlin,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'MaxFunEvals',5000);
%'diffMinChange',1e-4,...
end

lb = 1e-6.*ones(size(initParams));
ub = 4e-3 * ones(size(initParams));

if SSDind
    [paramVals,finalDiff] = fmincon(f,initParams,[],[],[],[],lb,...
    ub,[],options);
else
    [paramVals,finalDiff] = lsqnonlin(f,initParams,lb,...
    ub,options);
end

end

%note: paramVals = a 3 x N  matrix, and we're only going to deal with the
%diagonals, because in every voxel we've pre-accounted for the directions. 


function differences = obj_func_direct_fit(paramVals,S0,DW,W,bMat,sig,SSDind)

%paramMat = vals_to_mat(paramVals);

voxParams = W * paramVals;
sigGuess = repmat(S0,[1 size(DW,2)]).*DT_diag_forward( bMat,voxParams);
differences = double(DW - sqrt(sigGuess.^2 + sig.^2));


if SSDind
    differences = sum(differences(:).^2);
else
    differences = sqrt(sum(differences.^2,2));    
end

end




