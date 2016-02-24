function Run_Regfit_All_ItDirs(topDir)
%how many diffusion 'cycles' there are, = 108/6 = 18 in this case
lengthCycle  = 6;
nIter = 40;

%each 'cycle' is a no-diff acquisition and 5 diffusion-weighted volumes.
for nCycles = 2:5
    nReadings = lengthCycle*nCycles;
    dataDirName = fullfile(topDir,[num2str(nReadings),'_Readings']);
    for downSamplingNumber = 1:15
        for iIteration = 1:nIter
            downSampledNewDir = fullfile(dataDirName,['Downsampled_',num2str(downSamplingNumber)]);
            subjDir = fullfile(downSampledNewDir,['It_',num2str(iIteration)]);
            
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
            
            Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,1:3);
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

            if ~exist(outName ,'file')
                paramVals = direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind);
                %%
                dtVals = get_DT_from_diffusivities(paramVals);
                save(DTparamsName  ,'dtVals','-ascii');
                save(outName,'paramVals','-ascii');
            end
            
            
        end
    end
    
end
end


function dtVals = get_DT_from_diffusivities(diffusivities)

MD = mean(diffusivities,2);
tmp = (diffusivities- repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(diffusivities.^2,2));

dtVals(:,1) = MD;
dtVals(:,2) = FA;

end

