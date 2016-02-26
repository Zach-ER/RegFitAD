% %adds noise to a voxel's signal. 
% 
function S = add_rician_noise(signals,sigma)

realNoise = sigma.*randn(size(signals));
imNoise =   sigma.*randn(size(signals));


S = ((signals + realNoise).^2 + imNoise.^2).^.5;