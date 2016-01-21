function Pipeline( )
%PIPELINE Summary of this function goes here
%   Detailed explanation goes here

subjDir = '/Users/zer/RegFitAD/data/Ep/11610';
run_reg_fit_wholebrain(subjDir);
end



function run_reg_fit_wholebrain( subjDir )
%This runs the regional fit on the whole-brain, trimming none of it.

%adding paths:
%addpath(genpath('/home/zeatonro/NIfTI_20140122'));
%addpath('/home/zeatonro/MultiProd');
addpath('/Users/zer/RegFitAD/code')

%name boilerplate
DWname = fullfile(subjDir,'Corrected_DW.nii.gz');

cortParcName = fullfile(subjDir,'T1_Diffspace','Lobes_Diffspace.nii.gz');
segName = fullfile(subjDir,'T1_Diffspace','Segs_Diffspace.nii.gz');
SnoughtName = fullfile(subjDir,'Fitted_DT','DT_S0.nii.gz');
V1Name = fullfile(subjDir,'Fitted_DT','DT_V1.nii.gz');
V2Name = fullfile(subjDir,'Fitted_DT','DT_V2.nii.gz');
bMaskName = fullfile(subjDir,'T1_Diffspace','Brain_Mask.nii.gz');

outName = fullfile(subjDir,'Fitted_DT','it_01','reg_results.txt');


%loading
Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;

bMask = load_untouch_nii(bMaskName);bMask = bMask.img >.5; 
%Labs = load_untouch_nii(cortParcName);

%distance from the cortex we'll consider.
%cortDistThresh = 1000;

%getting the labels right.
%labelSum = sum(Labs.img(:,:,:,2:end),4);
%closeToCort = bwdist(labelSum>.1) < cortDistThresh;

%Ignoring labels for the moment. 
%Segs.img = cat(4,Segs.img(:,:,:,[2,4]).*repmat(closeToCort,[1 1 1 2]),Labs.img(:,:,:,2:end));

%1st dimension is irrelevant. 
Segs.img = Segs.img(:,:,:,2:end);

Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img;
S0 = load_untouch_nii(SnoughtName); S0 = S0.img;
bvals = load(fullfile(subjDir,'rot_bvals'));
bvecs = load(fullfile(subjDir,'rot_bvecs'));

[DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs);

%going to exclude voxels where the b = 0 are not the highest values
% DW2 = repmat(bMask,[1 1 1 size(DW,4)]).*DW./repmat(S0,[1 1 1 size(DW,4)]);
% normedDW = DW2(:,:,:,bvals==1000);
% badDWInds = sum(normedDW > 1.5,4) > 0;
% bMask(badDWInds) = 0;

%%
[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);

%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
S0 = S0(bMask);

%%
k = size(W,2);
initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);

%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel.
riceNoise = sqrt(13); SSDind = 's'; %1,0,'s'
%note- this is a tad high, but there's excellent immunity to it.. .

%% fitting the thing 
[paramVals, sigGuess] = direct_fit_regseg(S0,DW,W,bMat,initParams,riceNoise,SSDind);
MD = mean(paramVals,2);
tmp = (paramVals - repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(paramVals.^2,2));

paramVals(:,4) = MD; paramVals(:,5) = FA;

save(outName,'paramVals','-ascii');

%%
paramVals = load(outName); 
paramVals(:,4:5) = [];
imHolder = load_untouch_nii(DWname);
imHolder.hdr.dime.dim(5) = size(sigGuess,2);

blankIm = zeros(size(bMask,1),size(bMask,2),size(bMask,3),size(sigGuess,2));
smallerDW = imHolder; smallerDW.img = blankIm;
synthDW = imHolder;   synthDW.img = blankIm;

outDWname = fullfile(subjDir,'Fitted_DT','it_01','DW.nii.gz');
outSynthName = fullfile(subjDir,'Fitted_DT','it_01','DWsynth.nii.gz');

for it = 1:size(sigGuess,2)
    tmp  = zeros(size(bMask));
    tmp(bMask) = DW(:,it);
    smallerDW.img(:,:,:,it) = tmp;
    
    tmp(bMask) = sigGuess(:,it);
    synthDW.img(:,:,:,it) = tmp;
    
end
save_untouch_nii(smallerDW,outDWname);
save_untouch_nii(synthDW,outSynthName);


end

function [DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs)

high_indices = bvals > 1000 | bvals == 300;
bvals(high_indices) = [];
bvecs(:,high_indices) = [];
DW(:,:,:,high_indices) = [];

end




