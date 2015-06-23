%%
addpath(genpath('/Users/zer/RegionalEstimates/code'));

subjDir = '/Users/zer/RegFitAD/data/babTest';
DTDir = fullfile(subjDir,'DT');
%%
DWname = fullfile(subjDir,'DW_data.nii.gz');
maskName = fullfile(subjDir,'Brain_mask.nii.gz');
segName = fullfile(subjDir,'Segmentations_DiffSpace_PSF.nii.gz');
Segs = load_untouch_nii(segName);Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img; 

%going to use the brain-mask generated from the segmentation
bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.5 & sum(Segs,4) > 0.5; 


%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
k = size(W,2);

%% 
[~,bMat] = prepare_b_matrices(subjDir,DTDir,bMask);

%%
initParams = repmat([1.7e-3, .1e-3,.1e-3],[k 1]);
voxParams = W * initParams;

outSigs = DT_diag_forward( bMat,voxParams);


SigOut = load_untouch_nii(DWname);
for ii = 1:size(SigOut.img,4)
   
    tmpImg = 0.*bMask; tmpImg(bMask) = outSigs(:,ii);
    SigOut.img(:,:,:,ii) = tmpImg;
    
end
outName = fullfile(subjDir,'sigCheck.nii.gz');
save_untouch_nii(SigOut,outName);


