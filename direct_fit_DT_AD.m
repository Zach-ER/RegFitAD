function  paramVals  = direct_fit_DT_AD( DW,W,bMat,initParams,sig,SSDind)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

f = @(x)obj_func_direct_fit(x,DW,W,bMat,sig,SSDind);

if SSDind
options = optimoptions(@fmincon,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',10000);
else
options = optimoptions(@lsqnonlin,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',10000);
end

lb = 1e-6.*ones(size(initParams));
ub = 3.5e-3 * ones(size(initParams));

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


function differences = obj_func_direct_fit(paramVals,DW,W,bMat,sig,SSDind)

%paramMat = vals_to_mat(paramVals);

voxParams = W * paramVals;
sigGuess = DT_diag_forward( bMat,voxParams);
differences = double(DW - sqrt(sigGuess.^2 + sig.^2));

if SSDind
differences = sum(differences(:).^2);
else
differences = sum(abs(differences),2);    
end

end




