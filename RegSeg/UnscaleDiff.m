function UnscaleDiff(S0Name,DwName,outName)
%UNSCALEDIFF This takes away the scaling by S0. 

S0 = load_untouch_nii(S0Name);
DW = load_untouch_nii(DwName);
DWunscal = DW; 
for it = 1:size(DW.img,4)
   DWunscal.img(:,:,:,it) = DW.img(:,:,:,it)./(S0.img+eps);
end
save_untouch_nii(DWunscal,outName); 

end

