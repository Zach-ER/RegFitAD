function Create_Small_Phantom(hcpTopDirec,expName)
% This function will take a piece of the HCP data to make into a phantom.
% We are looking for somewhere that has just 3 tissue classes - 

% we are going to create the empty datasets to resample to, to get the data
% at different resolutions. 

% we will take into account the first 16 or so b-values - 

DWname = '/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/data.nii.gz';
SegsName = fullfile(hcpTopDirec,'Segs_Diffspace.nii.gz'); 

bvals = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvals');
bvecs = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvecs');

segs = load_untouch_nii(SegsName); 

if ~exist(expName,'dir')
    mkdir(expName);
end

make_gold_stand_DW(bvals,bvecs,DWname,expName);
make_gold_stand_segs(segs,expName);

fornixName = fullfile(hcpTopDirec,'Diffusion_Fornix_Divided.nii.gz');
segName = fullfile(expName,'Segs_Reduced.nii.gz');
fornix = load_untouch_nii(fornixName); 
outFornix = fullfile(expName,'Segs_With_Fornix.nii.gz');

combine_segs_label(fornix,segName,outFornix); 

end

function combine_segs_label(diffSeg,segName,outName)

segs =   load_untouch_nii(segName);
%how to scale the remaining tissue types 
seg_scale = 1-sum(diffSeg.img,4); 

scaledSegs = segs;
for i = 1:size(segs.img,4)
    scaledSegs.img(:,:,:,i)= segs.img(:,:,:,i).*seg_scale;
end

scaledSegs.img = cat(4,scaledSegs.img,diffSeg.img);
scaledSegs.hdr.dime.dim(5) = size(scaledSegs.img,4); 
save_untouch_nii(scaledSegs,outName);
end

function cropped = crop_image(imageName,xbounds,ybounds,zbounds)

cropped = load_untouch_nii(imageName); 
cropped.img = cropped.img(xbounds(1):xbounds(2),ybounds(1):ybounds(2),...
    zbounds(1):zbounds(2),:);
cropped.hdr.dime.dim(2:4) = [size(cropped.img,1),size(cropped.img,2),...
    size(cropped.img,3)];

end


function make_gold_stand_DW(bvals,bvecs,DWname,outDir)


dwOut = fullfile(outDir,'DW.nii.gz');
bvalName= fullfile(outDir,'bvals');
bvecName= fullfile(outDir,'bvecs');

if ~exist(dwOut,'file')
DW = load_untouch_nii(DWname); 
bval_indices = bvals < 1200; 
bvals = bvals(bval_indices);
bvecs = bvecs(:,bval_indices); 

newDW.hdr = DW.hdr; 
newDW.ext = DW.ext; 
newDW.fileprefix=DW.fileprefix ;
newDW.filetype=DW.filetype ;
newDW.machine=DW.machine ;
newDW.untouch=DW.untouch;
newDW.img = DW.img(:,:,:,bval_indices); 
newDW.hdr.dime.dim(2:5) = size(newDW.img); 
save_untouch_nii(newDW,dwOut); 
save(bvalName,'bvals','-ascii');
save(bvecName,'bvecs','-ascii');
end
end


function make_gold_stand_segs(segs,outDir)

segImg = segs.img(:,:,:,:); 
segsOutName = fullfile(outDir,'Segs_Reduced.nii.gz');
segsOut = segs; 
segsOut.img = segImg;
segsOut.hdr.dime.dim(2:5) = size(segImg);
save_untouch_nii(segsOut,segsOutName);

Mask = segsOut;
Mask.img = sum(segsOut.img,4) > .5;
Mask.hdr.dime.dim(2:4) = size(Mask.img);
Mask.hdr.dime.dim(1) = 3; 
Mask.hdr.dime.datatype = 4;
MaskName = fullfile(outDir,'Mask.nii.gz');
save_untouch_nii(Mask,MaskName);

end




