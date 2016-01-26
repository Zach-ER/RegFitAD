function fit_with_s0_as_param()

subjDir = '/Users/zer/RegFitAD/data/Ep/TestS0';
baseName = 'it_0';

for i = 0:50
run_reg_fit_wholebrain(subjDir,i,baseName);
bash_profile = 'source ~/.bash_profile; ';
pyCMD = 'python /Users/zer/RegFitAD/code/RegSeg/Register_Resample_Segs.py';
system([bash_profile,pyCMD]);

end


end

function run_reg_fit_wholebrain( subjDir ,itNum,baseName)
%This runs the regional fit on the whole-brain, trimming none of it.

itDir = fullfile(subjDir,[baseName,num2str(itNum)]);
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
DW = load_untouch_nii(DWname); DW = DW.img./1e6;
bvals = load(fullfile(RAWdir,'bvals'));
bvecs = load(fullfile(RAWdir,'bvecs'));


%%
[DW,bvals,bvecs] = remove_high_bvals(DW,bvals,bvecs);

[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);


%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);

%%
k = size(W,2);
initParamName = fullfile(itDir,'init_params.txt');
if exist(initParamName,'file')
    initParams = load(initParamName);
else
    initParams = repmat([.001, 1.7e-3, 1.2e-3,1.1e-3],[k 1]);
end


%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel.
riceNoise = 0 ;%sqrt(13); 
SSDind = 's'; %1,0,'s'
%note- this is a tad high, but there's excellent immunity to it.. .

%% fitting the thing 

if ~exist(outName,'file')
    [paramVals, sigGuess] = do_fit(DW,W,bMat,initParams,riceNoise,SSDind);
    
    save(outName,'paramVals','-ascii');
    
    %% making the synthetic ims
    
    imHolder = load_untouch_nii(DWname);
    
    blankIm = zeros(size(bMask,1),size(bMask,2),size(bMask,3),size(sigGuess,2));
    synthDW = imHolder;   synthDW.img = blankIm;
    
    outSynthName = fullfile(itDir,'DWsynth.nii.gz');
    
    for it = 1:size(sigGuess,2)
        tmp  = zeros(size(bMask));
        tmp(bMask) = sigGuess(:,it);
        synthDW.img(:,:,:,it) = tmp;
    end
    
    
    synthDW.hdr.dime.dim(2:5) = size(synthDW.img);
    save_untouch_nii(synthDW,outSynthName);
end

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
V1Name = fullfile(RAWdir,'DT','DT_V1.nii.gz');
V2Name = fullfile(RAWdir,'DT','DT_V2.nii.gz');
bMaskName = fullfile(RAWdir,'Brain_Mask.nii.gz');

end




