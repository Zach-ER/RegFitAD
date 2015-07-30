function [bMat,bMask] = prepare_b_matrices(V1Name,V2Name,bMask,bvals,bvecs)
%function PREPARE_B_MATRICES will go through the data after it has been
%fitted using FSL. It will make and save the appropriately-rotated
%b-matrices, so that 
princDir = load_untouch_nii(V1Name); 
princDir = princDir.img;
seconDir = load_untouch_nii(V2Name);
seconDir = seconDir.img; 

if size(bvecs,2) ~= 3
   bvecs = bvecs'; 
end

%going to make a b-matrix at each direction. 

defaultDirec = [1; 0; 0];
defaultDirec2 = [0; 1; 0];

ctr = 1; 

bMat = zeros(sum(bMask(:)),length(bvals),3);
for iz = 1:size(bMask,3)
for iy = 1:size(bMask,2)
for ix = 1:size(bMask,1)

    if bMask(ix,iy,iz)   
        voxDir1 = squeeze(princDir(ix,iy,iz,:));
        voxDir2 = squeeze(seconDir(ix,iy,iz,:));
        
        %this aligns the primary direction
        rotMat1 = calc_rot_mat(voxDir1,defaultDirec);
        %aligns secondary direction 
        rotMat2 = calc_rot_mat(rotMat1*voxDir2,defaultDirec2);
        combinedRot = rotMat2*rotMat1; 
        
        if sum(isnan(rotMat1(:)+rotMat2(:))) > 0
            bMask(ix,iy,iz) = 0;
        continue
        end
        %rotating the vector matrix
        g = bvecs * combinedRot';
        
        b = [g(:,1).^2 2*g(:,1).*g(:,2) 2*g(:,1).*g(:,3) g(:,2).^2 2*g(:,2).*g(:,3) g(:,3).^2];
        b = repmat(bvals(:),[1 6]).*b;
        
        bMat(ctr,:,:) = b(:,[1,4,6]);
        ctr= ctr+1;
    end
end
end
end
end

function rotMat = calc_rot_mat(voxDir,chosenDir)

v = cross(voxDir(:),chosenDir(:)) ;
s = norm(v);
c = dot(voxDir(:),chosenDir(:));
vMat = [0,-v(3),v(2);v(3),0,-v(1);-v(2),v(1),0];

rotMat = eye(3) +vMat +  (vMat * vMat) .*(1-c)./(s.^2);


end
