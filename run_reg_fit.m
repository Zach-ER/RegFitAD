%% script to run the regional-fitting directly on the processed data. 

addpath(genpath('/Users/zer/RegionalEstimates/code'));

subjDir = '/Users/zer/RegFitAD/data/babTest';
DTDir = fullfile(subjDir,'DT');
%%
DWname = fullfile(subjDir,'DW_data.nii.gz');
maskName = fullfile(subjDir,'Brain_mask.nii.gz');
segName = fullfile(subjDir,'Segmentations_DiffSpace_PSF.nii.gz');
Segs = load_untouch_nii(segName);Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img; 
load(fullfile(subjDir,'bvals.txt'));
load(fullfile(subjDir,'bvecs.txt'));

%going to use the brain-mask generated from the segmentation
bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.5 & sum(Segs,4) > 0.5; 


%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);

b0Indices = bvals==0; 
for ii = 1:size(DW,1)
    DW(ii,:) = DW(ii,:)./mean(DW((ii),b0Indices));
end

% eliminatingBvals = bvals == 750; 
% DW(:,eliminatingBvals) = []; 
% bvals(eliminatingBvals) = [];
% bvecs(:,eliminatingBvals) = [];

k = size(W,2);
initParams = repmat([1.7e-3, .1e-3,.1e-3],[k 1]);

%% 
[~,bMat] = prepare_b_matrices(subjDir,DTDir,bMask,bvals,bvecs);

paramVals = direct_fit_DT_AD(DW,W,bMat,initParams,0.05,0);

guessedSigs = DT_diag_forward(bMat,W*paramVals);




