%%
%script to run the regional-fitting directly on the processed data. 

addpath(genpath('/Users/zer/RegionalEstimates/code'));

subjDir = '/Users/zer/RegFitAD/data/babTest';
DTDir = fullfile(subjDir,'DT');
%%
DWname = fullfile(subjDir,'DW_data.nii.gz');
S0name = fullfile(DTDir,'DT_S0.nii.gz');
maskName = fullfile(subjDir,'Brain_mask.nii.gz');
segName = fullfile(subjDir,'Segmentations_DiffSpace_PSF.nii.gz');
Segs = load_untouch_nii(segName);Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img; 
S0 = load_untouch_nii(S0name); S0 = S0.img; 

%going to use the brain-mask generated from the segmentation
bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.5 & sum(Segs,4) > 0.5; 


%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
S0 = S0(bMask);

for ii = 1:size(DW,2)
    DW(:,ii) = DW(:,ii)./S0(ii);
end


k = size(W,2);
initParams = repmat([1.7e-3, .1e-3,.1e-3],[k 1]);

%% 
[~,bMat] = prepare_b_matrices(subjDir,DTDir,bMask);
direct_fit_DT_AD(DW,W,bMat,initParams,0,0);
