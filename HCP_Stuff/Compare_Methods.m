function [myMeth,classical] = Compare_Methods()
%COMPARE_METHODS This looks at the results for classical and reg-fit, using
%an HCP phantom sampled to different resolutions. 

nResamples = 8; 
myMeth = get_regfit_results(nResamples);
classical = get_classical_results(nResamples,.8); 


figure(2); clf;
subplot(1,2,1); 
plot(myMeth.FAs,'xr'); hold on; 
plot(classical.FAs,'ko'); 

subplot(1,2,2); 
plot(myMeth.MDs,'xr'); hold on; 
plot(classical.MDs,'ko'); 

tmp=0;
end

function myMeth = get_regfit_results(nResamples)

myMeth.FAs = zeros(nResamples,3);
myMeth.MDs = zeros(nResamples,3);

for i = 1:nResamples
    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts',['downSampled_',num2str(i)]);
    DTparamsName = fullfile(subjDir,'DTvals.txt');
    
    dtVals = load(DTparamsName);
    myMeth.FAs(i,:) = (dtVals(:,2))';
    myMeth.MDs(i,:) = (dtVals(:,1))';
    
    
    
end
end

function classical = get_classical_results(nResamples, thresh)

classical.FAs = zeros(nResamples,3);
classical.MDs = zeros(nResamples,3);

for i = 1:nResamples

    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts',['downSampled_',num2str(i)]);
    segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
    FAname = fullfile(subjDir,'DT','DT_FA.nii.gz');
    MDname = fullfile(subjDir,'DT','DT_MD.nii.gz');
    
    seg = load_untouch_nii(segName); seg = seg.img; 
    FA = load_untouch_nii(FAname); FA = FA.img; 
    MD = load_untouch_nii(MDname); MD = MD.img; 
        
    for iSegNo = 1:3
    
        tissue = seg(:,:,:,iSegNo) > thresh; 
        tissueCount = sum(tissue(:)); 
        fprintf('Here we have %d of tissue %i\n',tissueCount,iSegNo); 
        classical.FAs(i,iSegNo) = mean(FA(tissue));
        classical.MDs(i,iSegNo) = mean(MD(tissue));
    
    end

end
end
