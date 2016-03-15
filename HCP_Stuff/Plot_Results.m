function Plot_Results(results,figNums,nBval)
%nBval is the number of cycles of bvals we are including. 
data{1} = results.FAs; 
data{2} = results.MDs; 

plot_data(data{1},figNums(1),nBval); 
set(gca,'ylim',[0 1])
plot_data(data{2},figNums(2),nBval); 
set(gca,'ylim',[0 3e-3])

end

function plot_data(param,figNum,nBval)

figure(figNum)
clf
hold on 
%number of iterations
for i = 1:size(param,3)
   
    data = squeeze(param(:,:,i,nBval)); 
    plot(data(:,1),'xr'); 
    plot(data(:,2),'xk'); 
    plot(data(:,3),'xg'); 
    plot(data(:,4),'xm'); 
    plot(data(:,5),'xb'); 
    plot(data(:,6),'xy'); 
    plot(data(:,7),'xc'); 
    plot(data(:,8),'xr'); 
    
end

end