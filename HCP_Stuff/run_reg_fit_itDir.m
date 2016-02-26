function run_reg_fit_itDir(subjDir,segInds,riceNoise,diffsOut,DTparamsOut)

[DW,Segs,bMat,bMask] = load_diff_data(subjDir,segInds);
%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);

%%
k = size(W,2);
initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
%%

SSDind = 's'; %1,0,'s'

%if ~exist(outName ,'file')
paramVals = direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind);
%%
dtVals = get_DT_from_diffusivities(paramVals);
save(DTparamsOut,'dtVals','-ascii');
save(diffsOut,'paramVals','-ascii');
%end

end


