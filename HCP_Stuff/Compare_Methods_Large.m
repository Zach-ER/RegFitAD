function [myMeth,classicalMeth,csvMat] = Compare_Methods_Large(topDir,nSegs,thresh,dirBase)
%This will plot the estimates for the different approaches. For all
%iterations of the comparison...
lengthCycle  = 6;
nIter = 10;
segDims = 1:nSegs; %[1:3,5]; 
nResamps = 11; 

% number of different b-val settings, iterations, nResamples, nTissues
myMeth.FAs = zeros(nResamps,nSegs,nIter,5);
myMeth.MDs = zeros(nResamps,nSegs,nIter,5);

classicalMeth = myMeth; 

dtName = 'DTOutS0s300.txt';
diffName = 'DiffOutsS0s300.txt';
% 
% dtName   = 'DTups.txt';
% diffName = 'diffsUps.txt';
% 
diffName = 'diffOut_noiseless_sig200.txt';
dtName   = 'DTOut_noiseless_sig200.txt';

%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
nCycles = [2,5,8,12];
%nCycles = [2,5,10];
ctr =1 ; 

csvMat = {'Method','nReadings','nResampling','nRegion','paramName','Thresh','Value'};
for whichCycle = 1:length(nCycles)
    nReadings = lengthCycle*nCycles(whichCycle);
    dataDirName = fullfile(topDir,[num2str(nReadings),'_Readings']);
    for downSamplingNumber = 1:nResamps
        for iIteration = 1:nIter
            downSampledNewDir = fullfile(dataDirName,['Downsampled_',num2str(downSamplingNumber)]);
            subjDir = fullfile(downSampledNewDir,[dirBase,num2str(iIteration)]);
            
            %
            [FA,MD] = get_my_meth(subjDir,diffName,dtName);
            
            myMeth.FAs(downSamplingNumber,:,iIteration,whichCycle) = FA(:);
            myMeth.MDs(downSamplingNumber,:,iIteration,whichCycle) = MD(:);
            
            for iRegion = segDims
               a= row_of_outmat('MyMeth',nReadings,downSamplingNumber,iRegion,'FA','NA',FA(iRegion)); 
               csvMat = [csvMat;a]; 
               a = row_of_outmat('MyMeth',nReadings,downSamplingNumber,iRegion,'MD','NA',MD(iRegion)); 
               csvMat = [csvMat;a]; 
            end
            
            [FA,MD] = get_classical(subjDir,thresh,segDims);
            classicalMeth.FAs(downSamplingNumber,:,iIteration,whichCycle) = FA(:);
            classicalMeth.MDs(downSamplingNumber,:,iIteration,whichCycle) = MD(:);
            
            for iRegion = segDims
               a= row_of_outmat('Classical',nReadings,downSamplingNumber,...
                   iRegion,'FA',thresh,FA(iRegion)); 
               csvMat = [csvMat;a]; 
               a = row_of_outmat('Classical',nReadings,downSamplingNumber,...
                   iRegion,'MD',thresh,MD(iRegion)); 
               csvMat = [csvMat;a]; 
            end
            
        end
    end
end
end

%tries to get the data so R will have it. 
function row = row_of_outmat(Method,nReadings,nResamp,nRegion,paramName,Thresh,Value)

row = cell(1,7);
row = {Method,num2str(nReadings),num2str(nResamp),num2str(nRegion),paramName,...
    num2str(Thresh),num2str(Value)};


end

%% This collects my results from the directories
function [FA,MD] = get_my_meth(subjDir,diffName,dtName)

outName = fullfile(subjDir,diffName);
DTparamsName = fullfile(subjDir,dtName);
DTvals = load(DTparamsName);
FA = DTvals(:,2);
MD = DTvals(:,1);

end

%% this gets the results from the classical method,
function  [FA,MD] = get_classical(subjDir,thresh,segDims)
dtFold = fullfile(subjDir,'DT'); 
segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
FAname = fullfile(dtFold,'DT_FA.nii.gz');
MDname = fullfile(dtFold,'DT_MD.nii.gz');

seg = load_untouch_nii(segName); seg = seg.img;
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
