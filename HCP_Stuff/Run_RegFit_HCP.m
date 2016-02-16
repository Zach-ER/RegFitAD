function Run_RegFit_HCP

outSuffix = 'first12';
bInds = 1:12;

%at the moment, this still has the S0 values, which might not be ideal...
for i = 1:15
    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/OneVoxROI',...
        ['downSampled_',num2str(i)]);
    DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
    segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
    
    %note - will have to process these first...
    DTdir = fullfile(subjDir,['DT_',outSuffix]);
    SnoughtName = fullfile(DTdir,'DT_S0.nii.gz');
    V1Name = fullfile(DTdir,'DT_V1.nii.gz');
    V2Name = fullfile(DTdir,'DT_V2.nii.gz');
    
    outName = fullfile(subjDir,['diffusivities_',outSuffix,'.txt']);
    DTparamsName = fullfile(subjDir,['DTvals_',outSuffix,'.txt']);
    %loading
    Segs = load_untouch_nii(segName);
    %getting rid of unphysically small values that mess up normalisation.
    Segs.img(Segs.img < 1e-3) = 0;
    
    bMask = sum(Segs.img,4) > 0.9;
    
    Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,1:3);
    DW = load_untouch_nii(DWname); DWout=DW;
    DW = DW.img(:,:,:,bInds); DWout.img = DW;
    S0 = load_untouch_nii(SnoughtName); S0 = S0.img;
    bvals = load(fullfile(subjDir,'bvals')); bvals = bvals(bInds);
    bvecs = load(fullfile(subjDir,'bvecs')); bvecs = bvecs(:,bInds);
    
    %saving bvals/bvecs in reduced form.
    bvalOutName = fullfile(subjDir,['bvals_',outSuffix]);
    bvecOutName = fullfile(subjDir,['bvecs_',outSuffix]);
    dataOutName = fullfile(subjDir,['DW_',outSuffix,'.nii.gz']);
    
    save(bvalOutName,'bvals','-ascii');
    save(bvecOutName,'bvecs','-ascii');
    DWout.hdr.dime.dim(5) = size(DWout.img,4);
    save_untouch_nii(DWout,dataOutName);
    
    if exist(SnoughtName,'file')
        %%
        [bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs);
        %%
        W = flattener_4d(Segs,bMask);
        DW = flattener_4d(DW,bMask);
        S0 = S0(bMask);
        %%
        k = size(W,2);
        initParams = repmat([1.7e-3, 1.2e-3,1.1e-3],[k 1]);
        %%
        %note: the Rician noise is added after the scaling by S0, so it is still
        %correct and is not a percentage of the signal at a voxel.
        riceNoise = 0;
        SSDind = 's'; %1,0,'s'
        %note- this is a tad high, but there's excellent immunity to it.. .
        
        if ~exist(outName,'file')
            paramVals = direct_fit_DT_AD(S0,DW,W,bMat,initParams,riceNoise,SSDind);
            dtVals = get_DT_from_diffusivities(paramVals);
            save(outName,'paramVals','-ascii');
            save(DTparamsName ,'dtVals','-ascii');
        end
        
        DTparamsName2 = fullfile(subjDir,['DTvals_S0Fit',outSuffix,'.txt']);
        if ~exist(DTparamsName2 ,'file')
            paramVals = direct_fit_with_S0(DW,W,bMat,initParams,riceNoise,SSDind);
            %%
            dtVals = get_DT_from_diffusivities(paramVals);
            save(DTparamsName2  ,'dtVals','-ascii');
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
