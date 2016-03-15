%This is to tie the pieces together to make future Zach able to understand
%what's going on... 

function Run_Start_To_Finish

segNos = 1:8; 
expName = 'Noise200'; 
segName = 'Segs_With_Fornix.nii.gz';%'Segs_With_Fornix_Divided.nii.gz'
nResamps = 15; 
scaleFacs=(linspace(1,20,nResamps)).^1/3;
riceNoise=200; 
nIter = 10;

hcpTopDirec = '/Users/zer/RegFitAD/data/HCPwStruct/Processed';
topDirec = '/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts';
expDir = fullfile(topDirec,expName); 
GoldStandDirec = fullfile(expDir,'GoldStand');

%%
Create_Small_Phantom(hcpTopDirec,GoldStandDirec); 
    
%%
Resample_to_different(GoldStandDirec,'Segs_Whole.nii.gz',scaleFacs); 

%% resample the whole things
sysArgs = ['source ~/.bash_profile;python ./resample_and_dtifit.py ',expDir,' ',...
    'Segs_Whole.nii.gz',' Segs_Whole.nii.gz DW_Resampled.nii.gz MaskForResampling.nii.gz 0'];
system(sysArgs); 

%% cut them down to size
for downSamplingNumber = 1:nResamps
    downSampledDir = fullfile(GoldStandDirec,['downSampled_',num2str(downSamplingNumber)]);
    Cut_Segs_Down( 6:8,...
        fullfile(downSampledDir,'Segs_Whole.nii.gz'),...
        fullfile(downSampledDir,'Segs_Resampled.nii.gz'),...
        fullfile(downSampledDir,'Mask.nii.gz'));
end
%%
%dirNames = pick_bvals_bvecs(expDir); 
dirNames = set_up_noisy_phantoms(expDir,riceNoise,nIter);
%%
sysArgs = ['source ~/.bash_profile;python ./dt_fit_phantoms.py ',expDir];
system(sysArgs); 
%%
tic

upsInd = 0; 
riceInd = 250;
for i = 1:length(dirNames)
    if upsInd == 1
        DiffsOut = fullfile(dirNames{i},'diffsUps.txt');
        DTOut   = fullfile(dirNames{i},'DTups.txt');
    else
        DiffsOut = fullfile(dirNames{i},'diffOut.txt');
        DTOut   = fullfile(dirNames{i},'DTout.txt');
    end
    
    if ~exist(DiffsOut,'file')
        if i > 1
           initParams = load(oldDiff); 
           if size(initParams,2) == 4
                initParams(:,1) = []; 
           end
        else
           initParams = 'n';
        end
        if mod(i,10) == 0
            fprintf('We are on iteration %i of %i at time %d \n',i,length(dirNames),toc)
        end
        run_reg_fit_itDir(dirNames{i},segNos,riceNoise,DiffsOut,DTOut,initParams,upsInd);
        
    end
    %this is to speed up by initialising with our last answer. This should
    %be OK as long as the region-search is exhaustive enough...
    oldDiff = DiffsOut; 
end


%linear or cubic
order = 3;
%upsample_in_directories(dirNames,order); 
%dtiFit_Upsampled(dirNames,order); 

end

%will upsample the data in the directories 
function dtiFit_Upsampled(dirNames,order)

for iUpsamp = 1:length(dirNames)
    if order == 3
        DWhigh = fullfile(dirNames{iUpsamp},'DW_Upsampled_Cubic.nii.gz'); 
        DTnom = 'DT';
    elseif order ==1 
        DWhigh = fullfile(dirNames{iUpsamp},'DW_Upsampled_Lin.nii.gz'); 
        DTnom = 'DTLin';
    end
    if iUpsamp == 1
        maskName = fullfile(dirNames{iUpsamp},'Mask.nii.gz');
    end
    
    outFold = fullfile(dirNames{iUpsamp},'DThigh');
    bvalName = fullfile(dirNames{iUpsamp},'bvals');
    bvecName = fullfile(dirNames{iUpsamp},'bvecs');
    
    if ~exist(outFold,'dir')
        mkdir(outFold)
    end
    
    
    if exist(DWhigh,'file')
    if ~exist(fullfile(outFold,[DTnom,'_FA.nii.gz']),'file')
        sysArgs = ['source ~/.bash_profile; dtifit -k ',DWhigh,' -m ',maskName,...
            ' -b ',bvalName, ' -r ',bvecName, ' -o ',fullfile(outFold,DTnom),...
            ' -w --save_tensor'];
        system(sysArgs);
    end
    end
end
end



function upsample_in_directories(dirNames,order)

for iUpsamp = 1:length(dirNames)
    
    DWlow = fullfile(dirNames{iUpsamp},'DW_Resampled.nii.gz');
    if iUpsamp == 1
        refVol = DWlow;
    end
    
   if order == 3
       DWhigh = fullfile(dirNames{iUpsamp},'DW_Upsampled_Cubic.nii.gz');
   elseif order == 1 
       DWhigh = fullfile(dirNames{iUpsamp},'DW_Upsampled_Lin.nii.gz');
   end
   
    if ~exist(DWhigh,'file')
        sysArgs = ['source ~/.bash_profile; reg_resample -ref ',refVol,' -flo ',...
            DWlow,' -res ',DWhigh, ' -inter ', num2str(order)];
        system(sysArgs);
    end
        

end

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



