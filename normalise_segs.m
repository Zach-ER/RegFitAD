function normedSeg = normalise_segs(segs)

%FUNCTION NORMALISE_SEGS 
%INPUTS:  segs: a 4-d segmentation nii structure, 
%OUTPUTS: normedSeg, an image with no negative values and renormalised
%probs

segImg = segs.img; 
segImg(segImg<0) = 0; 

probMap = sum(segImg,4);
for ii = 1:size(segImg,4)   
    segImg(:,:,:,ii) = segImg(:,:,:,ii)./(probMap + eps);    
end

%set up the container 
normedSeg = segs; 
normedSeg.img = segImg;