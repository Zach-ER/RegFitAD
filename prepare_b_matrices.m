function [bMatName,bMat] = prepare_b_matrices(dataDir,DTDir,bMask)
%function PREPARE_B_MATRICES will go through the data after it has been
%fitted using FSL. It will make and save the appropriately-rotated
%b-matrices, so that 
princDir = load_untouch_nii(fullfile(DTDir,'DT_V1.nii.gz')); 
princDir = princDir.img;

bvecs = load(fullfile(dataDir,'bvecs.txt'));
bvals = load(fullfile(dataDir,'bvals.txt'));

if size(bvecs,2) ~= 3
   bvecs = bvecs'; 
end

%going to make a b-matrix at each direction. 

defaultDirec = [1 0 0];

ctr = 1; 

for iz = 1:size(princDir,3)
for iy = 1:size(princDir,2)
for ix = 1:size(princDir,1)
if bMask(ix,iy,iz)
    
    voxDir = squeeze(princDir(ix,iy,iz,:));
    rotMat = vrrotvec2mat(vrrotvec(voxDir,defaultDirec));
    
    %rotating the vector matrix
    g = bvecs * rotMat;
    
    b = [g(:,1).^2 2*g(:,1).*g(:,2) 2*g(:,1).*g(:,3) g(:,2).^2 2*g(:,2).*g(:,3) g(:,3).^2];
    b = repmat(bvals(:),[1 6]).*b;
    
    bMat{ctr} = b(:,[1,4,6]);
    ctr= ctr+1; 

end
end
end
end

bMatName = fullfile(dataDir,'bMat.mat');
save(bMatName,'bMat');

end