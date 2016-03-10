function choose_bvec_combos()

load('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/DivFornixBoundingBoxWithPSF/GoldStand/bvecs');
load('/Users/zer/RegFitAD/data/HCPwStruct/RegFitXpts/DivFornixBoundingBoxWithPSF/GoldStand/bvals');


zero_indices = find(bvals<10); 

mat = zeros(14);
for i = 1:14
    for j = 1:14
        
        ind1 = (i-1)*6+1; ind2 = (j-1)*6+1;
        bvecs1 = bvecs(:,ind1:ind1+5);
        bvecs2 = bvecs(:,ind2:ind2+5);
        mat(i,j) = av_sim(bvecs1,bvecs2); 
        
    end
end



end

%calculates the average dot product between all vectors in the set
function av = av_sim(a,b)

av = 0; 
for i = 1:length(a)
   x = a(:,i); 
   for j = 1:length(b)
        y = b(:,j);
        av = av+abs(dot(x,y)); 
   end
end


end