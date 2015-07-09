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
    DTDir = fullfile(subjDir,'DT');
    DWname = fullfile(subjDir,'4156_corrected_dwi.nii.gz');
    labName = fullfile(subjDir,'labs_diff.nii.gz');
    segName = fullfile(subjDir,'segs_diff.nii.gz');
    FAName = fullfile(DTDir,'DT_FA.nii.gz');
    Segs = load_untouch_nii(segName);
    Labs = load_untouch_nii(labName);
    
    labelSum = sum(Labs.img(:,:,:,2:end),4);
    closeToCort = bwdist(labelSum>.1) < 1.5; 
    
    FAholder = load_untouch_nii(FAName);
    Segs.img = cat(4,Segs.img(:,:,:,[1,3]).*repmat(closeToCort,[1 1 1 2]),Labs.img(:,:,:,2:end));
       
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
bMask = load_untouch_nii(maskName); bMask= bMask.img > 0.5 & sum(Segs,4) > 0.5; 

%going to exclude voxels where the b = 0 are not the highest values

DW2 = DW./repmat(S0,[1 1 1 size(DW,4)]);
badDWInds = DW2(:,:,:,bvals==1000);
badDWInds = sum(badDWInds > 1.1,4) > 0;
bMask(badDWInds) = 0; 

%%
%seeing if it's faster on a subset of the data - but it's not really 
exclusionInds = []; 
bvals(exclusionInds) = []; bvecs(:,exclusionInds) = [];
DW(:,:,:,exclusionInds) = []; 


%% 
[~,bMat,bMask] = prepare_b_matrices(subjDir,DTDir,bMask,bvals,bvecs);

%%

W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
S0 = S0(bMask);

%%
%going to exclude voxels in the CSF with S0 below a certain threshold, as I
%think these are erroneous. 
% csfInds = find(W(:,1) > 0.98);
% badCsfInds = find(S0(csfInds)<100);
% W(badCsfInds,:) = [];
% DW(badCsfInds,:) = [];
% S0(badCsfInds,:) = [];
% bMat(badCsfInds,:,:) = []; 
% 
% indices = find(bMask);
% bMask(indices(badCsfInds)) = 0; 

%%
k = size(W,2);
initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
initParams(1,:) = [3e-3,3e-3,3e-3];

%%
%bit for changing the approach into a phantom problem. 
% gsParams = rand(size(initParams)).*5e-3;
% 
% for ii = 1:length(gsParams)
% gsParams(ii,:) = sort(gsParams(ii,:),'descend');
% end
% dwGS = repmat(S0,[1 size(DW,2)]).*DT_diag_forward(bMat,W*gsParams);
% 


%%
riceNoise = 0.05; SSDind = 0;  
%dwGSNoisy = add_noise_to_phantom(dwGS,riceNoise);

paramVals = direct_fit_DT_AD(S0,DW,W,bMat,initParams,riceNoise,SSDind);
%paramVals = direct_fit_DT_AD(S0,dwGS,W,bMat,initParams,riceNoise,SSDind);


guessedSigs = DT_diag_forward(bMat,W*paramVals);
sigDiffs = sum((sqrt(guessedSigs.^2 + riceNoise.^2) - DW).^2,2); 

%%
MD = mean(paramVals,2); 

tmp = (paramVals - repmat(MD,[1 3])).^2;
FA = sqrt(1.5) .* sqrt( sum(tmp,2))./sqrt(sum(paramVals.^2,2));

%%

MDimg = zeros(size(bMask)); MDimg(bMask) = W*MD; 
FAimg = zeros(size(bMask)); FAimg(bMask) = W*FA; 
SSDimg = zeros(size(bMask)); SSDimg(bMask) = sigDiffs; 

FAholder.img(:,:,:,1) = MDimg*1e3; 
FAholder.img(:,:,:,2) = FAimg; 
FAholder.hdr.dime.dim(1) = 4; FAholder.hdr.dime.dim(5) = 2; 
save_untouch_nii(FAholder,fullfile(DTDir,'regFitted.nii.gz'));

%%
fittedSigs = load_untouch_nii(DWname);
tmpImg = zeros(size(bMask));
for ii = 1:size(fittedSigs.img,4)
    
    tmpImg(bMask) = guessedSigs(:,ii);
    fittedSigs.img(:,:,:,ii) = tmpImg;
    
end


save_untouch_nii(fittedSigs,fullfile(DTDir,'regSigs.nii.gz'));


