function flatImg = flattener_4d(imgIn,varargin)

%INPUT  A 4-d image, then (optionally) a brainMask
%OUTPUT a 2-d flattened image, with the first 3 dimensions of the input
%being flattened.

sizeIm = size(imgIn);

if nargin > 1
    bMask = varargin{1};
else
    bMask = ones(size(squeeze(imgIn(:,:,:,1))));
end
bMask = bMask > 0.01;


if numel(sizeIm) == 4
    
    nParams = size(imgIn,4);
    flatImg = zeros(sum(bMask(:)) , nParams,'single');
    
    for ii = 1:nParams
        flattened = imgIn(:,:,:,ii);
        flattened = flattened(bMask);
        flatImg(:,ii) = flattened(:);
    end
    
elseif numel(sizeIm) == 3
    
    nParams = size(imgIn,3);
    flatImg = zeros(sum(bMask(:)) , nParams,'single');
    for ii = 1:nParams
        flattened = imgIn(:,:,ii);
        flattened = flattened(bMask);
        flatImg(:,ii) = flattened(:);
    end
end