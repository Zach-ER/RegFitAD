function prepare_b_matrices(dataDir,DTDir)
%function PREPARE_B_MATRICES will go through the data after it has been
%fitted using FSL. It will make and save the appropriately-rotated
%b-matrices, so that 
princDir = load_untouch_nii(fullfile(DTDir,'DT_V1.nii.gz')); 
bMask = load_untouch_nii(fullfile(dataDir,'Brain_mask.nii.gz')); 
princDir = princDir.img; bMask = bMask.img; 

bvecs = load(fullfile(dataDir,'bvecs.txt'));
bvals = load(fullfile(dataDir,'bvals.txt'));

if size(bvecs,2) ~= 3
   bvecs = bvecs'; 
end

%going to make a b-matrix at each direction. 

bMat = cell(size(princDir(:,:,:,1)));
defaultDirec = [1 0 0];


for ix = 1:size(princDir,1)
for iy = 1:size(princDir,2)
for iz = 1:size(princDir,3)
if bMask(ix,iy,iz)
    
    voxDir = squeeze(princDir(ix,iy,iz,:));
    rotMat = vrrotvec2mat(vrrotvec(voxDir,defaultDirec));
    
    %rotating the vector matrix
    g = bvecs * rotMat;
    
    b = [g(:,1).^2 2*g(:,1).*g(:,2) 2*g(:,1).*g(:,3) g(:,2).^2 2*g(:,2).*g(:,3) g(:,3).^2];
    b = repmat(bvals(:),[1 6]).*b;
    
    bMat{ix,iy,iz} = b(:,[1,4,6]);


end
end
end
end

bMatName = fullfile(dataDir,'bMat.mat');
save(bMatName,'bMat');

end