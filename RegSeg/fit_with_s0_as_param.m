function fit_with_s0_as_param()

subjDir = '/Users/zer/RegFitAD/data/Ep/TestT1';
baseName = 'it_0';
T1Dir = '/Users/zer/RegFitAD/data/Ep/T1'; 

for i = 1:20
run_reg_fit_wholebrain(subjDir,i,baseName,T1Dir);
bash_profile = 'source ~/.bash_profile; ';
%pyCMD = 'python /Users/zer/RegFitAD/code/RegSeg/Register_Resample_Segs.py';
pyCMD = 'python /Users/zer/RegFitAD/code/RegSeg/Register_Resample_Segs_From_T1.py';
system([bash_profile,pyCMD]);

end


end

function run_reg_fit_wholebrain( subjDir ,itNum,baseName,T1Dir)
%This runs the regional fit on the whole-brain, trimming none of it.
DWfac = 1e6;

itDir = fullfile(subjDir,[baseName,num2str(itNum)]);
RAWdir = fullfile(subjDir,'Raw'); 

%adding paths:
addpath('/Users/zer/RegFitAD/code')

[DWname,V1Name,V2Name,bMaskName] = get_permanent_fnames(RAWdir);

%outNames 
segName = fullfile(itDir,'Segs_Diffspace.nii.gz');
outName = fullfile(itDir,'reg_results.txt');

%loading segmentations

bMask = load_untouch_nii(bMaskName);bMask = bMask.img >.5; 
DW = load_untouch_nii(DWname); DW = DW.img./DWfac;
bvals = load(fullfile(RAWdir,'bvals'));
bvecs = load(fullfile(RAWdir,'bvecs'));

W = flat_segs(segName,bMask); 

%%

[DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs);

[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);

%% T1 stuff 
T1MaskName = fullfile(T1Dir,'Brain_mask.nii.gz'); T1Mask = load_untouch_nii(T1MaskName);
T1Mask = T1Mask.img>.5; 
T1Name = fullfile(T1Dir,'T1.nii.gz');

T1SegName = fullfile(T1Dir,'Segmentation.nii.gz'); 
W_T1 = flat_segs(T1SegName,T1Mask);


%%
DW = flattener_4d(DW,bMask);

%%
k = size(W,2);
initParamName = fullfile(itDir,'init_params.txt');
if exist(initParamName,'file')
    initParams = load(initParamName);
else
    initParams = repmat([1e3./DWfac, 1.7e-3, 1.2e-3,1.1e-3],[k 1]);
end


%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel.
riceNoise = 0;%sqrt(13./DWfac); 
SSDind = 's'; %1,0,'s'
%note- this is a tad high, but there's excellent immunity to it.. .

%% fitting the thing 

if ~exist(outName,'file')
    [paramVals, sigGuess] = do_fit(DW,W,bMat,initParams,riceNoise,SSDind);
    
    save(outName,'paramVals','-ascii');
    
    %% making the synthetic ims
    
    outSynthName = fullfile(itDir,'DWsynth.nii.gz');
    save_synth_DW_lo(DWname,bMask,sigGuess,outSynthName);
    save_param_maps_high(T1Name,T1Mask,W_T1,paramVals,itDir);
    
end

end

function W = flat_segs(segName,bMask)

Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;
Segs = normalise_segs(Segs); Segs = Segs.img;
W = flattener_4d(Segs,bMask);


end

%Saves the low-resolution diffusion data 
function save_synth_DW_lo(DWname,bMask,sigGuess,outSynthName)
    
    imHolder = load_untouch_nii(DWname);
    blankIm = zeros(size(bMask,1),size(bMask,2),size(bMask,3),size(sigGuess,2));
    synthDW = imHolder;   synthDW.img = blankIm;
    
    for it = 1:size(sigGuess,2)
        tmp  = zeros(size(bMask));
        tmp(bMask) = sigGuess(:,it);
        synthDW.img(:,:,:,it) = tmp;
    end
    
    synthDW.hdr.dime.dim(2:5) = size(synthDW.img);
    save_untouch_nii(synthDW,outSynthName);
end

