%This is to tie the pieces together to make future Zach able to understand
%what's going on... 

segNos = 1:6; 

AboveDirec = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/WholeFornix';
GoldStandDirec = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/WholeFornix/GoldStand';

Create_Small_Phantom; 
Resample_to_different(GoldStandDirec); 
%PYTHON code
dirNames = pick_bvals_bvecs(AboveDirec); 
%PYTHON code 

riceNoise = 0; 
for i = 1:length(dirNames)
    DiffsOut = fullfile(dirNames{i},'diffOut.txt');
    DTOut   = fullfile(dirNames{i},'DTOut.txt');
    run_reg_fit_itDir(dirNames{i},segNos,riceNoise,DiffsOut,DTOut);
end