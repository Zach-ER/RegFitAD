function [myMeth,classical] = Compare_Methods()
%COMPARE_METHODS This looks at the results for classical and reg-fit, using
%an HCP phantom sampled to different resolutions. 

nResamples = 15; 

methWithS0 = get_regfit_results(nResamples,'_S0Fitfirst12');

%myMeth = get_regfit_results(nResamples,'');
classical = get_classical_results(nResamples,.8,'DT'); 
myMeth2 = get_regfit_results(nResamples,'_first12');
classical2 = get_classical_results(nResamples,.8,'DT_first12'); 


figure(2); clf;
subplot(1,2,1); 
plot(methWithS0.FAs,'x-r'); hold on; 
plot(myMeth2.FAs,'xm-'); hold on 
plot(classical.FAs,'ko-'); 
plot(classical2.FAs,'bo-'); 

subplot(1,2,2); 
plot(methWithS0.MDs,'xr-'); 
hold on; 
plot(myMeth2.MDs,'xm-'); 
plot(classical.MDs,'ko-'); 
plot(classical2.MDs,'bo-'); 


end

function myMeth = get_regfit_results(nResamples,extension)

myMeth.FAs = zeros(nResamples,3);
myMeth.MDs = zeros(nResamples,3);

for i = 1:nResamples
    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/OneVoxROI',['downSampled_',num2str(i)]);
    DTparamsName = fullfile(subjDir,['DTvals',extension,'.txt']);
    
    dtVals = load(DTparamsName);
    myMeth.FAs(i,:) = (dtVals(:,2))';
    myMeth.MDs(i,:) = (dtVals(:,1))';
    
    
    
end
end

function classical = get_classical_results(nResamples, thresh,dtFold)

classical.FAs = zeros(nResamples,3);
classical.MDs = zeros(nResamples,3);

for i = 1:nResamples

    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/OneVoxROI',['downSampled_',num2str(i)]);
    segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
    FAname = fullfile(subjDir,dtFold,'DT_FA.nii.gz');
    MDname = fullfile(subjDir,dtFold,'DT_MD.nii.gz');
    
    seg = load_untouch_nii(segName); seg = seg.img; 
    FA = load_untouch_nii(FAname); FA = FA.img; 
    MD = load_untouch_nii(MDname); MD = MD.img; 
        
    for iSegNo = 1:3
    
        tissue = seg(:,:,:,iSegNo) > thresh; 
        tissueCount = sum(tissue(:)); 
        %fprintf('Here we have %d of tissue %i\n',tissueCount,iSegNo); 
        classical.FAs(i,iSegNo) = mean(FA(tissue));
        classical.MDs(i,iSegNo) = mean(MD(tissue));
    
    end

end
end