function save_param_maps_high(T1Name,T1Mask,W_T1,paramVals,itDir)
    
    paramVals(:,1) = []; 
    MD = mean(paramVals,2); 

    tmp = (paramVals - repmat(MD,[1 3])).^2;
    FA = sqrt(1.5) .* sqrt( sum(tmp,2))./sqrt(sum(paramVals.^2,2));
    
    imHolder = load_untouch_nii(T1Name); 

    FAim = zeros(size(imHolder.img));
    FAim(T1Mask) = W_T1 * FA; 
    FAmap = imHolder; FAmap.img = single(FAim); 
    FAmap.hdr.dime.cal_max=0.8; 
    
    MDim = zeros(size(imHolder.img));
    MDim(T1Mask) = W_T1 * MD; 
    MDmap = imHolder; MDmap.img = single(MDim); 
    MDmap.hdr.dime.cal_max=0.0025; 
    
    FAname = fullfile(itDir,'T1FA.nii.gz');
    MDname = fullfile(itDir,'T1MD.nii.gz');
    
    save_untouch_nii(FAmap,FAname);
    save_untouch_nii(MDmap,MDname); 

end

function  [paramVals,sigGuess]  = do_fit(DW,W,bMat,initParams,sig,SSDind)
%DIRECT_FIT_DT This fits the DT model in the region-wise manner. It does
%this by pre-computing a rotation matrix for each voxel, that has the
%b-vectors rotated so that the same principal eigenvalues can describe each
%voxel in the region. 

f = @(x)obj_func_direct_fit(x,DW,W,bMat,sig,SSDind);

if (SSDind && SSDind ~= 's')
options = optimoptions(@fmincon,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'diffMinChange',1e-4,...
    'MaxFunEvals',1000);
else
options = optimoptions(@lsqnonlin,...
    'display','iter-detailed',...
    'tolfun',1e-6',...
    'tolx',1e-6,...
    'MaxFunEvals',1000);
%'/Users/zer/RegFitAD/data/1525'
end

lb = 1e-6.*ones(size(initParams));
ub = 5e-3 * ones(size(initParams));
lb(:,1) = 0; ub(:,1) = 10000;

if (SSDind && SSDind ~= 's')
    [paramVals,~] = fmincon(f,initParams,[],[],[],[],lb,ub,[],options);
else
    [paramVals,~] = lsqnonlin(f,initParams,lb,ub,options);
end

sigGuess = DT_diag_forward_with_S0(bMat,W*paramVals);

end

%note: paramVals = a 3 x N  matrix, and we're only going to deal with the
%diagonals, because in every voxel we've pre-accounted for the directions. 

function [DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs)

high_indices = bvals > 1000 | bvals == 300;
bvals(high_indices) = [];
bvecs(:,high_indices) = [];
DW(:,:,:,high_indices) = [];

end

function differences = obj_func_direct_fit(paramVals,DW,W,bMat,sig,SSDind)
%s for small
%paramMat = vals_to_mat(paramVals);

voxParams = W * paramVals;
sigGuess = DT_diag_forward_with_S0(bMat,voxParams);
differences = double(DW - sqrt(sigGuess.^2 + sig.^2));


if SSDind == 's';
    differences = differences;        
elseif  SSDind
    differences = sum(differences(:).^2);
else
    differences = sqrt(sum(differences.^2,2));    
end

end

function outSigs = DT_diag_forward_with_S0( bMat,paramVals)
%FUNCTION DT_forward will generate the signal from the principal
%eigenvalues, given bMat: the pre-computed b-matrix on a per-voxel level,
%and the 'paramVals' - which are the S0s, then the principal eigenvalues. 

Ds = paramVals(:,2:4); 
exponent = multiprod(bMat,Ds,[2 3],2);
S0s = repmat(paramVals(:,1),[1 size(exponent,2)]);

outSigs = S0s.*exp(-exponent);

end

function [DWname,V1Name,V2Name,bMaskName] = get_permanent_fnames(RAWdir)
%These never change - still fitting to the original data. 
DWname = fullfile(RAWdir,'DW.nii.gz');
V1Name = fullfile(RAWdir,'DT_V1.nii.gz');
V2Name = fullfile(RAWdir,'DT_V2.nii.gz');
bMaskName = fullfile(RAWdir,'Brain_Mask.nii.gz');

end




