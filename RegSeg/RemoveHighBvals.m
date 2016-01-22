function [bvals,bvecs]=RemoveHighBvals( bvalFname,bvecFname,bThresh,dwName,outName)
%REMOVEHIGHBVALS remove the vals higher than bThresh(2) and == bThresh(1) 

bvals = load(bvalFname); 
excludedInds = bvals>bThresh(2) | bvals == bThresh(1);
tmp = load_untouch_nii(dwName); 
tmp.img(:,:,:,excludedInds) = []; 
tmp.hdr.dime.dim(2:5) = size(tmp.img); 
save_untouch_nii(tmp,outName);
bvals(excludedInds) = []; 
bvecs = load(bvecFname);
bvecs(:,excludedInds) = []; 


end

