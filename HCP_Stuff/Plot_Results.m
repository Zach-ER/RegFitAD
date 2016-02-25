function Plot_Results(results,figNums,nBval)
%nBval is the number of cycles of bvals we are including. 
data{1} = results.FAs; 
data{2} = results.MDs; 

for i = 1:length(figNums)
    plot_data(data{i},figNums(i),nBval); 
    
end

end

function plot_data(param,figNum,nBval)

figure(figNum)
clf
hold on 
for i = 1:40
   
    data = squeeze(param(:,:,i,nBval)); 
    plot(data(:,1),'xr-'); 
%     plot(data(:,2),'xk-'); 
    plot(data(:,3),'xg-'); 
    plot(data(:,4),'xm-'); 
    plot(data(:,5),'xb-'); 
    plot(data(:,6),'xy-'); 
    
end

end