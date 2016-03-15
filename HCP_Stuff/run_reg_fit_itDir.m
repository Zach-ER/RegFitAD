function run_reg_fit_itDir(subjDir,segInds,riceNoise,diffsOut,DTparamsOut,initParams,upsInd)

[DW,Segs,bMat,bMask,S0] = load_diff_data(subjDir,segInds,upsInd);
%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
S0 = S0.img(bMask); 

%%
if initParams == 'n'
    k = size(W,2);
    initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
end
%%

SSDind = 's'; %1,0,'s'

%paramVals = direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind);
paramVals = direct_fit_DT_AD(S0,DW,W,bMat,initParams,riceNoise,SSDind);

%% note that paramVals now includes the signal... 
if size(paramVals,2) == 4
    dtVals = get_DT_from_diffusivities(paramVals(:,2:end));
elseif size(paramVals,2) == 3
    dtVals = get_DT_from_diffusivities(paramVals);
end
save(DTparamsOut,'dtVals','-ascii');
save(diffsOut,'paramVals','-ascii');
end


