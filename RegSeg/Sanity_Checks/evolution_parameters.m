function evolution_parameters

%This script will look at DT data that we've analysed from the folder -

testFold = '/Users/zer/RegFitAD/data/Ep/Testing_RegSeg';
foldBase = 'it_0';
foldBase = 'it_initcpp';

rawFold = fullfile(testFold,'Raw');
bMask = load_untouch_nii(fullfile(rawFold,'Brain_Mask.nii.gz'));
bMask = bMask.img > .5;
rawDatName = fullfile(rawFold,'DW.nii.gz');
rawDat = load_untouch_nii(rawDatName); rawDat = rawDat.img;

S0Name = fullfile(rawFold,'DT','DT_S0.nii.gz');
S0 = load_untouch_nii(S0Name); S0 = S0.img;

MDs = zeros(51,5);
FAs = MDs;
SSDs = zeros(51,1); SSDS0s = SSDs;
for i = 0:50
    
    foldName = fullfile(testFold,[foldBase,num2str(i)]);
    resultsName = fullfile(foldName,'reg_results.txt');
    paramVals = load(resultsName);
    MD = mean(paramVals,2);
    MDs(i+1,:) = MD(:);
    
    tmp = (paramVals - repmat(MD,[1,3])).^2;
    FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(paramVals.^2,2));
    FAs(i+1,:) = FA(:);
    
    synthImName = fullfile(foldName,'DWsynth.nii.gz');
    synthIm = load_untouch_nii(synthImName); synthIm= synthIm.img;
    SSDs(i+1) = calc_ssd(rawDat,synthIm,bMask);
    
    SSDS0s(i+1) = calc_ssd_S0(rawDat,synthIm,bMask,S0);
    
end
tmp = 0;

end



function SSD = calc_ssd(rawDat,synthIm,bMask)

SSD = (rawDat-synthIm).^2;
bMaskBig = repmat(bMask,[1 1 1 size(SSD,4)]);
SSD = SSD.* bMaskBig;
SSD = nansum(SSD(:));
end

function SSD = calc_ssd_S0(rawDat,synthIm,bMask,S0)

SSD = (rawDat-synthIm).^2;
bMaskBig = repmat(bMask,[1 1 1 size(SSD,4)]);
S0MaskedBig = repmat(S0,[1 1 1 size(SSD,4)]);
SSD = SSD.* S0MaskedBig.^2 .^ bMaskBig;
SSD = nansum(SSD(:));
end





