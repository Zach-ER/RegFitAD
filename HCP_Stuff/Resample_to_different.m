function Resample_to_different(topDirec)
% This function will make 'blanks' to resample to, with worse/better
% resolution

%TOPdirec should contain 'GoldStand' at the end of the path 
dwGoldName = fullfile(topDirec,'DW.nii.gz');
gold = load_untouch_nii(dwGoldName); 

scaleFacs=linspace(1,7,15); 

for i = 1:length(scaleFacs)
   
    newFold = fullfile(topDirec,['downSampled_',num2str(i)]);
    mkdir(newFold);
    blankName = fullfile(newFold,'Mask.nii.gz'); 
    
    newImg = gold; 
    newImg.img = zeros(size(gold.img,1),size(gold.img,2),size(gold.img,3));
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
