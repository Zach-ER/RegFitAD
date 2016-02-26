%uses the diffusivities to return the DT vals of MD, FA 
function dtVals = get_DT_from_diffusivities(diffusivities)

MD = mean(diffusivities,2);
tmp = (diffusivities- repmat(MD,[1,3])).^2;
FA = sqrt(1.5) .* sqrt(sum(tmp,2))./sqrt(sum(diffusivities.^2,2));

dtVals(:,1) = MD;
dtVals(:,2) = FA;

end