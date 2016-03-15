function Create_Small_Phantom(hcpTopDirec,expName)
% This function will take a piece of the HCP data to make into a phantom.
% We are looking for somewhere that has just 3 tissue classes - 

% we are going to create the empty datasets to resample to, to get the data
% at different resolutions. 

% we will take into account the first 16 or so b-values - 

pad = 10; 
DWname = '/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/data.nii.gz';
SegsName = fullfile(hcpTopDirec,'Segs_Diffspace.nii.gz'); 

bvals = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvals');
bvecs = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvecs');

segs = load_untouch_nii(SegsName); 

if ~exist(expName,'dir')
    mkdir(expName);
end

make_gold_stand_segs(segs,expName,'Segs_Whole.nii.gz');
fornixName = fullfile(hcpTopDirec,'Diffusion_Fornix_Divided.nii.gz');
segName = fullfile(expName,'Segs_Whole.nii.gz');
fornix = load_untouch_nii(fornixName); 
outFornix = fullfile(expName,'Segs_With_Fornix.nii.gz');
fornSeg = combine_segs_label(fornix,segName,outFornix); 

[xbounds,ybounds,zbounds]=get_seg_box(fornSeg,6:8,pad); 

segOut = fullfile(expName,'Segs_Whole.nii.gz'); 
seg = crop_image(fornSeg,xbounds,ybounds,zbounds,segOut); 

MaskName = fullfile(expName,'Mask.nii.gz');
make_mask_from_segs(seg,MaskName);

outDW = fullfile(expName,'DW.nii.gz'); 
if ~exist(outDW,'file')
    newDW  = make_gold_stand_DW(bvals,bvecs,DWname,expName);
    crop_image(newDW,xbounds,ybounds,zbounds,outDW);
end

end

%seg nifti, then the padding that we want to give it (probably 3
function [xbounds,ybounds,zbounds]=get_seg_box(segs,segDims,pad)


maskOfInterest = sum(segs.img(:,:,:,segDims),4);
RP = regionprops(maskOfInterest>.01,'BoundingBox'); 
BB = RP.BoundingBox;

xbounds = floor(BB(2))-pad:floor(BB(2))+BB(5)+2*pad; 
ybounds = floor(BB(1))-pad:floor(BB(1))+BB(4)+2*pad; 
zbounds = floor(BB(3))-pad:floor(BB(3))+BB(6)+2*pad; 



end

function scaledSegs = combine_segs_label(diffSeg,segName,outName)

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

function cropped = crop_image(oldImg,xbounds,ybounds,zbounds,outName)

cropped = oldImg;
cropped.img = oldImg.img(xbounds,ybounds,zbounds,:);
cropped.hdr.dime.dim(2:4) = [size(cropped.img,1),size(cropped.img,2),...
    size(cropped.img,3)];

% cropped.hdr.hist.srow_x(4) = oldImg.hdr.hist.srow_x(4) ...
%     + sign(cropped.hdr.hist.srow_x(1)).* xbounds(1);
% cropped.hdr.hist.srow_y(4) = oldImg.hdr.hist.srow_y(4) ...
%     + sign(cropped.hdr.hist.srow_y(2)).*ybounds(1);
% cropped.hdr.hist.srow_z(4) = oldImg.hdr.hist.srow_z(4)...
%     + sign(cropped.hdr.hist.srow_z(3)).*zbounds(1);
% 

save_untouch_nii(cropped,outName); 

end


function newDW = make_gold_stand_DW(bvals,bvecs,DWname,outDir)


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


function make_gold_stand_segs(segs,outDir,segsOut)

segImg = segs.img(:,:,:,:); 
segsOutName = fullfile(outDir,segsOut);
segsOut = segs; 
segsOut.img = segImg;
segsOut.hdr.dime.dim(2:5) = size(segImg);
save_untouch_nii(segsOut,segsOutName);

end

function make_mask_from_segs(segs,MaskName)

Mask = segs;
Mask.img = sum(segs.img,4) > .5;
Mask.hdr.dime.dim(2:4) = size(Mask.img);
Mask.hdr.dime.dim(1) = 3; 
Mask.hdr.dime.datatype = 4;
save_untouch_nii(Mask,MaskName);

end



