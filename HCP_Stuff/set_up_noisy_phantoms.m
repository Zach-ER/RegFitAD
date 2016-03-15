function dirNames = set_up_noisy_phantoms(topDir,sig,nIter)
%This function takes data from the gold-standard directories and pieces it
%into smaller chunks for repetitions of the experiments.

%how many diffusion 'cycles' there are, = 108/6 = 18 in this case
nTotalCycles = 18;
lengthCycle  = 6;
nResamps = 11; 
goldStandDir = fullfile(topDir,'GoldStand');
bvals = load(fullfile(goldStandDir,'bvals'));
bvecs = load(fullfile(goldStandDir,'bvecs'));

ctr = 1;
%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
for nCycles = [2,5,10]
    nReadings = lengthCycle*nCycles;
    dataDirName = fullfile(topDir,[num2str(nReadings),'_Readings']);
    if ~exist(dataDirName,'dir')
        mkdir(dataDirName)
    end
    
    for downSamplingNumber = 1:nResamps
        downSampledDir = fullfile(goldStandDir,['downSampled_',num2str(downSamplingNumber)]);
        
        
        segNom = 'Segs_Resampled.nii.gz'; maskNom = 'Mask.nii.gz';
        GS_DW = get_GS_data(downSampledDir);
        GS_SegName = fullfile(downSampledDir,segNom);
        GS_MaskName = fullfile(downSampledDir,maskNom);
        
        for iIteration = 1:nIter
           
            downSampledNewDir = fullfile(dataDirName,['Downsampled_',num2str(downSamplingNumber)]);
            if ~exist(downSampledNewDir,'dir')
                mkdir(downSampledNewDir)
            end
            
            noiseDir = fullfile(downSampledNewDir,['Noise_',num2str(iIteration)]);
            if ~exist(noiseDir,'dir')
                mkdir(noiseDir)
            end
            
            if ~exist(fullfile(noiseDir,'DW_Resampled.nii.gz'),'file')
                save_new_data(bvals,bvecs,GS_DW,nTotalCycles,nCycles,lengthCycle,noiseDir,sig);
            end
            %copy over the files for segmentations
            
            if ~exist(fullfile(noiseDir,segNom),'file')
                system(['cp ',GS_SegName,' ',noiseDir]);
            end
            if ~exist(fullfile(noiseDir,maskNom),'file')
                system(['cp ',GS_MaskName,' ',noiseDir]);
            end  

            dirNames{ctr,1} = noiseDir;
            ctr = ctr + 1;
            
        end
    end
    
end
end

function GS_DW = get_GS_data(downSampledDir)
GS_Name = fullfile(downSampledDir,'DW_Resampled.nii.gz');
GS_DW = load_untouch_nii(GS_Name);
end

%saves combinations of bvals/bvecs
function save_new_data(bvals,bvecs,GS_DW,nTotalCycles,nCycles,lengthCycle,itDir,sig)
randOrder = 1:nTotalCycles;
cyclesWeTake = randOrder(1:nCycles);

diffusionInds = [];
for iList = 1:length(cyclesWeTake)
    startInd = (cyclesWeTake(iList)-1)*lengthCycle +1 ;
    diffusionInds = [diffusionInds,startInd:startInd+lengthCycle-1];
end

name_save_new_diff_data(bvals,bvecs,GS_DW,diffusionInds,itDir,sig);
end


function name_save_new_diff_data(bvals,bvecs,GS_DW,diffusionInds,itDir,sig)
newDW = GS_DW;
newDW.img = newDW.img(:,:,:,diffusionInds);
newDW.img = add_rician_noise(newDW.img,sig); 
newDW.hdr.dime.dim(2:5) = size(newDW.img);
newBvals = bvals(diffusionInds);
newBvecs = bvecs(:,diffusionInds);

newName = fullfile(itDir,'DW_Resampled.nii.gz');

save_untouch_nii(newDW,newName);
save(fullfile(itDir,'bvecs'),'newBvecs','-ascii');
save(fullfile(itDir,'bvals'),'newBvals','-ascii');

end



