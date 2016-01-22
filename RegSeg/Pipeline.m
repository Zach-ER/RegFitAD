function Pipeline(itNum)
%PIPELINE Summary of this function goes here
%   Detailed explanation goes here

subjDir = '/Users/zer/RegFitAD/data/Ep/Testing_RegSeg';
%run_reg_fit_wholebrain(subjDir,0);

for i = 2:10
run_reg_fit_wholebrain(subjDir,i);
bash_profile = 'source ~/.bash_profile; ';
pyCMD = 'python /Users/zer/RegFitAD/code/RegSeg/Register_Resample_Segs.py';
system([bash_profile,pyCMD]);

end


end



function run_reg_fit_wholebrain( subjDir ,itNum)
%This runs the regional fit on the whole-brain, trimming none of it.

itDir = fullfile(subjDir,['it_0',num2str(itNum)]);
RAWdir = fullfile(subjDir,'Raw'); 

%adding paths:
%addpath(genpath('/home/zeatonro/NIfTI_20140122'));
%addpath('/home/zeatonro/MultiProd');
addpath('/Users/zer/RegFitAD/code')

%cortParcName = fullfile(subjDir,'T1_Diffspace','Lobes_Diffspace.nii.gz');


[DWname,V1Name,V2Name,bMaskName] = get_permanent_fnames(RAWdir);


%outNames 
segName = fullfile(itDir,'Segs_Diffspace.nii.gz');
outName = fullfile(itDir,'reg_results.txt');

%loading
Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;

bMask = load_untouch_nii(bMaskName);bMask = bMask.img >.5; 

%1st dimension is irrelevant. 

Segs = normalise_segs(Segs); Segs = Segs.img;
DW = load_untouch_nii(DWname); DW = DW.img;
bvals = load(fullfile(RAWdir,'bvals'));
bvecs = load(fullfile(RAWdir,'bvecs'));


%%
[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);

%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);
%S0 = ones(size(DW,1),1);

SnoughtName = fullfile(RAWdir,'DT','DT_S0.nii.gz');
S0 = load_untouch_nii(SnoughtName); S0 = S0.img;
S0 = S0(bMask);
% S0 = 0.*S0 +1; 

%%
k = size(W,2);
initParamName = fullfile(itDir,'init_params.txt');
if exist(initParamName,'file')
    initParams = load(initParamName);
else
    initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
end


%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel.
riceNoise = sqrt(13); SSDind = 's'; %1,0,'s'
%note- this is a tad high, but there's excellent immunity to it.. .

%% fitting the thing 
S0sized = repmat(S0,[1,size(DW,2)]);

if ~exist(outName,'file')
    [paramVals, sigGuess] = direct_fit_regseg(S0,DW.*S0sized,W,bMat,initParams,riceNoise,SSDind);
    
    save(outName,'paramVals','-ascii');
    
    %% making the synthetic ims
    
    imHolder = load_untouch_nii(DWname);
    
    blankIm = zeros(size(bMask,1),size(bMask,2),size(bMask,3),size(sigGuess,2));
    synthDW = imHolder;   synthDW.img = blankIm;
    
    outSynthName = fullfile(itDir,'DWsynth.nii.gz');
    
    for it = 1:size(sigGuess,2)
        tmp  = zeros(size(bMask));
        tmp(bMask) = sigGuess(:,it)./S0;
        synthDW.img(:,:,:,it) = tmp;
    end
    
    
    synthDW.hdr.dime.dim(2:5) = size(synthDW.img);
    save_untouch_nii(synthDW,outSynthName);
end

end

function [DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs)

high_indices = bvals > 1000 | bvals == 300;
bvals(high_indices) = [];
bvecs(:,high_indices) = [];
DW(:,:,:,high_indices) = [];

end

function [DWname,V1Name,V2Name,bMaskName] = get_permanent_fnames(RAWdir)
%These never change - still fitting to the original data. 
DWname = fullfile(RAWdir,'DW.nii.gz');
V1Name = fullfile(RAWdir,'DT','DT_V1.nii.gz');
V2Name = fullfile(RAWdir,'DT','DT_V2.nii.gz');
bMaskName = fullfile(RAWdir,'Brain_Mask.nii.gz');

end

%distance from the cortex we'll consider.
%cortDistThresh = 1000;

%getting the labels right.
%labelSum = sum(Labs.img(:,:,:,2:end),4);
%closeToCort = bwdist(labelSum>.1) < cortDistThresh;

%Ignoring labels for the moment. 
%Segs.img = cat(4,Segs.img(:,:,:,[2,4]).*repmat(closeToCort,[1 1 1 2]),Labs.img(:,:,:,2:end));

%Labs = load_untouch_nii(cortParcName);

%going to exclude voxels where the b = 0 are not the highest values
% DW2 = repmat(bMask,[1 1 1 size(DW,4)]).*DW./repmat(S0,[1 1 1 size(DW,4)]);
% normedDW = DW2(:,:,:,bvals==1000);
% badDWInds = sum(normedDW > 1.5,4) > 0;
% bMask(badDWInds) = 0;

