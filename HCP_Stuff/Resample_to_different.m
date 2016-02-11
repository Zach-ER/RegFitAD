function Resample_to_different()
% This function will make 'blanks' to resample to, with worse/better
% resolution

dwGoldName = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/GoldStand/DW.nii.gz';
gold = load_untouch_nii(dwGoldName); 

scaleFacs=linspace(1,4,8); 

for i = 1:length(scaleFacs)
   
    newFold = fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts',['downSampled_',num2str(i)]);
    mkdir(newFold);
    blankName = fullfile(newFold,'Mask.nii.gz'); 
    
    newImg = gold; 
    newImg.img = 0.*squeeze(gold.img(:,:,:,1));
    newImg.hdr.dime.pixdim(2:4) = gold.hdr.dime.pixdim(2:4).*scaleFacs(i);
    
    
    blankImSize = ceil(size(newImg.img)./scaleFacs(i));
    newImg.img = ones(blankImSize);
    
    newImg.hdr.dime.dim(2:4) = blankImSize;
    newImg.hdr.dime.dim(5) = 1;
    newImg.hdr.hist.srow_x(1:3) = newImg.hdr.hist.srow_x(1:3).*scaleFacs(i);
    newImg.hdr.hist.srow_y(1:3) = newImg.hdr.hist.srow_y(1:3).*scaleFacs(i);
    newImg.hdr.hist.srow_z(1:3) = newImg.hdr.hist.srow_z(1:3).*scaleFacs(i);
    newImg.hdr.hist.sform_code = 0; 
    
    save_untouch_nii(newImg,blankName); 
    
end
