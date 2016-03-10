function [myMeth,classicalMeth] = Compare_Methods_Large(topDir,nSegs,thresh,dirBase)
%This will plot the estimates for the different approaches. For all
%iterations of the comparison...
lengthCycle  = 6;
nIter = 10;
segDims = 1:nSegs; %[1:3,5]; 
nResamps = 8; 

% number of different b-val settings, iterations, nResamples, nTissues
myMeth.FAs = zeros(nResamps,nSegs,nIter,5);
myMeth.MDs = zeros(nResamps,nSegs,nIter,5);

classicalMeth = myMeth; 

dtName = 'DTOutS0s300.txt';
diffName = 'DiffOutsS0s300.txt';

%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
nCycles = [2,3,5,8,10];
for whichCycle = 1:5
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
            
            [FA,MD] = get_classical(subjDir,thresh,segDims);
            classicalMeth.FAs(downSamplingNumber,:,iIteration,whichCycle) = FA(:);
            classicalMeth.MDs(downSamplingNumber,:,iIteration,whichCycle) = MD(:);
        end
    end
end
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
