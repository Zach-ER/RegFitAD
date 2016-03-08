%This is to tie the pieces together to make future Zach able to understand
%what's going on... 

function Run_Start_To_Finish

segNos = 1:8; 
expName = 'DivFornixBoundingBox'; 
segName = 'Segs_With_Fornix.nii.gz';%'Segs_With_Fornix_Divided.nii.gz'

topDirec = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts';
AboveDirec = fullfile(topDirec,expName); 
GoldStandDirec = fullfile(AboveDirec,'GoldStand');
%%
%Create_Small_Phantom(GoldStandDirec); 

%%
%Resample_to_different(GoldStandDirec); 

%%
sysArgs = ['source ~/.bash_profile;python ./resample_and_dtifit.py ',AboveDirec,' ',...
    segName];
system(sysArgs); 


%%
dirNames = pick_bvals_bvecs(AboveDirec); 

%%
sysArgs = ['source ~/.bash_profile;python ./dt_fit_phantoms.py ',AboveDirec];
%system(sysArgs); 


%%
riceNoise = 0; 
tic
for i = 1:10%length(dirNames)
    DiffsOut = fullfile(dirNames{i},'diffOutwSig.txt');
    DTOut   = fullfile(dirNames{i},'DTOut.txt');
    
    if ~exist(DiffsOut,'file')
        
        if i > 1
           initParams = load(oldDiff); 
           initParams(:,1) = []; 
        else
           initParams = 'n';
        end
        
        if mod(i,10) == 0
            fprintf('We are on iteration %i of %i at time %d \n',i,length(dirNames),toc)
        end
        run_reg_fit_itDir(dirNames{i},segNos,riceNoise,DiffsOut,DTOut,initParams);
        
    end
    %this is to speed up by initialising with our last answer. This should
    %be OK as long as the region-search is exhaustive enough...
    oldDiff = DiffsOut; 
    
end

%% Fitting different noisy phantoms. 
%we need to record the number of readings, the Resampling number, 
% and the iteration number before the DTI - 
% dtOuts = zeros(length(dirNames),length(segNos),5); 
% 
% threshes = 0.4:.1:.9;
% classicalOuts = zeros(length(dirNames),length(segNos),5,length(threshes)); 
% riceNoise = 340; 
% 
% resultsName = fullfile(AboveDirec,'NoiseResults.mat'); 
% 
% 
% for i = 1:length(dirNames)
%     
%     %makes another directory with the right pieces for the fitting. 
%     noiseDir = make_noise_phant(dirNames{i},riceNoise); 
%     
%     DiffsOut = fullfile(noiseDir,'diff.txt');
%     DTOut   = fullfile(noiseDir,'DT.txt');
%     run_reg_fit_itDir(noiseDir,segNos,riceNoise,DiffsOut,DTOut);
%     
%     %get the extra bits
%     [nReadings,downsampleNo,itNo] = break_down_name(dirNames{i}); 
%     extraLines = [nReadings,downsampleNo,itNo];
%     extra1 = repmat(extraLines,[6 1]);
%     
%     %now time to save the data... 
%     DTvals = load(DTOut);
%     
%     dtOuts(i,:,:)=[DTvals,extra1]; 
%         
%     DTs = get_classical_results(noiseDir,segNos, threshes);    
%     extra2 = repmat(extraLines,[ 6 1 6] );
%     classicalOuts(i,:,:,:) = [DTs,extra2]; 
%     
%     save(resultsName,'dtOuts','classicalOuts'); 
%     
%     rmdir(noiseDir,'s'); 
% end

end

function DTs = get_classical_results(subjDir,segNos,threshes)

    DTdir = fullfile(subjDir,'DT'); 
    FA = load_untouch_nii(fullfile(DTdir,'DT_FA.nii.gz')); 
    MD = load_untouch_nii(fullfile(DTdir,'DT_MD.nii.gz')); 
    segs = load_untouch_nii(fullfile(subjDir,'Segs_Resampled.nii.gz'));
    
    DTs = zeros(size(segs.img,4),2,length(threshes));
    
    for iSegNo = 1:length(segNos)
    for iThresh = 1:length(threshes)
       
        thresh = threshes(iThresh);          
        
        tissue = segs.img(:,:,:,segNos(iSegNo)) > thresh;
        
        DTs(iSegNo,1,iThresh) = mean(MD.img(tissue));
        DTs(iSegNo,2,iThresh) = mean(FA.img(tissue));
    end
    end


end

function [nReadings,downsampleNo,itNo] = break_down_name(dirName)

broken = strsplit(dirName,'/'); 
readings = strsplit(broken{end-2},'_'); 
nReadings = str2num(readings{1}); 

downsampled = strsplit(broken{end-1},'_'); 
downsampleNo= str2num(downsampled{2}); 

its= strsplit(broken{end-1},'_'); 
itNo= str2num(its{2}); 

end



