function Create_Small_Phantom(outDir)
% This function will take a piece of the HCP data to make into a phantom.
% We are looking for somewhere that has just 3 tissue classes - 

% we are going to create the empty datasets to resample to, to get the data
% at different resolutions. 

% we will take into account the first 16 or so b-values - 

hcpTopDirec = '/Users/zer/RegFitAD/data/HCPwStruct/Processed';
experimentDir = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts'; 

DWname = '/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/data.nii.gz';
SegsName = fullfile(hcpTopDirec,'Segs_Diffspace.nii.gz'); 

bvals = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvals');
bvecs = load('/Users/zer/RegFitAD/data/HCPwStruct/122317/T1w/Diffusion/bvecs');

segs = load_untouch_nii(SegsName); 

%wm/gm
xbounds = [60,80]; ybounds = [75,85]; zbounds = [80,100]; 
%cerebellum
xbounds = [75,75]; ybounds = [55,75]; zbounds = [31,41]; 
%expName = 'OneVoxCRB'; 
%
xbounds = [59,83]; ybounds = [76,109]; zbounds= [49,68]; 

%expName = 'OneVoxFornix'; 
%xbounds = [69,69]; ybounds = [76,109]; zbounds= [49,68]; 

if ~exist(outDir,'dir')
    mkdir(outDir);
end

make_gold_stand_DW(xbounds,ybounds,zbounds,bvals,bvecs,DWname,outDir);
make_gold_stand_segs(xbounds,ybounds,zbounds,segs,outDir);

fornixName = fullfile(hcpTopDirec,'Diffusion_Fornix.nii.gz');
fornixName = fullfile(hcpTopDirec,'Diffusion_Fornix_Divided.nii.gz');
segName = fullfile(outDir,'Segs_Reduced.nii.gz');
fornix = crop_image(fornixName,xbounds,ybounds,zbounds); 
outFornix = fullfile(outDir,'Segs_With_Fornix.nii.gz');
outFornix = fullfile(outDir,'Segs_With_Fornix_Divided.nii.gz');

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


function make_gold_stand_DW(xbounds,ybounds,zbounds,bvals,bvecs,DWname,outDir)


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
newDW.img = DW.img(xbounds(1):xbounds(2),ybounds(1):ybounds(2),...
    zbounds(1):zbounds(2),bval_indices); 
newDW.hdr.dime.dim(2:5) = size(newDW.img); 
save_untouch_nii(newDW,dwOut); 
save(bvalName,'bvals','-ascii');
save(bvecName,'bvecs','-ascii');
end
end


function make_gold_stand_segs(xbounds,ybounds,zbounds,segs,outDir)

segImg = segs.img(xbounds(1):xbounds(2),ybounds(1):ybounds(2),...
    zbounds(1):zbounds(2),:); 
segsOutName = fullfile(outDir,'Segs_Reduced.nii.gz');
segsOut = segs; 
segsOut.img = segImg;
segsOut.hdr.dime.dim(2:5) = size(segImg);
save_untouch_nii(segsOut,segsOutName);

Mask = segsOut;
Mask.img = sum(segsOut.img,4) > .5;
Mask.hdr.dime.dim(2:4) = size(Mask.img);
MaskName = fullfile(outDir,'Mask.nii.gz');
save_untouch_nii(Mask,MaskName);

MaskDWImg = zeros(size(segs.img,1),size(segs.img,2),size(segs.img,3));
MaskDWImg(xbounds(1):xbounds(2),ybounds(1):ybounds(2),...
    zbounds(1):zbounds(2)) = 1; 
MaskDW = segs; 
MaskDW.img = MaskDWImg;
MaskDW.hdr.dime.dim(5) = 1; 
MaskDW.hdr.dime.dim(1) = 3;  
MaskDWName = fullfile(outDir,'DWmask.nii.gz');
save_untouch_nii(MaskDW,MaskDWName);


end

%% defining out region-of-interest mask - this was to check where I had put it
% mask = zeros(size(segs.img,1),size(segs.img,2),size(segs.img,3));
% mask(xbounds(1):xbounds(2),ybounds(1):ybounds(2),zbounds(1):zbounds(2)) = true;
% maskOut = segs; 
% maskOut.hdr.dime.dim(5) = 1;
% maskOutName = fullfile(experimentDir,'GoldStand','DWmask.nii.gz');
% maskOut.img = mask;
% save_untouch_nii(maskOut,maskOutName);


