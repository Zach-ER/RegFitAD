%% script to run the regional-fitting directly on the processed data. 

%addpath(genpath('/Users/zer/RegionalEstimates/code'));

babInd = 0; 

if babInd
    subjDir = '../data/babTest';
    DWname = fullfile(subjDir,'DW_data.nii.gz');
    segName = fullfile(subjDir,'LobalLabs.nii.gz');
    Segs = load_untouch_nii(segName);
else
    subjDir = '../data/4156';
    DWname = fullfile(subjDir,'4156_corrected_dwi.nii.gz');
    labName = fullfile(subjDir,'labs_diff.nii.gz');
    segName = fullfile(subjDir,'segs_diff.nii.gz');
    Segs = load_untouch_nii(segName);
    Labs = load_untouch_nii(labName);
    Segs.img = cat(4,Segs.img(:,:,:,[1,3]),Labs.img(:,:,:,2:end));
end

DTDir = fullfile(subjDir,'DT');
maskName = fullfile(subjDir,'Brain_mask.nii.gz');
SnoughtName = fullfile(DTDir,'DT_S0.nii.gz');


Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img; 
S0 = load_untouch_nii(SnoughtName); S0 = S0.img; 
load(fullfile(subjDir,'bvals.txt'));
load(fullfile(subjDir,'bvecs.txt'));

%going to use the brain-mask generated from the segmentation


%% bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.5 & sum(Segs,4) > 0.5; 

[~,bMat,bMask] = prepare_b_matrices(subjDir,DTDir,bMask,bvals,bvecs);

%%
DW = DW./repmat(S0,[1 1 1 size(DW,4)]);

W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
k = size(W,2);
initParams = repmat([1.7e-3, .1e-3,.1e-3],[k 1]);
% 
% b0Indices = bvals==0; 
% for ii = 1:size(DW,1)
%     DW(ii,:) = DW(ii,:)./(mean(DW((ii),b0Indices))+eps);
% end


%%
paramVals = direct_fit_DT_AD(DW,W,bMat,initParams,0.05,0);

guessedSigs = DT_diag_forward(bMat,W*paramVals);


%%
MD = mean(paramVals,2); 

tmp = (paramVals - repmat(MD,[1 3])).^2;
FA = sqrt(1.5) .* sqrt( sum(tmp,2))./sqrt(sum(paramVals.^2,2));







