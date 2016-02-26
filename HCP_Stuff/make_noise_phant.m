%makes a new directory (noiseDir) and puts some noisy data in there. And
%copies relevant meta-data (segs and bvals/bvecs) 

function noiseDir = make_noise_phant(subjDir,riceNoise)

noiseDir = fullfile(subjDir,'Noisy');
mkdir(noiseDir); 
DTout = fullfile(noiseDir,'DT'); 
mkdir(DTout); 

[DWname,segName,bvalName,bvecName,maskName] = name_files(subjDir);
[DWout,segOut,bvalOut,bvecOut,maskOut] = name_files(noiseDir);

DW = load_untouch_nii(DWname); 
DW.img = add_rician_noise(DW.img,riceNoise); 

save_untouch_nii(DW,DWout); 
copyfile(segName,segOut); 
copyfile(bvalName,bvalOut); 
copyfile(bvecName,bvecOut); 
copyfile(maskName,maskOut); 

sysCmd = ['source ~/.bash_profile; dtifit -m ',maskOut,' -k ',DWout,' -b ',bvalOut,' -r ',bvecOut,...
    ' -o ',DTout,'/DT'];
system(sysCmd);

end

function [DWname,segName,bvalName,bvecName,maskName] = name_files(subjDir)

DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
bvalName = fullfile(subjDir,'bvals'); 
bvecName = fullfile(subjDir,'bvecs'); 
maskName = fullfile(subjDir,'Mask.nii.gz'); 

end