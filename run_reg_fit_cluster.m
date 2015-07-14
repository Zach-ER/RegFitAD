function run_reg_fit_cluster( subjID )
%RUN_REG_FIT_CLUSTER will run the 'reg fit' algorithm on the data given a
%subject input code. 
%

%adding paths: 
addpath(genpath('/home/zeatonro/NIfTI_20140122'));
addpath('/home/zeatonro/MultiProd');

%where results go 
outDir = ['/home/zeatonro/RegFitAD/CortResults/Res',subjID];
%where the original dataset is 
dataDir = '/scratch2/mmodat/ivor/nico/data/drc/Phil/cortical_diffusion/';

%if I'm testing it locally
macPath = ['/Users/zer/RegFitAD/data/',subjID];
if exist(macPath,'dir')
   outDir =  macPath; dataDir = macPath;
end

outName = fullfile(outDir,'results.txt');
DTDir = fullfile(outDir,'DT');
%name boilerplate
DWname = fullfile(dataDir,[subjID,'_corrected_dwi.nii.gz']);

FreeSurfName = fullfile(outDir,'LabsDiff.nii.gz');
segName = fullfile(outDir,'SegDiff.nii.gz');
maskName = fullfile(outDir,'BMdiff.nii.gz');
SnoughtName = fullfile(DTDir,'DT_S0.nii.gz');
V1Name = fullfile(DTDir,'DT_V1.nii.gz');

%loading 
Segs = load_untouch_nii(segName);
Labs = load_untouch_nii(FreeSurfName);

%distance from the cortex we'll consider. 
cortDistThresh = 1.5; 

%getting the labels right. 
labelSum = sum(Labs.img(:,:,:,2:end),4);
closeToCort = bwdist(labelSum>.1) < cortDistThresh;
Segs.img = cat(4,Segs.img(:,:,:,[1,3]).*repmat(closeToCort,[1 1 1 2]),Labs.img(:,:,:,2:end));

Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img; 
S0 = load_untouch_nii(SnoughtName); S0 = S0.img; 
load(fullfile(DTDir,'bvals.txt'));
load(fullfile(DTDir,'bvecs.txt'));

%going to use the brain-mask generated from the segmentation
bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.1; 

%going to exclude voxels where the b = 0 are not the highest values

DW2 = repmat(bMask,[1 1 1 size(DW,4)]).*DW./repmat(S0,[1 1 1 size(DW,4)]);
normedDW = DW2(:,:,:,bvals==1000);
badDWInds = sum(normedDW > 1.5,4) > 0;
bMask(badDWInds) = 0; 

%% 
[bMat,bMask] = prepare_b_matrices(V1Name,bMask,bvals,bvecs);

%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
S0 = S0(bMask);

%%
k = size(W,2);
initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
% initParams(1,:) = 3e-3; 

%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel. 
riceNoise = 0; SSDind = 0;  

paramVals = direct_fit_DT_AD(S0,DW,W,bMat,initParams,riceNoise,SSDind);

%%
MD = mean(paramVals,2); 
tmp = (paramVals - repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt( sum(tmp,2))./sqrt(sum(paramVals.^2,2));

paramVals(:,4) = MD; paramVals(:,5) = FA; 

save(outName,'paramVals','-ascii');

end

