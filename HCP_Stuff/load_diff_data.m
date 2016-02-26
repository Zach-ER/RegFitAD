%loads the diffusion data from the given directory 
function [DW,Segs,bMat,bMask] = load_diff_data(subjDir,segInds)

DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
segName = fullfile(subjDir,'Segs_Resampled.nii.gz');

DTdir = fullfile(subjDir,'DT');
V1Name = fullfile(DTdir,'DT_V1.nii.gz');
V2Name = fullfile(DTdir,'DT_V2.nii.gz');

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

end
