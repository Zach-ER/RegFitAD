function Cut_Segs_Down( segDims, segName, segOutName, DWname, DWoutName,maskOutName)
%CUT_SEGS_DOWN will cut around the regions of interest after downsampling, 

seg = load_untouch_nii(segName); 

maskOfInterest = sum(seg.img(:,:,:,segDims),4);
RP = regionprops(maskOfInterest>.01,'BoundingBox'); 
BB = RP.BoundingBox;

xbounds = floor(BB(2))-1:floor(BB(2))+BB(5)+2; 
ybounds = floor(BB(1))-1:floor(BB(1))+BB(4)+2; 
zbounds = floor(BB(3))-1:floor(BB(3))+BB(6)+2; 

segOut = crop_image(segName,xbounds,ybounds,zbounds); 
save_untouch_nii(segOut,segOutName);

if ~exist(DWoutName,'file')
    DWout =  crop_image(DWname,xbounds,ybounds,zbounds); 
    save_untouch_nii(DWout,DWoutName); 
end

MaskOut = segOut;
MaskOut.img = sum(segOut.img,4)> .5; 
MaskOut.hdr.dime.dim(5) = 1; 
MaskOut.hdr.dime.dim(1) = 3; 
MaskOut.hdr.dime.datatype = 4; 
save_untouch_nii(MaskOut,maskOutName); 

end


function cropped = crop_image(imageName,xbounds,ybounds,zbounds)

cropped = load_untouch_nii(imageName); 
cropped.img = cropped.img(xbounds,ybounds,zbounds,:);
cropped.hdr.dime.dim(2:5) = size(cropped.img); 

end