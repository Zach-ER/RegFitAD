function Run_RegFit_HCP

%at the moment, this still has the S0 values, which might not be ideal... 
for i = 8:-1:1 
    
    subjDir= fullfile('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts',['downSampled_',num2str(i)]);
    DWname = fullfile(subjDir,'DW_Resampled.nii.gz');
    segName = fullfile(subjDir,'Segs_Resampled.nii.gz');
    SnoughtName = fullfile(subjDir,'DT','DT_S0.nii.gz');
    V1Name = fullfile(subjDir,'DT','DT_V1.nii.gz');
    V2Name = fullfile(subjDir,'DT','DT_V2.nii.gz');

    outName = fullfile(subjDir,'diffusivities.txt');
    DTparamsName = fullfile(subjDir,'DTvals.txt');

    %loading
    Segs = load_untouch_nii(segName);
    %getting rid of unphysically small values that mess up normalisation.
    Segs.img(Segs.img < 1e-3) = 0;
    
    bMask = sum(Segs.img,4) > 0.9;
    

    Segs = normalise_segs(Segs); Segs = Segs.img(:,:,:,1:3);
    DW = load_untouch_nii(DWname); DW = DW.img;
    S0 = load_untouch_nii(SnoughtName); S0 = S0.img;
    bvals = load(fullfile(subjDir,'bvals'));
    bvecs = load(fullfile(subjDir,'bvecs'));
    
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
    riceNoise = 0;%sqrt(13);
    SSDind = 's'; %1,0,'s'
    %note- this is a tad high, but there's excellent immunity to it.. .
    
    if ~exist(outName,'file')
    
        paramVals = direct_fit_DT_AD(S0,DW,W,bMat,initParams,riceNoise,SSDind);

        %%
        MD = mean(paramVals,2);
        tmp = (paramVals - repmat(MD,[1,3])).^2;
        FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(paramVals.^2,2));

        
        dtVals(:,1) = MD; 
        dtVals(:,2) = FA;
                

    end
    
    save(outName,'paramVals','-ascii');
    save(DTparamsName ,'dtVals','-ascii'); 
end

end

