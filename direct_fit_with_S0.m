function [paramVals,sigGuess]=direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind)

%This runs the regional fit on the whole-brain, trimming none of it.

%we need to scale our DW signal down so that it's in on the same scale as
%the diffusivities 

DWfac = 1000 * mean(DW(:,1)); %to get something on the same scale as diffusivity
DW = DW./DWfac; 

%include an extra column for the S0 
newParams = [initParams(:,1),initParams];

%% fitting the thing 
[paramVals, sigGuess] = do_fit(DW,W,bMat,newParams,riceNoise,SSDind);
  
paramVals(:,1) = []; 
    
end

function  [paramVals,sigGuess]  = do_fit(DW,W,bMat,initParams,sig,SSDind)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

f = @(x)obj_func_direct_fit(x,DW,W,bMat,sig,SSDind);

if (SSDind && SSDind ~= 's')
options = optimoptions(@fmincon,...
    'display','none',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',1000);
else
options = optimoptions(@lsqnonlin,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'MaxFunEvals',1000);
%'/Users/zer/RegFitAD/data/1525'
end

lb = 1e-6.*ones(size(initParams));
ub = 5e-3 * ones(size(initParams));
lb(:,1) = 0; ub(:,1) = 10000;

if (SSDind && SSDind ~= 's')
    [paramVals,~] = fmincon(f,initParams,[],[],[],[],lb,ub,[],options);
else
    [paramVals,~] = lsqnonlin(f,initParams,lb,ub,options);
end

sigGuess = DT_diag_forward_with_S0(bMat,W*paramVals);

end

function differences = obj_func_direct_fit(paramVals,DW,W,bMat,sig,SSDind)
%s for small
%paramMat = vals_to_mat(paramVals);

voxParams = W * paramVals;
sigGuess = DT_diag_forward_with_S0(bMat,voxParams);
differences = double(DW - sqrt(sigGuess.^2 + sig.^2));


if SSDind == 's';
    differences = differences;        
elseif  SSDind
    differences = sum(differences(:).^2);
else
    differences = sqrt(sum(differences.^2,2));    
end

end

function outSigs = DT_diag_forward_with_S0( bMat,paramVals)
%FUNCTION DT_forward will generate the signal from the principal
%eigenvalues, given bMat: the pre-computed b-matrix on a per-voxel level,
%and the 'paramVals' - which are the S0s, then the principal eigenvalues. 

Ds = paramVals(:,2:4); 
exponent = multiprod(bMat,Ds,[2 3],2);
S0s = repmat(paramVals(:,1),[1 size(exponent,2)]);

outSigs = S0s.*exp(-exponent);

end



