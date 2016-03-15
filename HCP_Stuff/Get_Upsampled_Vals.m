function [classicalMeth,csvMat]=Get_Upsampled_Vals(topDir,nSegs,thresh,dirBase,order)
%This will plot the estimates for the different approaches. For all
%iterations of the comparison...
lengthCycle  = 6;
nIter = 10;
segDims = 1:nSegs; %[1:3,5]; 
nResamps = 11; 

% number of different b-val settings, iterations, nResamples, nTissues
classicalMeth.FAs = zeros(nResamps,nSegs,nIter,5);
classicalMeth.MDs = zeros(nResamps,nSegs,nIter,5);

%doesn't matter which seg it is 
segName = fullfile(topDir,'12_Readings','Downsampled_1',[dirBase,'1'],...
    'Segs_Resampled.nii.gz');
seg = load_untouch_nii(segName); 

csvMat = {'Method','nReadings','nResampling','nRegion','paramName','Thresh','Value'};
%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
nCycles = [2,5,8,12];
%nCycles = [2,5,10];
for whichCycle = 1:length(nCycles)
    nReadings = lengthCycle*nCycles(whichCycle);
    dataDirName = fullfile(topDir,[num2str(nReadings),'_Readings']);
    for downSamplingNumber = 1:nResamps
        for iIteration = 1:nIter
            downSampledNewDir = fullfile(dataDirName,['Downsampled_',num2str(downSamplingNumber)]);
            subjDir = fullfile(downSampledNewDir,[dirBase,num2str(iIteration)]);
           
            [FA,MD] = get_classical(seg.img,subjDir,thresh,segDims,order);
            classicalMeth.FAs(downSamplingNumber,:,iIteration,whichCycle) = FA(:);
            classicalMeth.MDs(downSamplingNumber,:,iIteration,whichCycle) = MD(:);
            
            for iRegion = segDims
               a= row_of_outmat('Upsampled',nReadings,downSamplingNumber,iRegion,'FA','NA',FA(iRegion)); 
               csvMat = [csvMat;a]; 
               a = row_of_outmat('Upsampled',nReadings,downSamplingNumber,iRegion,'MD','NA',MD(iRegion)); 
               csvMat = [csvMat;a]; 
            end
            
        end
    end
end
end


%% this gets the results from the classical method,
function  [FA,MD] = get_classical(seg,subjDir,thresh,segDims,order)
dtFold = fullfile(subjDir,'DThigh'); 
if order ==3
    FAname = fullfile(dtFold,'DT_FA.nii.gz');
    MDname = fullfile(dtFold,'DT_MD.nii.gz');
elseif order ==1
    FAname = fullfile(dtFold,'DTLin_FA.nii.gz');
    MDname = fullfile(dtFold,'DTLin_MD.nii.gz');
end
    

FAimg = load_untouch_nii(FAname); FAimg = FAimg.img;
MDimg = load_untouch_nii(MDname); MDimg = MDimg.img;

for iSegNo = 1:length(segDims)
    
    tissue = seg(:,:,:,segDims(iSegNo)) > thresh;
    %tissueCount = sum(tissue(:));
    %fprintf('Here we have %d of tissue %i\n',tissueCount,iSegNo);
    FA(iSegNo) = mean(FAimg(tissue));
    MD(iSegNo) = mean(MDimg(tissue));
    
end
end

%tries to get the data so R will have it. 
function row = row_of_outmat(Method,nReadings,nResamp,nRegion,paramName,Thresh,Value)

row = cell(1,7);
row = {Method,num2str(nReadings),num2str(nResamp),num2str(nRegion),paramName,...
    num2str(Thresh),num2str(Value)};


end
