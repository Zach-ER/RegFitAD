%loads the diffusion data from the given directory 
function [DW,Segs,bMat,bMask,S0] = load_diff_data(subjDir,segInds,upsInd)

if upsInd ==1 
    DWname = fullfile(subjDir,'DW_Upsampled_Cubic.nii.gz');
    segName = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/Noise2/12_Readings/Downsampled_1/Noise_1/Segs_Resampled.nii.gz';    
else
    DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
    segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
end

if upsInd == 1
    DTdir = fullfile(subjDir,'DThigh');
else
    DTdir = fullfile(subjDir,'DT');
end

V1Name = fullfile(DTdir,'DT_V1.nii.gz');
V2Name = fullfile(DTdir,'DT_V2.nii.gz');
S0Name = fullfile(DTdir,'DT_S0.nii.gz');

bvalName = fullfile(subjDir,'bvals'); 
bvecName = fullfile(subjDir,'bvecs'); 

%loading
Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;

bMask = sum(Segs.img,4) > 0.9;

Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,segInds);
DW = load_untouch_nii(DWname);
DW = DW.img;
bvals = load(bvalName);
bvecs = load(bvecName);

[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);
S0 = load_untouch_nii(S0Name); 

end
