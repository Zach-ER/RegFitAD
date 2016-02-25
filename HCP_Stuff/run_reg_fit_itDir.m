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

%loads the diffusion data from the given directory 
function [DW,Segs,bMat,bMask] = load_diff_data(subjDir,segInds)

DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
segName = fullfile(subjDir,'Segs_Resampled.nii.gz');

DTdir = fullfile(subjDir,'DT');
V1Name = fullfile(DTdir,'DT_V1.nii.gz');
V2Name = fullfile(DTdir,'DT_V2.nii.gz');

bvalName = fullfile(subjDir,'bvals'); 
bvecName = fullfile(subjDir,'bvecs'); 

%loading
Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;

bMask = sum(Segs.img,4) > 0.9;

Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,segInds);
DW = load_untouch_nii(DWname);
DW = DW.img;
bvals = load(bvalName);
bvecs = load(bvecName);

[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);

end


function dtVals = get_DT_from_diffusivities(diffusivities)

MD = mean(diffusivities,2);
tmp = (diffusivities- repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(diffusivities.^2,2));

dtVals(:,1) = MD;
dtVals(:,2) = FA;

end

