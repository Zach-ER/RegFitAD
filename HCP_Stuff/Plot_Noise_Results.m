`function  Plot_Noise_Results(thresh)
%PLOT_NOISE_RESULTS summarises the results from the noisy phantom fitting -
%

load('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/WholeFornix/NoiseResults.mat'); 
classicRes = squeeze(classicalOuts(:,:,:,thresh)); 
nReadings = 12; 

plot_results(1,2,nReadings,classicRes); 
set(gca,'ylim',[0 1])
title('Classic Results')
plot_results(2,2,nReadings,dtOuts); 
set(gca,'ylim',[0 1])
title('My Method')

plot_results(3,1,nReadings,classicRes); 
title('Classic Results')
set(gca,'ylim',[0 .003])
plot_results(4,1,nReadings,dtOuts); 
title('My Method')
set(gca,'ylim',[0 .003])

end

function plot_results(figNo,paramNo,nReadings,results)

figure(figNo)
clf
hold on 
colspec = {'xr','xg','xc','xk','xm','xb'};

for ii = 1:size(results,1)
   
    if results(ii,1,3) == nReadings
        simDat = squeeze(results(ii,:,:));
        nResample = simDat(:,4); 
        
        for jj = 1:size(simDat,1)
            plot(nResample+(-.3+.1*jj),simDat(jj,paramNo),colspec{jj})
        end
    
    
    end
    
end

end