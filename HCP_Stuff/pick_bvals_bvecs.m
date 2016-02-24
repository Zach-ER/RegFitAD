function pick_bvals_bvecs(topDir)
%This function takes data from the gold-standard directories and pieces it
%into smaller chunks for repetitions of the experiments.

nIter = 40;
%how many diffusion 'cycles' there are, = 108/6 = 18 in this case
nTotalCycles = 18;
lengthCycle  = 6;
goldStandDir = fullfile(topDir,'GoldStand');
bvals = load(fullfile(goldStandDir,'bvals'));
bvecs = load(fullfile(goldStandDir,'bvecs'));

segInds = [1:6]; 

%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
for nCycles = 2:5
    nReadings = lengthCycle*nCycles;
    dataDirName = fullfile(topDir,[num2str(nReadings),'_Readings']);
    if ~exist(dataDirName,'dir')
        mkdir(dataDirName)
    end
    
    for downSamplingNumber = 1:15
        downSampledDir = fullfile(goldStandDir,['downSampled_',num2str(downSamplingNumber)]);
        
        GS_DW = get_GS_data(downSampledDir);
        GS_SegName = fullfile(downSampledDir,'Segs_Resampled.nii.gz');
        GS_MaskName = fullfile(downSampledDir,'Mask.nii.gz');
        
        for iIteration = 1:nIter
            
            downSampledNewDir = fullfile(dataDirName,['Downsampled_',num2str(downSamplingNumber)]);
            if ~exist(downSampledNewDir,'dir')
                mkdir(downSampledNewDir)
            end
            
            itDir = fullfile(downSampledNewDir,['It_',num2str(iIteration)]);
            if ~exist(itDir,'dir')
                mkdir(itDir)
            end
            
           save_comb_of_bvals(bvals,bvecs,GS_DW,nTotalCycles,nCycles,lengthCycle,itDir);
            
            %copy over the files for segmentations 
            system(['cp ',GS_SegName,' ',itDir]);
            system(['cp ',GS_MaskName,' ',itDir]);

            
         %   run_reg_fit_itDir(itDir,segInds); 
            
        end
    end
    
end
end

function GS_DW = get_GS_data(downSampledDir)
GS_Name = fullfile(downSampledDir,'DW_Resampled.nii.gz');
GS_DW = load_untouch_nii(GS_Name);
end

%saves combinations of bvals/bvecs 
function save_comb_of_bvals(bvals,bvecs,GS_DW,nTotalCycles,nCycles,lengthCycle,itDir)
randOrder = randperm(nTotalCycles);
cyclesWeTake = randOrder(1:nCycles);

diffusionInds = [];
for iList = 1:length(cyclesWeTake)
    startInd = (cyclesWeTake(iList)-1)*lengthCycle +1 ;
    diffusionInds = [diffusionInds,startInd:startInd+lengthCycle-1];
end

name_save_new_diff_data(bvals,bvecs,GS_DW,diffusionInds,itDir);
end


function name_save_new_diff_data(bvals,bvecs,GS_DW,diffusionInds,itDir)
newDW = GS_DW;
newDW.img = newDW.img(:,:,:,diffusionInds);
newDW.hdr.dime.dim(2:5) = size(newDW.img);
newBvals = bvals(diffusionInds);
newBvecs = bvecs(:,diffusionInds);

newName = fullfile(itDir,'DW_Resampled.nii.gz');

save_untouch_nii(newDW,newName);
save(fullfile(itDir,'bvecs'),'newBvecs','-ascii');
save(fullfile(itDir,'bvals'),'newBvals','-ascii');

end


function run_reg_fit_itDir(subjDir,segInds)

DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
segName = fullfile(subjDir,'Segs_Resampled.nii.gz');

%note - will have to process these first...
DTdir = fullfile(subjDir,'DT');
V1Name = fullfile(DTdir,'DT_V1.nii.gz');
V2Name = fullfile(DTdir,'DT_V2.nii.gz');

%loading
Segs = load_untouch_nii(segName);
%getting rid of unphysically small values that mess up normalisation.
Segs.img(Segs.img < 1e-3) = 0;

bMask = sum(Segs.img,4) > 0.9;

Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,segInds);
DW = load_untouch_nii(DWname);
DW = DW.img;
bvals = load(fullfile(subjDir,'bvals'));
bvecs = load(fullfile(subjDir,'bvecs'));

[bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);
%%
W = flattener_4d(Segs,bMask);
DW = flattener_4d(DW,bMask);

%%
k = size(W,2);
initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
%%
%note: the Rician noise is added after the scaling by S0, so it is still
%correct and is not a percentage of the signal at a voxel.
riceNoise = 0;
SSDind = 's'; %1,0,'s'
%note- this is a tad high, but there's excellent immunity to it.. .

outName = fullfile(subjDir,'Diffs.txt');
DTparamsName = fullfile(subjDir,'DTvals.txt');

%if ~exist(outName ,'file')
    paramVals = direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind);
    %%
    dtVals = get_DT_from_diffusivities(paramVals);
    save(DTparamsName  ,'dtVals','-ascii');
    save(outName,'paramVals','-ascii');
%end

end



function dtVals = get_DT_from_diffusivities(diffusivities)

MD = mean(diffusivities,2);
tmp = (diffusivities- repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(diffusivities.^2,2));

dtVals(:,1) = MD;
dtVals(:,2) = FA;

end


